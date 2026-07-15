#!/usr/bin/env bash
# Canonical fixed OpenClaw health probe for F-A4 bootstrap validation.
#
# This reads the installed ai.openclaw.gateway LaunchDaemon configuration,
# validates the expected gateway identity and environment, then invokes a fixed
# Node worker that drops to openclawgw and runs only OpenClaw health.

set -euo pipefail

LABEL="ai.openclaw.gateway"
PLIST="${AGENT_OS_GATEWAY_PLIST:-/Library/LaunchDaemons/ai.openclaw.gateway.plist}"
PLISTBUDDY="${AGENT_OS_TEST_PLISTBUDDY:-/usr/libexec/PlistBuddy}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER="$SCRIPT_DIR/fa4-openclawgw-health-probe.mjs"

fail() {
  echo "$*" >&2
  exit 1
}

plist_value() {
  "$PLISTBUDDY" -c "Print $1" "$PLIST" 2>/dev/null
}

write_fixture_plist() {
  local plist="$1"
  local node_bin="$2"
  local entrypoint="$3"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>ai.openclaw.gateway</string>
  <key>UserName</key><string>openclawgw</string>
  <key>GroupName</key><string>openclawgw</string>
  <key>ProgramArguments</key>
  <array>
    <string>$node_bin</string>
    <string>$entrypoint</string>
    <string>gateway</string>
    <string>--port</string>
    <string>18789</string>
    <string>--bind</string>
    <string>loopback</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key><string>/Users/agent</string>
    <key>OPENCLAW_CONFIG_PATH</key><string>/Users/agent/.openclaw/openclaw.json</string>
    <key>OPENCLAW_STATE_DIR</key><string>/Users/agent/.openclaw/state</string>
    <key>PATH</key><string>/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
EOF
}

if [ "${1:-}" = "--self-test" ]; then
  test_root="$(mktemp -d /private/tmp/fa4-health-probe-selftest.XXXXXX)"
  node_bin="$(command -v node)"
  entrypoint="$test_root/openclaw-entrypoint.js"
  plist="$test_root/gateway.plist"
  cat > "$entrypoint" <<'EOF'
if (process.env.AGENT_OS_FIXTURE_HEALTH_FAIL === "1") {
  process.exit(55);
}
process.exit(process.argv[2] === "health" ? 0 : 64);
EOF
  write_fixture_plist "$plist" "$node_bin" "$entrypoint"
  AGENT_OS_GATEWAY_PLIST="$plist" AGENT_OS_HEALTH_PROBE_ALLOW_NONROOT_TEST=1 "$0" >/dev/null
  echo "SELF TEST health-probe-fixture-success: PASS"

  write_fixture_plist "$plist" "$test_root/missing-node" "$entrypoint"
  if AGENT_OS_GATEWAY_PLIST="$plist" AGENT_OS_HEALTH_PROBE_ALLOW_NONROOT_TEST=1 "$0" > "$test_root/missing.out" 2>&1; then
    echo "SELF TEST assertion failed: missing node executable accepted" >&2
    exit 1
  fi
  grep -q "gateway node executable missing or not executable" "$test_root/missing.out"
  echo "SELF TEST health-probe-stale-executable-rejected: PASS"

  write_fixture_plist "$plist" "$node_bin" "$entrypoint"
  if AGENT_OS_GATEWAY_PLIST="$plist" AGENT_OS_HEALTH_PROBE_ALLOW_NONROOT_TEST=1 AGENT_OS_FIXTURE_HEALTH_FAIL=1 "$0" > "$test_root/fail.out" 2>&1; then
    echo "SELF TEST assertion failed: nonzero health accepted" >&2
    exit 1
  fi
  echo "SELF TEST health-probe-nonzero-health-rejected: PASS"
  rm -rf "$test_root"
  echo "OPENCLAWGW HEALTH PROBE SELF TEST: PASS"
  exit 0
fi

if [ "${AGENT_OS_HEALTH_PROBE_ALLOW_NONROOT_TEST:-0}" != "1" ] && [ "$(id -u)" -ne 0 ]; then
  fail "HEALTH_PROBE_PRECONDITION_FAILED: run as root so the worker can switch to openclawgw"
fi

[ -r "$PLIST" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: gateway plist is not readable: $PLIST"
[ -x "$PLISTBUDDY" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: PlistBuddy is not executable: $PLISTBUDDY"
[ -r "$WORKER" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: worker is not readable: $WORKER"

label="$(plist_value :Label)"
user_name="$(plist_value :UserName)"
group_name="$(plist_value :GroupName)"
node_bin="$(plist_value :ProgramArguments:0)"
entrypoint="$(plist_value :ProgramArguments:1)"
gateway_arg="$(plist_value :ProgramArguments:2)"
home_value="$(plist_value :EnvironmentVariables:HOME)"
config_path="$(plist_value :EnvironmentVariables:OPENCLAW_CONFIG_PATH)"
state_dir="$(plist_value :EnvironmentVariables:OPENCLAW_STATE_DIR)"
path_value="$(plist_value :EnvironmentVariables:PATH)"

[ "$label" = "$LABEL" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: unexpected gateway label: $label"
[ "$user_name" = "openclawgw" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: unexpected gateway user: $user_name"
[ "$group_name" = "openclawgw" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: unexpected gateway group: $group_name"
[ "$gateway_arg" = "gateway" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: ProgramArguments do not describe the gateway entrypoint"
[ -x "$node_bin" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: gateway node executable missing or not executable: $node_bin"
[ -r "$entrypoint" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: OpenClaw entrypoint missing or not readable: $entrypoint"
[ "$home_value" = "/Users/agent" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: unexpected gateway HOME: $home_value"
[ "$config_path" = "/Users/agent/.openclaw/openclaw.json" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: unexpected OPENCLAW_CONFIG_PATH: $config_path"
[ "$state_dir" = "/Users/agent/.openclaw/state" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: unexpected OPENCLAW_STATE_DIR: $state_dir"
[ -n "$path_value" ] || fail "HEALTH_PROBE_PRECONDITION_FAILED: gateway PATH is empty"

AGENT_OS_OPENCLAW_NODE="$node_bin" \
AGENT_OS_OPENCLAW_ENTRYPOINT="$entrypoint" \
AGENT_OS_OPENCLAW_HOME="$home_value" \
AGENT_OS_OPENCLAW_CONFIG_PATH="$config_path" \
AGENT_OS_OPENCLAW_STATE_DIR="$state_dir" \
AGENT_OS_OPENCLAW_PATH="$path_value" \
"$node_bin" "$WORKER"
