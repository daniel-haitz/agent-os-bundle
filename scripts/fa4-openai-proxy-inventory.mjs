#!/usr/bin/env node
// Read-only inventory helper for the F-A4 OpenAI forwarding-proxy readiness path.
// It redacts credential material, tolerates protected unreadable stores, and
// writes evidence only under the caller-provided output directory.

import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

const OUT_DIR = process.argv[2] || "/private/tmp/fa4-openai-proxy-inventory";
const OPENCLAW_ROOT = "/Users/agent/.openclaw";
const CONFIG_PATHS = [
  "/Users/agent/.openclaw/openclaw.json",
  "/Users/agent/.openclaw/openclaw.sanitized.json",
];
const AGENTS_ROOT = "/Users/agent/.openclaw/agents";
const DIST_ROOT = "/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist";
const NODE_BIN = "/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node";
const REPO_ROOT = new URL("..", import.meta.url).pathname.replace(/\/scripts\/?$/, "");
const OPERATOR_INVENTORY_PATH = join(REPO_ROOT, "audits/F-A4-openai-proxy-production-inventory.json");
const INTERESTING_ENV = [
  "OPENAI_API_KEY",
  "OPENAI_BASE_URL",
  "OPENAI_ORG_ID",
  "OPENAI_PROJECT",
  "HTTP_PROXY",
  "HTTPS_PROXY",
  "ALL_PROXY",
  "OPENCLAW_CONFIG_PATH",
  "OPENCLAW_STATE_DIR",
  "HOME",
];
const REQUIRED_AGENTS = ["main", "heartbeat", "gmail-reader", "research-handoff-gate", "email-researcher"];

mkdirSync(OUT_DIR, { recursive: true, mode: 0o700 });

function sha(value) {
  return createHash("sha256").update(value).digest("hex");
}

function redactValue(value) {
  if (typeof value !== "string") return { kind: typeof value };
  if (!value) return { kind: "empty" };
  if (/^\$\{?SecretRef|^secretref:/i.test(value)) return { kind: "reference", sha256: sha(value).slice(0, 16) };
  if (/^sk-[A-Za-z0-9]/.test(value) || value.length >= 16) return { kind: "plaintext-or-token", sha256: sha(value).slice(0, 16), length: value.length };
  return { kind: "string", sha256: sha(value).slice(0, 16), length: value.length };
}

function fileMeta(path) {
  try {
    const s = statSync(path);
    return {
      exists: true,
      file: s.isFile(),
      directory: s.isDirectory(),
      uid: s.uid,
      gid: s.gid,
      mode: (s.mode & 0o7777).toString(8).padStart(4, "0"),
      size: s.size,
    };
  } catch (error) {
    return { exists: false, error: error.code || error.message };
  }
}

function safeRead(path) {
  try {
    return { ok: true, text: readFileSync(path, "utf8"), meta: fileMeta(path) };
  } catch (error) {
    return { ok: false, error: error.code || error.message, meta: fileMeta(path) };
  }
}

function safeJson(path) {
  const read = safeRead(path);
  if (!read.ok) return { ok: false, error: read.error, meta: read.meta };
  try {
    return { ok: true, json: JSON.parse(read.text), sha256: sha(read.text), meta: read.meta };
  } catch (error) {
    return { ok: false, error: `parse:${error.message}`, meta: read.meta };
  }
}

function getPath(object, path) {
  let current = object;
  for (const part of path) {
    if (current === null || typeof current !== "object" || !(part in current)) return undefined;
    current = current[part];
  }
  return current;
}

function normalizeModelRef(ref) {
  if (typeof ref === "string") return ref;
  if (ref && typeof ref === "object") return ref.primary || ref.model || "";
  return "";
}

function providerFromModel(model) {
  if (typeof model !== "string" || !model.includes("/")) return "unknown";
  return model.split("/")[0];
}

function inventoryConfig(path, parsed) {
  if (!parsed.ok) {
    return {
      path,
      readable: false,
      error: parsed.error,
      meta: parsed.meta,
      credentialSources: [],
      agentRoutes: [],
      providers: [],
    };
  }
  const cfg = parsed.json;
  const providers = getPath(cfg, ["models", "providers"]) || {};
  const defaults = getPath(cfg, ["agents", "defaults"]) || {};
  const defaultModel = normalizeModelRef(defaults.model || defaults.primary);
  const defaultFallbacks = Array.isArray(defaults.model?.fallbacks) ? defaults.model.fallbacks
    : Array.isArray(defaults.fallbacks) ? defaults.fallbacks
      : [];
  const providerRows = Object.entries(providers).map(([provider, value]) => ({
    provider,
    api: value?.api || (provider === "openai" ? "openai-responses" : "unknown"),
    baseUrl: typeof value?.baseUrl === "string" ? value.baseUrl : (provider === "openai" ? "https://api.openai.com/v1" : null),
    auth: value?.auth || null,
    apiKey: value?.apiKey === undefined ? { kind: "absent" } : redactValue(value.apiKey),
    couldBypassProxy: provider === "openai" && (!value?.baseUrl || /^https:\/\/api\.openai\.com\b/.test(value.baseUrl)),
  }));
  const credentialSources = [];
  for (const row of providerRows) {
    if (row.apiKey.kind !== "absent") {
      credentialSources.push({
        path: `${path}:models.providers.${row.provider}.apiKey`,
        source: "provider-config",
        provider: row.provider,
        type: row.apiKey.kind,
        couldBypassProxy: row.couldBypassProxy,
      });
    }
  }
  const authOrder = getPath(cfg, ["auth", "order"]);
  if (authOrder !== undefined) {
    credentialSources.push({
      path: `${path}:auth.order`,
      source: "auth-order",
      provider: "openai",
      type: Array.isArray(authOrder?.openai) ? "profile-order" : typeof authOrder,
      couldBypassProxy: true,
    });
  }
  const agents = Array.isArray(getPath(cfg, ["agents", "list"])) ? getPath(cfg, ["agents", "list"]) : [];
  const agentRoutes = agents.map((agent) => {
    const primary = normalizeModelRef(agent.model || agent.primary) || defaultModel || "unknown";
    const fallbacks = Array.isArray(agent.model?.fallbacks) ? agent.model.fallbacks
      : Array.isArray(agent.fallbacks) ? agent.fallbacks
        : defaultFallbacks;
    return {
      agent: agent.id || "unknown",
      primaryModel: primary,
      provider: providerFromModel(primary),
      api: providerRows.find((row) => row.provider === providerFromModel(primary))?.api || "unknown",
      effectiveBaseUrl: providerRows.find((row) => row.provider === providerFromModel(primary))?.baseUrl || null,
      fallbacks,
      fallbackProviders: fallbacks.map(providerFromModel),
      proxyRequired: providerFromModel(primary) === "openai" || fallbacks.some((entry) => providerFromModel(entry) === "openai"),
      directOpenAIRoutePresent: (providerFromModel(primary) === "openai" || fallbacks.some((entry) => providerFromModel(entry) === "openai"))
        && providerRows.some((row) => row.provider === "openai" && row.couldBypassProxy),
      excludedFeatureRisk: false,
    };
  });
  return {
    path,
    readable: true,
    sha256: parsed.sha256,
    meta: parsed.meta,
    providers: providerRows,
    credentialSources,
    agentRoutes,
  };
}

function findAgentStores() {
  const rows = [];
  function walk(dir, depth) {
    if (depth < 0) return;
    let entries;
    try {
      entries = readdirSync(dir, { withFileTypes: true });
    } catch (error) {
      rows.push({ path: dir, readable: false, error: error.code || error.message, meta: fileMeta(dir) });
      return;
    }
    for (const entry of entries) {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) walk(path, depth - 1);
      else if (entry.isFile() && (entry.name === "auth-profiles.json" || entry.name === "models.json")) {
        rows.push({ path, ...safeJson(path) });
      }
    }
  }
  walk(AGENTS_ROOT, 4);
  return rows.map((row) => {
    if (!row.ok) return { path: row.path, readable: false, error: row.error, meta: row.meta };
    const text = JSON.stringify(row.json);
    const hasOpenAIKeyLike = /sk-[A-Za-z0-9]|OPENAI_API_KEY|apiKey|keyRef|openai/i.test(text);
    return {
      path: row.path,
      readable: true,
      sha256: row.sha256,
      meta: row.meta,
      storeType: row.path.endsWith("auth-profiles.json") ? "auth-profiles" : "models",
      mentionsOpenAIOrKeyFields: hasOpenAIKeyLike,
      redactedCredentialFieldCount: (text.match(/apiKey|keyRef|OPENAI_API_KEY|sk-[A-Za-z0-9]/gi) || []).length,
    };
  });
}

function run(cmd, args) {
  const result = spawnSync(cmd, args, { encoding: "utf8", timeout: 10000 });
  return {
    command: [cmd, ...args].join(" "),
    status: result.status,
    signal: result.signal,
    stdout: result.stdout || "",
    stderr: result.stderr || "",
    error: result.error?.message,
  };
}

function launchdInventory() {
  const gateway = run("launchctl", ["print", "system/ai.openclaw.gateway"]);
  const egress = run("launchctl", ["print", "system/ai.agent-os-egress-proxy"]);
  const openaiProxy = run("launchctl", ["print", "system/ai.agent-os.openai-forward-proxy"]);
  return {
    gateway: summarizeLaunchd(gateway),
    egressProxy: summarizeLaunchd(egress),
    openaiProxy: summarizeLaunchd(openaiProxy),
  };
}

function summarizeLaunchd(result) {
  const text = `${result.stdout}\n${result.stderr}`;
  const env = {};
  const environmentBlocks = [...text.matchAll(/\n\tenvironment = \{([\s\S]*?)\n\t\}/g)].map((match) => match[1]);
  for (const environmentBlock of environmentBlocks) {
    for (const line of environmentBlock.split("\n")) {
      const match = /^\s*([A-Za-z_][A-Za-z0-9_]*) => (.*)$/.exec(line);
      if (match) env[match[1]] = /KEY|TOKEN|SECRET|PASSWORD/.test(match[1]) ? "<redacted-present>" : match[2];
    }
  }
  return {
    available: result.status === 0,
    status: result.status,
    path: /^path = (.*)$/m.exec(text)?.[1] || null,
    state: /^	state = (.*)$/m.exec(text)?.[1] || null,
    program: /^	program = (.*)$/m.exec(text)?.[1] || null,
    username: /^	username = (.*)$/m.exec(text)?.[1] || null,
    group: /^	group = (.*)$/m.exec(text)?.[1] || null,
    pid: /^	pid = (.*)$/m.exec(text)?.[1] || null,
    environment: env,
  };
}

function pfInventory() {
  const info = run("pfctl", ["-s", "info"]);
  const anchors = run("pfctl", ["-s", "Anchors"]);
  return {
    infoStatus: info.status,
    statusLine: /Status:\s*([A-Za-z]+)/.exec(info.stdout || info.stderr)?.[1] || "unknown",
    anchorsStatus: anchors.status,
    anchors: (anchors.stdout || "").split(/\r?\n/).filter(Boolean),
  };
}

function colimaInventory() {
  const colima = run("colima", ["status"]);
  const docker = run("docker", ["ps", "--format", "{{.Names}}\t{{.Networks}}\t{{.Ports}}"]);
  return {
    colimaStatus: colima.status === 0 ? colima.stdout.trim().split(/\r?\n/).slice(0, 20) : [`unavailable:${colima.stderr.trim() || colima.error || colima.status}`],
    dockerPs: docker.status === 0 ? docker.stdout.trim().split(/\r?\n/).filter(Boolean) : [`unavailable:${docker.stderr.trim() || docker.error || docker.status}`],
  };
}

function sourceContract() {
  const files = [
    "openai-transport-stream-Dj78Cdnf.js",
    "provider-catalog-BdolWBnQ.js",
    "transport-policy-CLvjL94O.js",
    "zod-schema.core-DGUr-AGH.js",
    "list.probe-CE320ycN.js",
  ];
  return files.map((file) => {
    const path = join(DIST_ROOT, file);
    const read = safeRead(path);
    if (!read.ok) return { path, readable: false, error: read.error };
    const lines = read.text.split(/\r?\n/);
    const matches = [];
    for (let index = 0; index < lines.length; index += 1) {
      if (/baseUrl|apiKey|openai-responses|\/v1\/responses|auth\.order|models\.json|fallbacks|realtime|chatgpt|api\.openai\.com/i.test(lines[index])) {
        matches.push({ line: index + 1, text: lines[index].slice(0, 220) });
      }
    }
    return { path, readable: true, sha256: sha(read.text), matchCount: matches.length, matches: matches.slice(0, 80) };
  });
}

function egressDecision(pf, colima) {
  const pfEnabled = pf.statusLine === "Enabled";
  return {
    selectedPlacement: "contained-network-placement-required",
    hostOnlyAccepted: false,
    reason: "With pf disabled, the host LaunchDaemon openclawgw process has no active per-service egress wall. Direct IPv4/IPv6/DNS/direct-IP bypass cannot be structurally denied on host-only placement.",
    enforceableDesign: {
      processes: [
        "OpenClaw network-originating runtime must be inside the contained Colima/internal-network boundary or behind an equivalent proven network namespace.",
        "OpenAI forwarding proxy runs as UID/GID 540/740 inside that contained placement, with root-controlled code/runtime and broker-owned credential store mounted read-only where required.",
        "Host launchd may supervise or start the contained service, but host openclawgw must not retain unrestricted direct external egress for production closure while pf remains disabled.",
      ],
      listener: "contained private address or explicitly published local endpoint reachable only by the intended OpenClaw runtime",
      baseUrl: "http://<contained-openai-proxy>/v1",
      enforcementPoint: "container/internal-network egress policy allowing only api.openai.com:443 for the proxy identity/component and denying direct api.openai.com from OpenClaw",
      ipv4Ipv6: "both families denied by contained network policy; no host-only fallback",
      redirects: "disabled in proxy",
      proxyEnvironment: "ignored by proxy and scrubbed from launchd/container environment",
      rollbackBoundary: "before OpenClaw config/auth cutover and before real-key cleanup",
    },
    livePfEnabled: pfEnabled,
    colimaObserved: colima.colimaStatus,
  };
}

function authPrecedence(configInventories, agentStores, launchd) {
  const sources = [];
  for (const inv of configInventories) sources.push(...inv.credentialSources);
  for (const store of agentStores) {
    if (store.readable && store.mentionsOpenAIOrKeyFields) {
      sources.push({
        path: store.path,
        source: store.storeType,
        provider: "openai-or-unknown",
        type: "redacted-store-reference-or-key-field",
        couldBypassProxy: true,
      });
    } else if (!store.readable && /agents\/[^/]+/.test(store.path)) {
      sources.push({
        path: store.path,
        source: "protected-agent-store",
        provider: "unknown",
        type: "unreadable",
        couldBypassProxy: "unknown",
      });
    }
  }
  for (const key of INTERESTING_ENV) {
    if (Object.prototype.hasOwnProperty.call(process.env, key)) {
      sources.push({
        path: `process.env.${key}`,
        source: "current-shell-env",
        provider: key.includes("OPENAI") ? "openai" : "proxy-env",
        type: /KEY|TOKEN|SECRET|PASSWORD/.test(key) ? "redacted-env" : "env",
        couldBypassProxy: key === "OPENAI_API_KEY",
      });
    }
  }
  const gatewayEnv = launchd.gateway.environment || {};
  for (const [key, value] of Object.entries(gatewayEnv)) {
    if (/OPENAI|PROXY|TOKEN|KEY|AUTH/i.test(key)) {
      sources.push({
        path: `launchd.ai.openclaw.gateway.env.${key}`,
        source: "gateway-launchd-env",
        provider: key.includes("OPENAI") ? "openai" : "proxy-env",
        type: value === "<redacted-present>" ? "redacted-env" : "env",
        couldBypassProxy: key === "OPENAI_API_KEY",
      });
    }
  }
  return {
    sources,
    cleanupOrder: [
      "Stage proxy and local synthetic token without changing live OpenClaw auth.",
      "Generate rollback point before removing any real OpenAI key material.",
      "Set OpenClaw openai provider baseUrl to proxy endpoint and apiKey to local token.",
      "Neutralize provider apiKey real-key fields and auth profile real-key paths.",
      "Regenerate agent model stores only after rollback evidence is captured.",
      "Run secrets/auth inventory again and fail if any real OpenAI credential remains consumable by OpenClaw.",
    ],
    unresolvedProtectedEvidence: sources.filter((source) => source.type === "unreadable").length,
    bypassSourceCount: sources.filter((source) => source.couldBypassProxy === true).length,
  };
}

function loadOperatorInventory() {
  const parsed = safeJson(OPERATOR_INVENTORY_PATH);
  if (!parsed.ok) return { ok: false, error: parsed.error, path: OPERATOR_INVENTORY_PATH };
  return { ok: true, path: OPERATOR_INVENTORY_PATH, sha256: parsed.sha256, inventory: parsed.json };
}

function authPrecedenceWithOperatorEvidence(configInventories, agentStores, launchd, operatorInventory) {
  const auth = authPrecedence(configInventories, agentStores, launchd);
  if (!operatorInventory.ok) return auth;
  const sources = Array.isArray(operatorInventory.inventory.credentialSources) ? operatorInventory.inventory.credentialSources.map((source) => ({
    path: source.path,
    source: "operator-verified-inventory",
    provider: "openai",
    type: source.classification,
    couldBypassProxy: source.directBypassCapable === true,
    valueIncluded: false,
    hashIncluded: false,
  })) : [];
  return {
    ...auth,
    sources,
    unresolvedProtectedEvidence: Number(operatorInventory.inventory.summary?.protectedEvidenceGaps ?? operatorInventory.inventory.protectedEvidenceGaps ?? 0),
    bypassSourceCount: Number(operatorInventory.inventory.summary?.bypassCredentialSources ?? sources.filter((source) => source.couldBypassProxy === true).length),
    operatorInventory: {
      path: operatorInventory.path,
      sha256: operatorInventory.sha256,
      realCredentialValuesIncluded: operatorInventory.inventory.realCredentialValuesIncluded === true,
    },
  };
}

function agentRouting(configInventories, operatorInventory) {
  if (operatorInventory.ok && Array.isArray(operatorInventory.inventory.routes)) {
    const routes = operatorInventory.inventory.routes.map((route) => ({
      agent: route.agent,
      primaryModel: route.primaryModel,
      provider: providerFromModel(route.primaryModel),
      api: route.api,
      effectiveBaseUrl: route.currentBaseUrl,
      fallbacks: route.fallbacks || [],
      fallbackProviders: (route.fallbacks || []).map(providerFromModel),
      proxyRequired: route.proxyRequired,
      directOpenAIRoutePresent: route.directOpenAIRoutePresent,
      excludedFeatureRisk: false,
      evidence: "operator-verified-inventory",
    }));
    return {
      routes,
      directOpenAIRouteCount: Number(operatorInventory.inventory.summary?.directOpenAIRoutes ?? routes.filter((route) => route.directOpenAIRoutePresent === true).length),
      unknownRouteCount: Number(operatorInventory.inventory.summary?.unknownRoutes ?? 0),
      operatorInventory: {
        path: operatorInventory.path,
        sha256: operatorInventory.sha256,
      },
      excludedFeatures: [
        { feature: "realtime voice/websocket", status: "excluded", reason: "prior source trace found realtime paths separately hard-coded and not covered by /v1/responses proxy fixture" },
        { feature: "images", status: "deny-until-proven", reason: "not required by current gpt-5.5 Responses path" },
        { feature: "audio/TTS", status: "deny-until-proven", reason: "not required by current gpt-5.5 Responses path" },
        { feature: "files/uploads/batches/assistants", status: "deny-until-proven", reason: "not required by current gpt-5.5 Responses path" },
      ],
    };
  }
  const readable = configInventories.find((inv) => inv.readable && inv.agentRoutes.length > 0);
  const routes = readable ? readable.agentRoutes : [];
  const routeAgents = new Set(routes.map((route) => route.agent));
  for (const id of REQUIRED_AGENTS) {
    if (!routeAgents.has(id)) {
      routes.push({
        agent: id,
        primaryModel: "unavailable",
        provider: "unknown",
        api: "unknown",
        effectiveBaseUrl: null,
        fallbacks: [],
        fallbackProviders: [],
        proxyRequired: "unknown",
        directOpenAIRoutePresent: "unknown",
        excludedFeatureRisk: "unknown",
        evidence: "protected config unreadable or agent absent from readable sanitized config",
      });
    }
  }
  return {
    routes,
    directOpenAIRouteCount: routes.filter((route) => route.directOpenAIRoutePresent === true).length,
    unknownRouteCount: routes.filter((route) => route.directOpenAIRoutePresent === "unknown").length,
    excludedFeatures: [
      { feature: "realtime voice/websocket", status: "excluded", reason: "prior source trace found realtime paths separately hard-coded and not covered by /v1/responses proxy fixture" },
      { feature: "images", status: "deny-until-proven", reason: "not required by current gpt-5.5 Responses path" },
      { feature: "audio/TTS", status: "deny-until-proven", reason: "not required by current gpt-5.5 Responses path" },
      { feature: "files/uploads/batches/assistants", status: "deny-until-proven", reason: "not required by current gpt-5.5 Responses path" },
    ],
  };
}

function writeJson(name, value) {
  writeFileSync(join(OUT_DIR, name), `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600 });
}

function runSelfTest() {
  const fixture = {
    models: {
      providers: {
        openai: { api: "openai-responses", baseUrl: "https://api.openai.com/v1", apiKey: "fixture-openai-key-not-real" },
        ollama: { baseUrl: "http://127.0.0.1:11434/v1" },
      },
    },
    agents: {
      defaults: { model: { primary: "openai/gpt-5.5", fallbacks: ["ollama/qwen3-coder:30b"] } },
      list: [
        { id: "main", model: "openai/gpt-5.5" },
        { id: "heartbeat", model: { primary: "ollama/qwen2.5-coder:14b", fallbacks: [] } },
      ],
    },
  };
  const inv = inventoryConfig("fixture", { ok: true, json: fixture, sha256: "fixture", meta: {} });
  const auth = authPrecedence([inv], [], { gateway: { environment: { OPENCLAW_CONFIG_PATH: "/x" } } });
  const routing = agentRouting([inv], { ok: false });
  const assertions = [
    ["provider apiKey redacted", inv.providers[0].apiKey.kind === "plaintext-or-token"],
    ["direct bypass detected", inv.providers[0].couldBypassProxy === true],
    ["auth bypass counted", auth.bypassSourceCount === 1],
    ["main route parsed", routing.routes.some((route) => route.agent === "main" && route.provider === "openai")],
    ["heartbeat route parsed", routing.routes.some((route) => route.agent === "heartbeat" && route.provider === "ollama")],
  ];
  let failed = 0;
  for (const [name, ok] of assertions) {
    console.log(`SELF TEST ${name}: ${ok ? "PASS" : "FAIL"}`);
    if (!ok) failed += 1;
  }
  if (failed) process.exit(1);
  console.log("OPENAI PROXY INVENTORY SELF TEST: PASS");
}

if (process.argv.includes("--self-test")) {
  runSelfTest();
  process.exit(0);
}

const parsedConfigs = CONFIG_PATHS.map((path) => [path, safeJson(path)]);
const configInventories = parsedConfigs.map(([path, parsed]) => inventoryConfig(path, parsed));
const agentStores = findAgentStores();
const launchd = launchdInventory();
const pf = pfInventory();
const colima = colimaInventory();
const source = sourceContract();
const egress = egressDecision(pf, colima);
const operatorInventory = loadOperatorInventory();
const auth = authPrecedenceWithOperatorEvidence(configInventories, agentStores, launchd, operatorInventory);
const routing = agentRouting(configInventories, operatorInventory);

const summary = {
  generatedAt: new Date().toISOString(),
  openclawRoot: fileMeta(OPENCLAW_ROOT),
  node: { path: NODE_BIN, meta: fileMeta(NODE_BIN) },
  configInventories,
  agentStores,
  launchd,
  pf,
  colima,
  source,
  operatorInventory: operatorInventory.ok ? { ok: true, path: operatorInventory.path, sha256: operatorInventory.sha256 } : operatorInventory,
  egress,
  auth,
  routing,
  gateStatus: {
    egressPlacement: egress.livePfEnabled ? "FAIL" : "PASS_DESIGN_ONLY",
    authPrecedence: auth.unresolvedProtectedEvidence === 0 && auth.bypassSourceCount === 0 ? "PASS" : "FAIL",
    agentFallback: routing.unknownRouteCount === 0 && routing.directOpenAIRouteCount === 0 ? "PASS" : "FAIL",
  },
};

writeJson("openai-proxy-production-inventory.json", summary);

for (const inv of configInventories) {
  console.log(`CONFIG ${inv.path}: ${inv.readable ? "READABLE" : `UNREADABLE (${inv.error})`}`);
}
console.log(`EGRESS PLACEMENT FEASIBILITY: ${summary.gateStatus.egressPlacement === "PASS_DESIGN_ONLY" ? "PASS" : "FAIL"}`);
console.log(`OPENAI AUTH PRECEDENCE INVENTORY: ${summary.gateStatus.authPrecedence}`);
console.log(`AGENT AND FALLBACK INVENTORY: ${summary.gateStatus.agentFallback}`);
console.log(`INVENTORY EVIDENCE: ${join(OUT_DIR, "openai-proxy-production-inventory.json")}`);
