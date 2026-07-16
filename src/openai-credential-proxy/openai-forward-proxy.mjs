#!/usr/bin/env node
// Agent OS OpenAI forwarding proxy.
//
// Initial scope is intentionally narrow: authenticate a local OpenClaw caller,
// strip caller credentials, inject the broker-owned upstream credential, and
// forward only POST /v1/responses to a fixed OpenAI-compatible upstream.

import http from "node:http";
import https from "node:https";
import { createHash, timingSafeEqual } from "node:crypto";
import { createReadStream, existsSync, readFileSync, statSync } from "node:fs";
import { URL } from "node:url";

const TEST_MODE = process.env.AGENT_OS_OPENAI_PROXY_TEST_MODE === "1";
const DEFAULT_BIND_HOST = "127.0.0.1";
const DEFAULT_BIND_PORT = 18187;
const DEFAULT_UPSTREAM_ORIGIN = "https://api.openai.com";
const PRODUCTION_UPSTREAM_TOKEN_PATH = "/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets/openai-upstream.json";
const PRODUCTION_LOCAL_TOKEN_PATH = "/Users/openai-credential-broker/agent-os-openai-credential-broker/local-token/openai-proxy-token";

const BIND_HOST = process.env.AGENT_OS_OPENAI_PROXY_BIND_HOST || DEFAULT_BIND_HOST;
const BIND_PORT = Number.parseInt(process.env.AGENT_OS_OPENAI_PROXY_BIND_PORT || `${DEFAULT_BIND_PORT}`, 10);
const UPSTREAM_ORIGIN = TEST_MODE && process.env.AGENT_OS_OPENAI_PROXY_UPSTREAM_ORIGIN
  ? process.env.AGENT_OS_OPENAI_PROXY_UPSTREAM_ORIGIN
  : DEFAULT_UPSTREAM_ORIGIN;
const LOCAL_TOKEN_PATH = process.env.AGENT_OS_OPENAI_PROXY_LOCAL_TOKEN_PATH || PRODUCTION_LOCAL_TOKEN_PATH;
const UPSTREAM_TOKEN_PATH = process.env.AGENT_OS_OPENAI_PROXY_UPSTREAM_TOKEN_PATH || PRODUCTION_UPSTREAM_TOKEN_PATH;

const MAX_HEADER_BYTES = Number.parseInt(process.env.AGENT_OS_OPENAI_PROXY_MAX_HEADER_BYTES || "16384", 10);
const MAX_BODY_BYTES = Number.parseInt(process.env.AGENT_OS_OPENAI_PROXY_MAX_BODY_BYTES || "4194304", 10);
const REQUEST_TIMEOUT_MS = Number.parseInt(process.env.AGENT_OS_OPENAI_PROXY_REQUEST_TIMEOUT_MS || "30000", 10);
const UPSTREAM_TIMEOUT_MS = Number.parseInt(process.env.AGENT_OS_OPENAI_PROXY_UPSTREAM_TIMEOUT_MS || "30000", 10);
const IDLE_TIMEOUT_MS = Number.parseInt(process.env.AGENT_OS_OPENAI_PROXY_IDLE_TIMEOUT_MS || "120000", 10);
const MAX_CONCURRENCY = Number.parseInt(process.env.AGENT_OS_OPENAI_PROXY_MAX_CONCURRENCY || "8", 10);

let activeRequests = 0;

function readTokenFile(path, key) {
  const stat = statSync(path);
  if (!stat.isFile()) throw new Error(`token path is not a file: ${path}`);
  const raw = readFileSync(path, "utf8").trim();
  if (!raw) throw new Error(`token path is empty: ${path}`);
  if (raw.startsWith("{")) {
    const parsed = JSON.parse(raw);
    const value = parsed?.[key];
    if (typeof value !== "string" || !value.trim()) throw new Error(`token field missing: ${key}`);
    return value.trim();
  }
  return raw;
}

function resolveLocalToken() {
  if (TEST_MODE && process.env.AGENT_OS_OPENAI_PROXY_LOCAL_TOKEN) {
    return process.env.AGENT_OS_OPENAI_PROXY_LOCAL_TOKEN;
  }
  return readTokenFile(LOCAL_TOKEN_PATH, "localToken");
}

function resolveUpstreamToken() {
  if (TEST_MODE && process.env.AGENT_OS_OPENAI_PROXY_UPSTREAM_TOKEN) {
    return process.env.AGENT_OS_OPENAI_PROXY_UPSTREAM_TOKEN;
  }
  return readTokenFile(UPSTREAM_TOKEN_PATH, "openaiApiKey");
}

const LOCAL_TOKEN = resolveLocalToken();
const UPSTREAM_TOKEN = resolveUpstreamToken();
const LOCAL_TOKEN_BUFFER = Buffer.from(LOCAL_TOKEN);

function tokenHash(value) {
  return createHash("sha256").update(value).digest("hex").slice(0, 16);
}

function logMeta(event, fields = {}) {
  const safe = {
    ts: new Date().toISOString(),
    event,
    ...fields,
  };
  process.stdout.write(`${JSON.stringify(safe)}\n`);
}

function reject(res, status, code) {
  res.writeHead(status, {
    "content-type": "application/json",
    "cache-control": "no-store",
  });
  res.end(`${JSON.stringify({ error: code })}\n`);
}

function parseBearer(req) {
  const raw = req.headers.authorization;
  if (Array.isArray(raw)) return { ok: false, code: "duplicate_authorization" };
  if (typeof raw !== "string") return { ok: false, code: "missing_authorization" };
  const match = /^Bearer ([A-Za-z0-9._~+/-]+={0,2})$/.exec(raw.trim());
  if (!match) return { ok: false, code: "invalid_authorization" };
  const supplied = Buffer.from(match[1]);
  if (supplied.length !== LOCAL_TOKEN_BUFFER.length) return { ok: false, code: "invalid_authorization" };
  if (!timingSafeEqual(supplied, LOCAL_TOKEN_BUFFER)) return { ok: false, code: "invalid_authorization" };
  return { ok: true };
}

function hasForbiddenHeader(req) {
  for (const name of Object.keys(req.headers)) {
    const lower = name.toLowerCase();
    if (lower === "x-api-key" || lower === "proxy-authorization" || lower === "forwarded" || lower.startsWith("x-forwarded-")) {
      return lower;
    }
  }
}

function hasDuplicateHeader(req, headerName) {
  const wanted = headerName.toLowerCase();
  let count = 0;
  for (let index = 0; index < req.rawHeaders.length; index += 2) {
    if (req.rawHeaders[index]?.toLowerCase() === wanted) count += 1;
  }
  return count > 1;
}

function buildForwardHeaders(req) {
  const headers = {};
  for (const [name, value] of Object.entries(req.headers)) {
    const lower = name.toLowerCase();
    if (
      lower === "authorization" ||
      lower === "x-api-key" ||
      lower === "proxy-authorization" ||
      lower === "forwarded" ||
      lower.startsWith("x-forwarded-") ||
      lower === "host" ||
      lower === "connection" ||
      lower === "proxy-connection" ||
      lower === "upgrade" ||
      lower === "keep-alive" ||
      lower === "transfer-encoding"
    ) continue;
    if (value !== undefined) headers[name] = value;
  }
  headers.authorization = `Bearer ${UPSTREAM_TOKEN}`;
  headers.host = new URL(UPSTREAM_ORIGIN).host;
  return headers;
}

function requestPath(req) {
  try {
    const parsed = new URL(req.url, "http://127.0.0.1");
    return parsed.pathname + parsed.search;
  } catch {
    return req.url || "";
  }
}

function isAbsoluteForm(url) {
  return /^https?:\/\//i.test(url || "");
}

function handleHealth(req, res) {
  if (req.method !== "GET") return reject(res, 405, "method_not_allowed");
  res.writeHead(200, { "content-type": "application/json", "cache-control": "no-store" });
  res.end(`${JSON.stringify({ ok: true, service: "agent-os-openai-forward-proxy" })}\n`);
}

function forwardResponses(req, res) {
  if (activeRequests >= MAX_CONCURRENCY) return reject(res, 503, "concurrency_limit");
  activeRequests += 1;

  const upstream = new URL(UPSTREAM_ORIGIN);
  const client = upstream.protocol === "http:" && TEST_MODE ? http : https;
  const headers = buildForwardHeaders(req);
  const options = {
    protocol: upstream.protocol,
    hostname: upstream.hostname,
    port: upstream.port || (upstream.protocol === "https:" ? 443 : 80),
    method: "POST",
    path: "/v1/responses",
    headers,
    timeout: UPSTREAM_TIMEOUT_MS,
  };

  let bodyBytes = 0;
  let completed = false;
  const upstreamReq = client.request(options, (upstreamRes) => {
    if ((upstreamRes.statusCode || 0) >= 300 && (upstreamRes.statusCode || 0) < 400 && upstreamRes.headers.location) {
      clearTimeout(timeout);
      res.writeHead(502, {
        "content-type": "application/json",
        "cache-control": "no-store",
        "connection": "close",
      });
      res.end(`${JSON.stringify({ error: "upstream_redirect_rejected" })}\n`);
      completed = true;
      activeRequests -= 1;
      logMeta("request_redirect_rejected", {
        method: req.method,
        path: requestPath(req),
        upstreamStatus: upstreamRes.statusCode,
      });
      upstreamRes.resume();
      return;
    }
    res.writeHead(upstreamRes.statusCode || 502, sanitizeResponseHeaders(upstreamRes.headers));
    upstreamRes.pipe(res);
    upstreamRes.on("end", () => {
      completed = true;
      activeRequests -= 1;
      logMeta("request_complete", {
        method: req.method,
        path: requestPath(req),
        upstreamStatus: upstreamRes.statusCode,
      });
    });
  });

  const timeout = setTimeout(() => {
    upstreamReq.destroy(new Error("idle timeout"));
    if (!res.headersSent) reject(res, 504, "idle_timeout");
  }, IDLE_TIMEOUT_MS);

  upstreamReq.on("timeout", () => {
    upstreamReq.destroy(new Error("upstream timeout"));
    if (!res.headersSent) reject(res, 504, "upstream_timeout");
  });
  upstreamReq.on("error", (error) => {
    clearTimeout(timeout);
    if (!completed) {
      activeRequests -= 1;
      completed = true;
    }
    if (!res.headersSent) reject(res, 502, "upstream_error");
    else res.destroy(error);
    logMeta("request_error", {
      method: req.method,
      path: requestPath(req),
      error: error.message,
    });
  });
  upstreamReq.on("close", () => clearTimeout(timeout));
  res.on("close", () => {
    if (!completed) upstreamReq.destroy(new Error("client disconnected"));
  });

  req.on("data", (chunk) => {
    bodyBytes += chunk.length;
    if (bodyBytes > MAX_BODY_BYTES) {
      upstreamReq.destroy(new Error("body too large"));
      if (!res.headersSent) reject(res, 413, "body_too_large");
      req.destroy();
      return;
    }
    upstreamReq.write(chunk);
  });
  req.on("end", () => upstreamReq.end());
}

function sanitizeResponseHeaders(headers) {
  const out = {};
  for (const [name, value] of Object.entries(headers)) {
    const lower = name.toLowerCase();
    if (lower === "set-cookie" || lower === "www-authenticate" || lower === "proxy-authenticate") continue;
    if (lower === "connection" || lower === "transfer-encoding" || lower === "keep-alive") continue;
    out[name] = value;
  }
  return out;
}

function route(req, res) {
  req.setTimeout(REQUEST_TIMEOUT_MS, () => {
    reject(res, 408, "request_timeout");
    req.destroy();
  });

  const host = req.headers.host;
  const expectedHost = `${BIND_HOST}:${BIND_PORT}`;
  const path = requestPath(req);

  if (path === "/healthz") return handleHealth(req, res);
  if (req.method === "CONNECT") return reject(res, 405, "connect_rejected");
  if (isAbsoluteForm(req.url)) return reject(res, 400, "absolute_url_rejected");
  if (req.headers.upgrade) return reject(res, 400, "upgrade_rejected");
  if (host && host !== expectedHost && host !== "localhost" && !host.startsWith("localhost:")) return reject(res, 400, "host_rejected");
  if (req.method !== "POST") return reject(res, 405, "method_not_allowed");
  if (path !== "/v1/responses") return reject(res, 404, "path_not_allowed");
  if (hasDuplicateHeader(req, "authorization")) return reject(res, 401, "duplicate_authorization");
  const forbidden = hasForbiddenHeader(req);
  if (forbidden) return reject(res, 400, `forbidden_header:${forbidden}`);
  const auth = parseBearer(req);
  if (!auth.ok) return reject(res, 401, auth.code);
  return forwardResponses(req, res);
}

if (!TEST_MODE && UPSTREAM_ORIGIN !== DEFAULT_UPSTREAM_ORIGIN) {
  throw new Error("production upstream origin must be https://api.openai.com");
}

if (!Number.isInteger(BIND_PORT) || BIND_PORT < 1 || BIND_PORT > 65535) {
  throw new Error("invalid bind port");
}

if (!existsSync(LOCAL_TOKEN_PATH) && !(TEST_MODE && process.env.AGENT_OS_OPENAI_PROXY_LOCAL_TOKEN)) {
  throw new Error("local token unavailable");
}
if (!existsSync(UPSTREAM_TOKEN_PATH) && !(TEST_MODE && process.env.AGENT_OS_OPENAI_PROXY_UPSTREAM_TOKEN)) {
  throw new Error("upstream token unavailable");
}

const server = http.createServer({ maxHeaderSize: MAX_HEADER_BYTES }, route);
server.on("connect", (_req, socket) => {
  socket.end("HTTP/1.1 405 Method Not Allowed\r\nConnection: close\r\nContent-Length: 0\r\n\r\n");
});
server.listen(BIND_PORT, BIND_HOST, () => {
  logMeta("proxy_listening", {
    bindHost: BIND_HOST,
    bindPort: BIND_PORT,
    upstreamOrigin: TEST_MODE ? UPSTREAM_ORIGIN : DEFAULT_UPSTREAM_ORIGIN,
    localTokenHash: tokenHash(LOCAL_TOKEN),
  });
});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    server.close(() => process.exit(0));
  });
}

export {
  buildForwardHeaders,
  parseBearer,
  sanitizeResponseHeaders,
};
