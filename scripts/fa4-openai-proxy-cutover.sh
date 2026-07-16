#!/usr/bin/env bash
# Controlled OpenAI proxy static cutover package validator.
#
# Default mode is dry-run and read-only. Production mode is intentionally gated
# because this script does not implement the production transaction.

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
OUT_DIR="${AGENT_OS_OPENAI_PROXY_CUTOVER_OUT:-/private/tmp/fa4-openai-proxy-cutover-${TS}}"
MANIFEST="$REPO_ROOT/deploy/openai-proxy/openai-proxy-deployment-manifest.json"
PROXY_SOURCE="$REPO_ROOT/src/openai-credential-proxy/openai-forward-proxy.mjs"
CONTAINED_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-contained-egress-tests.mjs"
FIXTURE_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-fixture-tests.mjs"
ROLLBACK_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-rollback-fixtures.mjs"
NODE_BIN="/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node"

mkdir -p "$OUT_DIR"
chmod 0700 "$OUT_DIR"
LOG="$OUT_DIR/cutover-dry-run.log"
FAILURES="$OUT_DIR/failures.tsv"
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

echo "F-A4 OpenAI proxy static cutover package validator"
echo "Mode: $MODE"
echo "Output: $OUT_DIR"

if [ "$MODE" = "production" ]; then
  fail "PRODUCTION MODE" "production cutover transaction is not implemented by this static package validator"
  echo "OPENAI PROXY PACKAGE STATIC READINESS: NO-GO"
  echo "OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO"
  echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
  exit 2
fi

for path in "$MANIFEST" "$PROXY_SOURCE" "$CONTAINED_TEST" "$FIXTURE_TEST" "$ROLLBACK_TEST"; do
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

echo
echo "Cutover phases prepared:"
cat <<'PHASES'
1. preflight
2. evidence capture
3. substrate verification
4. contained network creation
5. proxy image/runtime staging
6. upstream credential migration
7. local-token creation
8. proxy start
9. synthetic health and transport validation
10. direct-egress denial validation
11. OpenClaw config/auth patch
12. controlled gateway restart
13. functional OpenAI model test through proxy
14. verify main, research-handoff-gate, and email-researcher route through proxy
15. verify heartbeat and gmail-reader remain unchanged
16. residue scan
17. cold-start validation
18. reboot validation handoff
19. closure evidence
PHASES

cat > "$OUT_DIR/openclaw-config-patch-preview.json" <<'JSON'
{
  "models": {
    "providers": {
      "openai": {
        "baseUrl": "http://agent-os-openai-forward-proxy:18187/v1",
        "api": "openai-responses",
        "auth": "api-key",
        "apiKey": "<synthetic-local-proxy-token>"
      }
    }
  }
}
JSON
chmod 0600 "$OUT_DIR/openclaw-config-patch-preview.json"
pass "CONFIG PATCH PREVIEW"

echo
echo "Credential migration design:"
echo "- read existing provider apiKey inside operator-owned script memory only"
echo "- write upstream key to broker-owned 0600 store via stdin/file descriptor only"
echo "- do not print value, do not pass on command line, do not write to repository"
echo "- remove source only after proxy health, config cutover, model route, and rollback point pass"

echo
if [ -s "$FAILURES" ]; then
  echo "Cutover package blockers:"
  cat "$FAILURES"
  echo "OPENAI PROXY PACKAGE STATIC READINESS: NO-GO"
  echo "OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO"
  echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
  exit 2
fi

echo "OPENAI PROXY PACKAGE STATIC READINESS: GO"
echo "OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO"
echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
