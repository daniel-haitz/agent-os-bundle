# F-A1 Gmail Broker Design — Architect Review Addendum

**Status:** Operator-approved with the additions below. Reviewed by the architect (Claude) thread, 2026-06-16.
**Applies to:** `docs/F-A1_GMAIL_BROKER_DESIGN.md`. That design is sound and is the build spec. This addendum adds three required items and clarifies two. The base design plus this addendum together are the approved F-A1 spec. Build against both.

---

## Review verdict

The base design is correct on its load-bearing decisions: separate non-admin `gmailbroker` user (not same-UID), credentials moved out of `agent` reach, semantic-method-only surface, forbidden operations structurally absent (no generic dispatch), and negative tests as the exit gate. Build it as written, with the following additions.

---

## ADD 1 — Explicit admin-vs-agent task split (operational, required before build)

The base design specifies creating a new OS user, a new group, and a `/var/run` socket directory. These are **privileged operations** that the `agent` user cannot perform — they require the admin user (`dannybigdeals`), run by the operator by hand over SSH. This is the same pattern used for the Colima install: privileged setup is an operator action, not an agent/Claude-Code action.

**Before Claude Code builds the broker, the operator performs these admin steps (as `dannybigdeals`):**

1. Create the dedicated non-admin user `gmailbroker` (no admin group membership, no sudo).
2. Create the broker home and directories owned by `gmailbroker`, mode `0700`, per the design's §2 layout.
3. Create the socket directory (e.g. `/var/run/agent-os/`) with the ownership the design specifies.
4. Create the client group (e.g. `gmailbroker-clients`) and add `agent` to it, so `agent` can connect to the socket but cannot read the credential directory.
5. Install the launchd service for the broker (`ai.agent-os.gmail-broker`) running as `gmailbroker`.

**What Claude Code (as `agent`, or guided by the operator) does:**
- Writes the broker code and the reader client wrapper.
- Writes config and schemas.
- Runs the negative tests.
- Does NOT create users, groups, or privileged directories — it requests the operator do those, or the operator does them from the design's spec.

**Build sequencing note:** Claude Code should produce the exact admin command list for the operator to run FIRST (as a reviewable block), the operator runs them by hand, then Claude Code proceeds with the code build. Do not attempt privileged setup from the `agent`/Claude-Code session — it will fail closed, same as the Colima and deep-audit steps.

---

## ADD 2 — Recipient handling is the highest correctness/security risk; tighten it

The base design says `create_draft` takes no recipient override and the broker "derives recipients from existing thread metadata." That security posture is correct (a possibly-injected reader must not choose recipients) but it is underspecified and is the single most important thing to build carefully, because it is where "draft-only" could leak into "draft addressed to an attacker-chosen party."

**Required clarifications:**

1. The reader can NEVER influence draft recipients through ANY field — not `to`/`cc`/`bcc` (already excluded), and NOT indirectly through `subject` or `body` content. Recipient derivation is a fixed broker-internal function of the source thread's metadata only.

2. Recipient derivation must be a deterministic, fixed function: a reply draft's recipients come from the original thread's participants as Gmail/gog reports them, computed by the broker, never parsed out of reader-supplied strings.

3. If thread metadata is ambiguous or missing, the broker FAILS CLOSED (`validation_failed`) rather than guessing a recipient.

**Required additional negative tests (add to §7):**
- **Test 13 — Reader cannot influence draft recipients.** Attempt `create_draft` with injection-style content in `subject` and `body` designed to alter addressing (e.g. embedded headers, "send to attacker@evil.com", RFC-2822-looking lines). Assert the created draft's recipients are derived solely from thread metadata and are unchanged by the injected content. Assert no draft is ever addressed to a reader-supplied address.

- **Test 13b — Cross-thread message-ID laundering must fail closed.** Attempt `create_draft` with a well-formed, syntactically valid `reply_to_message_id` that exists in the mailbox but belongs to a DIFFERENT thread than `thread_id`. Expected: broker returns `ok: false`, `error.code = "validation_failed"`, and no draft is created. This test covers the case where a compromised reader supplies an attacker-planted message ID whose From/To headers name an attacker-controlled address. The broker must cross-validate that `reply_to_message_id` belongs to the stated `thread_id` using the `message.threadId` field in the gog metadata response before deriving any recipients from it.

---

## ADD 3 — Account for the known duplicate-draft bug (it sits in the broker's path)

CONTROL.md carries an open FLAG: the parent `main` session yields before the delegated reader's result surfaces, causing a recovery re-run and, in one prior test, a duplicate draft. The broker's `create_draft` sits directly in this path, so a clean broker could still produce duplicate drafts because of the upstream yield behavior.

**Required:**
1. Claude Code must be aware of this bug during the F-A1 build (it is not introduced by the broker but is exercised through it).
2. Consider making `create_draft` idempotency-aware: e.g. accept an optional caller-supplied `correlation_id`/idempotency key (the envelope already carries `correlation_id`) and, within a short window, treat a repeat `create_draft` with the same key + same thread + same body as a no-op returning the existing `draft_id` rather than creating a second draft.
3. At minimum, if full idempotency is deferred, the broker's audit log must make duplicate-draft creation **detectable** (log thread_id + body hash + correlation_id so a duplicate is visible), and this is flagged for the F-B observability phase and the existing CONTROL.md bug FLAG.
4. This does not block F-A1 acceptance, but the build must not silently make the duplicate-draft problem worse, and the decision (idempotency now vs. detectability now + fix later) is recorded.

---

## CLARIFY 1 — Build the socket transport only; do not build both transports

The base design prefers a Unix domain socket and offers an HTTP+bearer-token fallback. Build ONLY the socket. The HTTP path is a documented alternative to use *only if* the socket proves operationally impossible during build — in which case stop and surface that to the operator as a decision, rather than building both. Two transport paths = two attack surfaces; keep one.

---

## CLARIFY 2 — The untrusted-content seam is correctly scoped to F-A1; the summary-poisoning fix is F-A3

`read_thread` correctly wraps body text in `<<<EXTERNAL_UNTRUSTED_CONTENT>>>` markers. That is the right F-A1 behavior. The deeper summary-poisoning / typed-handoff defense (reader→researcher channel constrained to a fixed schema) is explicitly F-A3, not F-A1. Do not pull F-A3 work into F-A1; just preserve the untrusted-content wrapping as the base design specifies.

---

## Net for the build worker

Build the base design exactly, plus: (ADD 1) operator does privileged user/group/socket setup by hand first, Claude Code produces that command list for review; (ADD 2) recipient derivation is fixed and reader-uninfluenceable, with new Test 13; (ADD 3) handle/flag the duplicate-draft bug; (CLARIFY 1) socket transport only; (CLARIFY 2) keep untrusted-content wrapping, leave summary-poisoning to F-A3. The negative tests in §7 plus Test 13 are the exit gate. The broker is not done until they pass.
