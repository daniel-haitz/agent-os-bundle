#!/usr/bin/env bash
# F-A4 operator-owned OpenClaw containment remediation harness.
#
# Bounded correction for validated OpenClaw 2026.6.11 findings:
# - unsafe local-model default fallback web exposure;
# - gmail-reader process/general shell risk;
# - plaintext OpenAI static API-key storage on supported SecretRef surfaces.
#
# Run from an operator root shell. This script must not print secret values.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root via sudo from the operator account." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${1:-/Users/dannybigdeals/fa4-openclaw-containment-remediation-${TS}}"
OPENCLAW_HOME="/Users/agent/.openclaw"
CONFIG="$OPENCLAW_HOME/openclaw.json"
STATE_DIR="$OPENCLAW_HOME/state"
SECRET_FILE="$OPENCLAW_HOME/secrets/agent-os-openai.json"
NODE_BIN="/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node"
OPENCLAW_BIN="/Users/agent/.local/bin/openclaw"
PATCH_FILE="$OUT_DIR/openclaw-containment.patch.json"
PLAN_FILE="$OUT_DIR/openclaw-secretref-plan.json"
ROLLBACK="$OUT_DIR/rollback.sh"
LOG="$OUT_DIR/remediation.log"
BACKUP_MANIFEST="$OUT_DIR/backup-manifest.tsv"

mkdir -p "$OUT_DIR"
chmod 0700 "$OUT_DIR"
exec > >(tee "$LOG") 2>&1
printf 'source\tbackup\n' > "$BACKUP_MANIFEST"

echo "F-A4 OpenClaw containment remediation started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Output: $OUT_DIR"

backup_file() {
  local src="$1"
  local label="$2"
  if [ -e "$src" ]; then
    local dest="$OUT_DIR/$label"
    cp -p "$src" "$dest"
    printf '%s\t%s\n' "$src" "$dest" >> "$BACKUP_MANIFEST"
    echo "Backed up $src -> $dest"
  else
    echo "Backup skipped, absent: $src"
  fi
}

backup_file "$CONFIG" "openclaw.json.before"
backup_file "$OPENCLAW_HOME/exec-approvals.json" "exec-approvals.json.before"
find "$OPENCLAW_HOME/agents" -maxdepth 4 -path '*/agent/openclaw-agent.sqlite*' -type f -print0 2>/dev/null \
  | while IFS= read -r -d '' db_file; do
      safe_name="$(printf '%s' "$db_file" | sed 's#^/Users/agent/.openclaw/##; s#[^A-Za-z0-9._-]#_#g')"
      backup_file "$db_file" "auth-${safe_name}.before"
    done
backup_file "$SECRET_FILE" "agent-os-openai.json.before"

cat > "$ROLLBACK" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [ "\$(id -u)" -ne 0 ]; then
  echo "ERROR: run rollback as root." >&2
  exit 1
fi
cp -p "$OUT_DIR/openclaw.json.before" "$CONFIG"
if [ -f "$OUT_DIR/exec-approvals.json.before" ]; then
  cp -p "$OUT_DIR/exec-approvals.json.before" "$OPENCLAW_HOME/exec-approvals.json"
fi
awk -F '\t' 'NR > 1 { print }' "$BACKUP_MANIFEST" | while IFS=$'\t' read -r source backup; do
  [ -n "\$source" ] || continue
  [ -n "\$backup" ] || continue
  if [ -f "\$backup" ]; then
    cp -p "\$backup" "\$source"
  fi
done
if ! grep -Fq "$SECRET_FILE" "$BACKUP_MANIFEST"; then
  rm -f "$SECRET_FILE"
fi
launchctl kickstart -k system/ai.openclaw.gateway
echo "Rollback restored saved config/auth/secret artifacts and kickstarted gateway."
EOF
chmod 0700 "$ROLLBACK"

"$NODE_BIN" --input-type=module - "$CONFIG" "$PATCH_FILE" "$PLAN_FILE" "$SECRET_FILE" "$OPENCLAW_HOME" "$OPENCLAW_HOME/exec-approvals.json" <<'NODE'
import fs from "node:fs";
import path from "node:path";
import { DatabaseSync } from "node:sqlite";

const [configPath, patchPath, planPath, secretPath, openclawHome, approvalsPath] = process.argv.slice(2);
const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"));
const approvals = JSON.parse(fs.readFileSync(approvalsPath, "utf8"));
const brokerClientPath = "/Users/agent/.openclaw/scripts/gmail-broker-client.mjs";

function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}

function unique(values) {
  return [...new Set(values.filter((value) => typeof value === "string" && value.trim()).map((value) => value.trim()))];
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
    mode: "allowlist",
    security: "allowlist",
    ask: "off",
    askFallback: "deny",
    autoAllowSkills: false,
    strictInlineEval: true,
  };
  return next;
}

function validateGmailReaderExecApproval() {
  const readerPolicy = asObject(asObject(approvals.agents)["gmail-reader"]);
  const allowlist = Array.isArray(readerPolicy.allowlist) ? readerPolicy.allowlist : [];
  if (readerPolicy.security !== "allowlist") {
    throw new Error("gmail-reader exec approval policy is not security=allowlist");
  }
  if (readerPolicy.ask !== "off") {
    throw new Error("gmail-reader exec approval policy is not ask=off");
  }
  if (readerPolicy.askFallback !== "deny") {
    throw new Error("gmail-reader exec approval policy is not askFallback=deny");
  }
  if (readerPolicy.autoAllowSkills !== false) {
    throw new Error("gmail-reader exec approval policy is not autoAllowSkills=false");
  }
  if (allowlist.length === 0) {
    throw new Error("gmail-reader exec approval allowlist is empty; fixed broker path is not validated");
  }
  for (const entry of allowlist) {
    const serialized = JSON.stringify(entry);
    if (!serialized.includes(brokerClientPath)) {
      throw new Error("gmail-reader exec approval allowlist contains a non-broker-client entry");
    }
    if (entry.pattern === "*" || entry.argPattern === "*" || entry.commandText === "*") {
      throw new Error("gmail-reader exec approval allowlist contains a wildcard entry");
    }
  }
}

function stripQwenFallback(modelConfig) {
  if (!modelConfig || typeof modelConfig !== "object" || Array.isArray(modelConfig)) return modelConfig;
  const next = { ...modelConfig };
  if (Array.isArray(next.fallbacks)) {
    next.fallbacks = next.fallbacks.filter((entry) => entry !== "ollama/qwen3-coder:30b");
  }
  return next;
}

const defaults = asObject(asObject(cfg.agents).defaults);
const agents = Array.isArray(asObject(cfg.agents).list) ? cfg.agents.list.map((agent) => ({ ...agent })) : [];
const gmailIndex = agents.findIndex((agent) => agent && agent.id === "gmail-reader");
if (gmailIndex === -1) throw new Error("gmail-reader not found in agents.list");
validateGmailReaderExecApproval();

const providerApiKey = asObject(asObject(cfg.models).providers).openai?.apiKey;
if (typeof providerApiKey !== "string" || providerApiKey.length < 8) {
  throw new Error("models.providers.openai.apiKey is not a plaintext string; refusing to infer secret source");
}

const agentRoot = path.join(openclawHome, "agents");
const manualProfile = { agentId: null, key: null };
for (const entry of fs.readdirSync(agentRoot, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const agentId = entry.name;
  const dbPath = path.join(agentRoot, agentId, "agent", "openclaw-agent.sqlite");
  if (!fs.existsSync(dbPath)) continue;
  const db = new DatabaseSync(dbPath, { readOnly: true });
  try {
    const row = db.prepare("SELECT store_json FROM auth_profile_store WHERE store_key = 'primary'").get();
    if (!row?.store_json) continue;
    const store = JSON.parse(row.store_json);
    const profile = store?.profiles?.["openai:manual"];
    if (profile?.type === "api_key" && typeof profile.key === "string" && profile.key.length >= 8) {
      manualProfile.agentId = agentId;
      manualProfile.key = profile.key;
      break;
    }
  } finally {
    db.close();
  }
}

if (!manualProfile.key) {
  throw new Error("profiles.openai:manual.key plaintext was not found in an auth-profile store; stop and use OpenClaw secrets configure/apply rather than editing SQLite directly");
}

const secretPayload = {
  models: { providers: { openai: { apiKey: providerApiKey } } },
  profiles: { "openai:manual": { key: manualProfile.key } },
};
fs.writeFileSync(secretPath, `${JSON.stringify(secretPayload, null, 2)}\n`, { mode: 0o440 });

agents[gmailIndex].tools = removeDangerousTools(agents[gmailIndex].tools);
agents[gmailIndex].sandbox = {
  ...asObject(agents[gmailIndex].sandbox),
  workspaceAccess: "none",
};

const nextDefaultModel = stripQwenFallback(defaults.model);
const patch = {
  agents: {
    defaults: {
      model: nextDefaultModel,
    },
    list: agents,
  },
};
fs.writeFileSync(patchPath, `${JSON.stringify(patch, null, 2)}\n`, { mode: 0o600 });

const plan = {
  version: 1,
  protocolVersion: 1,
  providerUpserts: {
    agent_os_openai: {
      source: "file",
      path: secretPath,
      mode: "json",
      maxBytes: 4096,
    },
  },
  targets: [
    {
      type: "models.providers.apiKey",
      path: "models.providers.openai.apiKey",
      pathSegments: ["models", "providers", "openai", "apiKey"],
      providerId: "openai",
      ref: { source: "file", provider: "agent_os_openai", id: "/models/providers/openai/apiKey" },
    },
    {
      type: "auth-profiles.api_key.key",
      path: "profiles.openai:manual.key",
      pathSegments: ["profiles", "openai:manual", "key"],
      agentId: manualProfile.agentId,
      authProfileProvider: "openai",
      ref: { source: "file", provider: "agent_os_openai", id: "/profiles/openai:manual/key" },
    },
  ],
};
fs.writeFileSync(planPath, `${JSON.stringify(plan, null, 2)}\n`, { mode: 0o600 });

console.log(`Prepared config patch and SecretRef plan for manual profile agent: ${manualProfile.agentId}`);
NODE

chown root:openclawgw "$SECRET_FILE"
chmod 0440 "$SECRET_FILE"
echo "Created SecretRef backing file at $SECRET_FILE with root:openclawgw 0440."

export HOME=/Users/agent
export OPENCLAW_CONFIG_PATH="$CONFIG"
export OPENCLAW_STATE_DIR="$STATE_DIR"
export PATH="/Users/agent/.local/bin:/Users/agent/.local/openclaw/tools/node-v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

echo "Validating config patch..."
"$OPENCLAW_BIN" config patch --file "$PATCH_FILE" --replace-path agents.list --replace-path agents.defaults.model --dry-run

echo "Applying config patch..."
"$OPENCLAW_BIN" config patch --file "$PATCH_FILE" --replace-path agents.list --replace-path agents.defaults.model

echo "Validating SecretRef migration plan..."
"$OPENCLAW_BIN" secrets apply --from "$PLAN_FILE" --dry-run

echo "Applying SecretRef migration plan..."
"$OPENCLAW_BIN" secrets apply --from "$PLAN_FILE"

echo "Removing unsafe qwen fallback through models command for compatibility..."
"$OPENCLAW_BIN" models fallbacks remove ollama/qwen3-coder:30b || true

echo "Validating updated config..."
"$OPENCLAW_BIN" config validate

echo "Reloading SecretRef runtime snapshot..."
"$OPENCLAW_BIN" secrets reload --json || {
  echo "WARN: secrets reload failed; gateway restart/kickstart validation is required."
}

echo "Kickstarting OpenClaw gateway to load config changes..."
launchctl kickstart -k system/ai.openclaw.gateway
sleep 3

echo "Post-remediation validation commands:"
"$OPENCLAW_BIN" --version
"$OPENCLAW_BIN" security audit --json
"$OPENCLAW_BIN" security audit --deep --json
"$OPENCLAW_BIN" doctor --lint --json
"$OPENCLAW_BIN" secrets audit --json
"$OPENCLAW_BIN" secrets audit --check --json
"$OPENCLAW_BIN" sandbox explain --agent main --json
"$OPENCLAW_BIN" sandbox explain --agent gmail-reader --json
"$OPENCLAW_BIN" sandbox explain --agent email-researcher --json
launchctl print system/ai.openclaw.gateway | sed -n '1,120p'

echo "F-A4 OpenClaw containment remediation completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Rollback: sudo $ROLLBACK"
