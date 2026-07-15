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
GATEWAY_LABEL="system/ai.openclaw.gateway"
GATEWAY_PLIST="/Library/LaunchDaemons/ai.openclaw.gateway.plist"
PATCH_FILE="$OUT_DIR/openclaw-containment.patch.json"
PLAN_FILE="$OUT_DIR/openclaw-secretref-plan.json"
ROLLBACK="$OUT_DIR/rollback.sh"
LOG="$OUT_DIR/remediation.log"
BACKUP_MANIFEST="$OUT_DIR/backup-manifest.tsv"
SECRETS_AUDIT_JSON="$OUT_DIR/secrets-audit-post.json"
SECURITY_AUDIT_JSON="$OUT_DIR/security-audit-post.json"
SECURITY_AUDIT_DEEP_JSON="$OUT_DIR/security-audit-deep-post.json"
DOCTOR_LINT_JSON="$OUT_DIR/doctor-lint-post.json"
MUTATION_STARTED=0

mkdir -p "$OUT_DIR"
chmod 0700 "$OUT_DIR"
exec > >(tee "$LOG") 2>&1
printf 'source\tbackup\n' > "$BACKUP_MANIFEST"

echo "F-A4 OpenClaw containment remediation started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Output: $OUT_DIR"

on_error() {
  local status=$?
  echo "ERROR: F-A4 OpenClaw containment remediation failed with status $status." >&2
  if [ "$MUTATION_STARTED" -eq 1 ]; then
    echo "ROLLBACK AVAILABLE: sudo $ROLLBACK" >&2
  fi
  exit "$status"
}
trap on_error ERR

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
launchctl bootout "$GATEWAY_LABEL" 2>/dev/null || true
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
if [ -f "$GATEWAY_PLIST" ]; then
  launchctl bootstrap system "$GATEWAY_PLIST" 2>/dev/null || true
fi
launchctl kickstart -k "$GATEWAY_LABEL"
echo "Rollback restored saved config/auth/secret artifacts and kickstarted gateway."
EOF
chmod 0700 "$ROLLBACK"

run_json_capture_allow_exit() {
  local name="$1"
  local output="$2"
  shift 2
  echo "$name..."
  set +e
  "$@" > "$output"
  local status=$?
  set -e
  echo "$name exit status: $status"
}

"$NODE_BIN" --input-type=module - "$CONFIG" "$PATCH_FILE" "$PLAN_FILE" "$SECRET_FILE" "$OPENCLAW_HOME" "$OPENCLAW_HOME/exec-approvals.json" <<'NODE'
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
  if (readerPolicy.security !== "allowlist") {
    throw new Error("gmail-reader exec approval policy is not security=allowlist");
  }
  if (readerPolicy.ask !== "off") {
    throw new Error("gmail-reader exec approval policy is not ask=off");
  }
  if (readerPolicy.askFallback !== "deny") {
    throw new Error("gmail-reader exec approval policy is not askFallback=deny");
  }
  const inheritedAutoAllowSkills = readerPolicy.autoAllowSkills ?? wildcardPolicy.autoAllowSkills ?? defaultsPolicy.autoAllowSkills ?? false;
  let autoAllowSkillsStatus = "unsafe";
  if (readerPolicy.autoAllowSkills === false) autoAllowSkillsStatus = "explicit false";
  else if (readerPolicy.autoAllowSkills === undefined && inheritedAutoAllowSkills === false) autoAllowSkillsStatus = "safely defaulted false";
  if (inheritedAutoAllowSkills !== false) {
    throw new Error("gmail-reader exec approval policy has unsafe autoAllowSkills=true");
  }
  if (allowlist.length === 0) {
    throw new Error("gmail-reader exec approval allowlist is empty; fixed broker path is not validated");
  }
  let brokerPathMatch = true;
  let boundedMethodPattern = true;
  let regexCompiled = true;
  let approvedMethodsAccepted = true;
  let bareMethodDenied = true;
  let lfInjectionDenied = true;
  let crInjectionDenied = true;
  let crlfInjectionDenied = true;
  let foreignMethodDenied = true;
  let commandChainingDenied = true;
  for (const entry of allowlist) {
    const serialized = JSON.stringify(entry);
    if (!serialized.includes(brokerClientPath)) {
      throw new Error("gmail-reader exec approval allowlist contains a non-broker-client entry");
    }
    if (entry.pattern === "*" || entry.argPattern === "*" || entry.commandText === "*") {
      throw new Error("gmail-reader exec approval allowlist contains a wildcard entry");
    }
    const executableFields = [entry.pattern, entry.commandText, entry.lastResolvedPath].filter((value) => typeof value === "string");
    if (executableFields.some((value) => /(^|[ /])(bash|sh|zsh|osascript|python|python3|ruby|perl|php)( |$)/.test(value) && !value.includes(brokerClientPath))) {
      throw new Error("gmail-reader exec approval allowlist contains an unrelated executable");
    }
    brokerPathMatch = brokerPathMatch && serialized.includes(brokerClientPath);
    if (typeof entry.argPattern !== "string") {
      throw new Error("gmail-reader exec approval allowlist is missing bounded argPattern");
    }
    let argRegex;
    try {
      argRegex = new RegExp(entry.argPattern);
    } catch (error) {
      regexCompiled = false;
      throw new Error(`gmail-reader exec approval argPattern failed to compile: ${error.message}`);
    }
    for (const method of approvedBrokerMethods) {
      if (!argRegex.test(`${method} {}`)) {
        approvedMethodsAccepted = false;
        throw new Error(`gmail-reader exec approval allowlist is missing approved broker method: ${method}`);
      }
    }
    const rejectionCases = [
      ["bareMethodDenied", "health_check"],
      ["lfInjectionDenied", "health_check {}\n/bin/sh"],
      ["lfInjectionDenied", "health_check {\n}"],
      ["crInjectionDenied", "health_check {}\r/bin/sh"],
      ["crInjectionDenied", "health_check {\r}"],
      ["crlfInjectionDenied", "health_check {}\r\n/bin/sh"],
      ["crlfInjectionDenied", "health_check {\r\n}"],
      ["commandChainingDenied", "health_check {}; /bin/sh"],
      ["foreignMethodDenied", "unapproved_method {}"],
      ["foreignMethodDenied", "delete_thread {}"],
      ["lfInjectionDenied", "create_draft {}\n/bin/sh"],
      ["crInjectionDenied", "create_draft {}\r/bin/sh"],
    ];
    for (const [name, candidate] of rejectionCases) {
      if (!argRegex.test(candidate)) continue;
      if (name === "bareMethodDenied") bareMethodDenied = false;
      if (name === "lfInjectionDenied") lfInjectionDenied = false;
      if (name === "crInjectionDenied") crInjectionDenied = false;
      if (name === "crlfInjectionDenied") crlfInjectionDenied = false;
      if (name === "commandChainingDenied") commandChainingDenied = false;
      if (name === "foreignMethodDenied") foreignMethodDenied = false;
      throw new Error(`gmail-reader exec approval argPattern accepted unsafe invocation: ${name}`);
    }
    boundedMethodPattern = boundedMethodPattern && approvedMethodsAccepted && foreignMethodDenied;
  }
  const strictInlineEvalStatus = "default false; not security-relevant because broker path is not an interpreter allowlist";
  console.log(`Exec approval preflight: autoAllowSkills=${autoAllowSkillsStatus}; strictInlineEval=${strictInlineEvalStatus}; allowlistEntries=${allowlist.length}; brokerPathMatch=${brokerPathMatch}; boundedMethodPattern=${boundedMethodPattern}; regexCompiled=${regexCompiled}; approvedMethodsAccepted=${approvedMethodsAccepted}; bareMethodDenied=${bareMethodDenied}; lfInjectionDenied=${lfInjectionDenied}; crInjectionDenied=${crInjectionDenied}; crlfInjectionDenied=${crlfInjectionDenied}; foreignMethodDenied=${foreignMethodDenied}; commandChainingDenied=${commandChainingDenied}`);
}

function stripQwenFallback(modelConfig) {
  if (!modelConfig || typeof modelConfig !== "object" || Array.isArray(modelConfig)) return modelConfig;
  const next = { ...modelConfig };
  if (Array.isArray(next.fallbacks)) {
    next.fallbacks = next.fallbacks.filter((entry) => entry !== "ollama/qwen3-coder:30b");
  }
  return next;
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

const defaults = asObject(asObject(cfg.agents).defaults);
const agents = Array.isArray(asObject(cfg.agents).list) ? cfg.agents.list.map((agent) => ({ ...agent })) : [];
const gmailIndex = agents.findIndex((agent) => agent && agent.id === "gmail-reader");
if (gmailIndex === -1) throw new Error("gmail-reader not found in agents.list");
validateGmailReaderExecApproval();

const secretPayload = {};
const planTargets = [];
const providerApiKey = asObject(asObject(cfg.models).providers).openai?.apiKey;
if (typeof providerApiKey === "string" && providerApiKey.length >= 8) {
  setNested(secretPayload, ["models", "providers", "openai", "apiKey"], providerApiKey);
  planTargets.push({
    type: "models.providers.apiKey",
    path: "models.providers.openai.apiKey",
    pathSegments: ["models", "providers", "openai", "apiKey"],
    providerId: "openai",
    ref: { source: "file", provider: "agent_os_openai", id: "/models/providers/openai/apiKey" },
  });
} else if (!isSecretRef(providerApiKey)) {
  throw new Error("models.providers.openai.apiKey is neither plaintext nor a SecretRef; refusing to infer secret source");
}

const agentRoot = path.join(openclawHome, "agents");
const manualProfiles = [];
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
      manualProfiles.push({ agentId, key: profile.key, keyRef: null });
    } else if (profile?.type === "api_key" && isSecretRef(profile.keyRef)) {
      manualProfiles.push({ agentId, key: null, keyRef: profile.keyRef });
    }
  } finally {
    db.close();
  }
}

if (manualProfiles.length === 0) {
  throw new Error("profiles.openai:manual was not found in exactly one auth-profile store; stop and inspect OpenClaw auth state");
}
if (manualProfiles.length > 1) {
  throw new Error(`profiles.openai:manual appeared in ${manualProfiles.length} auth-profile stores; refusing ambiguous SecretRef migration`);
}

const manualProfile = manualProfiles[0];
if (manualProfile.key) {
  setNested(secretPayload, ["profiles", "openai:manual", "key"], manualProfile.key);
  planTargets.push({
    type: "auth-profiles.api_key.key",
    path: "profiles.openai:manual.key",
    pathSegments: ["profiles", "openai:manual", "key"],
    agentId: manualProfile.agentId,
    authProfileProvider: "openai",
    ref: { source: "file", provider: "agent_os_openai", id: "/profiles/openai:manual/key" },
  });
}

if (planTargets.length > 0) {
  fs.writeFileSync(secretPath, `${JSON.stringify(secretPayload, null, 2)}\n`, { mode: 0o440 });
}

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
  targets: planTargets,
};
fs.writeFileSync(planPath, `${JSON.stringify(plan, null, 2)}\n`, { mode: 0o600 });

console.log(`Prepared config patch and SecretRef plan for manual profile agent: ${manualProfile.agentId}; targets=${planTargets.length}`);
NODE

if [ -f "$SECRET_FILE" ]; then
  chown root:openclawgw "$SECRET_FILE"
  chmod 0440 "$SECRET_FILE"
  echo "Created SecretRef backing file at $SECRET_FILE with root:openclawgw 0440."
else
  echo "SecretRef backing file already represented by existing refs; no new secret file created."
fi

export HOME=/Users/agent
export OPENCLAW_CONFIG_PATH="$CONFIG"
export OPENCLAW_STATE_DIR="$STATE_DIR"
export PATH="/Users/agent/.local/bin:/Users/agent/.local/openclaw/tools/node-v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

echo "Validating config patch..."
"$OPENCLAW_BIN" config patch --file "$PATCH_FILE" --replace-path agents.list --replace-path agents.defaults.model --dry-run

echo "Applying config patch..."
MUTATION_STARTED=1
"$OPENCLAW_BIN" config patch --file "$PATCH_FILE" --replace-path agents.list --replace-path agents.defaults.model

echo "Validating SecretRef migration plan..."
if "$NODE_BIN" -e 'const fs=require("fs"); process.exit((JSON.parse(fs.readFileSync(process.argv[1],"utf8")).targets||[]).length > 0 ? 0 : 1)' "$PLAN_FILE"; then
  "$OPENCLAW_BIN" secrets apply --from "$PLAN_FILE" --dry-run
else
  echo "No SecretRef migration targets; skipping secrets apply dry-run."
fi

echo "Applying SecretRef migration plan..."
if "$NODE_BIN" -e 'const fs=require("fs"); process.exit((JSON.parse(fs.readFileSync(process.argv[1],"utf8")).targets||[]).length > 0 ? 0 : 1)' "$PLAN_FILE"; then
  "$OPENCLAW_BIN" secrets apply --from "$PLAN_FILE"
else
  echo "No SecretRef migration targets; skipping secrets apply."
fi

echo "Removing unsafe qwen fallback through models command for compatibility..."
"$OPENCLAW_BIN" models fallbacks remove ollama/qwen3-coder:30b || true

echo "Validating updated config..."
"$OPENCLAW_BIN" config validate --json

echo "Reloading SecretRef runtime snapshot..."
"$OPENCLAW_BIN" secrets reload --json || {
  echo "WARN: secrets reload failed; gateway restart/kickstart validation is required."
}

echo "Kickstarting OpenClaw gateway to load config changes..."
launchctl kickstart -k system/ai.openclaw.gateway
sleep 3

echo "Post-remediation validation commands:"
"$OPENCLAW_BIN" --version
run_json_capture_allow_exit "security audit" "$SECURITY_AUDIT_JSON" "$OPENCLAW_BIN" security audit --json
run_json_capture_allow_exit "security audit deep" "$SECURITY_AUDIT_DEEP_JSON" "$OPENCLAW_BIN" security audit --deep --json
run_json_capture_allow_exit "doctor lint" "$DOCTOR_LINT_JSON" "$OPENCLAW_BIN" doctor --lint --json
run_json_capture_allow_exit "secrets audit" "$SECRETS_AUDIT_JSON" "$OPENCLAW_BIN" secrets audit --json
"$NODE_BIN" --input-type=module - "$SECURITY_AUDIT_JSON" "$SECURITY_AUDIT_DEEP_JSON" "$DOCTOR_LINT_JSON" <<'NODE'
import fs from "node:fs";

const [securityPath, securityDeepPath, doctorPath] = process.argv.slice(2);

function readJson(path) {
  return JSON.parse(fs.readFileSync(path, "utf8"));
}

function securityFindings(report) {
  return Array.isArray(report.findings) ? report.findings : [];
}

function assertSecurityAudit(path, label) {
  const report = readJson(path);
  const findings = securityFindings(report);
  const critical = findings.filter((finding) => finding.severity === "critical");
  const smallModelCritical = critical.filter((finding) => JSON.stringify(finding).includes("ollama/qwen3-coder:30b") || JSON.stringify(finding).includes("small-model"));
  if (smallModelCritical.length > 0) {
    console.error(`${label} acceptance failed: unsafe small-model critical finding remains.`);
    process.exit(1);
  }
  console.log(`${label} acceptance passed: critical=${critical.length}, smallModelCritical=0.`);
}

function assertDoctorLint(path) {
  const report = readJson(path);
  const findings = Array.isArray(report.findings) ? report.findings : [];
  const errors = findings.filter((finding) => finding.severity === "error");
  if (errors.length > 0) {
    console.error(`doctor lint acceptance failed: error findings=${errors.length}.`);
    process.exit(1);
  }
  console.log(`doctor lint acceptance passed: warnings/info accepted, errors=0.`);
}

assertSecurityAudit(securityPath, "security audit");
assertSecurityAudit(securityDeepPath, "security audit deep");
assertDoctorLint(doctorPath);
NODE
"$NODE_BIN" --input-type=module - "$SECRETS_AUDIT_JSON" <<'NODE'
import fs from "node:fs";

const [auditPath] = process.argv.slice(2);
const report = JSON.parse(fs.readFileSync(auditPath, "utf8"));
const summary = report.summary ?? {};
const plaintextCount = Number(summary.plaintextCount ?? -1);
const unresolvedRefCount = Number(summary.unresolvedRefCount ?? -1);
const shadowedRefCount = Number(summary.shadowedRefCount ?? -1);

if (plaintextCount !== 0 || unresolvedRefCount !== 0 || shadowedRefCount !== 0) {
  console.error(
    `Secrets audit acceptance failed: plaintextCount=${plaintextCount}, unresolvedRefCount=${unresolvedRefCount}, shadowedRefCount=${shadowedRefCount}`,
  );
  process.exit(1);
}

console.log("Secrets audit acceptance passed: plaintextCount=0, unresolvedRefCount=0, shadowedRefCount=0.");
NODE
"$OPENCLAW_BIN" sandbox explain --agent main --json
"$OPENCLAW_BIN" sandbox explain --agent gmail-reader --json
"$OPENCLAW_BIN" sandbox explain --agent email-researcher --json
launchctl print system/ai.openclaw.gateway | sed -n '1,120p'

echo "F-A4 OpenClaw containment remediation completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Rollback: sudo $ROLLBACK"
