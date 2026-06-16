# F-A1 Gmail Capability Broker — Operator Deploy List

**Run by:** operator (`dannybigdeals` via `sudo`) on the Mac mini.
**Assumes privileged setup is DONE** (verified 2026-06-16 morning session):
- `gmailbroker` user UID 503, primary group 703 — exists ✓
- `gmailbroker-clients` group GID 702 with `agent` as member — exists ✓
- `/Users/gmailbroker/agent-os-gmail-broker/` tree with 0700 credential dirs — exists ✓
- `/var/run/agent-os/` owned `gmailbroker:gmailbroker-clients 0750` — exists ✓
- launchd plist `ai.agent-os.gmail-broker` installed but NOT loaded — exists ✓
- Agent-side credential boundary: all three credential paths return Permission denied to `agent` — proven ✓

**Do not re-create users, groups, the home dir, the broker tree, the socket dir, or the plist.**

---

## Pre-step — Add `gmailbroker` to `gmailbroker-clients`

Required so the broker process can `chown` its socket file to GID 702 after binding.
(A non-root process can only set group ownership to one of its own groups.)
Verified this session: `gmailbroker` is NOT currently in `gmailbroker-clients`.

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

## After deploy

Update `BUILD_STATE.md` / `HANDOFF_BRIEF.md` to record broker service live.
Next: build the client wrapper (`/Users/agent/.openclaw/scripts/gmail-broker-client.mjs`) and run the F-A1 negative tests (§7 of design + Tests 13/13b from addendum).
Old agent-side credential paths must NOT be retired until the negative tests pass and F-A2 credential containment is complete.
