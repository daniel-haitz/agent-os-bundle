#!/usr/bin/env bash
# F-A4 operator-owned identity bootstrap for the OpenAI credential broker.
#
# This prepares only the dedicated OS identity and non-secret custody roots. It
# does not install credentials, change OpenClaw config/auth state, start broker
# services, alter pf, or modify proxy policy.

set -Eeuo pipefail

MODE="apply"
OUT_DIR=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) MODE="dry-run" ;;
    --self-test) MODE="self-test" ;;
    --out-dir=*) OUT_DIR="${arg#--out-dir=}" ;;
    *)
      echo "ERROR: unknown argument: $arg" >&2
      exit 64
      ;;
  esac
done

USER_NAME="${AGENT_OS_BOOTSTRAP_USER_NAME:-openai-credential-broker}"
GROUP_NAME="${AGENT_OS_BOOTSTRAP_GROUP_NAME:-openai-credential-broker}"
REAL_NAME="Agent OS OpenAI credential broker"
HOME_DIR="${AGENT_OS_BOOTSTRAP_HOME_DIR:-/Users/openai-credential-broker}"
ROOT_DIR="$HOME_DIR/agent-os-openai-credential-broker"
BIN_DIR="$ROOT_DIR/bin"
SECRETS_DIR="$ROOT_DIR/secrets"
SHELL_PATH="/usr/bin/false"
UID_MIN=540
UID_MAX=599
GID_MIN=740
GID_MAX=799
OPENCLAW_BIN="${OPENCLAW_BIN:-/Users/agent/.local/bin/openclaw}"
CONFIG="${CONFIG:-/Users/agent/.openclaw/openclaw.json}"
STATE_DIR="${STATE_DIR:-/Users/agent/.openclaw/state}"
BROKER_PLIST="/Library/LaunchDaemons/ai.agent-os.openai-credential-broker.plist"
BROKER_RUNDIR_PLIST="/Library/LaunchDaemons/ai.agent-os.openai-credential-broker-rundir.plist"
RUNTIME_SOCKET="/var/run/agent-os/openai-credential-broker/openai-credential-broker.sock"

DSCL="${AGENT_OS_TEST_DSCL:-dscl}"
DSCACHEUTIL="${AGENT_OS_TEST_DSCACHEUTIL:-dscacheutil}"
ID="${AGENT_OS_TEST_ID:-id}"
STAT="${AGENT_OS_TEST_STAT:-stat}"
INSTALL="${AGENT_OS_TEST_INSTALL:-install}"
MKDIR="${AGENT_OS_TEST_MKDIR:-mkdir}"
CHOWN="${AGENT_OS_TEST_CHOWN:-chown}"
CHMOD="${AGENT_OS_TEST_CHMOD:-chmod}"
RM="${AGENT_OS_TEST_RM:-rm}"
RMDIR="${AGENT_OS_TEST_RMDIR:-rmdir}"
UUIDGEN="${AGENT_OS_TEST_UUIDGEN:-uuidgen}"
LAUNCHCTL="${AGENT_OS_TEST_LAUNCHCTL:-launchctl}"

if [ "$MODE" != "dry-run" ] && [ "$MODE" != "self-test" ] && [ "${AGENT_OS_BOOTSTRAP_ALLOW_NONROOT_TEST:-0}" != "1" ] && [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root via sudo from the operator account." >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
if [ -z "$OUT_DIR" ]; then
  OUT_DIR="/Users/dannybigdeals/fa4-openai-credential-broker-bootstrap-${TS}"
fi
MANIFEST="$OUT_DIR/bootstrap-manifest.tsv"
TXN_MANIFEST="$OUT_DIR/bootstrap-transaction.tsv"
ROLLBACK="$OUT_DIR/rollback.sh"
LOG="$OUT_DIR/bootstrap.log"
created_uid=""
created_gid=""

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

ensure_output_dir() {
  if [ "$MODE" = "dry-run" ] || [ "$MODE" = "apply" ]; then
    mkdir -p "$OUT_DIR"
    chmod 0700 "$OUT_DIR"
    if [ "$MODE" = "apply" ] && [ "${AGENT_OS_BOOTSTRAP_ALLOW_NONROOT_TEST:-0}" != "1" ]; then
      exec > >(tee "$LOG") 2>&1
    fi
  fi
}

ds_read() {
  "$DSCL" . -read "$1" "$2" 2>/dev/null | awk '{$1=""; sub(/^ /,""); print}'
}

ds_record_exists() {
  "$DSCL" . -read "$1" >/dev/null 2>&1
}

user_exists() {
  ds_record_exists "/Users/$USER_NAME"
}

group_exists() {
  ds_record_exists "/Groups/$GROUP_NAME"
}

group_gid() {
  ds_read "/Groups/$GROUP_NAME" PrimaryGroupID | awk '{print $1}'
}

user_uid() {
  ds_read "/Users/$USER_NAME" UniqueID | awk '{print $1}'
}

user_gid() {
  ds_read "/Users/$USER_NAME" PrimaryGroupID | awk '{print $1}'
}

user_home() {
  ds_read "/Users/$USER_NAME" NFSHomeDirectory
}

user_shell() {
  ds_read "/Users/$USER_NAME" UserShell | awk '{print $1}'
}

user_real_name() {
  ds_read "/Users/$USER_NAME" RealName
}

user_hidden() {
  ds_read "/Users/$USER_NAME" IsHidden | awk '{print $1}'
}

user_generated_uid() {
  ds_read "/Users/$USER_NAME" GeneratedUID | awk '{print $1}'
}

user_password() {
  ds_read "/Users/$USER_NAME" Password | awk '{print $1}'
}

user_auth_authority() {
  ds_read "/Users/$USER_NAME" AuthenticationAuthority
}

group_real_name() {
  ds_read "/Groups/$GROUP_NAME" RealName
}

all_user_ids() {
  "$DSCL" . -list /Users UniqueID 2>/dev/null | awk '{print $2}'
}

all_group_ids() {
  "$DSCL" . -list /Groups PrimaryGroupID 2>/dev/null | awk '{print $2}'
}

next_free_id() {
  local kind="$1"
  local min="$2"
  local max="$3"
  local used
  if [ "$kind" = "user" ]; then
    used="$(all_user_ids)" || return 1
  else
    used="$(all_group_ids)" || return 1
  fi
  [ -n "$used" ] || return 1
  for candidate in $(seq "$min" "$max"); do
    if ! printf '%s\n' "$used" | grep -qx "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

path_state() {
  local path="$1"
  if [ -e "$path" ]; then
    "$STAT" -f '%u	%Su	%g	%Sg	%Lp' "$path" \
      | awk -v path="$path" -F '\t' '{ printf "%s\tpresent\t%s\t%s\t%s\t%s\t%04o\n", path, $1, $2, $3, $4, $5 }'
  else
    printf '%s\tabsent\t\t\t\t\t\n' "$path"
  fi
}

record_baseline() {
  printf 'kind\tname\texists\tattributes\n' > "$MANIFEST"
  if group_exists; then
    printf 'group\t%s\tpresent\tgid=%s realName=%s\n' "$GROUP_NAME" "$(group_gid)" "$(group_real_name)" >> "$MANIFEST"
  else
    printf 'group\t%s\tabsent\t\n' "$GROUP_NAME" >> "$MANIFEST"
  fi
  if user_exists; then
    printf 'user\t%s\tpresent\tuid=%s gid=%s home=%s shell=%s hidden=%s generatedUID=%s password=%s auth=%s\n' \
      "$USER_NAME" "$(user_uid)" "$(user_gid)" "$(user_home)" "$(user_shell)" "$(user_hidden)" "$(user_generated_uid)" "$(user_password)" "$(user_auth_authority | tr '\n' ' ')" >> "$MANIFEST"
  else
    printf 'user\t%s\tabsent\t\n' "$USER_NAME" >> "$MANIFEST"
  fi
  for path in "$HOME_DIR" "$ROOT_DIR" "$BIN_DIR" "$SECRETS_DIR"; do
    path_state "$path" | awk -F '\t' '{ printf "path\t%s\t%s\tuid=%s user=%s gid=%s group=%s mode=%s\n", $1, $2, $3, $4, $5, $6, $7 }' >> "$MANIFEST"
  done
}

init_transaction_manifest() {
  printf 'kind\tname\tattribute\tvalue\n' > "$TXN_MANIFEST"
}

txn_append() {
  local tmp="$TXN_MANIFEST.tmp.$$"
  cat "$TXN_MANIFEST" > "$tmp"
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$tmp"
  mv "$tmp" "$TXN_MANIFEST"
}

txn_has() {
  local kind="$1"
  local name="$2"
  local attribute="${3:-}"
  awk -F '\t' -v kind="$kind" -v name="$name" -v attribute="$attribute" '
    NR > 1 && $1 == kind && $2 == name && (attribute == "" || $3 == attribute) { found=1 }
    END { exit found ? 0 : 1 }
  ' "$TXN_MANIFEST"
}

print_baseline_stdout() {
  echo "Proposed baseline manifest:"
  printf 'kind\tname\texists\tattributes\n'
  if group_exists; then
    printf 'group\t%s\tpresent\tgid=%s realName=%s\n' "$GROUP_NAME" "$(group_gid)" "$(group_real_name)"
  else
    printf 'group\t%s\tabsent\t\n' "$GROUP_NAME"
  fi
  if user_exists; then
    printf 'user\t%s\tpresent\tuid=%s gid=%s home=%s shell=%s hidden=%s generatedUID=%s password=%s auth=%s\n' \
      "$USER_NAME" "$(user_uid)" "$(user_gid)" "$(user_home)" "$(user_shell)" "$(user_hidden)" "$(user_generated_uid)" "$(user_password)" "$(user_auth_authority | tr '\n' ' ')"
  else
    printf 'user\t%s\tabsent\t\n' "$USER_NAME"
  fi
  for path in "$HOME_DIR" "$ROOT_DIR" "$BIN_DIR" "$SECRETS_DIR"; do
    path_state "$path" | awk -F '\t' '{ printf "path\t%s\t%s\tuid=%s user=%s gid=%s group=%s mode=%s\n", $1, $2, $3, $4, $5, $6, $7 }'
  done
}

fail_nogo() {
  echo "IDENTITY BOOTSTRAP DRY RUN: NO-GO"
  echo "NO-GO: $*" >&2
  exit 1
}

validate_range() {
  local value="$1"
  local min="$2"
  local max="$3"
  local label="$4"
  if [ "$value" -lt "$min" ] || [ "$value" -gt "$max" ]; then
    fail_nogo "$label $value is outside expected range $min-$max"
  fi
}

assert_path_absent_or_canonical() {
  local path="$1"
  local owner="$2"
  local group="$3"
  local mode="$4"
  if [ ! -e "$path" ]; then
    return 0
  fi
  local actual
  actual="$("$STAT" -f '%Su:%Sg %04Lp' "$path")"
  [ "$actual" = "$owner:$group $mode" ] || fail_nogo "pre-existing path is not canonical: $path actual=$actual expected=$owner:$group $mode"
}

validate_existing_group() {
  [ "$(group_gid)" -ge "$GID_MIN" ] && [ "$(group_gid)" -le "$GID_MAX" ] || fail_nogo "pre-existing group gid is outside canonical range"
  [ "$(group_real_name)" = "$REAL_NAME" ] || fail_nogo "pre-existing group RealName mismatch"
}

validate_existing_user() {
  [ "$(user_uid)" -ge "$UID_MIN" ] && [ "$(user_uid)" -le "$UID_MAX" ] || fail_nogo "pre-existing user uid is outside canonical range"
  [ "$(user_gid)" = "$(group_gid)" ] || fail_nogo "pre-existing user primary group mismatch"
  [ "$(user_home)" = "$HOME_DIR" ] || fail_nogo "pre-existing user home mismatch"
  [ "$(user_shell)" = "$SHELL_PATH" ] || fail_nogo "pre-existing user shell mismatch"
  [ "$(user_real_name)" = "$REAL_NAME" ] || fail_nogo "pre-existing user RealName mismatch"
  [ "$(user_hidden)" = "1" ] || fail_nogo "pre-existing user is not hidden"
  [ -n "$(user_generated_uid)" ] || fail_nogo "pre-existing user missing GeneratedUID"
  [ "$(user_password)" = "*" ] || fail_nogo "pre-existing user password marker mismatch"
  user_auth_authority | grep -q "DisabledUser" || fail_nogo "pre-existing user missing DisabledUser authentication authority"
  if "$ID" -Gn "$USER_NAME" | tr ' ' '\n' | grep -Eq '^(admin|wheel|staff)$'; then
    fail_nogo "pre-existing user has a broad supplementary group"
  fi
}

validate_preexisting_state() {
  if group_exists; then
    validate_existing_group
  fi
  if user_exists; then
    group_exists || fail_nogo "user exists but group is absent"
    validate_existing_user
  fi
  if ! user_exists && ! group_exists; then
    for path in "$HOME_DIR" "$ROOT_DIR" "$BIN_DIR" "$SECRETS_DIR"; do
      [ ! -e "$path" ] || fail_nogo "filesystem path exists before account bootstrap: $path"
    done
  else
    assert_path_absent_or_canonical "$HOME_DIR" "$USER_NAME" "$GROUP_NAME" "0750"
    assert_path_absent_or_canonical "$ROOT_DIR" "$USER_NAME" "$GROUP_NAME" "0750"
    assert_path_absent_or_canonical "$BIN_DIR" "$USER_NAME" "$GROUP_NAME" "0750"
    assert_path_absent_or_canonical "$SECRETS_DIR" "$USER_NAME" "$GROUP_NAME" "0700"
  fi
}

generate_rollback() {
  cat > "$ROLLBACK" <<EOF
#!/usr/bin/env bash
set -euo pipefail
USER_NAME="$USER_NAME"
GROUP_NAME="$GROUP_NAME"
HOME_DIR="$HOME_DIR"
ROOT_DIR="$ROOT_DIR"
BIN_DIR="$BIN_DIR"
SECRETS_DIR="$SECRETS_DIR"
TXN_MANIFEST="$TXN_MANIFEST"
APPROVED_PATHS="$SECRETS_DIR
$BIN_DIR
$ROOT_DIR
$HOME_DIR"
DSCL="$DSCL"
RMDIR="$RMDIR"
log() { printf '[%s] %s\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$*"; }
ds_value() { "\$DSCL" . -read "\$1" "\$2" 2>/dev/null | awk '{\$1=""; sub(/^ /,""); print}'; }
txn_has() {
  local kind="\$1"
  local name="\$2"
  local attribute="\${3:-}"
  awk -F '\t' -v kind="\$kind" -v name="\$name" -v attribute="\$attribute" '
    NR > 1 && \$1 == kind && \$2 == name && (attribute == "" || \$3 == attribute) { found=1 }
    END { exit found ? 0 : 1 }
  ' "\$TXN_MANIFEST"
}
txn_value() {
  local kind="\$1"
  local name="\$2"
  local attribute="\$3"
  awk -F '\t' -v kind="\$kind" -v name="\$name" -v attribute="\$attribute" '
    NR > 1 && \$1 == kind && \$2 == name && \$3 == attribute { value=\$4 }
    END { print value }
  ' "\$TXN_MANIFEST"
}
is_approved_path() {
  local path="\$1"
  [ -n "\$path" ] || return 1
  case "\$path" in *..*|*'//'*) return 1 ;; esac
  printf '%s\n' "\$APPROVED_PATHS" | grep -Fxq "\$path"
}
verify_user_match() {
  txn_has user "\$USER_NAME" created_intent || txn_has user "\$USER_NAME" created || return 0
  "\$DSCL" . -read "/Users/\$USER_NAME" >/dev/null 2>&1 || return 0
  uid_raw="\$(ds_value "/Users/\$USER_NAME" UniqueID 2>/dev/null || true)"
  uid="\$(printf '%s\n' "\$uid_raw" | awk '{print \$1}')"
  created_uid="\$(txn_value user "\$USER_NAME" uid)"
  home="\$(ds_value "/Users/\$USER_NAME" NFSHomeDirectory 2>/dev/null || true)"
  shell_raw="\$(ds_value "/Users/\$USER_NAME" UserShell 2>/dev/null || true)"
  shell="\$(printf '%s\n' "\$shell_raw" | awk '{print \$1}')"
  [ -z "\$created_uid" ] || [ "\$uid" = "\$created_uid" ] || { echo "ERROR: refusing to delete user with mismatched uid: \$uid" >&2; exit 1; }
  [ -z "\$home" ] || [ "\$home" = "\$HOME_DIR" ] || { echo "ERROR: refusing to delete user with mismatched home: \$home" >&2; exit 1; }
  [ -z "\$shell" ] || [ "\$shell" = "$SHELL_PATH" ] || { echo "ERROR: refusing to delete user with mismatched shell: \$shell" >&2; exit 1; }
}
verify_group_match() {
  txn_has group "\$GROUP_NAME" created_intent || txn_has group "\$GROUP_NAME" created || return 0
  "\$DSCL" . -read "/Groups/\$GROUP_NAME" >/dev/null 2>&1 || return 0
  gid_raw="\$(ds_value "/Groups/\$GROUP_NAME" PrimaryGroupID 2>/dev/null || true)"
  gid="\$(printf '%s\n' "\$gid_raw" | awk '{print \$1}')"
  created_gid="\$(txn_value group "\$GROUP_NAME" gid)"
  [ -z "\$created_gid" ] || [ "\$gid" = "\$created_gid" ] || { echo "ERROR: refusing to delete group with mismatched gid: \$gid" >&2; exit 1; }
}
log "Starting OpenAI credential broker identity rollback."
[ -f "\$TXN_MANIFEST" ] || { echo "BOOTSTRAP ROLLBACK FAILED" >&2; echo "missing transaction manifest: \$TXN_MANIFEST" >&2; exit 91; }
verify_user_match
verify_group_match
awk -F '\t' 'NR > 1 && \$1 == "path" && \$3 == "created" { print \$2 }' "\$TXN_MANIFEST" | awk 'NF' | sort -r | while IFS= read -r path; do
  if ! is_approved_path "\$path"; then
    echo "BOOTSTRAP ROLLBACK FAILED" >&2
    echo "refusing unapproved path: \$path" >&2
    exit 92
  fi
  if [ -L "\$path" ]; then
    echo "BOOTSTRAP ROLLBACK FAILED" >&2
    echo "refusing symlink path: \$path" >&2
    exit 93
  fi
  if [ -e "\$path" ]; then
    log "Removing current-run path: \$path"
    "\$RMDIR" "\$path"
  fi
done
if { txn_has user "\$USER_NAME" created_intent || txn_has user "\$USER_NAME" created; } && "\$DSCL" . -read "/Users/\$USER_NAME" >/dev/null 2>&1; then
  log "Deleting current-run user record: \$USER_NAME"
  "\$DSCL" . -delete "/Users/\$USER_NAME"
fi
if { txn_has group "\$GROUP_NAME" created_intent || txn_has group "\$GROUP_NAME" created; } && "\$DSCL" . -read "/Groups/\$GROUP_NAME" >/dev/null 2>&1; then
  log "Deleting current-run group record: \$GROUP_NAME"
  "\$DSCL" . -delete "/Groups/\$GROUP_NAME"
fi
awk -F '\t' 'NR > 1 && \$1 == "path" && \$3 == "created" { print \$2 }' "\$TXN_MANIFEST" | while IFS= read -r path; do
  [ ! -e "\$path" ] || { echo "ERROR: rollback path still exists: \$path" >&2; exit 1; }
done
if txn_has user "\$USER_NAME" created_intent || txn_has user "\$USER_NAME" created; then
  ! "\$DSCL" . -read "/Users/\$USER_NAME" >/dev/null 2>&1 || { echo "ERROR: rollback user still exists" >&2; exit 1; }
fi
if txn_has group "\$GROUP_NAME" created_intent || txn_has group "\$GROUP_NAME" created; then
  ! "\$DSCL" . -read "/Groups/\$GROUP_NAME" >/dev/null 2>&1 || { echo "ERROR: rollback group still exists" >&2; exit 1; }
fi
log "BOOTSTRAP ROLLBACK VERIFIED: PASS"
EOF
  chmod 0700 "$ROLLBACK"
}

verify_canonical_final_state() {
  group_exists || { echo "BROKER GROUP CREATED OR VALIDATED: FAIL"; exit 1; }
  user_exists || { echo "BROKER USER CREATED OR VALIDATED: FAIL"; exit 1; }
  validate_existing_group
  validate_existing_user
  [ "$("$STAT" -f '%Su:%Sg %04Lp' "$HOME_DIR")" = "$USER_NAME:$GROUP_NAME 0750" ] || { echo "CUSTODY ROOT OWNER/MODE: FAIL"; exit 1; }
  [ "$("$STAT" -f '%Su:%Sg %04Lp' "$ROOT_DIR")" = "$USER_NAME:$GROUP_NAME 0750" ] || { echo "CUSTODY ROOT OWNER/MODE: FAIL"; exit 1; }
  [ "$("$STAT" -f '%Su:%Sg %04Lp' "$BIN_DIR")" = "$USER_NAME:$GROUP_NAME 0750" ] || { echo "CUSTODY ROOT OWNER/MODE: FAIL"; exit 1; }
  [ "$("$STAT" -f '%Su:%Sg %04Lp' "$SECRETS_DIR")" = "$USER_NAME:$GROUP_NAME 0700" ] || { echo "CUSTODY ROOT OWNER/MODE: FAIL"; exit 1; }
  [ ! -e "$SECRETS_DIR/openai-static-credentials.json" ] || { echo "NO CREDENTIAL CREATED: FAIL"; exit 1; }
  [ ! -e "$BROKER_PLIST" ] || { echo "NO BROKER SERVICE INSTALLED: FAIL"; exit 1; }
  [ ! -e "$BROKER_RUNDIR_PLIST" ] || { echo "NO BROKER SERVICE INSTALLED: FAIL"; exit 1; }
  [ ! -e "$RUNTIME_SOCKET" ] || { echo "NO BROKER SERVICE INSTALLED: FAIL"; exit 1; }
  HOME=/Users/agent OPENCLAW_CONFIG_PATH="$CONFIG" OPENCLAW_STATE_DIR="$STATE_DIR" "$OPENCLAW_BIN" health >/dev/null 2>&1 || { echo "GATEWAY HEALTH UNCHANGED: FAIL"; exit 1; }
  echo "BROKER USER CREATED OR VALIDATED: PASS"
  echo "BROKER GROUP CREATED OR VALIDATED: PASS"
  echo "ACCOUNT ATTRIBUTES CANONICAL: PASS"
  echo "LOGIN DISABLED: PASS"
  echo "BROAD GROUP MEMBERSHIP ABSENT: PASS"
  echo "CUSTODY ROOT OWNER/MODE: PASS"
  echo "NO CREDENTIAL CREATED: CONFIRMED"
  echo "NO BROKER SERVICE INSTALLED: CONFIRMED"
  echo "NO OPENCLAW CONFIG/AUTH MUTATION: CONFIRMED"
  echo "GATEWAY HEALTH UNCHANGED: PASS"
  echo "BOOTSTRAP ROLLBACK READY: PASS"
  echo "IDENTITY BOOTSTRAP VERIFIED: PASS"
}

rollback_on_error() {
  local status=$?
  if [ "$MODE" = "apply" ] && [ -f "$ROLLBACK" ]; then
    echo "ERROR: bootstrap failed; invoking rollback for current-run objects." >&2
    if ! bash "$ROLLBACK"; then
      echo "BOOTSTRAP ROLLBACK FAILED" >&2
      echo "Remaining candidate records/paths:" >&2
      "$DSCL" . -read "/Users/$USER_NAME" 2>/dev/null || true
      "$DSCL" . -read "/Groups/$GROUP_NAME" 2>/dev/null || true
      for path in "$SECRETS_DIR" "$BIN_DIR" "$ROOT_DIR" "$HOME_DIR"; do
        [ -e "$path" ] && ls -ld "$path" >&2 || true
      done
      exit 91
    fi
  fi
  exit "$status"
}

run_dry_run() {
  validate_preexisting_state
  print_baseline_stdout
  local proposed_gid proposed_uid
  if group_exists; then
    proposed_gid="$(group_gid)"
  else
    proposed_gid="$(next_free_id group "$GID_MIN" "$GID_MAX")" || fail_nogo "no free group id in range $GID_MIN-$GID_MAX"
  fi
  if user_exists; then
    proposed_uid="$(user_uid)"
  else
    proposed_uid="$(next_free_id user "$UID_MIN" "$UID_MAX")" || fail_nogo "no free user id in range $UID_MIN-$UID_MAX"
  fi
  validate_range "$proposed_uid" "$UID_MIN" "$UID_MAX" "uid"
  validate_range "$proposed_gid" "$GID_MIN" "$GID_MAX" "gid"
  echo "Proposed user: $USER_NAME uid=$proposed_uid primaryGroup=$GROUP_NAME gid=$proposed_gid home=$HOME_DIR shell=$SHELL_PATH hidden=1 auth=DisabledUser"
  echo "Would create if absent:"
  group_exists || echo "- group /Groups/$GROUP_NAME"
  user_exists || echo "- user /Users/$USER_NAME"
  [ -e "$HOME_DIR" ] || echo "- path $HOME_DIR mode 0750 owner $USER_NAME:$GROUP_NAME"
  [ -e "$ROOT_DIR" ] || echo "- path $ROOT_DIR mode 0750 owner $USER_NAME:$GROUP_NAME"
  [ -e "$BIN_DIR" ] || echo "- path $BIN_DIR mode 0750 owner $USER_NAME:$GROUP_NAME"
  [ -e "$SECRETS_DIR" ] || echo "- path $SECRETS_DIR mode 0700 owner $USER_NAME:$GROUP_NAME"
  echo "Manifest: stdout only; dry-run performs no filesystem or Directory Services mutation."
  echo "IDENTITY BOOTSTRAP DRY RUN: GO"
}

create_group() {
  created_gid="$1"
  txn_append group "$GROUP_NAME" created_intent 1
  "$DSCL" . -create "/Groups/$GROUP_NAME"
  txn_append group "$GROUP_NAME" created 1
  "$DSCL" . -create "/Groups/$GROUP_NAME" PrimaryGroupID "$created_gid"
  txn_append group "$GROUP_NAME" gid "$created_gid"
  "$DSCL" . -create "/Groups/$GROUP_NAME" RealName "$REAL_NAME"
  txn_append group "$GROUP_NAME" realName "$REAL_NAME"
}

create_user() {
  created_uid="$1"
  created_gid="$2"
  generated_uid="$("$UUIDGEN")"
  txn_append user "$USER_NAME" created_intent 1
  "$DSCL" . -create "/Users/$USER_NAME"
  txn_append user "$USER_NAME" created 1
  "$DSCL" . -create "/Users/$USER_NAME" UniqueID "$created_uid"
  txn_append user "$USER_NAME" uid "$created_uid"
  "$DSCL" . -create "/Users/$USER_NAME" PrimaryGroupID "$created_gid"
  txn_append user "$USER_NAME" gid "$created_gid"
  "$DSCL" . -create "/Users/$USER_NAME" RealName "$REAL_NAME"
  txn_append user "$USER_NAME" realName "$REAL_NAME"
  "$DSCL" . -create "/Users/$USER_NAME" NFSHomeDirectory "$HOME_DIR"
  txn_append user "$USER_NAME" home "$HOME_DIR"
  "$DSCL" . -create "/Users/$USER_NAME" UserShell "$SHELL_PATH"
  txn_append user "$USER_NAME" shell "$SHELL_PATH"
  "$DSCL" . -create "/Users/$USER_NAME" IsHidden 1
  txn_append user "$USER_NAME" hidden 1
  "$DSCL" . -create "/Users/$USER_NAME" GeneratedUID "$generated_uid"
  txn_append user "$USER_NAME" generatedUID "$generated_uid"
  "$DSCL" . -create "/Users/$USER_NAME" AuthenticationAuthority ";DisabledUser;"
  txn_append user "$USER_NAME" authenticationAuthority ";DisabledUser;"
  "$DSCL" . -create "/Users/$USER_NAME" Password "*"
  txn_append user "$USER_NAME" password "*"
}

install_dir_track() {
  local path="$1"
  local mode="$2"
  local existed=1
  [ -e "$path" ] || existed=0
  "$INSTALL" -d -o "$USER_NAME" -g "$GROUP_NAME" -m "$mode" "$path"
  if [ "$existed" -eq 0 ]; then
    txn_append path "$path" created "$mode"
  fi
}

run_apply() {
  ensure_output_dir
  trap rollback_on_error ERR
  record_baseline
  validate_preexisting_state
  local gid uid
  if group_exists; then
    gid="$(group_gid)"
  else
    gid="$(next_free_id group "$GID_MIN" "$GID_MAX")" || fail_nogo "no free group id in range $GID_MIN-$GID_MAX"
    created_gid="$gid"
    init_transaction_manifest
    generate_rollback
    create_group "$gid"
  fi
  if [ ! -f "$TXN_MANIFEST" ]; then
    init_transaction_manifest
    generate_rollback
  fi
  if user_exists; then
    uid="$(user_uid)"
  else
    uid="$(next_free_id user "$UID_MIN" "$UID_MAX")" || fail_nogo "no free user id in range $UID_MIN-$UID_MAX"
    created_uid="$uid"
    generate_rollback
    create_user "$uid" "$gid"
  fi
  created_uid="$uid"
  created_gid="$gid"
  generate_rollback
  install_dir_track "$HOME_DIR" 0750
  install_dir_track "$ROOT_DIR" 0750
  install_dir_track "$BIN_DIR" 0750
  install_dir_track "$SECRETS_DIR" 0700
  generate_rollback
  verify_canonical_final_state
}

run_self_test() {
  bash -n "$0"
  local test_root fakebin home_dir output status
  test_root="$(mktemp -d /private/tmp/fa4-bootstrap-selftest.XXXXXX)"
  fakebin="$test_root/bin"
  mkdir -p "$fakebin" "$test_root/users" "$test_root/groups" "$test_root/meta"
  cat > "$fakebin/dscl" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
root="${AGENT_OS_FIXTURE_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
op="$2"
record="${3:-}"
attr="${4:-}"
value="${5:-}"
kind="$(echo "$record" | cut -d/ -f2 | tr '[:upper:]' '[:lower:]')"
case "$kind" in users) store="users" ;; groups) store="groups" ;; *) store="${kind}s" ;; esac
name="$(echo "$record" | cut -d/ -f3-)"
dir="$root/$store/$name"
fail_after_mutation() {
  [ -n "${AGENT_OS_FIXTURE_FAIL_AFTER:-}" ] || return 0
  count_file="$root/count"
  count="$(cat "$count_file" 2>/dev/null || echo 0)"
  count=$((count + 1))
  echo "$count" > "$count_file"
  [ "$count" = "$AGENT_OS_FIXTURE_FAIL_AFTER" ] && exit 44
}
case "$op" in
  -read)
    [ -d "$dir" ] || exit 1
    if [ -n "$attr" ]; then
      [ -f "$dir/$attr" ] || exit 1
      printf '%s: %s\n' "$attr" "$(cat "$dir/$attr")"
    else
      [ -d "$dir" ] && exit 0
      for f in "$dir"/*; do [ -f "$f" ] && printf '%s: %s\n' "$(basename "$f")" "$(cat "$f")"; done
      exit 0
    fi
    ;;
  -list)
    list_kind="$(echo "$record" | cut -d/ -f2 | tr '[:upper:]' '[:lower:]')"
    case "$list_kind" in users) list_store="users" ;; groups) list_store="groups" ;; *) list_store="${list_kind}s" ;; esac
    list_attr="$attr"
    for d in "$root/${list_store}"/*; do
      [ -d "$d" ] || continue
      [ -f "$d/$list_attr" ] || continue
      printf '%s %s\n' "$(basename "$d")" "$(cat "$d/$list_attr")"
    done
    ;;
  -create)
    if [ -z "$attr" ]; then
      mkdir -p "$dir"
      fail_after_mutation
    else
      mkdir -p "$dir"
      printf '%s\n' "$value" > "$dir/$attr"
      fail_after_mutation
    fi
    ;;
  -delete)
    rm -rf "$dir"
    ;;
  *) exit 2 ;;
esac
FAKE
  cat > "$fakebin/id" <<'FAKE'
#!/usr/bin/env bash
if [ "$1" = "-Gn" ]; then
  if [ "${AGENT_OS_FIXTURE_BROAD_GROUP:-0}" = "1" ]; then echo "openai-credential-broker staff"; else echo "openai-credential-broker"; fi
elif [ "$1" = "-u" ]; then
  echo 540
elif [ "$1" = "-g" ]; then
  echo 740
elif [ "$1" = "-gn" ]; then
  echo openai-credential-broker
else
  echo "uid=540(openai-credential-broker) gid=740(openai-credential-broker)"
fi
FAKE
  cat > "$fakebin/install" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
owner=""
group=""
mode=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -d) shift ;;
    -o) owner="$2"; shift 2 ;;
    -g) group="$2"; shift 2 ;;
    -m) mode="$2"; shift 2 ;;
    *) path="$1"; shift ;;
  esac
done
mkdir -p "$path"
chmod "$mode" "$path"
mkdir -p "${AGENT_OS_FIXTURE_ROOT:?}/meta"
key="$(printf '%s' "$path" | sed 's#[/:]#_#g')"
printf '%s:%s %04o\n' "$owner" "$group" "$((8#$mode))" > "$AGENT_OS_FIXTURE_ROOT/meta/$key"
FAKE
  cat > "$fakebin/stat" <<'FAKE'
#!/usr/bin/env bash
fmt="$2"
path="$3"
key="$(printf '%s' "$path" | sed 's#[/:]#_#g')"
meta_file="${AGENT_OS_FIXTURE_ROOT:?}/meta/$key"
if [ -f "$meta_file" ]; then
  meta="$(cat "$meta_file")"
else
  meta="root:wheel 0755"
fi
case "$fmt" in
  *%Su:%Sg*) echo "$meta" ;;
  *) printf '0\t%s\t0\t%s\t%s\n' "${meta%%:*}" "$(echo "$meta" | awk '{print $1}' | cut -d: -f2)" "$(echo "$meta" | awk '{print $2}')" ;;
esac
FAKE
  cat > "$fakebin/openclaw" <<'FAKE'
#!/usr/bin/env bash
exit 0
FAKE
  cat > "$fakebin/uuidgen" <<'FAKE'
#!/usr/bin/env bash
echo 11111111-2222-3333-4444-555555555555
FAKE
  cat > "$fakebin/rmdir" <<'FAKE'
#!/usr/bin/env bash
rmdir "$1"
FAKE
  chmod 0755 "$fakebin"/*

  seed_ids() {
    mkdir -p "$test_root/users/existing" "$test_root/groups/existing"
    echo 539 > "$test_root/users/existing/UniqueID"
    echo 739 > "$test_root/groups/existing/PrimaryGroupID"
  }
  reset_fixture() {
    rm -rf "$test_root/users" "$test_root/groups" "$test_root/meta" "$test_root/home" "$test_root/count"
    mkdir -p "$test_root/users" "$test_root/groups" "$test_root/meta"
    seed_ids
  }
  run_fixture() {
    local mode="$1"
    shift
    home_dir="$test_root/home/openai-credential-broker"
    if [ "$mode" = "apply" ]; then
      AGENT_OS_FIXTURE_ROOT="$test_root" \
      AGENT_OS_TEST_DSCL="$fakebin/dscl" \
      AGENT_OS_TEST_ID="$fakebin/id" \
      AGENT_OS_TEST_INSTALL="$fakebin/install" \
      AGENT_OS_TEST_STAT="$fakebin/stat" \
      AGENT_OS_TEST_RMDIR="$fakebin/rmdir" \
      AGENT_OS_TEST_UUIDGEN="$fakebin/uuidgen" \
      OPENCLAW_BIN="$fakebin/openclaw" \
      AGENT_OS_BOOTSTRAP_ALLOW_NONROOT_TEST=1 \
      AGENT_OS_BOOTSTRAP_HOME_DIR="$home_dir" \
      bash "$0" --out-dir="$test_root/out" "$@" > "$test_root/output" 2>&1
      return $?
    fi
    AGENT_OS_FIXTURE_ROOT="$test_root" \
    AGENT_OS_TEST_DSCL="$fakebin/dscl" \
    AGENT_OS_TEST_ID="$fakebin/id" \
    AGENT_OS_TEST_INSTALL="$fakebin/install" \
    AGENT_OS_TEST_STAT="$fakebin/stat" \
    AGENT_OS_TEST_RMDIR="$fakebin/rmdir" \
    AGENT_OS_TEST_UUIDGEN="$fakebin/uuidgen" \
    OPENCLAW_BIN="$fakebin/openclaw" \
    AGENT_OS_BOOTSTRAP_ALLOW_NONROOT_TEST=1 \
    AGENT_OS_BOOTSTRAP_HOME_DIR="$home_dir" \
    bash "$0" "$mode" --out-dir="$test_root/out" "$@" > "$test_root/output" 2>&1
  }
  assert_file_absent() { [ ! -e "$1" ] || { echo "SELF TEST assertion failed: expected absent $1" >&2; cat "$test_root/output" >&2 || true; exit 1; }; }
  assert_file_present() { [ -e "$1" ] || { echo "SELF TEST assertion failed: expected present $1" >&2; cat "$test_root/output" >&2 || true; exit 1; }; }
  assert_grep() { grep -q "$1" "$2" || { echo "SELF TEST assertion failed: missing $1" >&2; cat "$2" >&2; exit 1; }; }

  reset_fixture
  output="$(run_fixture --dry-run)"
  assert_grep "IDENTITY BOOTSTRAP DRY RUN: GO" "$test_root/output"
  [ ! -d "$test_root/out" ] || { echo "SELF TEST assertion failed: dry-run wrote output dir" >&2; exit 1; }
  echo "SELF TEST dry-run-zero-write-wrapper-calls: PASS"

  reset_fixture
  run_fixture apply
  assert_file_present "$test_root/users/openai-credential-broker/UniqueID"
  assert_file_present "$test_root/groups/openai-credential-broker/PrimaryGroupID"
  assert_file_present "$home_dir/agent-os-openai-credential-broker/secrets"
  echo "SELF TEST fully-absent-state: PASS"

  run_fixture apply
  assert_grep "IDENTITY BOOTSTRAP VERIFIED: PASS" "$test_root/output"
  echo "SELF TEST successful-rerun-idempotent: PASS"

  reset_fixture
  mkdir -p "$test_root/users/openai-credential-broker"
  echo 999 > "$test_root/users/openai-credential-broker/UniqueID"
  set +e; run_fixture --dry-run; status=$?; set -e
  [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: conflicting user accepted" >&2; exit 1; }
  echo "SELF TEST conflicting-user-record: PASS"

  reset_fixture
  mkdir -p "$test_root/groups/openai-credential-broker"
  echo 999 > "$test_root/groups/openai-credential-broker/PrimaryGroupID"
  set +e; run_fixture --dry-run; status=$?; set -e
  [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: conflicting group accepted" >&2; exit 1; }
  echo "SELF TEST conflicting-group-record: PASS"

  reset_fixture
  mkdir -p "$home_dir"
  set +e; run_fixture --dry-run; status=$?; set -e
  [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: partial filesystem accepted" >&2; exit 1; }
  echo "SELF TEST partial-filesystem-state: PASS"

  reset_fixture
  for id_value in $(seq "$UID_MIN" "$UID_MAX"); do
    mkdir -p "$test_root/users/used-$id_value"
    echo "$id_value" > "$test_root/users/used-$id_value/UniqueID"
  done
  set +e; run_fixture --dry-run; status=$?; set -e
  [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: exhausted UID range accepted" >&2; exit 1; }
  echo "SELF TEST uid-collision-range-exhausted: PASS"

  reset_fixture
  for id_value in $(seq "$GID_MIN" "$GID_MAX"); do
    mkdir -p "$test_root/groups/used-$id_value"
    echo "$id_value" > "$test_root/groups/used-$id_value/PrimaryGroupID"
  done
  set +e; run_fixture --dry-run; status=$?; set -e
  [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: exhausted GID range accepted" >&2; exit 1; }
  echo "SELF TEST gid-collision-range-exhausted: PASS"

  for fail_at in 1 2 3 4 5 6 7 8 9 10 11 12; do
    reset_fixture
    set +e
    AGENT_OS_FIXTURE_FAIL_AFTER="$fail_at" run_fixture apply
    status=$?
    set -e
    [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: injected failure $fail_at succeeded" >&2; exit 1; }
    assert_file_absent "$test_root/users/openai-credential-broker"
    assert_file_absent "$test_root/groups/openai-credential-broker"
  done
  echo "SELF TEST failure-after-each-directory-service-stage-rolls-back: PASS"

  reset_fixture
  run_fixture apply
  bash "$test_root/out/rollback.sh" > "$test_root/rollback-output" 2>&1
  assert_file_absent "$test_root/users/openai-credential-broker"
  assert_file_absent "$test_root/groups/openai-credential-broker"
  assert_file_absent "$home_dir"
  assert_grep "BOOTSTRAP ROLLBACK VERIFIED: PASS" "$test_root/rollback-output"
  echo "SELF TEST rollback-removes-current-run-objects: PASS"

  reset_fixture
  run_fixture apply
  echo 999 > "$test_root/users/openai-credential-broker/UniqueID"
  set +e; bash "$test_root/out/rollback.sh" > "$test_root/rollback-output" 2>&1; status=$?; set -e
  [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: rollback accepted changed UID" >&2; exit 1; }
  echo "SELF TEST rollback-refuses-changed-uid: PASS"

  reset_fixture
  mkdir -p "$test_root/groups/openai-credential-broker"
  echo 740 > "$test_root/groups/openai-credential-broker/PrimaryGroupID"
  echo "$REAL_NAME" > "$test_root/groups/openai-credential-broker/RealName"
  mkdir -p "$test_root/users/openai-credential-broker"
  echo 540 > "$test_root/users/openai-credential-broker/UniqueID"
  echo 740 > "$test_root/users/openai-credential-broker/PrimaryGroupID"
  echo "$REAL_NAME" > "$test_root/users/openai-credential-broker/RealName"
  echo "$home_dir" > "$test_root/users/openai-credential-broker/NFSHomeDirectory"
  echo "$SHELL_PATH" > "$test_root/users/openai-credential-broker/UserShell"
  echo 1 > "$test_root/users/openai-credential-broker/IsHidden"
  echo 11111111-2222-3333-4444-555555555555 > "$test_root/users/openai-credential-broker/GeneratedUID"
  echo ";DisabledUser;" > "$test_root/users/openai-credential-broker/AuthenticationAuthority"
  echo "*" > "$test_root/users/openai-credential-broker/Password"
  set +e; AGENT_OS_FIXTURE_BROAD_GROUP=1 run_fixture --dry-run; status=$?; set -e
  [ "$status" -ne 0 ] || { echo "SELF TEST assertion failed: broad group accepted" >&2; exit 1; }
  echo "SELF TEST broad-group-membership-rejected: PASS"

  rm -rf "$test_root"
  echo "IDENTITY BOOTSTRAP SELF TEST: PASS"
}

case "$MODE" in
  dry-run) run_dry_run ;;
  apply) run_apply ;;
  self-test) run_self_test ;;
esac
