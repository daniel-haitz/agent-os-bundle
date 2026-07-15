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

launchctl bootout system/ai.agent-os-egress-proxy 2>/dev/null || true
if [ -f "$PLIST" ]; then
  launchctl bootstrap system "$PLIST"
  launchctl kickstart -k system/ai.agent-os-egress-proxy
fi
launchctl print system/ai.agent-os-egress-proxy || true
EOF
chmod 0700 "$OUT_DIR/rollback.sh"

install -d -o root -g egressproxy -m 0750 "$SUPPORT_DIR"
install -d -o egressproxy -g egressproxy -m 0750 "$LOG_DIR"
install -o root -g egressproxy -m 0440 "$DRAFT_DIR/agent-os-egress-proxy.mjs" "$SOURCE"
install -o root -g egressproxy -m 0440 "$DRAFT_DIR/allowlist.txt" "$ALLOWLIST"
install -o root -g egressproxy -m 0440 "$DRAFT_DIR/agent-os-egress.anchor" "$ANCHOR"
install -o root -g wheel -m 0644 "$DRAFT_DIR/ai.agent-os-egress-proxy.plist" "$PLIST"

launchctl bootout system/ai.agent-os-egress-proxy 2>/dev/null || true
launchctl bootstrap system "$PLIST"
launchctl kickstart -k system/ai.agent-os-egress-proxy
sleep 2
launchctl print system/ai.agent-os-egress-proxy
lsof -nP -iTCP:13128 -sTCP:LISTEN

echo "Proxy repair/install complete. Next operator steps:"
echo "1. Run proxy allow/deny sanity checks from docs/F-A4_LOCK_PHASE5_EGRESS_WALL_DRAFT.md."
echo "2. Add the pf.conf fragment only after review, then dry-run /etc/pf.conf."
echo "3. Re-run scripts/fa4-operator-readonly-validation.sh and reconcile evidence."
echo "4. Rollback, if required: sudo $OUT_DIR/rollback.sh"
