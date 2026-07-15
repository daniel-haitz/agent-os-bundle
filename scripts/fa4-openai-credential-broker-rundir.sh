#!/bin/sh
# Create the boot-ephemeral runtime directory for the OpenAI credential broker.
# This runs as root from launchd before the broker starts.

set -eu

ROOT_DIR="/var/run/agent-os"
RUN_DIR="/var/run/agent-os/openai-credential-broker"
BROKER_USER="openai-credential-broker"
BROKER_GROUP="openclawgw"

if [ -L "$ROOT_DIR" ] || [ -L "$RUN_DIR" ]; then
  echo "ERROR: refusing symlinked runtime directory" >&2
  exit 1
fi

if [ ! -d "$ROOT_DIR" ]; then
  mkdir -p "$ROOT_DIR"
  chown root:wheel "$ROOT_DIR"
  chmod 0755 "$ROOT_DIR"
fi

if [ ! -d "$ROOT_DIR" ]; then
  echo "ERROR: missing runtime root: $ROOT_DIR" >&2
  exit 1
fi
case "$(stat -f '%Su:%Sg:%04Lp' "$ROOT_DIR")" in
  root:wheel:0755|gmailbroker:gmailbroker-clients:0750) ;;
  *)
    echo "ERROR: unexpected runtime root metadata: $(stat -f '%Su:%Sg:%04Lp' "$ROOT_DIR")" >&2
    exit 1
    ;;
esac

mkdir -p "$RUN_DIR"
chown "$BROKER_USER:$BROKER_GROUP" "$RUN_DIR"
chmod 0750 "$RUN_DIR"

exit 0
