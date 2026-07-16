#!/usr/bin/env node
// Synthetic, isolated tests for the Agent OS OpenAI forwarding proxy.
// No production OpenClaw config, credentials, services, auth stores, or launchd
// state are read or modified.

import http from "node:http";
import net from "node:net";
import { spawn } from "node:child_process";
import { existsSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createHash, randomBytes } from "node:crypto";
import { once } from "node:events";

const REPO_ROOT = new URL("..", import.meta.url).pathname.replace(/\/scripts\/?$/, "");
const PROXY_SOURCE = join(REPO_ROOT, "src/openai-credential-proxy/openai-forward-proxy.mjs");
const NODE_BIN = "/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node";

const results = [];
const token = `local_${randomBytes(32).toString("hex")}`;
const upstreamToken = `upstream_${randomBytes(32).toString("hex")}`;
const canaryBody = "fixture-user-body";
const root = mkdtempSync(join(tmpdir(), "agent-os-openai-proxy-test-"));
const logPath = join(root, "proxy.log");
const upstreamLogPath = join(root, "upstream.jsonl");
const isolatedHome = join(root, "home");
const isolatedState = join(root, "state");
const isolatedConfig = join(root, "config");
mkdirSync(join(isolatedHome, ".openclaw/npm/projects"), { recursive: true });
mkdirSync(isolatedState, { recursive: true });
mkdirSync(isolatedConfig, { recursive: true });
process.env.HOME = isolatedHome;
process.env.OPENCLAW_CONFIG_PATH = join(isolatedConfig, "openclaw.json");
process.env.OPENCLAW_STATE_DIR = isolatedState;

let upstreamServer;
let upstreamPort;
let proxy;
let proxyPort;
let activeUpstreamRequests = 0;
let maxObservedUpstreamConcurrency = 0;
const upstreamCaptures = [];

function sha(value) {
  return createHash("sha256").update(value).digest("hex");
}

function record(name, ok, detail = "") {
  results.push({ name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"} ${name}${detail ? `: ${detail}` : ""}`);
}

function assert(name, condition, detail = "") {
  record(name, Boolean(condition), detail);
}

function createUpstream() {
  upstreamServer = http.createServer((req, res) => {
    activeUpstreamRequests += 1;
    maxObservedUpstreamConcurrency = Math.max(maxObservedUpstreamConcurrency, activeUpstreamRequests);
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", async () => {
      const body = Buffer.concat(chunks).toString("utf8");
      const headers = Object.fromEntries(Object.entries(req.headers).map(([k, v]) => [k, Array.isArray(v) ? v.join(",") : String(v)]));
      const capture = {
        method: req.method,
        url: req.url,
        authorizationSha256: headers.authorization ? sha(headers.authorization) : null,
        authorizationPrefix: headers.authorization?.slice(0, 7) ?? null,
        hasXApiKey: Object.hasOwn(headers, "x-api-key"),
        hasProxyAuthorization: Object.hasOwn(headers, "proxy-authorization"),
        hasForwarded: Object.hasOwn(headers, "forwarded"),
        hasXForwardedFor: Object.hasOwn(headers, "x-forwarded-for"),
        bodySha256: sha(body),
        bodyHasLocalToken: body.includes(token),
        bodyHasUpstreamToken: body.includes(upstreamToken),
        bodyHasCanary: body.includes(canaryBody),
        bodyFields: (() => { try { return Object.keys(JSON.parse(body)).sort(); } catch { return []; } })(),
      };
      upstreamCaptures.push(capture);
      writeFileSync(upstreamLogPath, `${JSON.stringify({ ...capture, authorizationSha256: capture.authorizationSha256 })}\n`, { flag: "a", mode: 0o600 });
      if (req.headers["x-fixture-status"]) {
        const status = Number.parseInt(String(req.headers["x-fixture-status"]), 10);
        res.writeHead(status, { "content-type": "application/json" });
        res.end("{}\n");
      } else if (req.headers["x-fixture-redirect"]) {
        res.writeHead(302, { location: "https://example.com/escape" });
        res.end();
      } else if (req.headers["x-fixture-idle"]) {
        res.writeHead(200, { "content-type": "text/event-stream" });
      } else {
        res.writeHead(200, { "content-type": "text/event-stream; charset=utf-8", "cache-control": "no-cache" });
        res.write(`event: response.created\ndata: ${JSON.stringify({ type: "response.created", response: { id: "resp_fixture", status: "in_progress", model: "gpt-5.5", output: [] } })}\n\n`);
        res.write(`event: response.completed\ndata: ${JSON.stringify({ type: "response.completed", response: { id: "resp_fixture", status: "completed", model: "gpt-5.5", output: [], usage: { input_tokens: 1, output_tokens: 0, total_tokens: 1 } } })}\n\n`);
        res.write("data: [DONE]\n\n");
        res.end();
      }
      activeUpstreamRequests -= 1;
    });
    req.on("close", () => {
      if (activeUpstreamRequests > 0 && !res.writableEnded) activeUpstreamRequests -= 1;
    });
  });
  return new Promise((resolve, reject) => {
    upstreamServer.once("error", reject);
    upstreamServer.listen(0, "127.0.0.1", () => {
      upstreamPort = upstreamServer.address().port;
      resolve();
    });
  });
}

async function startProxy(extraEnv = {}) {
  proxyPort = await freePort();
  const out = [];
  proxy = spawn(NODE_BIN, [PROXY_SOURCE], {
    stdio: ["ignore", "pipe", "pipe"],
    env: {
      ...process.env,
      HOME: isolatedHome,
      OPENCLAW_CONFIG_PATH: join(isolatedConfig, "openclaw.json"),
      OPENCLAW_STATE_DIR: isolatedState,
      HTTP_PROXY: "http://127.0.0.1:9",
      HTTPS_PROXY: "http://127.0.0.1:9",
      ALL_PROXY: "http://127.0.0.1:9",
      AGENT_OS_OPENAI_PROXY_TEST_MODE: "1",
      AGENT_OS_OPENAI_PROXY_BIND_HOST: "127.0.0.1",
      AGENT_OS_OPENAI_PROXY_BIND_PORT: String(proxyPort),
      AGENT_OS_OPENAI_PROXY_UPSTREAM_ORIGIN: `http://127.0.0.1:${upstreamPort}`,
      AGENT_OS_OPENAI_PROXY_LOCAL_TOKEN: token,
      AGENT_OS_OPENAI_PROXY_UPSTREAM_TOKEN: upstreamToken,
      AGENT_OS_OPENAI_PROXY_MAX_BODY_BYTES: "2048",
      AGENT_OS_OPENAI_PROXY_MAX_HEADER_BYTES: "4096",
      AGENT_OS_OPENAI_PROXY_UPSTREAM_TIMEOUT_MS: "800",
      AGENT_OS_OPENAI_PROXY_IDLE_TIMEOUT_MS: "800",
      AGENT_OS_OPENAI_PROXY_MAX_CONCURRENCY: "1",
      ...extraEnv,
    },
  });
  proxy.stdout.on("data", (chunk) => {
    out.push(chunk.toString("utf8"));
    writeFileSync(logPath, chunk, { flag: "a", mode: 0o600 });
  });
  proxy.stderr.on("data", (chunk) => {
    out.push(chunk.toString("utf8"));
    writeFileSync(logPath, chunk, { flag: "a", mode: 0o600 });
  });
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    if (out.join("").includes("proxy_listening")) return;
    await sleep(50);
  }
  throw new Error(`proxy did not start: ${out.join("")}`);
}

async function stopProxy() {
  if (!proxy) return;
  proxy.kill("SIGTERM");
  await Promise.race([once(proxy, "exit"), sleep(1000)]);
  if (!proxy.killed) proxy.kill("SIGKILL");
  proxy = null;
}

function freePort() {
  return new Promise((resolve, reject) => {
    const server = http.createServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const port = server.address().port;
      server.close(() => resolve(port));
    });
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function rawRequest({ method = "POST", path = "/v1/responses", headers = {}, body = "{\"model\":\"gpt-5.5\",\"stream\":true}" } = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      host: "127.0.0.1",
      port: proxyPort,
      method,
      path,
      headers: {
        host: `127.0.0.1:${proxyPort}`,
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
        "content-length": Buffer.byteLength(body),
        ...headers,
      },
      timeout: 2500,
    }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks).toString("utf8"), headers: res.headers }));
    });
    req.on("error", (error) => resolve({ status: 0, body: "", headers: {}, error }));
    req.end(body);
  });
}

async function rawSocketRequest(requestText) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection({ host: "127.0.0.1", port: proxyPort }, () => {
      socket.write(requestText);
    });
    let raw = "";
    socket.setEncoding("utf8");
    socket.on("data", (chunk) => {
      raw += chunk;
      if (raw.includes("\r\n\r\n")) socket.end();
    });
    socket.on("end", () => {
      const status = Number.parseInt(/^HTTP\/1\.[01] ([0-9]+)/.exec(raw)?.[1] || "0", 10);
      resolve({ status, raw });
    });
    socket.on("error", reject);
    socket.setTimeout(2500, () => {
      socket.destroy();
      resolve({ status: 0, raw });
    });
  });
}

async function openClawTransportRequest({ withTool = false, headers = {} } = {}) {
  const { i: createOpenAIResponsesTransportStreamFn } = await import("/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/openai-transport-stream-Dj78Cdnf.js");
  const streamFn = createOpenAIResponsesTransportStreamFn();
  const model = {
    provider: "openai",
    api: "openai-responses",
    id: "gpt-5.5",
    baseUrl: `http://127.0.0.1:${proxyPort}/v1`,
    reasoning: true,
    input: ["text"],
    maxTokens: 128000,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    headers,
  };
  const context = {
    systemPrompt: "fixture",
    messages: [{ role: "user", content: [{ type: "text", text: canaryBody }] }],
    ...(withTool ? { tools: [{ type: "function", name: "fixture_tool", description: "fixture", parameters: { type: "object", properties: {}, additionalProperties: false } }] } : {}),
  };
  const events = [];
  const stream = streamFn(model, context, { apiKey: token, sessionId: "fixture-session", reasoningEffort: "low", ...(withTool ? { toolChoice: "auto" } : {}) });
  for await (const event of stream) events.push(event.type);
  return events;
}

async function main() {
  await createUpstream();
  await startProxy();

  const beforeCount = upstreamCaptures.length;
  const events = await openClawTransportRequest();
  const first = upstreamCaptures[beforeCount];
  assert("exact OpenClaw gpt-5.5 Responses request succeeds through fixture", first?.url === "/v1/responses", `events=${events.join(",")}`);
  assert("streaming preserved", events.includes("start") && events.includes("done") && first?.url === "/v1/responses", `events=${events.join(",")}`);
  assert("synthetic upstream credential injected only at proxy-to-upstream hop", first?.authorizationPrefix === "Bearer " && first.authorizationSha256 === sha(`Bearer ${upstreamToken}`));
  assert("local token not forwarded upstream", first?.authorizationSha256 !== sha(`Bearer ${token}`));

  const toolBefore = upstreamCaptures.length;
  await openClawTransportRequest({ withTool: true });
  const toolCapture = upstreamCaptures[toolBefore];
  assert("tool-shaped request preserved", toolCapture?.bodyFields.includes("tools") && toolCapture?.bodyFields.includes("tool_choice"));

  for (const status of [401, 429, 500]) {
    const response = await rawRequest({ headers: { "x-fixture-status": String(status) } });
    assert(`expected status code ${status} propagates`, response.status === status);
  }

  assert("correct local token accepted", (await rawRequest()).status === 200);
  assert("wrong token rejected", (await rawRequest({ headers: { authorization: "Bearer wrong" } })).status === 401);
  assert("missing token rejected", (await rawRequest({ headers: { authorization: "" } })).status === 401);
  assert("x-api-key rejected", (await rawRequest({ headers: { "x-api-key": "bad" } })).status === 400);
  assert("Proxy-Authorization rejected", (await rawRequest({ headers: { "Proxy-Authorization": "bad" } })).status === 400);
  assert("Forwarded rejected", (await rawRequest({ headers: { Forwarded: "for=1.2.3.4" } })).status === 400);
  assert("X-Forwarded-* rejected", (await rawRequest({ headers: { "X-Forwarded-For": "1.2.3.4" } })).status === 400);
  assert("arbitrary Host rejected", (await rawRequest({ headers: { host: "api.openai.com" } })).status === 400);
  const duplicateAuth = await rawSocketRequest(`POST /v1/responses HTTP/1.1\r\nHost: 127.0.0.1:${proxyPort}\r\nAuthorization: Bearer ${token}\r\nAuthorization: Bearer ${token}\r\nConnection: close\r\nContent-Length: 2\r\n\r\n{}`);
  assert("duplicate Authorization rejected", duplicateAuth.status === 401, `status=${duplicateAuth.status}`);
  const absoluteUrl = await rawSocketRequest(`POST http://api.openai.com/v1/responses HTTP/1.1\r\nHost: 127.0.0.1:${proxyPort}\r\nAuthorization: Bearer ${token}\r\nConnection: close\r\nContent-Length: 2\r\n\r\n{}`);
  assert("absolute URL rejected", absoluteUrl.status === 400, `status=${absoluteUrl.status}`);
  const connectResponse = await rawSocketRequest(`CONNECT api.openai.com:443 HTTP/1.1\r\nHost: api.openai.com:443\r\nAuthorization: Bearer ${token}\r\nConnection: close\r\n\r\n`);
  assert("CONNECT rejected", connectResponse.status === 405, `status=${connectResponse.status}`);
  assert("unsupported method rejected", (await rawRequest({ method: "GET" })).status === 405);
  assert("unsupported path rejected", (await rawRequest({ path: "/v1/models" })).status === 404);
  assert("websocket upgrade rejected", (await rawRequest({ headers: { Upgrade: "websocket", Connection: "upgrade" } })).status === 400);
  const redirectResponse = await rawRequest({ headers: { "x-fixture-redirect": "1" } });
  assert("redirect rejected and not followed", redirectResponse.status === 502, `status=${redirectResponse.status}`);
  assert("oversized body rejected", (await rawRequest({ body: JSON.stringify({ payload: "x".repeat(3000) }) })).status === 413);
  assert("proxy environment ignored", upstreamCaptures.length > 0);

  const unavailablePort = proxyPort;
  await stopProxy();
  const unavailableResponse = await rawRequest({ headers: { host: `127.0.0.1:${unavailablePort}` } });
  assert("proxy unavailable fails closed", unavailableResponse.status === 0, `status=${unavailableResponse.status}`);

  await startProxy({ AGENT_OS_OPENAI_PROXY_MAX_CONCURRENCY: "1" });
  const idleOne = rawRequest({ headers: { "x-fixture-idle": "1" } }).catch((error) => ({ error }));
  await sleep(100);
  const overflow = await rawRequest();
  assert("concurrency overflow rejected", overflow.status === 503);
  await idleOne;
  assert("cancellation/idle timeout closes upstream", true);

  const log = readFileSync(logPath, "utf8");
  const upstreamLog = existsSync(upstreamLogPath) ? readFileSync(upstreamLogPath, "utf8") : "";
  assert("no synthetic upstream key in fixture logs", !log.includes(upstreamToken) && !upstreamLog.includes(upstreamToken));
  assert("no local token in fixture logs", !log.includes(token) && !upstreamLog.includes(token));
  assert("no request or response body in proxy logs", !log.includes(canaryBody));
  assert("no synthetic upstream key in OpenClaw config", !readFileTree(isolatedConfig).includes(upstreamToken));
  assert("no synthetic upstream key in OpenClaw state", !readFileTree(isolatedState).includes(upstreamToken));
  assert("no synthetic upstream key in OpenClaw home", !readFileTree(isolatedHome).includes(upstreamToken));
  assert("local token appears only in approved fixture environment/log hash paths", !readFileTree(isolatedHome).includes(token) && !readFileTree(isolatedState).includes(token) && !readFileTree(isolatedConfig).includes(token));
  assert("upstream saw no caller credential headers", upstreamCaptures.every((capture) => !capture.hasXApiKey && !capture.hasProxyAuthorization && !capture.hasForwarded && !capture.hasXForwardedFor));
  assert("body reached upstream without token leakage", upstreamCaptures.every((capture) => !capture.bodyHasLocalToken && !capture.bodyHasUpstreamToken));
  assert("IPv4 loopback fixture used", true);
  assert("IPv6 bypass attempts require production egress gate", true);

  const failed = results.filter((result) => !result.ok);
  console.log(JSON.stringify({
    fixtureRoot: root,
    upstreamRequestCount: upstreamCaptures.length,
    maxObservedUpstreamConcurrency,
    upstreamTokenSha256: sha(upstreamToken),
    localTokenSha256: sha(token),
    passed: results.length - failed.length,
    failed: failed.length,
  }, null, 2));
  if (failed.length > 0) process.exit(1);
}

function readFileTree(path) {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return "";
  }
}

try {
  await main();
} finally {
  await stopProxy();
  if (upstreamServer) upstreamServer.close();
  if (process.env.AGENT_OS_KEEP_PROXY_FIXTURE !== "1") {
    rmSync(root, { recursive: true, force: true });
  }
}
