#!/usr/bin/env bash
# F-A4 no-mutation readiness check for OpenClaw containment remediation.
#
# Run from an operator root shell. This script reads protected runtime files,
# builds sanitized/dry-run artifacts in an output directory, and performs no
# OpenClaw config, SecretRef, gateway, proxy, or pf mutation.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "NO-GO: run as root via sudo from the operator account." >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${1:-/Users/dannybigdeals/fa4-openclaw-containment-readiness-${TS}}"
OPENCLAW_HOME="/Users/agent/.openclaw"
CONFIG="$OPENCLAW_HOME/openclaw.json"
STATE_DIR="$OPENCLAW_HOME/state"
NODE_BIN="/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node"
OPENCLAW_BIN="/Users/agent/.local/bin/openclaw"
PATCH_FILE="$OUT_DIR/openclaw-containment.patch.json"
PLAN_FILE="$OUT_DIR/openclaw-secretref-plan.json"
TEMP_SECRET_FILE="$OUT_DIR/agent-os-openai-readiness-secret.json"
LOG="$OUT_DIR/readiness.log"

mkdir -p "$OUT_DIR"
chmod 0700 "$OUT_DIR"
exec > >(tee "$LOG") 2>&1

export HOME=/Users/agent
export OPENCLAW_CONFIG_PATH="$CONFIG"
export OPENCLAW_STATE_DIR="$STATE_DIR"
export PATH="/Users/agent/.local/bin:/Users/agent/.local/openclaw/tools/node-v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

echo "F-A4 OpenClaw containment readiness started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Output: $OUT_DIR"

"$NODE_BIN" --input-type=module - "$CONFIG" "$PATCH_FILE" "$PLAN_FILE" "$TEMP_SECRET_FILE" "$OPENCLAW_HOME" "$OPENCLAW_HOME/exec-approvals.json" <<'NODE'
import fs from "node:fs";
import path from "node:path";
import { DatabaseSync } from "node:sqlite";

const [configPath, patchPath, planPath, secretPath, openclawHome, approvalsPath] = process.argv.slice(2);
const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"));
const approvals = JSON.parse(fs.readFileSync(approvalsPath, "utf8"));
const brokerClientPath = "/Users/agent/.openclaw/scripts/gmail-broker-client.mjs";
const approvedBrokerMethods = new Set(["health_check", "search_threads", "read_thread", "create_draft", "list_drafts", "get_draft"]);

function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}

function unique(values) {
  return [...new Set(values.filter((value) => typeof value === "string" && value.trim()).map((value) => value.trim()))];
}

function isSecretRef(value) {
  return value && typeof value === "object" && !Array.isArray(value) && typeof value.source === "string" && typeof value.provider === "string" && typeof value.id === "string";
}

function setNested(target, pathSegments, value) {
  let current = target;
  for (const segment of pathSegments.slice(0, -1)) {
    current[segment] = asObject(current[segment]);
    current = current[segment];
  }
  current[pathSegments[pathSegments.length - 1]] = value;
}

function removeDangerousTools(tools) {
  const next = { ...asObject(tools) };
  const denyAdd = ["process", "write", "edit", "apply_patch", "browser", "group:web"];
  const removeFromAllow = new Set([...denyAdd, "web_search", "web_fetch", "x_search", "browser", "process"]);
  next.deny = unique([...(Array.isArray(next.deny) ? next.deny : []), ...denyAdd]);
  for (const field of ["allow", "alsoAllow"]) {
    if (Array.isArray(next[field])) next[field] = next[field].filter((entry) => !removeFromAllow.has(entry));
  }
  next.exec = {
    ...asObject(next.exec),
    security: "allowlist",
    ask: "off",
    strictInlineEval: true,
  };
  return next;
}

function validateGmailReaderExecApproval() {
  const defaultsPolicy = asObject(approvals.defaults);
  const wildcardPolicy = asObject(asObject(approvals.agents)["*"]);
  const readerPolicy = asObject(asObject(approvals.agents)["gmail-reader"]);
  const allowlist = Array.isArray(readerPolicy.allowlist) ? readerPolicy.allowlist : [];
  if (readerPolicy.security !== "allowlist") throw new Error("gmail-reader exec approval policy is not security=allowlist");
  if (readerPolicy.ask !== "off") throw new Error("gmail-reader exec approval policy is not ask=off");
  if (readerPolicy.askFallback !== "deny") throw new Error("gmail-reader exec approval policy is not askFallback=deny");
  const inheritedAutoAllowSkills = readerPolicy.autoAllowSkills ?? wildcardPolicy.autoAllowSkills ?? defaultsPolicy.autoAllowSkills ?? false;
  const autoAllowSkillsStatus = readerPolicy.autoAllowSkills === false ? "explicit false" : "safely defaulted false";
  if (inheritedAutoAllowSkills !== false) throw new Error("gmail-reader exec approval policy has unsafe autoAllowSkills=true");
  if (allowlist.length === 0) throw new Error("gmail-reader exec approval allowlist is empty");
  for (const entry of allowlist) {
    const serialized = JSON.stringify(entry);
    if (!serialized.includes(brokerClientPath)) throw new Error("allowlist contains a non-broker-client entry");
    if (entry.pattern === "*" || entry.argPattern === "*" || entry.commandText === "*") throw new Error("allowlist contains a wildcard entry");
    const executableFields = [entry.pattern, entry.commandText, entry.lastResolvedPath].filter((value) => typeof value === "string");
    if (executableFields.some((value) => /(^|[ /])(bash|sh|zsh|osascript|python|python3|ruby|perl|php)( |$)/.test(value) && !value.includes(brokerClientPath))) throw new Error("allowlist contains an unrelated executable");
    if (typeof entry.argPattern !== "string") throw new Error("allowlist is missing bounded argPattern");
    const argRegex = new RegExp(entry.argPattern);
    for (const method of approvedBrokerMethods) if (!argRegex.test(`${method} {}`)) throw new Error(`allowlist is missing approved method: ${method}`);
    for (const candidate of ["health_check", "health_check {}\n/bin/sh", "health_check {\n}", "health_check {}\r/bin/sh", "health_check {\r}", "health_check {}\r\n/bin/sh", "health_check {\r\n}", "health_check {}; /bin/sh", "unapproved_method {}", "delete_thread {}", "create_draft {}\n/bin/sh", "create_draft {}\r/bin/sh"]) {
      if (argRegex.test(candidate)) throw new Error(`allowlist accepted unsafe invocation: ${JSON.stringify(candidate)}`);
    }
  }
  console.log(`Exec approval preflight: autoAllowSkills=${autoAllowSkillsStatus}; allowlistEntries=${allowlist.length}; regexCompiled=true; approvedMethodsAccepted=true; bareMethodDenied=true; lfInjectionDenied=true; crInjectionDenied=true; crlfInjectionDenied=true; foreignMethodDenied=true; commandChainingDenied=true`);
}

function stripQwenFallback(modelConfig) {
  if (!modelConfig || typeof modelConfig !== "object" || Array.isArray(modelConfig)) return modelConfig;
  const next = { ...modelConfig };
  if (Array.isArray(next.fallbacks)) next.fallbacks = next.fallbacks.filter((entry) => entry !== "ollama/qwen3-coder:30b");
  return next;
}

validateGmailReaderExecApproval();

const defaults = asObject(asObject(cfg.agents).defaults);
const agents = Array.isArray(asObject(cfg.agents).list) ? cfg.agents.list.map((agent) => ({ ...agent })) : [];
const gmailIndex = agents.findIndex((agent) => agent && agent.id === "gmail-reader");
if (gmailIndex === -1) throw new Error("gmail-reader not found in agents.list");

const secretPayload = {};
const planTargets = [];
const providerApiKey = asObject(asObject(cfg.models).providers).openai?.apiKey;
if (typeof providerApiKey === "string" && providerApiKey.length >= 8) {
  setNested(secretPayload, ["models", "providers", "openai", "apiKey"], providerApiKey);
  planTargets.push({ type: "models.providers.apiKey", path: "models.providers.openai.apiKey", pathSegments: ["models", "providers", "openai", "apiKey"], providerId: "openai", ref: { source: "file", provider: "agent_os_openai", id: "/models/providers/openai/apiKey" } });
} else if (!isSecretRef(providerApiKey)) {
  throw new Error("models.providers.openai.apiKey is neither plaintext nor a SecretRef");
}

const manualProfiles = [];
for (const entry of fs.readdirSync(path.join(openclawHome, "agents"), { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const agentId = entry.name;
  const dbPath = path.join(openclawHome, "agents", agentId, "agent", "openclaw-agent.sqlite");
  if (!fs.existsSync(dbPath)) continue;
  const db = new DatabaseSync(dbPath, { readOnly: true });
  try {
    const row = db.prepare("SELECT store_json FROM auth_profile_store WHERE store_key = 'primary'").get();
    if (!row?.store_json) continue;
    const profile = JSON.parse(row.store_json)?.profiles?.["openai:manual"];
    if (profile?.type === "api_key" && typeof profile.key === "string" && profile.key.length >= 8) manualProfiles.push({ agentId, key: profile.key });
    else if (profile?.type === "api_key" && isSecretRef(profile.keyRef)) manualProfiles.push({ agentId, key: null });
  } finally {
    db.close();
  }
}
if (manualProfiles.length !== 1) throw new Error(`expected exactly one openai:manual profile, found ${manualProfiles.length}`);
if (manualProfiles[0].key) {
  setNested(secretPayload, ["profiles", "openai:manual", "key"], manualProfiles[0].key);
  planTargets.push({ type: "auth-profiles.api_key.key", path: "profiles.openai:manual.key", pathSegments: ["profiles", "openai:manual", "key"], agentId: manualProfiles[0].agentId, authProfileProvider: "openai", ref: { source: "file", provider: "agent_os_openai", id: "/profiles/openai:manual/key" } });
}
if (planTargets.length > 0) fs.writeFileSync(secretPath, `${JSON.stringify(secretPayload, null, 2)}\n`, { mode: 0o600 });

agents[gmailIndex].tools = removeDangerousTools(agents[gmailIndex].tools);
agents[gmailIndex].sandbox = { ...asObject(agents[gmailIndex].sandbox), workspaceAccess: "none" };
fs.writeFileSync(patchPath, `${JSON.stringify({ agents: { defaults: { model: stripQwenFallback(defaults.model) }, list: agents } }, null, 2)}\n`, { mode: 0o600 });
fs.writeFileSync(planPath, `${JSON.stringify({ version: 1, protocolVersion: 1, providerUpserts: { agent_os_openai: { source: "file", path: secretPath, mode: "json", maxBytes: 4096 } }, targets: planTargets }, null, 2)}\n`, { mode: 0o600 });
console.log(`Readiness artifacts generated: targets=${planTargets.length}; manualProfileAgent=${manualProfiles[0].agentId}`);
NODE

echo "CONFIG PATCH DRY RUN"
"$OPENCLAW_BIN" config patch --file "$PATCH_FILE" --replace-path agents.list --replace-path agents.defaults.model --dry-run --json

if "$NODE_BIN" -e 'const fs=require("fs"); process.exit((JSON.parse(fs.readFileSync(process.argv[1],"utf8")).targets||[]).length > 0 ? 0 : 1)' "$PLAN_FILE"; then
  echo "SECRETREF PLAN DRY RUN"
  "$OPENCLAW_BIN" secrets apply --from "$PLAN_FILE" --dry-run --json
else
  echo "SECRETREF PLAN DRY RUN skipped: no migration targets"
fi

echo "GO: F-A4 OpenClaw containment readiness passed without runtime mutation."
