# F-A2 Proof Loop Runbook

**Status:** STAGED — ready for Codex execution. Live config untouched. Restore path verified.
**Goal:** Confirm that the Gmail reader works end-to-end through the broker with the old credential paths blinded. This is the proof that F-A2 Part 1 wiring is real enforcement, not just documentation.
**F-A2 scope (operator-locked):** Reader Credential Containment ONLY. This does NOT achieve exfiltration containment. Exit gate must NOT claim the reader is contained against leakage — only against credential theft.
**F-A2 Part 2 (deletion of originals) is LOCKED until this proof loop passes and the operator gives explicit go.**

---

## Context: the two old credential paths

These are the files that must be blinded in step 1. Confirmed live on disk:

| Path | Type | Current permissions | Owner |
|---|---|---|---|
| `/Users/agent/.openclaw/secrets/gog-keyring-password` | file | 0600 | agent:staff |
| `/Users/agent/.openclaw/gmail-draft-gog/` | directory | 0755 | agent:staff |

Both are owned by `agent`. `chmod` on them does not require `sudo` — the agent user is the owner.

The proof: if the reader can complete `search_threads` → `read_thread` → `create_draft` with both paths at mode 0000, the reader is not using them. The broker holds the live credentials and the broker path is the only path that works.

---

## Broker status check (run before step 1)

Confirm the broker is up:

```bash
node /Users/agent/.openclaw/scripts/gmail-broker-client.mjs health_check '{}'
```

Expected: `{"ok":true,"result":{"status":"ok","service":"gmail-broker",...}}`

If the broker is down, do NOT proceed. Restart via launchd:
```bash
launchctl kickstart -k gui/$(id -u agent)/ai.agent-os.gmail-broker
```
(must be run from a `dannybigdeals` session with admin rights)

---

## Audit log baseline (operator, BEFORE step 1)

Run this from a `dannybigdeals` session before blinding. Captures the current state so the proof loop's new entries are distinguishable:

```bash
# As dannybigdeals:
sudo -u gmailbroker wc -l /Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl
sudo -u gmailbroker tail -5 /Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl
```

Record the line count. After the proof loop, the new entries will be the lines after that count.

---

## Step 1 — Blind both old credential paths

Run as `agent` user (agent owns the files, no sudo needed):

```bash
chmod 000 /Users/agent/.openclaw/secrets/gog-keyring-password
chmod 000 /Users/agent/.openclaw/gmail-draft-gog
```

Verify the blind took:

```bash
stat -f "%OLp %N" \
  /Users/agent/.openclaw/secrets/gog-keyring-password \
  /Users/agent/.openclaw/gmail-draft-gog
# Expected: 0000 for both
```

**Note for Codex:** these paths are not in the `.claude/settings.local.json` allowlist and will produce a permission prompt. The operator must approve the prompts for both `chmod` calls, or run these two lines manually as `agent` via SSH before starting Codex.

---

## Step 2 — Delegate the reader loop

With paths blinded, give the main OpenClaw agent this instruction via Codex or Telegram:

```
Delegate to gmail-reader: Search for the most recent email thread in the past 30 days,
read it, and prepare a draft reply. Report the draft_id and subject when done.
```

The reader must complete `search_threads` → `read_thread` → `create_draft` entirely through the broker client at `/Users/agent/.openclaw/scripts/gmail-broker-client.mjs`.

**PASS gate:** The reader completes the loop and returns a `draft_id`.

**FAIL condition:** The reader errors, hangs, or attempts to call `gog` directly (which would fail with EACCES on the blinded paths). If EACCES appears in the output, that proves the old path was being attempted — record it and stop.

**Duplicate draft warning:** The known parent-yield bug (CONTROL.md flag) may cause a recovery re-run. If a second draft is created, note both `draft_id` values. This is benign; delete the duplicate manually in Gmail UI. Do not stop the proof loop for a duplicate draft.

---

## Step 3 — Confirm the broker audit log

Run from a `dannybigdeals` session immediately after the reader loop completes:

```bash
# Full method trace for the run:
sudo -u gmailbroker grep -E '"method":"(search_threads|read_thread|create_draft)"' \
  /Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl | tail -20

# Scan for any raw or send calls (must return empty):
sudo -u gmailbroker grep -E '"method":"(send_message|send_draft|raw_gmail_api_call|return_token|return_keyring_password)"' \
  /Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl
```

**PASS looks like:**
```json
{"ts":"...","event":"gmail_broker.request","method":"search_threads",...}
{"ts":"...","event":"gmail_broker.result","method":"search_threads","status":"ok",...}
{"ts":"...","event":"gmail_broker.request","method":"read_thread",...}
{"ts":"...","event":"gmail_broker.result","method":"read_thread","status":"ok",...}
{"ts":"...","event":"gmail_broker.request","method":"create_draft",...}
{"ts":"...","event":"gmail_broker.result","method":"create_draft","status":"ok",...}
```
Three request+result pairs. The raw/send grep returns nothing.

**FAIL / STOP condition:** Any line with `send_message`, `send_draft`, `raw_gmail_api_call`, `return_token`, or `return_keyring_password` in the `method` field = containment breach. **STOP immediately. Do NOT proceed to step 5 (restore). Do NOT proceed to Part 2.** Report the offending lines to the operator. Leave paths blinded until the breach is understood.

---

## Step 4 — Verify the draft recipient

Retrieve the `draft_id` from the Codex/reader output. Then verify the recipient via the broker:

```bash
node /Users/agent/.openclaw/scripts/gmail-broker-client.mjs get_draft \
  '{"draft_id":"<draft_id from step 2>"}'
```

This returns `subject` and `body_text`. To verify the recipient (the broker's `get_draft` does not return the To: header), the operator opens Gmail web UI → Drafts → finds the draft by subject → checks the To: field.

**PASS:** Draft is addressed to `daniel.haitz@gmail.com`. Recipient is derived from thread metadata, not supplied by the reader.

**FAIL / STOP:** Draft is addressed to any other address. **STOP. Do NOT restore. Do NOT proceed to Part 2.** Record the actual recipient and report.

---

## Step 5 — Restore the blinded paths

Only proceed here if steps 3 and 4 both PASS.

Run as `agent`:

```bash
chmod 0600 /Users/agent/.openclaw/secrets/gog-keyring-password
chmod 0755 /Users/agent/.openclaw/gmail-draft-gog
```

Verify restore:

```bash
stat -f "%OLp %N" \
  /Users/agent/.openclaw/secrets/gog-keyring-password \
  /Users/agent/.openclaw/gmail-draft-gog
# Expected: 0600 and 0755 respectively
```

These commands have been dry-run against a scratch copy. The restore is a proven clean inverse (diff: empty).

---

## Restore dry-run evidence (Task 3 of DROP F-A2-STAGE)

Run against `/tmp/fa2-restore-test/` (scratch copies, no credential content):

```
ORIGINAL  gog-keyring-password: 0600
ORIGINAL  gmail-draft-gog/    : 0755
BLINDED   gog-keyring-password: 0000
BLINDED   gmail-draft-gog/    : 0000
RESTORED  gog-keyring-password: 0600
RESTORED  gmail-draft-gog/    : 0755

DIFF RESULT: EMPTY — restored permissions identical to original. Restore is a clean inverse.
```

---

## Post-proof cleanup

After step 5:

1. Delete any test drafts created during the loop from Gmail UI.
2. Update CONTROL.md: move F-A2 proof loop from NEXT to DONE; write F-A2 Part 2 as NEXT (only if all gates passed).
3. Commit `~/.openclaw` state with the result.

---

## STOP conditions (any of these = halt and report, do not continue)

- Broker health check fails before step 1 → fix broker, do not blind
- Reader errors with EACCES on the broker socket (not the old paths) → investigate
- Audit log shows any forbidden method → containment breach, leave blinded, report
- Draft recipient is not `daniel.haitz@gmail.com` → recipient leak, leave blinded, report
- Restore stat shows wrong permissions → do not proceed to Part 2, investigate

**F-A2 Part 2 (deletion of agent-side credential originals) is LOCKED until all five proof-loop steps PASS and the operator gives explicit go.**
