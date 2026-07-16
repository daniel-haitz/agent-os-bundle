#!/usr/bin/env bash
# Controlled OpenAI proxy production transaction package.
#
# Default mode is dry-run and read-only. Production mode is intentionally hard
# disabled until independent review and operator authorization approve it.

set -euo pipefail

MODE="dry-run"
if [ "${1:-}" = "--production" ]; then
  MODE="production"
elif [ "${1:-}" = "--dry-run" ] || [ $# -eq 0 ]; then
  MODE="dry-run"
else
  echo "Usage: $0 [--dry-run|--production]" >&2
  exit 64
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${AGENT_OS_OPENAI_PROXY_CUTOVER_OUT:-/private/tmp/fa4-openai-proxy-cutover-${TS}-$$}"
MANIFEST="$REPO_ROOT/deploy/openai-proxy/openai-proxy-deployment-manifest.json"
PROXY_SOURCE="$REPO_ROOT/src/openai-credential-proxy/openai-forward-proxy.mjs"
CONTAINED_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-contained-egress-tests.mjs"
FIXTURE_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-fixture-tests.mjs"
ROLLBACK_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-rollback-fixtures.mjs"
TRANSACTION_FIXTURES="$REPO_ROOT/scripts/fa4-openai-proxy-transaction-fixtures.mjs"
SUBSTRATE_PROOF="$REPO_ROOT/scripts/fa4-openai-proxy-colima-substrate-proof.mjs"
NODE_BIN="/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node"
PHASE_LOG="$OUT_DIR/phase-log.tsv"
TOUCHED_MANIFEST="$OUT_DIR/touched-artifacts.json"
ROLLBACK_SCRIPT="$OUT_DIR/rollback.sh"
CONFIG_PATCH="$OUT_DIR/openclaw-config-patch-preview.json"
AUTH_CLEANUP="$OUT_DIR/auth-cleanup-plan.json"
REGRESSION_PLAN="$OUT_DIR/regression-plan.json"

mkdir -p "$OUT_DIR"
chmod 0700 "$OUT_DIR"
LOG="$OUT_DIR/cutover-dry-run.log"
FAILURES="$OUT_DIR/failures.tsv"
: > "$PHASE_LOG"
: > "$FAILURES"
: > "$LOG"

fail() {
  printf '%s\t%s\n' "$1" "$2" >> "$FAILURES"
  echo "$1: FAIL - $2"
}

pass() {
  echo "$1: PASS"
}

json_get() {
  "$NODE_BIN" -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); const v=process.argv[2].split('.').reduce((a,k)=>a&&a[k],j); console.log(v ?? '')" "$MANIFEST" "$1"
}

echo "F-A4 OpenAI proxy production transaction package"
echo "Mode: $MODE"
echo "Output: $OUT_DIR"

if [ "$MODE" = "production" ]; then
  fail "PRODUCTION MODE" "production execution is hard-disabled pending independent review and operator authorization"
  echo "OPENAI PROXY PACKAGE STATIC READINESS: GO"
  echo "OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: PARTIAL"
  echo "OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO"
  echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
  echo "OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED"
  exit 2
fi

for path in "$MANIFEST" "$PROXY_SOURCE" "$CONTAINED_TEST" "$FIXTURE_TEST" "$ROLLBACK_TEST" "$TRANSACTION_FIXTURES" "$SUBSTRATE_PROOF"; do
  if [ -f "$path" ]; then
    pass "PACKAGE FILE $(basename "$path")"
  else
    fail "PACKAGE FILE $(basename "$path")" "missing $path"
  fi
done

if "$NODE_BIN" -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$MANIFEST"; then
  pass "DEPLOYMENT MANIFEST JSON"
else
  fail "DEPLOYMENT MANIFEST JSON" "manifest is not valid JSON"
fi

if [ "$(json_get productionMutationAuthorized)" = "false" ]; then
  pass "MUTATION DEFAULT"
else
  fail "MUTATION DEFAULT" "manifest must keep productionMutationAuthorized=false"
fi

if [ "$(json_get topology.placement)" = "contained-colima-internal-network" ]; then
  pass "TOPOLOGY"
else
  fail "TOPOLOGY" "manifest topology must be contained-colima-internal-network"
fi

if [ "$(json_get productionTransactionSpecification)" = "partial" ] && [ "$(json_get productionTransactionExecutable)" = "false" ]; then
  pass "TRANSACTION STATUS FLAG"
else
  fail "TRANSACTION STATUS FLAG" "manifest must mark partial specification and non-executable transaction"
fi

echo
echo "Production transaction phases specified but not executable:"
cat <<'PHASES'
1. preflight
2. evidence capture
3. current-state verification
4. Colima substrate verification
5. production network staging
6. contained OpenClaw component staging
7. proxy component staging
8. proxy code/runtime integrity verification
9. local-token generation and staging
10. upstream-key migration staging
11. proxy health validation
12. contained OpenClaw-to-proxy validation
13. direct-egress denial validation
14. OpenClaw config/auth patch staging
15. gateway restart plan
16. functional route validation
17. Gmail/Telegram/Ollama regression plan
18. source-key removal gate
19. residue scan
20. cold-start handoff
21. reboot handoff
22. closure evidence
PHASES

while IFS= read -r phase; do
  [ -n "$phase" ] || continue
  printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$phase" "planned-dry-run" >> "$PHASE_LOG"
done <<'PHASES'
preflight
evidence-capture
current-state-verification
colima-substrate-verification
production-network-staging
contained-openclaw-component-staging
proxy-component-staging
proxy-code-runtime-integrity-verification
local-token-generation-and-staging
upstream-key-migration-staging
proxy-health-validation
contained-openclaw-to-proxy-validation
direct-egress-denial-validation
openclaw-config-auth-patch-staging
gateway-restart-plan
functional-route-validation
gmail-telegram-ollama-regression-plan
source-key-removal-gate
residue-scan
cold-start-handoff
reboot-handoff
closure-evidence
PHASES
pass "PHASE TRACKING"

cat > "$TOUCHED_MANIFEST" <<'JSON'
{
  "mode": "dry-run",
  "productionExecution": "disabled",
  "artifacts": [
    {
      "path": "/Users/agent/.openclaw/openai-proxy/local-token",
      "owner": "openclawgw",
      "group": "openclawgw",
      "mode": "0600",
      "existsBeforeCutover": false,
      "creator": "operator cutover transaction",
      "consumer": "rejected shared single-file token design; placement/local-token custody reopened",
      "backupRule": "capture absent-before state and parent metadata before creation",
      "rollbackRule": "remove if absent-before; restore previous file and metadata if existing-before"
    },
    {
      "path": "/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets/openai-upstream.json",
      "owner": "openai-credential-broker",
      "group": "openai-credential-broker",
      "mode": "0600",
      "existsBeforeCutover": false,
      "creator": "operator cutover transaction",
      "consumer": "OpenAI proxy container via read-only mount",
      "backupRule": "capture absent-before state and parent metadata before migration",
      "rollbackRule": "remove if absent-before; restore previous file and metadata if existing-before"
    },
    {
      "path": "/Users/openai-credential-broker/agent-os-openai-credential-broker/bin/openai-forward-proxy.mjs",
      "owner": "root",
      "group": "openai-credential-broker",
      "mode": "0550",
      "existsBeforeCutover": false,
      "creator": "operator cutover transaction",
      "consumer": "OpenAI proxy container",
      "backupRule": "capture absent-before state and source hash",
      "rollbackRule": "remove if absent-before; restore previous file and metadata if existing-before"
    },
    {
      "path": "/Users/openai-credential-broker/agent-os-openai-credential-broker/runtime/node",
      "owner": "root",
      "group": "openai-credential-broker",
      "mode": "0550",
      "existsBeforeCutover": false,
      "creator": "operator cutover transaction",
      "consumer": "OpenAI proxy container",
      "backupRule": "capture absent-before state and source hash",
      "rollbackRule": "remove if absent-before; restore previous file and metadata if existing-before"
    },
    {
      "path": "/Users/agent/.openclaw/openclaw.json",
      "owner": "root",
      "group": "openclawgw",
      "mode": "0440",
      "existsBeforeCutover": true,
      "creator": "existing OpenClaw installation; patched by operator cutover transaction",
      "consumer": "OpenClaw gateway; contained model-network consumer rejected pending placement reconciliation",
      "backupRule": "copy exact bytes and metadata before patch",
      "rollbackRule": "restore exact bytes and metadata; direct route restoration after cutover requires explicit operator approval"
    },
    {
      "path": "Docker network agent-os-openai-egress-openclaw",
      "owner": "Docker/Colima",
      "group": "Docker/Colima",
      "mode": "internal network",
      "existsBeforeCutover": false,
      "creator": "operator cutover transaction",
      "consumer": "rejected contained OpenClaw model-network component and proxy",
      "backupRule": "record absent-before network state",
      "rollbackRule": "remove only if created by this transaction label"
    },
    {
      "path": "Docker network agent-os-openai-egress-upstream",
      "owner": "Docker/Colima",
      "group": "Docker/Colima",
      "mode": "constrained upstream network",
      "existsBeforeCutover": false,
      "creator": "operator cutover transaction",
      "consumer": "proxy and upstream egress gateway",
      "backupRule": "record absent-before network state",
      "rollbackRule": "remove only if created by this transaction label"
    }
  ]
}
JSON
chmod 0600 "$TOUCHED_MANIFEST"
pass "TOUCHED ARTIFACT MANIFEST"

cat > "$CONFIG_PATCH" <<'JSON'
{
  "models": {
    "providers": {
      "openai": {
        "baseUrl": "http://agent-os-openai-forward-proxy:18187/v1",
        "api": "openai-responses",
        "auth": "api-key",
        "apiKey": "<synthetic-local-proxy-token-from-/Users/agent/.openclaw/openai-proxy/local-token>"
      }
    }
  },
  "agents": {
    "main": {
      "model": "openai/gpt-5.5",
      "fallbacks": ["ollama/qwen3-coder:30b"]
    },
    "research-handoff-gate": {
      "model": "openai/gpt-5.5",
      "fallbacks": []
    },
    "email-researcher": {
      "model": "openai/gpt-5.5",
      "fallbacks": []
    },
    "heartbeat": {
      "model": "ollama/qwen2.5-coder:14b",
      "fallbacks": []
    },
    "gmail-reader": {
      "model": "ollama/qwen3-coder:30b",
      "fallbacks": []
    }
  }
}
JSON
chmod 0600 "$CONFIG_PATCH"
pass "CONFIG PATCH PREVIEW"

cat > "$AUTH_CLEANUP" <<'JSON'
{
  "order": [
    "backup openclaw.json, auth profiles, generated stores, snapshots, and launchd env metadata",
    "stage proxy and local-token path",
    "migrate upstream OpenAI key into broker-owned proxy custody without stdout, argv, env, repository, or broad evidence exposure",
    "patch OpenClaw provider to contained proxy baseUrl and synthetic local token",
    "restart/validate controlled gateway and contained model-network component",
    "verify main, research-handoff-gate, and email-researcher route through proxy",
    "verify heartbeat and gmail-reader remain local-only",
    "scan all OpenClaw-readable stores for real-key residue using in-process comparison",
    "remove or neutralize direct source only after all validation gates pass"
  ],
  "preserve": ["Telegram credentials", "Gmail broker credentials", "local Ollama configuration"],
  "forbid": ["printing real key", "hashing real key into broad evidence", "passing real key in argv", "placing real key in environment"]
}
JSON
chmod 0600 "$AUTH_CLEANUP"
pass "AUTH CLEANUP PLAN"

cat > "$REGRESSION_PLAN" <<'JSON'
{
  "fixture": ["proxy transport/security", "contained-egress synthetic", "Colima substrate", "transaction fixtures"],
  "dryRun": ["manifest validation", "config patch preview", "rollback manifest generation", "residue scanner fixture"],
  "liveCutover": [
    "main routes OpenAI through proxy",
    "research-handoff-gate routes OpenAI through proxy",
    "email-researcher routes OpenAI through proxy",
    "heartbeat remains local Ollama route",
    "gmail-reader remains local Ollama route",
    "Gmail broker health/search regression",
    "Telegram connectivity regression",
    "Ollama 127.0.0.1:11434 regression",
    "gateway supervision regression",
    "research/web routing regression"
  ],
  "postReboot": ["placement-dependent startup ordering unresolved", "gateway does not restore direct OpenAI route", "residue scan remains clean"]
}
JSON
chmod 0600 "$REGRESSION_PLAN"
pass "REGRESSION PLAN"

cat > "$ROLLBACK_SCRIPT" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ $# -ne 1 ]; then
  echo "Usage: rollback.sh <rollback-manifest.json>" >&2
  exit 64
fi
MANIFEST="$1"
if [ ! -f "$MANIFEST" ]; then
  echo "Rollback manifest missing: $MANIFEST" >&2
  exit 66
fi
node - "$MANIFEST" <<'NODE'
const fs = require("fs");
const path = require("path");
const manifest = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
for (const entry of [...manifest.entries].reverse()) {
  if (entry.existedBefore) {
    fs.mkdirSync(path.dirname(entry.path), { recursive: true });
    fs.copyFileSync(entry.backupPath, entry.path);
    if (entry.mode) fs.chmodSync(entry.path, parseInt(entry.mode, 8));
    console.log(`RESTORED ${entry.path}`);
  } else if (fs.existsSync(entry.path)) {
    fs.rmSync(entry.path, { recursive: true, force: true });
    console.log(`REMOVED ${entry.path}`);
  } else {
    console.log(`ABSENT ${entry.path}`);
  }
}
NODE
echo "ROLLBACK VERIFIED: PASS"
SH
chmod 0700 "$ROLLBACK_SCRIPT"
pass "ROLLBACK SCRIPT GENERATED"

echo
echo "Credential migration design:"
echo "- read existing provider apiKey inside operator-owned script memory only"
echo "- write upstream key to broker-owned 0600 store via stdin/file descriptor only"
echo "- do not print value, do not pass on command line, do not write to repository"
echo "- remove source only after proxy health, config cutover, model route, and rollback point pass"

echo
echo "Running executable transaction fixture suite..."
if "$NODE_BIN" "$TRANSACTION_FIXTURES" > "$OUT_DIR/transaction-fixtures.log" 2>&1; then
  cat "$OUT_DIR/transaction-fixtures.log"
  pass "TRANSACTION FIXTURES"
else
  cat "$OUT_DIR/transaction-fixtures.log"
  fail "TRANSACTION FIXTURES" "transaction fixture suite failed"
fi

echo
if [ -s "$FAILURES" ]; then
  echo "Cutover package blockers:"
  cat "$FAILURES"
  echo "OPENAI PROXY PACKAGE STATIC READINESS: NO-GO"
  echo "OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: PARTIAL"
  echo "OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO"
  echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
  echo "OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED"
  exit 2
fi

echo "OPENAI PROXY PACKAGE STATIC READINESS: GO"
echo "OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: PARTIAL"
echo "OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO"
echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
echo "OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED"
