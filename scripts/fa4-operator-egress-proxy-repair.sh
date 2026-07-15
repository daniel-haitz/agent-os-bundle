#!/usr/bin/env bash
# F-A4 operator-owned egress proxy repair/install harness.
#
# Run by the human operator from an admin shell. This installs the already
# reviewed draft proxy artifacts into their root-owned runtime paths and starts
# the egress proxy LaunchDaemon. It does not edit OpenClaw config or pf.conf.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root via sudo from the operator account." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${1:-/Users/dannybigdeals/fa4-egress-proxy-repair-${TS}}"
BACKUP_DIR="$OUT_DIR/backup"
DRAFT_DIR="$REPO_ROOT/drafts/fa4-phase5"
SUPPORT_DIR="/Library/Application Support/agent-os-egress-proxy"
LOG_DIR="/Library/Logs/agent-os-egress-proxy"
PLIST="/Library/LaunchDaemons/ai.agent-os-egress-proxy.plist"
SOURCE="$SUPPORT_DIR/agent-os-egress-proxy.mjs"
ALLOWLIST="$SUPPORT_DIR/allowlist.txt"
ANCHOR="$SUPPORT_DIR/agent-os-egress.anchor"
LABEL="ai.agent-os-egress-proxy"
HOST="127.0.0.1"
PORT="13128"
EXPECTED_USER="egressproxy"
EXPECTED_GROUP="egressproxy"
LAUNCHD_TIMEOUT_SECONDS=20
BOOTSTRAP_RETRIES=4
BOOTSTRAP_RETRY_SLEEP=2

mkdir -p "$OUT_DIR" "$BACKUP_DIR"
chmod 0700 "$OUT_DIR" "$BACKUP_DIR"
exec > >(tee "$OUT_DIR/repair.log") 2>&1

echo "F-A4 egress proxy repair started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "repo: $REPO_ROOT"
echo "evidence: $OUT_DIR"

backup_path() {
  local path="$1"
  if [ -e "$path" ]; then
    mkdir -p "$BACKUP_DIR$(dirname "$path")"
    cp -p "$path" "$BACKUP_DIR$path"
    printf '%s\n' "$path" >> "$BACKUP_DIR/present-paths.txt"
  else
    printf '%s\n' "$path" >> "$BACKUP_DIR/absent-paths.txt"
  fi
}

service_present() {
  launchctl print "system/$LABEL" >/dev/null 2>&1
}

wait_service_absent() {
  local deadline=$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  while service_present; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo "ERROR: $LABEL still present after bootout timeout." >&2
      launchctl print "system/$LABEL" || true
      return 1
    fi
    sleep 1
  done
  echo "$LABEL is absent from launchd."
}

wait_service_present() {
  local deadline=$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  until service_present; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo "ERROR: $LABEL did not appear after bootstrap timeout." >&2
      return 1
    fi
    sleep 1
  done
  echo "$LABEL is present in launchd."
}

assert_service_running() {
  local state
  state="$(launchctl print "system/$LABEL")"
  printf '%s\n' "$state"
  printf '%s\n' "$state" | grep -q "state = running" || {
    echo "ERROR: $LABEL is not running." >&2
    return 1
  }
  printf '%s\n' "$state" | grep -q "username = $EXPECTED_USER" || {
    echo "ERROR: $LABEL is not running as $EXPECTED_USER." >&2
    return 1
  }
  printf '%s\n' "$state" | grep -q "group = $EXPECTED_GROUP" || {
    echo "ERROR: $LABEL is not running with group $EXPECTED_GROUP." >&2
    return 1
  }
}

wait_service_running() {
  local deadline=$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  until assert_service_running; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo "ERROR: $LABEL did not reach running state before timeout." >&2
      return 1
    fi
    sleep 1
  done
}

assert_listener() {
  lsof -nP -a -iTCP@"$HOST:$PORT" -sTCP:LISTEN -u "$EXPECTED_USER" >/dev/null || {
    echo "ERROR: $LABEL is not listening on $HOST:$PORT as $EXPECTED_USER." >&2
    lsof -nP -iTCP:"$PORT" -sTCP:LISTEN || true
    return 1
  }
  lsof -nP -a -iTCP@"$HOST:$PORT" -sTCP:LISTEN -u "$EXPECTED_USER"
}

wait_listener() {
  local deadline=$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  until assert_listener; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo "ERROR: $LABEL listener did not become ready before timeout." >&2
      return 1
    fi
    sleep 1
  done
}

reload_launchdaemon() {
  local plist="$1"
  local attempt status output

  echo "Requesting bootout for system/$LABEL..."
  set +e
  output="$(launchctl bootout "system/$LABEL" 2>&1)"
  status=$?
  set -e
  echo "bootout exit status: $status"
  [ -z "$output" ] || printf '%s\n' "$output"

  wait_service_absent

  for attempt in $(seq 1 "$BOOTSTRAP_RETRIES"); do
    echo "bootstrap attempt $attempt/$BOOTSTRAP_RETRIES: $plist"
    set +e
    output="$(launchctl bootstrap system "$plist" 2>&1)"
    status=$?
    set -e
    echo "bootstrap exit status: $status"
    [ -z "$output" ] || printf '%s\n' "$output"

    if [ "$status" -eq 0 ]; then
      break
    fi
    if [ "$status" -eq 5 ] || printf '%s\n' "$output" | grep -q "Bootstrap failed: 5"; then
      if [ "$attempt" -lt "$BOOTSTRAP_RETRIES" ]; then
        echo "bootstrap hit launchctl error 5; waiting before retry."
        sleep "$BOOTSTRAP_RETRY_SLEEP"
        wait_service_absent
        continue
      fi
    fi
    echo "ERROR: bootstrap failed for $LABEL after attempt $attempt." >&2
    return 1
  done

  wait_service_present
  launchctl kickstart -k "system/$LABEL"
  wait_service_present
  wait_service_running
  wait_listener
}

if ! id -u egressproxy >/dev/null 2>&1; then
  echo "ERROR: egressproxy user does not exist. Create it through the reviewed F-A4 operator process first." >&2
  exit 1
fi

node --check "$DRAFT_DIR/agent-os-egress-proxy.mjs"
plutil -lint "$DRAFT_DIR/ai.agent-os-egress-proxy.plist"
plutil -lint "$DRAFT_DIR/ai.agent-os-egress-pf.plist"
sh -n "$DRAFT_DIR/phase5-proof-commands.sh"
pfctl -nf "$DRAFT_DIR/agent-os-egress.anchor"

backup_path "$SOURCE"
backup_path "$ALLOWLIST"
backup_path "$ANCHOR"
backup_path "$PLIST"

cat > "$OUT_DIR/rollback.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$BACKUP_DIR"
LABEL="$LABEL"
HOST="$HOST"
PORT="$PORT"
EXPECTED_USER="$EXPECTED_USER"
EXPECTED_GROUP="$EXPECTED_GROUP"
PLIST="$PLIST"
LAUNCHD_TIMEOUT_SECONDS="$LAUNCHD_TIMEOUT_SECONDS"
BOOTSTRAP_RETRIES="$BOOTSTRAP_RETRIES"
BOOTSTRAP_RETRY_SLEEP="$BOOTSTRAP_RETRY_SLEEP"

service_present() {
  launchctl print "system/\$LABEL" >/dev/null 2>&1
}

wait_service_absent() {
  local deadline=\$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  while service_present; do
    if [ "\$SECONDS" -ge "\$deadline" ]; then
      echo "ERROR: \$LABEL still present after bootout timeout." >&2
      launchctl print "system/\$LABEL" || true
      return 1
    fi
    sleep 1
  done
  echo "\$LABEL is absent from launchd."
}

wait_service_present() {
  local deadline=\$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  until service_present; do
    if [ "\$SECONDS" -ge "\$deadline" ]; then
      echo "ERROR: \$LABEL did not appear after bootstrap timeout." >&2
      return 1
    fi
    sleep 1
  done
  echo "\$LABEL is present in launchd."
}

assert_service_running() {
  local state
  state="\$(launchctl print "system/\$LABEL")"
  printf '%s\n' "\$state"
  printf '%s\n' "\$state" | grep -q "state = running" || {
    echo "ERROR: \$LABEL is not running." >&2
    return 1
  }
  printf '%s\n' "\$state" | grep -q "username = \$EXPECTED_USER" || {
    echo "ERROR: \$LABEL is not running as \$EXPECTED_USER." >&2
    return 1
  }
  printf '%s\n' "\$state" | grep -q "group = \$EXPECTED_GROUP" || {
    echo "ERROR: \$LABEL is not running with group \$EXPECTED_GROUP." >&2
    return 1
  }
}

wait_service_running() {
  local deadline=\$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  until assert_service_running; do
    if [ "\$SECONDS" -ge "\$deadline" ]; then
      echo "ERROR: \$LABEL did not reach running state before timeout." >&2
      return 1
    fi
    sleep 1
  done
}

assert_listener() {
  lsof -nP -a -iTCP@"\$HOST:\$PORT" -sTCP:LISTEN -u "\$EXPECTED_USER" >/dev/null || {
    echo "ERROR: \$LABEL is not listening on \$HOST:\$PORT as \$EXPECTED_USER." >&2
    lsof -nP -iTCP:"\$PORT" -sTCP:LISTEN || true
    return 1
  }
  lsof -nP -a -iTCP@"\$HOST:\$PORT" -sTCP:LISTEN -u "\$EXPECTED_USER"
}

wait_listener() {
  local deadline=\$((SECONDS + LAUNCHD_TIMEOUT_SECONDS))
  until assert_listener; do
    if [ "\$SECONDS" -ge "\$deadline" ]; then
      echo "ERROR: \$LABEL listener did not become ready before timeout." >&2
      return 1
    fi
    sleep 1
  done
}

reload_launchdaemon() {
  local plist="\$1"
  local attempt status output

  echo "Requesting bootout for system/\$LABEL..."
  set +e
  output="\$(launchctl bootout "system/\$LABEL" 2>&1)"
  status=\$?
  set -e
  echo "bootout exit status: \$status"
  [ -z "\$output" ] || printf '%s\n' "\$output"

  wait_service_absent

  if [ ! -f "\$plist" ]; then
    echo "rollback target plist absent; service remains unloaded."
    return 0
  fi

  for attempt in \$(seq 1 "\$BOOTSTRAP_RETRIES"); do
    echo "bootstrap attempt \$attempt/\$BOOTSTRAP_RETRIES: \$plist"
    set +e
    output="\$(launchctl bootstrap system "\$plist" 2>&1)"
    status=\$?
    set -e
    echo "bootstrap exit status: \$status"
    [ -z "\$output" ] || printf '%s\n' "\$output"

    if [ "\$status" -eq 0 ]; then
      break
    fi
    if [ "\$status" -eq 5 ] || printf '%s\n' "\$output" | grep -q "Bootstrap failed: 5"; then
      if [ "\$attempt" -lt "\$BOOTSTRAP_RETRIES" ]; then
        echo "bootstrap hit launchctl error 5; waiting before retry."
        sleep "\$BOOTSTRAP_RETRY_SLEEP"
        wait_service_absent
        continue
      fi
    fi
    echo "ERROR: bootstrap failed for \$LABEL after attempt \$attempt." >&2
    return 1
  done

  wait_service_present
  launchctl kickstart -k "system/\$LABEL"
  wait_service_present
  wait_service_running
  wait_listener
}

restore_path() {
  local path="\$1"
  if [ -e "\$BACKUP_DIR\$path" ]; then
    mkdir -p "\$(dirname "\$path")"
    cp -p "\$BACKUP_DIR\$path" "\$path"
    echo "restored \$path"
  elif [ -f "\$BACKUP_DIR/absent-paths.txt" ] && grep -Fxq "\$path" "\$BACKUP_DIR/absent-paths.txt"; then
    rm -f "\$path"
    echo "removed newly-created file \$path"
  else
    echo "no rollback record for \$path"
  fi
}

restore_path "$SOURCE"
restore_path "$ALLOWLIST"
restore_path "$ANCHOR"
restore_path "$PLIST"

reload_launchdaemon "\$PLIST"
EOF
chmod 0700 "$OUT_DIR/rollback.sh"

install -d -o root -g egressproxy -m 0750 "$SUPPORT_DIR"
install -d -o egressproxy -g egressproxy -m 0750 "$LOG_DIR"
install -o root -g egressproxy -m 0440 "$DRAFT_DIR/agent-os-egress-proxy.mjs" "$SOURCE"
install -o root -g egressproxy -m 0440 "$DRAFT_DIR/allowlist.txt" "$ALLOWLIST"
install -o root -g egressproxy -m 0440 "$DRAFT_DIR/agent-os-egress.anchor" "$ANCHOR"
install -o root -g wheel -m 0644 "$DRAFT_DIR/ai.agent-os-egress-proxy.plist" "$PLIST"

reload_launchdaemon "$PLIST"

echo "Proxy repair/install complete. Next operator steps:"
echo "1. Run proxy allow/deny sanity checks from docs/F-A4_LOCK_PHASE5_EGRESS_WALL_DRAFT.md."
echo "2. Add the pf.conf fragment only after review, then dry-run /etc/pf.conf."
echo "3. Re-run scripts/fa4-operator-readonly-validation.sh and reconcile evidence."
echo "4. Rollback, if required: sudo $OUT_DIR/rollback.sh"
