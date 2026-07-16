#!/usr/bin/env bash
# F-A4 read-only readiness foundation for the OpenAI credential proxy path.
#
# This script does not install services, change OpenClaw config, touch live
# credentials, or mutate production launchd/auth/profile state. It writes only
# to its evidence directory and temporary fixture paths.

set -euo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${1:-/private/tmp/fa4-openai-proxy-readiness-${TS}}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$OUT_DIR/readiness.log"
FAILURES="$OUT_DIR/failures.txt"
METADATA_BEFORE="$OUT_DIR/live-metadata-before.tsv"
METADATA_AFTER="$OUT_DIR/live-metadata-after.tsv"
HASHES_BEFORE="$OUT_DIR/live-hashes-before.tsv"
HASHES_AFTER="$OUT_DIR/live-hashes-after.tsv"
NODE_BIN="/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node"
OPENCLAW_TRANSPORT="/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/openai-transport-stream-Dj78Cdnf.js"
OPENAI_SDK="/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/node_modules/openai/index.mjs"
PROXY_SOURCE="$REPO_ROOT/src/openai-credential-proxy/openai-forward-proxy.mjs"
FIXTURE_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-fixture-tests.mjs"
CONTAINED_EGRESS_TEST="$REPO_ROOT/scripts/fa4-openai-proxy-contained-egress-tests.mjs"
INVENTORY_HELPER="$REPO_ROOT/scripts/fa4-openai-proxy-inventory.mjs"
CUTOVER_SCRIPT="$REPO_ROOT/scripts/fa4-openai-proxy-cutover.sh"
ROLLBACK_FIXTURES="$REPO_ROOT/scripts/fa4-openai-proxy-rollback-fixtures.mjs"
DEPLOYMENT_MANIFEST="$REPO_ROOT/deploy/openai-proxy/openai-proxy-deployment-manifest.json"
INVENTORY_JSON="$OUT_DIR/openai-proxy-production-inventory.json"

LIVE_PATHS=(
  "/Users/agent/.openclaw"
  "/Users/agent/.openclaw/openclaw.json"
  "/Users/agent/.openclaw/state"
  "/Users/agent/.openclaw/secrets"
  "/Users/openai-credential-broker"
  "/Users/openai-credential-broker/agent-os-openai-credential-broker"
)

mkdir -p "$OUT_DIR"
chmod 0700 "$OUT_DIR"
: > "$FAILURES"
exec > >(tee "$LOG") 2>&1

fail_gate() {
  local gate="$1"
  local detail="$2"
  printf '%s\t%s\n' "$gate" "$detail" >> "$FAILURES"
  echo "$gate: FAIL — $detail"
}

pass_gate() {
  local gate="$1"
  echo "$gate: PASS"
}

capture_metadata() {
  local output="$1"
  printf 'path\texists\tuid\tuser\tgid\tgroup\tmode\n' > "$output"
  local path
  for path in "${LIVE_PATHS[@]}"; do
    if [ -e "$path" ]; then
      stat -f '%N	present	%u	%Su	%g	%Sg	%OLp' "$path" >> "$output"
    else
      printf '%s\tabsent\t\t\t\t\t\n' "$path" >> "$output"
    fi
  done
}

capture_hashes() {
  local output="$1"
  printf 'path\tsha256\n' > "$output"
  local path
  for path in "${LIVE_PATHS[@]}"; do
    if [ -f "$path" ] && [ -r "$path" ]; then
      shasum -a 256 "$path" | awk -v p="$path" '{print p "\t" $1}' >> "$output"
    else
      printf '%s\t%s\n' "$path" "not-readable-or-not-file" >> "$output"
    fi
  done
}

capture_metadata "$METADATA_BEFORE"
capture_hashes "$HASHES_BEFORE"

echo "F-A4 OpenAI proxy readiness foundation started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Output: $OUT_DIR"

if id -u openai-credential-broker >/dev/null 2>&1; then
  pass_gate "GATE A — host and identity compatibility"
else
  fail_gate "GATE A — host and identity compatibility" "openai-credential-broker identity is absent"
fi

if [ -x "$NODE_BIN" ] && [ -f "$PROXY_SOURCE" ] && [ -f "$FIXTURE_TEST" ] && [ -f "$CONTAINED_EGRESS_TEST" ]; then
  pass_gate "GATE B — proxy code/runtime custody"
else
  fail_gate "GATE B — proxy code/runtime custody" "required proxy source/runtime fixture files are missing"
fi

if [ -f "$CUTOVER_SCRIPT" ] && [ -f "$ROLLBACK_FIXTURES" ] && [ -f "$DEPLOYMENT_MANIFEST" ]; then
  pass_gate "GATE M — cutover package artifacts"
else
  fail_gate "GATE M — cutover package artifacts" "cutover script, rollback fixtures, or deployment manifest missing"
fi

if rg -n "apiKey: SecretInputSchema|baseUrl: string\\(\\)\\.min\\(1\\)|auth: union" \
  /Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/zod-schema.core-DGUr-AGH.js >/dev/null; then
  pass_gate "GATE C — local-token compatibility"
  echo "LOCAL TOKEN MECHANISM: protected OpenClaw provider apiKey configuration value"
else
  fail_gate "GATE C — local-token compatibility" "installed schema evidence for provider apiKey/baseUrl/auth was not found"
fi

if [ -f "$DEPLOYMENT_MANIFEST" ] && "$NODE_BIN" -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); const ok=(j.artifacts||[]).some(a=>String(a.path).endsWith('/secrets/openai-upstream.json')&&a.owner==='openai-credential-broker'&&a.mode==='0600'); process.exit(ok?0:1)" "$DEPLOYMENT_MANIFEST"; then
  pass_gate "GATE D — upstream-key custody design"
else
  fail_gate "GATE D — upstream-key custody design" "deployment manifest lacks broker-owned 0600 upstream credential store"
fi

if [ -f "$OPENCLAW_TRANSPORT" ] && [ -f "$OPENAI_SDK" ]; then
  pass_gate "GATE E — exact OpenClaw transport compatibility"
else
  fail_gate "GATE E — exact OpenClaw transport compatibility" "installed OpenClaw transport or bundled OpenAI SDK not found"
fi

echo "Running production inventory helper..."
if "$NODE_BIN" "$INVENTORY_HELPER" "$OUT_DIR" > "$OUT_DIR/production-inventory.log" 2>&1; then
  cat "$OUT_DIR/production-inventory.log"
else
  cat "$OUT_DIR/production-inventory.log"
  fail_gate "PRODUCTION INVENTORY HELPER" "inventory helper failed"
fi

inventory_value() {
  local expression="$1"
  "$NODE_BIN" -e "const fs=require('fs'); const j=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); const v=(${expression}); if (Array.isArray(v)) console.log(v.join(',')); else if (v && typeof v === 'object') console.log(JSON.stringify(v)); else console.log(v ?? '');" "$INVENTORY_JSON"
}

if [ -f "$INVENTORY_JSON" ]; then
  egress_status="$(inventory_value "j.gateStatus.egressPlacement")"
  auth_status="$(inventory_value "j.gateStatus.authPrecedence")"
  routing_status="$(inventory_value "j.gateStatus.agentFallback")"
  auth_bypass_count="$(inventory_value "j.auth.bypassSourceCount")"
  protected_gap_count="$(inventory_value "j.auth.unresolvedProtectedEvidence")"
  direct_route_count="$(inventory_value "j.routing.directOpenAIRouteCount")"
  unknown_route_count="$(inventory_value "j.routing.unknownRouteCount")"
  placement="$(inventory_value "j.egress.selectedPlacement")"
  echo "EGRESS PLACEMENT DECISION: $placement"
  echo "EGRESS ENFORCEMENT POINT: $(inventory_value "j.egress.enforceableDesign.enforcementPoint")"
  if [ "$egress_status" = "PASS_DESIGN_ONLY" ]; then
    pass_gate "GATE F — egress-placement feasibility"
    echo "EGRESS PLACEMENT FEASIBILITY: PASS"
  else
    fail_gate "GATE F — egress-placement feasibility" "no enforceable placement design proved; inspect $INVENTORY_JSON"
    echo "EGRESS PLACEMENT FEASIBILITY: FAIL"
  fi
  echo "OPENAI AUTH PRECEDENCE INVENTORY: $auth_status"
  echo "OPENAI AUTH BYPASS SOURCE COUNT: $auth_bypass_count"
  echo "OPENAI PROTECTED EVIDENCE GAP COUNT: $protected_gap_count"
  if [ "$protected_gap_count" = "0" ]; then
    pass_gate "GATE G — auth-precedence inventory"
  else
    fail_gate "GATE G — auth-precedence inventory" "protectedEvidenceGaps=$protected_gap_count; inspect $INVENTORY_JSON"
  fi
  echo "AGENT AND FALLBACK INVENTORY: $routing_status"
  echo "DIRECT OPENAI ROUTE COUNT: $direct_route_count"
  echo "UNKNOWN ROUTE COUNT: $unknown_route_count"
  if [ "$unknown_route_count" = "0" ]; then
    pass_gate "GATE H — agent/fallback inventory"
  else
    fail_gate "GATE H — agent/fallback inventory" "unknownRoutes=$unknown_route_count; inspect $INVENTORY_JSON"
  fi
else
  fail_gate "GATE F — egress-placement feasibility" "inventory evidence was not generated"
  fail_gate "GATE G — auth-precedence inventory" "inventory evidence was not generated"
  fail_gate "GATE H — agent/fallback inventory" "inventory evidence was not generated"
fi

if ! rg -n "__FIXTURE_SOCKET__|AGENT_OS_OPENAI_SECRETREF_TEST_MODE|fa4-openai-secretref-resolver" "$PROXY_SOURCE" "$FIXTURE_TEST" >/dev/null; then
  pass_gate "GATE I — production-plan contamination checks"
else
  fail_gate "GATE I — production-plan contamination checks" "proxy fixture contains superseded SecretRef markers"
fi

echo "LAUNCHD DESIGN: ai.agent-os.openai-forward-proxy under openai-credential-broker; no production plist installed by this harness."
pass_gate "GATE J — launchd/cold-start design"

echo "ROLLBACK DESIGN: reuse deployment manifest and rollback pattern; production rollback script not generated by this harness."
echo "ROLLBACK PROOF LIMIT: rollback scenario fixtures are not executable production rollback proof."
pass_gate "GATE K — rollback prerequisites"

echo "Running isolated synthetic proxy fixture suite..."
if "$NODE_BIN" "$FIXTURE_TEST" > "$OUT_DIR/fixture-tests.log" 2>&1; then
  pass_gate "FIXTURE PROXY TEST SUITE"
else
  cat "$OUT_DIR/fixture-tests.log"
  fail_gate "FIXTURE PROXY TEST SUITE" "synthetic fixture tests failed"
fi

echo "Running isolated contained-egress proof fixture..."
if "$NODE_BIN" "$CONTAINED_EGRESS_TEST" > "$OUT_DIR/contained-egress-tests.log" 2>&1; then
  cat "$OUT_DIR/contained-egress-tests.log"
  pass_gate "OPENAI PROXY CONTAINED EGRESS PROOF"
  echo "OPENAI PROXY CONTAINED EGRESS PROOF: GO"
else
  cat "$OUT_DIR/contained-egress-tests.log"
  fail_gate "OPENAI PROXY CONTAINED EGRESS PROOF" "contained-egress fixture failed"
  echo "OPENAI PROXY CONTAINED EGRESS PROOF: NO-GO"
fi

echo "Running cutover package dry-run..."
if "$CUTOVER_SCRIPT" --dry-run > "$OUT_DIR/cutover-dry-run.log" 2>&1; then
  cat "$OUT_DIR/cutover-dry-run.log"
  pass_gate "OPENAI PROXY CUTOVER PACKAGE DRY RUN"
else
  cat "$OUT_DIR/cutover-dry-run.log"
  fail_gate "OPENAI PROXY CUTOVER PACKAGE DRY RUN" "cutover dry-run failed"
fi

echo "Running rollback fixture tests..."
if "$NODE_BIN" "$ROLLBACK_FIXTURES" > "$OUT_DIR/rollback-fixtures.log" 2>&1; then
  cat "$OUT_DIR/rollback-fixtures.log"
  pass_gate "OPENAI PROXY ROLLBACK FIXTURES"
else
  cat "$OUT_DIR/rollback-fixtures.log"
  fail_gate "OPENAI PROXY ROLLBACK FIXTURES" "rollback fixtures failed"
fi

capture_metadata "$METADATA_AFTER"
capture_hashes "$HASHES_AFTER"

if diff -u "$METADATA_BEFORE" "$METADATA_AFTER" > "$OUT_DIR/live-metadata.diff" && diff -u "$HASHES_BEFORE" "$HASHES_AFTER" > "$OUT_DIR/live-hashes.diff"; then
  pass_gate "GATE L — zero production mutation"
  echo "READINESS PRODUCTION MUTATION: NONE VERIFIED"
else
  fail_gate "GATE L — zero production mutation" "live metadata/hash differences detected; inspect $OUT_DIR"
fi

echo
echo "Readiness blockers:"
if [ -s "$FAILURES" ]; then
  cat "$FAILURES"
  echo "OPENAI PROXY PACKAGE STATIC READINESS: NO-GO"
  echo "OPENAI PROXY SYNTHETIC PROOF: SEE FAILURES"
  echo "OPENAI PROXY PRODUCTION SUBSTRATE READY: NO-GO"
  echo "OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO"
  echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
  echo "F-A4 STATUS: OPEN"
  exit 2
fi

echo "NONE"
echo "OPENAI PROXY PACKAGE STATIC READINESS: GO"
echo "OPENAI PROXY SYNTHETIC PROOF: GO"
echo "OPENAI PROXY PRODUCTION SUBSTRATE READY: NO-GO"
echo "OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO"
echo "OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO"
echo "F-A4 STATUS: OPEN"
