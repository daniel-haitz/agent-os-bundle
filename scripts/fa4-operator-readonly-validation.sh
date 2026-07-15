#!/usr/bin/env bash
# F-A4 operator-owned read-only validation harness.
#
# Run by the human operator from an admin shell. This script intentionally uses
# sudo for protected read-only checks while preserving the root-owned OpenClaw
# tamper lock. It must not print secret values.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root via sudo from the operator account." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${1:-/Users/dannybigdeals/fa4-readonly-validation-${TS}}"
SUMMARY_FILE="$OUT_DIR/summary.tsv"
OPENCLAW_BIN="/Users/agent/.local/bin/openclaw"
NODE_BIN="/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node"
BROKER_CLIENT="/Users/agent/.openclaw/scripts/gmail-broker-client.mjs"
GATE_SCRIPT="/Users/agent/.openclaw/scripts/research-handoff-gate.mjs"
GATE_TEST="/Users/agent/.openclaw/scripts/test-research-handoff-gate.mjs"

mkdir -p "$OUT_DIR"
chmod 0700 "$OUT_DIR"
printf 'check\texit_status\tcommand\n' > "$SUMMARY_FILE"

redact() {
  sed -E \
    -e 's/("?(api[_-]?key|token|password|secret|authorization|refresh[_-]?token|access[_-]?token)"?[[:space:]]*[:=][[:space:]]*)("[^"]+"|[^[:space:],}]+)/\1"<redacted>"/Ig' \
    -e 's/(Bearer )[A-Za-z0-9._~+\/=-]+/\1<redacted>/Ig'
}

run_capture() {
  local name="$1"
  shift
  {
    echo "### $name"
    echo "\$ $*"
    set +e
    "$@" 2>&1 | redact
    local cmd_status=${PIPESTATUS[0]}
    set -e
    echo "exit status: $cmd_status"
    printf '%s\t%s\t%s\n' "$name" "$cmd_status" "$*" >> "$SUMMARY_FILE"
    echo
  } | tee "$OUT_DIR/$name.txt"
}

run_as_openclawgw() {
  sudo -u openclawgw -g openclawgw env \
    HOME=/Users/agent \
    OPENCLAW_CONFIG_PATH=/Users/agent/.openclaw/openclaw.json \
    OPENCLAW_STATE_DIR=/Users/agent/.openclaw/state \
    PATH=/Users/agent/.local/bin:/Users/agent/.local/openclaw/tools/node-v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    "$@"
}

echo "F-A4 read-only validation capture: $OUT_DIR"
date -u +%Y-%m-%dT%H:%M:%SZ | tee "$OUT_DIR/timestamp.txt"

run_capture openclaw-version run_as_openclawgw "$OPENCLAW_BIN" --version
run_capture gateway-launchd launchctl print system/ai.openclaw.gateway
run_capture broker-launchd launchctl print system/ai.agent-os.gmail-broker
run_capture egress-proxy-launchd launchctl print system/ai.agent-os-egress-proxy
run_capture process-identities ps -axo user,uid,pid,ppid,command
run_capture openclaw-path-modes stat -f '%Sp %Su:%Sg %N' \
  /Users/agent/.openclaw \
  /Users/agent/.openclaw/openclaw.json \
  /Users/agent/.openclaw/npm \
  /Users/agent/.openclaw/npm/projects \
  /Users/agent/.openclaw/scripts \
  /Users/agent/.openclaw/scripts/gmail-broker-client.mjs
run_capture broker-socket-modes stat -f '%Sp %Su:%Sg %N' \
  /var/run/agent-os \
  /var/run/agent-os/gmail-broker.sock

run_capture openclaw-security-audit run_as_openclawgw "$OPENCLAW_BIN" security audit --json
run_capture openclaw-security-audit-deep run_as_openclawgw "$OPENCLAW_BIN" security audit --deep --json
run_capture openclaw-doctor-lint run_as_openclawgw "$OPENCLAW_BIN" doctor --lint --json
run_capture openclaw-secrets-audit run_as_openclawgw "$OPENCLAW_BIN" secrets audit --json
run_capture sandbox-main run_as_openclawgw "$OPENCLAW_BIN" sandbox explain --agent main --json
run_capture sandbox-gmail-reader run_as_openclawgw "$OPENCLAW_BIN" sandbox explain --agent gmail-reader --json
run_capture sandbox-email-researcher run_as_openclawgw "$OPENCLAW_BIN" sandbox explain --agent email-researcher --json

run_capture pf-info pfctl -s info
run_capture pf-rules pfctl -s rules
run_capture pf-anchors pfctl -s Anchors

run_capture broker-health sudo -u openclawgw -g openclawgw "$NODE_BIN" "$BROKER_CLIENT" health_check '{}'
run_capture broker-search sudo -u openclawgw -g openclawgw "$NODE_BIN" "$BROKER_CLIENT" search_threads '{"query":"newer_than:30d","limit":1}'
run_capture f-a3-clean sudo -u openclawgw -g openclawgw "$GATE_SCRIPT" --no-log '{"thread_summary":"discarded by gate","research_request":{"kind":"company_fact","entity":"OpenAI","topic":"products"}}'
run_capture f-a3-adversarial-suite sudo -u openclawgw -g openclawgw "$NODE_BIN" "$GATE_TEST"

cat > "$OUT_DIR/README.txt" <<EOF
F-A4 read-only validation completed.

Review files in this directory for:
- summary.tsv check index and exit statuses
- OpenClaw audit/doctor/secrets status
- sandbox explain output
- pf and egress proxy state
- broker and F-A3 regression evidence

Do not publish raw outputs if a redaction warning appears or secrets are visible.
EOF

echo "F-A4 read-only validation complete: $OUT_DIR"
