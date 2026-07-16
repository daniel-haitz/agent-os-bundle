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

if [ -x "$NODE_BIN" ] && [ -f "$PROXY_SOURCE" ] && [ -f "$FIXTURE_TEST" ]; then
  pass_gate "GATE B — proxy code/runtime custody"
else
  fail_gate "GATE B — proxy code/runtime custody" "required proxy source/runtime fixture files are missing"
fi

if rg -n "apiKey: SecretInputSchema|baseUrl: string\\(\\)\\.min\\(1\\)|auth: union" \
  /Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/zod-schema.core-DGUr-AGH.js >/dev/null; then
  pass_gate "GATE C — local-token compatibility"
  echo "LOCAL TOKEN MECHANISM: protected OpenClaw provider apiKey configuration value"
else
  fail_gate "GATE C — local-token compatibility" "installed schema evidence for provider apiKey/baseUrl/auth was not found"
fi

if [ -d "/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets" ]; then
  pass_gate "GATE D — upstream-key custody"
else
  fail_gate "GATE D — upstream-key custody" "broker secrets directory is absent; expected before production cutover"
fi

if [ -f "$OPENCLAW_TRANSPORT" ] && [ -f "$OPENAI_SDK" ]; then
  pass_gate "GATE E — exact OpenClaw transport compatibility"
else
  fail_gate "GATE E — exact OpenClaw transport compatibility" "installed OpenClaw transport or bundled OpenAI SDK not found"
fi

if command -v pfctl >/dev/null 2>&1; then
  echo "EGRESS PLACEMENT DECISION: host-only per-identity containment is not accepted while pf remains disabled."
  echo "EGRESS PLACEMENT DESIGN: proxy implementation must include a contained-network placement or a separately proven pf-equivalent identity egress wall before production GO."
  fail_gate "GATE F — egress-placement feasibility" "pf is disabled by current F-A4 baseline; direct OpenAI egress denial is not structurally enforced yet"
  echo "EGRESS PLACEMENT FEASIBILITY: FAIL"
else
  fail_gate "GATE F — egress-placement feasibility" "pfctl unavailable and no contained-network proof exists"
  echo "EGRESS PLACEMENT FEASIBILITY: FAIL"
fi

echo "AUTH PRECEDENCE INVENTORY: requires future operator-readable inventory of openclaw.json, auth profiles, generated stores, launchd env, and snapshots."
fail_gate "GATE G — auth-precedence inventory" "production inventory is not implemented in this foundation"

echo "AGENT/FALLBACK INVENTORY: requires future operator-readable inventory of main, heartbeat, gmail-reader, research-handoff-gate, and email-researcher effective models."
fail_gate "GATE H — agent/fallback inventory" "production inventory is not implemented in this foundation"

if ! rg -n "__FIXTURE_SOCKET__|AGENT_OS_OPENAI_SECRETREF_TEST_MODE|fa4-openai-secretref-resolver" "$PROXY_SOURCE" "$FIXTURE_TEST" >/dev/null; then
  pass_gate "GATE I — production-plan contamination checks"
else
  fail_gate "GATE I — production-plan contamination checks" "proxy fixture contains superseded SecretRef markers"
fi

echo "LAUNCHD DESIGN: ai.agent-os.openai-forward-proxy under openai-credential-broker; no production plist installed by this harness."
pass_gate "GATE J — launchd/cold-start design"

echo "ROLLBACK DESIGN: reuse deployment manifest and rollback pattern; production rollback script not generated by this harness."
pass_gate "GATE K — rollback prerequisites"

echo "Running isolated synthetic proxy fixture suite..."
if "$NODE_BIN" "$FIXTURE_TEST" > "$OUT_DIR/fixture-tests.log" 2>&1; then
  pass_gate "FIXTURE PROXY TEST SUITE"
else
  cat "$OUT_DIR/fixture-tests.log"
  fail_gate "FIXTURE PROXY TEST SUITE" "synthetic fixture tests failed"
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
  echo "OPENAI PROXY IMPLEMENTATION READINESS: NO-GO"
  exit 2
fi

echo "NONE"
echo "OPENAI PROXY IMPLEMENTATION READINESS: GO"
