#!/usr/bin/env bash
# F-A4 operator-owned identity bootstrap for the OpenAI credential broker.
#
# This prepares only the dedicated OS identity. It does not install credentials,
# change OpenClaw config/auth state, start remediation, alter pf, or modify proxy
# policy.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root via sudo from the operator account." >&2
  exit 1
fi

USER_NAME="openai-credential-broker"
GROUP_NAME="openai-credential-broker"
HOME_DIR="/Users/openai-credential-broker"
SHELL_PATH="/usr/bin/false"
UID_MIN=540
UID_MAX=599
GID_MIN=740
GID_MAX=799

next_free_id() {
  local kind="$1"
  local min="$2"
  local max="$3"
  local used
  if [ "$kind" = "user" ]; then
    used="$(dscl . -list /Users UniqueID | awk '{print $2}')"
  else
    used="$(dscl . -list /Groups PrimaryGroupID | awk '{print $2}')"
  fi
  for candidate in $(seq "$min" "$max"); do
    if ! printf '%s\n' "$used" | grep -qx "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  echo "ERROR: no free $kind id in range $min-$max" >&2
  return 1
}

if dscl . -read "/Groups/$GROUP_NAME" >/dev/null 2>&1; then
  gid="$(dscl . -read "/Groups/$GROUP_NAME" PrimaryGroupID | awk '{print $2}')"
else
  gid="$(next_free_id group "$GID_MIN" "$GID_MAX")"
  dscl . -create "/Groups/$GROUP_NAME"
  dscl . -create "/Groups/$GROUP_NAME" PrimaryGroupID "$gid"
  dscl . -create "/Groups/$GROUP_NAME" RealName "Agent OS OpenAI credential broker"
fi

if dscl . -read "/Users/$USER_NAME" >/dev/null 2>&1; then
  uid="$(dscl . -read "/Users/$USER_NAME" UniqueID | awk '{print $2}')"
else
  uid="$(next_free_id user "$UID_MIN" "$UID_MAX")"
  dscl . -create "/Users/$USER_NAME"
  dscl . -create "/Users/$USER_NAME" UniqueID "$uid"
  dscl . -create "/Users/$USER_NAME" PrimaryGroupID "$gid"
  dscl . -create "/Users/$USER_NAME" RealName "Agent OS OpenAI credential broker"
  dscl . -create "/Users/$USER_NAME" NFSHomeDirectory "$HOME_DIR"
  dscl . -create "/Users/$USER_NAME" UserShell "$SHELL_PATH"
  dscl . -create "/Users/$USER_NAME" Password "*"
fi

current_gid="$(dscl . -read "/Users/$USER_NAME" PrimaryGroupID | awk '{print $2}')"
current_home="$(dscl . -read "/Users/$USER_NAME" NFSHomeDirectory | cut -d' ' -f2-)"
current_shell="$(dscl . -read "/Users/$USER_NAME" UserShell | awk '{print $2}')"

[ "$current_gid" = "$gid" ] || { echo "ERROR: unexpected primary gid: $current_gid expected $gid" >&2; exit 1; }
[ "$current_home" = "$HOME_DIR" ] || { echo "ERROR: unexpected home: $current_home" >&2; exit 1; }
[ "$current_shell" = "$SHELL_PATH" ] || { echo "ERROR: unexpected shell: $current_shell" >&2; exit 1; }

install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0750 "$HOME_DIR"
install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0750 "$HOME_DIR/agent-os-openai-credential-broker"
install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0750 "$HOME_DIR/agent-os-openai-credential-broker/bin"
install -d -o "$USER_NAME" -g "$GROUP_NAME" -m 0700 "$HOME_DIR/agent-os-openai-credential-broker/secrets"

echo "OPENAI CREDENTIAL BROKER IDENTITY BOOTSTRAP: PASS"
