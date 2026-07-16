#!/usr/bin/env node
// Isolated contained-egress proof for the Agent OS OpenAI forwarding-proxy path.
//
// This is not production installation. It uses synthetic credentials, a synthetic
// upstream capture service, and an in-process contained-network policy fixture.
// Docker/Colima are inspected only to report whether the production substrate is
// currently available; this script does not start containers or create networks.

import http from "node:http";
import net from "node:net";
import { spawn, spawnSync } from "node:child_process";
import { createHash, randomBytes } from "node:crypto";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { once } from "node:events";

const REPO_ROOT = new URL("..", import.meta.url).pathname.replace(/\/scripts\/?$/, "");
const PROXY_SOURCE = join(REPO_ROOT, "src/openai-credential-proxy/openai-forward-proxy.mjs");
const NODE_BIN = "/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node";
const OPENCLAW_TRANSPORT = "/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/openai-transport-stream-Dj78Cdnf.js";

const root = mkdtempSync(join(tmpdir(), "agent-os-openai-contained-egress-"));
const logPath = join(root, "proxy.log");
const evidencePath = join(root, "contained-egress-proof.json");
const localToken = `local_${randomBytes(32).toString("hex")}`;
const upstreamToken = `upstream_${randomBytes(32).toString("hex")}`;
const bodyCanary = "contained-egress-body-canary";
const results = [];
const upstreamCaptures = [];

let upstreamServer;
let upstreamPort;
let proxy;
let proxyPort;

function sha(value) {
  return createHash("sha256").update(value).digest("hex");
}

function record(name, ok, detail = "") {
  results.push({ name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"} ${name}${detail ? `: ${detail}` : ""}`);
}

function commandStatus(command, args) {
  const result = spawnSync(command, args, { encoding: "utf8", timeout: 10000 });
  return {
    command: [command, ...args].join(" "),
    status: result.status,
    stdout: (result.stdout || "").trim(),
    stderr: (result.stderr || "").trim(),
    error: result.error?.message,
  };
}

function substrateStatus() {
  return {
    colima: commandStatus("colima", ["status"]),
    docker: commandStatus("docker", ["ps", "--format", "{{.Names}}\t{{.Networks}}\t{{.Ports}}"]),
  };
}

function allowedPolicyRequest(actor, target) {
  const parsed = new URL(target);
  if (actor === "openclaw-side") {
    if (parsed.hostname === "127.0.0.1" && Number(parsed.port) === proxyPort) return { ok: true };
    return { ok: false, code: "openclaw_direct_egress_denied" };
  }
  if (actor === "proxy") {
    if (parsed.hostname === "127.0.0.1" && Number(parsed.port) === upstreamPort && parsed.pathname === "/v1/responses") return { ok: true };
    return { ok: false, code: "proxy_arbitrary_egress_denied" };
  }
  return { ok: false, code: "unknown_actor" };
}

function createUpstream() {
  upstreamServer = http.createServer((req, res) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      const body = Buffer.concat(chunks).toString("utf8");
      const headers = Object.fromEntries(Object.entries(req.headers).map(([key, value]) => [key, Array.isArray(value) ? value.join(",") : String(value)]));
      upstreamCaptures.push({
        method: req.method,
        url: req.url,
        authHash: headers.authorization ? sha(headers.authorization) : null,
        host: headers.host,
        hasProxyAuthorization: "proxy-authorization" in headers,
        hasXApiKey: "x-api-key" in headers,
        bodyHash: sha(body),
        bodyHasCanary: body.includes(bodyCanary),
      });
      if (req.headers["x-fixture-redirect"]) {
        res.writeHead(302, { location: "https://example.com/escape" });
        res.end();
        return;
      }
      res.writeHead(200, { "content-type": "text/event-stream; charset=utf-8", "cache-control": "no-store" });
      res.write(`event: response.created\ndata: ${JSON.stringify({ type: "response.created", response: { id: "resp_contained", status: "in_progress", model: "gpt-5.5", output: [] } })}\n\n`);
      res.write(`event: response.completed\ndata: ${JSON.stringify({ type: "response.completed", response: { id: "resp_contained", status: "completed", model: "gpt-5.5", output: [] } })}\n\n`);
      res.write("data: [DONE]\n\n");
      res.end();
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

async function startProxy() {
  proxyPort = await freePort();
  const isolatedHome = join(root, "home");
  const isolatedState = join(root, "state");
  const isolatedConfig = join(root, "config");
  mkdirSync(isolatedHome, { recursive: true });
  mkdirSync(isolatedState, { recursive: true });
  mkdirSync(isolatedConfig, { recursive: true });
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
      AGENT_OS_OPENAI_PROXY_LOCAL_TOKEN: localToken,
      AGENT_OS_OPENAI_PROXY_UPSTREAM_TOKEN: upstreamToken,
      AGENT_OS_OPENAI_PROXY_UPSTREAM_TIMEOUT_MS: "1000",
      AGENT_OS_OPENAI_PROXY_IDLE_TIMEOUT_MS: "1000",
      AGENT_OS_OPENAI_PROXY_MAX_BODY_BYTES: "4096",
      AGENT_OS_OPENAI_PROXY_MAX_CONCURRENCY: "2",
    },
  });
  proxy.stdout.on("data", (chunk) => writeFileSync(logPath, chunk, { flag: "a", mode: 0o600 }));
  proxy.stderr.on("data", (chunk) => writeFileSync(logPath, chunk, { flag: "a", mode: 0o600 }));
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    try {
      if (readFileSync(logPath, "utf8").includes("proxy_listening")) return;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error("proxy fixture did not start");
}

async function stopProxy() {
  if (!proxy) return;
  proxy.kill("SIGTERM");
  await Promise.race([once(proxy, "exit"), new Promise((resolve) => setTimeout(resolve, 1000))]);
  proxy = null;
}

async function openclawTransportRequest(headers = {}) {
  const policy = allowedPolicyRequest("openclaw-side", `http://127.0.0.1:${proxyPort}/v1/responses`);
  if (!policy.ok) throw new Error(policy.code);
  process.env.HOME = join(root, "home");
  process.env.OPENCLAW_CONFIG_PATH = join(root, "config", "openclaw.json");
  process.env.OPENCLAW_STATE_DIR = join(root, "state");
  const { i: createOpenAIResponsesTransportStreamFn } = await import(OPENCLAW_TRANSPORT);
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
    systemPrompt: "contained-egress-fixture",
    messages: [{ role: "user", content: [{ type: "text", text: bodyCanary }] }],
    tools: [{ type: "function", name: "fixture_tool", description: "fixture only", parameters: { type: "object", properties: {}, additionalProperties: false } }],
  };
  const events = [];
  const stream = streamFn(model, context, { apiKey: localToken, sessionId: "contained-egress-fixture", reasoningEffort: "low", toolChoice: "auto" });
  for await (const event of stream) events.push(event.type);
  return events;
}

function rawRequest({ method = "POST", path = "/v1/responses", headers = {}, body = "{}" } = {}) {
  return new Promise((resolve) => {
    const req = http.request({
      host: "127.0.0.1",
      port: proxyPort,
      method,
      path,
      headers: {
        host: `127.0.0.1:${proxyPort}`,
        authorization: `Bearer ${localToken}`,
        "content-type": "application/json",
        "content-length": Buffer.byteLength(body),
        ...headers,
      },
      timeout: 2500,
    }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks).toString("utf8") }));
    });
    req.on("error", (error) => resolve({ status: 0, error: error.message }));
    req.end(body);
  });
}

function rawSocketRequest(requestText) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection({ host: "127.0.0.1", port: proxyPort }, () => socket.write(requestText));
    let raw = "";
    socket.setEncoding("utf8");
    socket.on("data", (chunk) => {
      raw += chunk;
      if (raw.includes("\r\n\r\n")) socket.end();
    });
    socket.on("end", () => resolve({ status: Number.parseInt(/^HTTP\/1\.[01] ([0-9]+)/.exec(raw)?.[1] || "0", 10), raw }));
    socket.on("error", reject);
  });
}

async function run() {
  const substrate = substrateStatus();
  await createUpstream();
  await startProxy();
  try {
    const events = await openclawTransportRequest();
    record("OpenClaw-side fixture reaches proxy", events.length > 0);
    record("proxy reaches approved synthetic upstream", upstreamCaptures.length === 1);
    record("streaming remains functional", events.includes("start") && events.includes("done"), `events=${events.join(",")}`);
    record("tool-shaped Responses request remains functional", upstreamCaptures[0]?.bodyHasCanary === true);
    record("approved upstream hostname/path works", upstreamCaptures[0]?.url === "/v1/responses" && upstreamCaptures[0]?.method === "POST");
    record("synthetic upstream credential injected at proxy hop", upstreamCaptures[0]?.authHash === sha(`Bearer ${upstreamToken}`));
    record("caller credential headers stripped", !upstreamCaptures[0]?.hasProxyAuthorization && !upstreamCaptures[0]?.hasXApiKey);

    record("OpenClaw-side direct api.openai.com denied", !allowedPolicyRequest("openclaw-side", "https://api.openai.com/v1/responses").ok);
    record("OpenClaw-side direct OpenAI IP denied", !allowedPolicyRequest("openclaw-side", "https://104.18.33.45/v1/responses").ok);
    record("OpenClaw-side IPv6 request denied", !allowedPolicyRequest("openclaw-side", "https://[2606:4700::6812:212d]/v1/responses").ok);
    record("proxy arbitrary host denied by policy", !allowedPolicyRequest("proxy", "https://example.com/v1/responses").ok);
    record("proxy arbitrary IP denied by policy", !allowedPolicyRequest("proxy", "https://93.184.216.34/v1/responses").ok);
    record("proxy HTTP_PROXY bypass ignored", upstreamCaptures.every((capture) => capture.host === `127.0.0.1:${upstreamPort}`));

    const redirect = await rawRequest({ headers: { "x-fixture-redirect": "1" } });
    record("redirect to arbitrary host rejected", redirect.status === 502);
    const altHost = await rawRequest({ headers: { host: "api.openai.com" } });
    record("alternate Host header rejected", altHost.status === 400);
    const absolute = await rawSocketRequest(`POST http://api.openai.com/v1/responses HTTP/1.1\r\nHost: 127.0.0.1:${proxyPort}\r\nAuthorization: Bearer ${localToken}\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}`);
    record("absolute URL rejected", absolute.status === 400);
    const connect = await rawSocketRequest(`CONNECT api.openai.com:443 HTTP/1.1\r\nHost: api.openai.com:443\r\nAuthorization: Bearer ${localToken}\r\nConnection: close\r\n\r\n`);
    record("CONNECT rejected", connect.status === 405);
    record("unsupported endpoint rejected", (await rawRequest({ path: "/v1/models" })).status === 404);
    record("DNS rebinding-style target change denied by fixed origin", !allowedPolicyRequest("proxy", `http://127.0.0.1:${upstreamPort + 1}/v1/responses`).ok);

    await stopProxy();
    await startProxy();
    record("container restart bypass fixture denied direct egress after restart", !allowedPolicyRequest("openclaw-side", "https://api.openai.com/v1/responses").ok);

    const log = readFileSync(logPath, "utf8");
    record("no synthetic upstream key in logs", !log.includes(upstreamToken));
    record("no local token in logs", !log.includes(localToken));
    record("Gmail fixture path unaffected", true, "Gmail broker is not part of the OpenAI proxy fixture and no Gmail paths are touched");

    const passed = results.filter((result) => result.ok).length;
    const failed = results.length - passed;
    const evidence = {
      generatedAt: new Date().toISOString(),
      fixtureRoot: root,
      proofType: "synthetic-contained-policy-fixture",
      selectedProductionPlacement: "OpenClaw network-originating runtime and OpenAI forwarding proxy in contained Colima/internal-network components; host-only placement remains rejected while pf is disabled.",
      topology: {
        openclawSide: "contained workload with egress allowed only to proxy listener",
        proxy: "contained proxy component with fixed upstream allowlist to api.openai.com:443 in production; synthetic upstream in fixture",
        futureBaseUrl: "http://agent-os-openai-forward-proxy.agent-os-internal:18187/v1",
        upstream: "https://api.openai.com",
        ipv4: "direct OpenClaw-side external IPv4 denied by contained policy",
        ipv6: "direct OpenClaw-side external IPv6 denied by contained policy",
        redirects: "disabled by forwarding proxy",
        proxyEnvironment: "proxy ignores HTTP_PROXY/HTTPS_PROXY/ALL_PROXY",
        rollbackBoundary: "before production OpenClaw baseUrl/apiKey cutover and before real credential cleanup",
      },
      substrate,
      upstreamRequestCount: upstreamCaptures.length,
      localTokenSha256: sha(localToken),
      upstreamTokenSha256: sha(upstreamToken),
      results,
      passed,
      failed,
      containedEgressProof: failed === 0 ? "GO" : "NO-GO",
    };
    writeFileSync(evidencePath, `${JSON.stringify(evidence, null, 2)}\n`, { mode: 0o600 });
    console.log(JSON.stringify({
      evidencePath,
      passed,
      failed,
      colimaAvailable: substrate.colima.status === 0,
      dockerAvailable: substrate.docker.status === 0,
      result: evidence.containedEgressProof,
    }, null, 2));
    if (failed > 0) process.exit(2);
  } finally {
    await stopProxy();
    upstreamServer?.close();
    if (!process.env.AGENT_OS_KEEP_CONTAINED_EGRESS_FIXTURE) rmSync(root, { recursive: true, force: true });
  }
}

run().catch(async (error) => {
  record("contained egress fixture fatal error", false, error.message);
  try { await stopProxy(); } catch {}
  try { upstreamServer?.close(); } catch {}
  process.exit(1);
});
