# F-A1 Gmail Capability Broker — Operator Deploy List

**Current status (2026-07-14): COMPLETE — historical deployment record, not a rerun checklist.** Live state is tracked in `CONTROL.md`. Do not recreate users, groups, directories, credentials, or plists. Durable startup ordering is now: root-run `ai.agent-os.gmail-broker-rundir` establishes `/var/run/agent-os` as `gmailbroker:gmailbroker-clients 0750`; unprivileged `ai.agent-os.gmail-broker` waits on `KeepAlive.PathState[/var/run/agent-os]=true`. Both plists lint clean, broker is running as `gmailbroker`, socket is `gmailbroker:gmailbroker-clients 0660`, and broker health/search validation passes.

**Run by:** operator (`dannybigdeals` via `sudo`) on the Mac mini.
**Assumes privileged setup is DONE** (verified 2026-06-16 morning session):
- `gmailbroker` user UID 503, primary group 703 — exists ✓
- `gmailbroker-clients` group GID 702 with `agent` as member — exists ✓
- `/Users/gmailbroker/agent-os-gmail-broker/` tree with 0700 credential dirs — exists ✓
- `/var/run/agent-os/` owned `gmailbroker:gmailbroker-clients 0750` — exists ✓
- launchd plists `ai.agent-os.gmail-broker-rundir` and `ai.agent-os.gmail-broker` installed; broker loaded/running with durable `PathState` ordering — verified 2026-07-14 ✓
- Agent-side credential boundary: all three credential paths return Permission denied to `agent` — proven ✓

**Do not re-create users, groups, the home dir, the broker tree, the socket dir, or the plist.**

This deployment record proves the broker service and credential boundary only. A separate synchronized Codex Apps Gmail connector surface was confirmed by read-only audit on 2026-07-14; broker-only Gmail routing remains open under F-A4 until that external surface is disabled and negative-tested.

---

## Historical pre-step — Add `gmailbroker` to `gmailbroker-clients` (complete)

Required so the broker process can `chown` its socket file to GID 702 after binding.
(A non-root process can only set group ownership to one of its own groups.)
Historical condition at initial deployment: `gmailbroker` was not yet in `gmailbroker-clients`. This step is complete; do not append it again.

```bash
sudo dscl . -append /Groups/gmailbroker-clients GroupMembership gmailbroker
```

Verify:
```bash
dscl . -read /Groups/gmailbroker-clients GroupMembership
# Expected: GroupMembership: agent gmailbroker
```

---

## Step 3 — Migrate credential material to broker custody

**These copies MUST succeed.** Do not add `2>/dev/null || true` or any other error-suppression.
If any `install` command fails, stop, diagnose, and fix before continuing.

```bash
# Keyring password
sudo install -o gmailbroker -g gmailbroker -m 0600 \
  /Users/agent/.openclaw/secrets/gog-keyring-password \
  /Users/gmailbroker/agent-os-gmail-broker/secrets/gog-keyring-password

# OAuth credentials
sudo install -o gmailbroker -g gmailbroker -m 0600 \
  /Users/agent/.openclaw/gmail-draft-gog/data/credentials.json \
  /Users/gmailbroker/agent-os-gmail-broker/gog-home/data/credentials.json

# OAuth client config
sudo install -o gmailbroker -g gmailbroker -m 0600 \
  /Users/agent/.openclaw/gmail-draft-gog/oauth-client.json \
  /Users/gmailbroker/agent-os-gmail-broker/gog-home/oauth-client.json

# gog config
sudo install -o gmailbroker -g gmailbroker -m 0600 \
  /Users/agent/.openclaw/gmail-draft-gog/config/config.json \
  /Users/gmailbroker/agent-os-gmail-broker/gog-home/config/config.json

# Keyring files (.lock + all _gogcli_key_v1_* entries)
sudo install -o gmailbroker -g gmailbroker -m 0600 \
  /Users/agent/.openclaw/gmail-draft-gog/data/keyring/.lock \
  /Users/gmailbroker/agent-os-gmail-broker/gog-home/data/keyring/.lock

for kf in /Users/agent/.openclaw/gmail-draft-gog/data/keyring/_gogcli_key_v1_*; do
  sudo install -o gmailbroker -g gmailbroker -m 0600 \
    "$kf" \
    /Users/gmailbroker/agent-os-gmail-broker/gog-home/data/keyring/
done
```

Verify source permissions were not changed (agent must still reach old paths until F-A2 retires them):
```bash
ls -la /Users/agent/.openclaw/secrets/gog-keyring-password
ls -la /Users/agent/.openclaw/gmail-draft-gog/data/credentials.json
```

---

## Step 4 — Install broker binary and pinned gog binary

```bash
# Broker script
sudo install -o gmailbroker -g gmailbroker -m 0755 \
  /Users/agent/agent-os/src/gmail-broker/gmail-broker.mjs \
  /Users/gmailbroker/agent-os-gmail-broker/bin/gmail-broker.mjs

# Pinned safe gog binary (source: /Users/agent/.local/bin/)
sudo install -o gmailbroker -g gmailbroker -m 0755 \
  /Users/agent/.local/bin/gog-gmail-draft-safe \
  /Users/gmailbroker/agent-os-gmail-broker/bin/gog-gmail-draft-safe
```

Verify:
```bash
ls -la /Users/gmailbroker/agent-os-gmail-broker/bin/
```

---

## Step 6 — Pre-load credential readability check (run as `gmailbroker`)

Verify the broker process can open its own credentials before committing to loading the service.
**If any check prints FAIL, do NOT proceed to Step 7. Diagnose and fix first.**

```bash
sudo -u gmailbroker sh -c '
  fail=0

  test -r /Users/gmailbroker/agent-os-gmail-broker/secrets/gog-keyring-password \
    && echo "PASS: keyring-password" \
    || { echo "FAIL: keyring-password not readable by gmailbroker"; fail=1; }

  test -r /Users/gmailbroker/agent-os-gmail-broker/gog-home/data/credentials.json \
    && echo "PASS: credentials.json" \
    || { echo "FAIL: credentials.json not readable by gmailbroker"; fail=1; }

  test -r /Users/gmailbroker/agent-os-gmail-broker/gog-home/oauth-client.json \
    && echo "PASS: oauth-client.json" \
    || { echo "FAIL: oauth-client.json not readable by gmailbroker"; fail=1; }

  count=$(ls /Users/gmailbroker/agent-os-gmail-broker/gog-home/data/keyring/_gogcli_key_v1_* 2>/dev/null | wc -l | tr -d " ")
  test "$count" -gt 0 \
    && echo "PASS: keyring token files ($count found)" \
    || { echo "FAIL: no keyring token files readable by gmailbroker"; fail=1; }

  test -x /Users/gmailbroker/agent-os-gmail-broker/bin/gog-gmail-draft-safe \
    && echo "PASS: gog binary executable" \
    || { echo "FAIL: gog binary not executable by gmailbroker"; fail=1; }

  test -x /opt/homebrew/bin/node \
    && echo "PASS: node binary accessible" \
    || { echo "FAIL: node binary not accessible"; fail=1; }

  exit $fail
'
```

All six lines must print `PASS`.

---

## Step 7 — Load the launchd service

```bash
sudo launchctl load /Library/LaunchDaemons/ai.agent-os.gmail-broker.plist
```

Verify socket appeared and has correct permissions:
```bash
sleep 2
sudo launchctl list | grep ai.agent-os.gmail-broker
ls -la /var/run/agent-os/gmail-broker.sock
# Expected: srw-rw---- owner gmailbroker group gmailbroker-clients
```

---

## Step 8 — Smoke test (run as `agent`)

From an agent SSH session (not dannybigdeals):

```bash
echo '{"correlation_id":"deploy-smoke-01","method":"health_check","params":{}}' \
  | /opt/homebrew/bin/node -e "
    const net = require('net');
    let d = '';
    const s = net.createConnection('/var/run/agent-os/gmail-broker.sock');
    process.stdin.resume();
    s.on('connect', () => s.write(process.stdin.read() + '\n'));
    s.on('data', c => { d += c; });
    s.on('end', () => console.log(d));
  "
```

Expected: `"ok":true`, `"status":"ok"`, `"service":"gmail-broker"`.

---

## After deploy — completed record

The client wrapper, F-A1 negative tests, F-A2 credential retirement, confined broker proof, and socket-directory hardening are complete. Do not use this historical list to restore deleted agent-side credentials or repeat deployment. Read `CONTROL.md` for current state and the remaining F-A4 connector-containment task.
