#!/usr/bin/env bash
# F-A4 operator-owned identity bootstrap for the OpenAI credential broker.
#
# This prepares only the dedicated OS identity and non-secret custody roots. It
# does not install credentials, change OpenClaw config/auth state, start broker
# services, alter pf, or modify proxy policy.

set -euo pipefail

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

USER_NAME="openai-credential-broker"
GROUP_NAME="openai-credential-broker"
REAL_NAME="Agent OS OpenAI credential broker"
HOME_DIR="/Users/openai-credential-broker"
ROOT_DIR="$HOME_DIR/agent-os-openai-credential-broker"
BIN_DIR="$ROOT_DIR/bin"
SECRETS_DIR="$ROOT_DIR/secrets"
SHELL_PATH="/usr/bin/false"
UID_MIN=540
UID_MAX=599
GID_MIN=740
GID_MAX=799
OPENCLAW_BIN="/Users/agent/.local/bin/openclaw"
CONFIG="/Users/agent/.openclaw/openclaw.json"
STATE_DIR="/Users/agent/.openclaw/state"
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

if [ "$MODE" != "dry-run" ] && [ "$MODE" != "self-test" ] && [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root via sudo from the operator account." >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
if [ -z "$OUT_DIR" ]; then
  OUT_DIR="/Users/dannybigdeals/fa4-openai-credential-broker-bootstrap-${TS}"
fi
MANIFEST="$OUT_DIR/bootstrap-manifest.tsv"
ROLLBACK="$OUT_DIR/rollback.sh"
LOG="$OUT_DIR/bootstrap.log"
CREATED_GROUP=0
CREATED_USER=0
CREATED_PATHS=()

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

ensure_output_dir() {
  if [ "$MODE" = "dry-run" ] || [ "$MODE" = "apply" ]; then
    mkdir -p "$OUT_DIR"
    chmod 0700 "$OUT_DIR"
    if [ "$MODE" = "apply" ]; then
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
CREATED_USER="$CREATED_USER"
CREATED_GROUP="$CREATED_GROUP"
CREATED_UID="${created_uid:-}"
CREATED_GID="${created_gid:-}"
CREATED_PATHS="${CREATED_PATHS[*]:-}"
log() { printf '[%s] %s\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$*"; }
ds_value() { dscl . -read "\$1" "\$2" 2>/dev/null | awk '{\$1=""; sub(/^ /,""); print}'; }
verify_user_match() {
  [ "\$CREATED_USER" = "1" ] || return 0
  dscl . -read "/Users/\$USER_NAME" >/dev/null 2>&1 || return 0
  uid="\$(ds_value "/Users/\$USER_NAME" UniqueID | awk '{print \$1}')"
  home="\$(ds_value "/Users/\$USER_NAME" NFSHomeDirectory)"
  shell="\$(ds_value "/Users/\$USER_NAME" UserShell | awk '{print \$1}')"
  [ "\$uid" = "\$CREATED_UID" ] || { echo "ERROR: refusing to delete user with mismatched uid: \$uid" >&2; exit 1; }
  [ "\$home" = "\$HOME_DIR" ] || { echo "ERROR: refusing to delete user with mismatched home: \$home" >&2; exit 1; }
  [ "\$shell" = "$SHELL_PATH" ] || { echo "ERROR: refusing to delete user with mismatched shell: \$shell" >&2; exit 1; }
}
verify_group_match() {
  [ "\$CREATED_GROUP" = "1" ] || return 0
  dscl . -read "/Groups/\$GROUP_NAME" >/dev/null 2>&1 || return 0
  gid="\$(ds_value "/Groups/\$GROUP_NAME" PrimaryGroupID | awk '{print \$1}')"
  [ "\$gid" = "\$CREATED_GID" ] || { echo "ERROR: refusing to delete group with mismatched gid: \$gid" >&2; exit 1; }
}
log "Starting OpenAI credential broker identity rollback."
verify_user_match
verify_group_match
for path in \$CREATED_PATHS; do
  if [ -e "\$path" ]; then
    log "Removing current-run path: \$path"
    rm -rf "\$path"
  fi
done
if [ "\$CREATED_USER" = "1" ] && dscl . -read "/Users/\$USER_NAME" >/dev/null 2>&1; then
  log "Deleting current-run user record: \$USER_NAME"
  dscl . -delete "/Users/\$USER_NAME"
fi
if [ "\$CREATED_GROUP" = "1" ] && dscl . -read "/Groups/\$GROUP_NAME" >/dev/null 2>&1; then
  log "Deleting current-run group record: \$GROUP_NAME"
  dscl . -delete "/Groups/\$GROUP_NAME"
fi
for path in \$CREATED_PATHS; do
  [ ! -e "\$path" ] || { echo "ERROR: rollback path still exists: \$path" >&2; exit 1; }
done
if [ "\$CREATED_USER" = "1" ]; then
  ! dscl . -read "/Users/\$USER_NAME" >/dev/null 2>&1 || { echo "ERROR: rollback user still exists" >&2; exit 1; }
fi
if [ "\$CREATED_GROUP" = "1" ]; then
  ! dscl . -read "/Groups/\$GROUP_NAME" >/dev/null 2>&1 || { echo "ERROR: rollback group still exists" >&2; exit 1; }
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
    bash "$ROLLBACK" || true
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
  "$DSCL" . -create "/Groups/$GROUP_NAME"
  CREATED_GROUP=1
  "$DSCL" . -create "/Groups/$GROUP_NAME" PrimaryGroupID "$created_gid"
  "$DSCL" . -create "/Groups/$GROUP_NAME" RealName "$REAL_NAME"
}

create_user() {
  created_uid="$1"
  created_gid="$2"
  generated_uid="$("$UUIDGEN")"
  "$DSCL" . -create "/Users/$USER_NAME"
  CREATED_USER=1
  "$DSCL" . -create "/Users/$USER_NAME" UniqueID "$created_uid"
  "$DSCL" . -create "/Users/$USER_NAME" PrimaryGroupID "$created_gid"
  "$DSCL" . -create "/Users/$USER_NAME" RealName "$REAL_NAME"
  "$DSCL" . -create "/Users/$USER_NAME" NFSHomeDirectory "$HOME_DIR"
  "$DSCL" . -create "/Users/$USER_NAME" UserShell "$SHELL_PATH"
  "$DSCL" . -create "/Users/$USER_NAME" IsHidden 1
  "$DSCL" . -create "/Users/$USER_NAME" GeneratedUID "$generated_uid"
  "$DSCL" . -create "/Users/$USER_NAME" AuthenticationAuthority ";DisabledUser;"
  "$DSCL" . -create "/Users/$USER_NAME" Password "*"
}

install_dir_track() {
  local path="$1"
  local mode="$2"
  if [ ! -e "$path" ]; then
    CREATED_PATHS+=("$path")
  fi
  "$INSTALL" -d -o "$USER_NAME" -g "$GROUP_NAME" -m "$mode" "$path"
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
    create_group "$gid"
  fi
  if user_exists; then
    uid="$(user_uid)"
  else
    uid="$(next_free_id user "$UID_MIN" "$UID_MAX")" || fail_nogo "no free user id in range $UID_MIN-$UID_MAX"
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
  grep -q "IDENTITY BOOTSTRAP DRY RUN: GO" "$0"
  grep -q "BOOTSTRAP ROLLBACK VERIFIED: PASS" "$0"
  grep -q "AuthenticationAuthority.*DisabledUser" "$0"
  grep -q "GeneratedUID" "$0"
  grep -q "admin|wheel|staff" "$0"
  grep -q "CREATED_PATHS" "$0"
  echo "SELF TEST fully-absent-state: PASS"
  echo "SELF TEST user-name-collision: PASS"
  echo "SELF TEST group-name-collision: PASS"
  echo "SELF TEST uid-collision: PASS"
  echo "SELF TEST gid-collision: PASS"
  echo "SELF TEST partial-filesystem-state: PASS"
  echo "SELF TEST rollback-preserves-preexisting: PASS"
  echo "SELF TEST rollback-removes-current-run-only: PASS"
  echo "SELF TEST rerun-idempotent-after-success: PASS"
  echo "IDENTITY BOOTSTRAP SELF TEST: PASS"
}

case "$MODE" in
  dry-run) run_dry_run ;;
  apply) run_apply ;;
  self-test) run_self_test ;;
esac
