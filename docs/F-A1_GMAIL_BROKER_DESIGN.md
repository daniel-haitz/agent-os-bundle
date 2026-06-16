# F-A1 Gmail Capability Broker Design

Status: DESIGN PROPOSED, awaiting operator approval. No broker code exists from this document alone.

Purpose: make Gmail read/draft access structural instead of cooperative. F-A0 proved the Gmail reader currently runs `exec` as Unix user `agent` and can reach the gog keyring, keyring password, wrapper source, and gog config. The broker must move both credential custody and the Gmail action surface outside reader authority.

Non-goal: this does not solve poisoned summaries, search exfiltration, malicious draft content, or egress. Sensitive data remains held until the full F-A0 through F-D gate passes.

## 1. Placement & Process Model

### Required authority boundary

The broker MUST NOT run as Unix user `agent`.

Reason: F-A0 found the reader has same-UID `exec` authority as the current Gmail credential files. A same-host process under the same user would not close the hole; the reader could still read files, inspect wrapper source, run alternate child processes, or reach same-UID credential material.

Proposed design target:

- Create a dedicated non-admin macOS user for the broker, named `gmailbroker` unless the operator chooses a different name at build time.
- The broker process runs as `gmailbroker`.
- Gmail credential files are owned by `gmailbroker`, mode `0600` for files and `0700` for credential directories.
- The `agent` user must not be a member of any group that can read the broker credential directory.
- The broker does not need admin privileges after setup.

Alternative only if user creation is rejected: run the broker as the existing admin user `dannybigdeals`, but this is less clean because it places a high-value service under an admin account. Prefer a dedicated non-admin broker user.

### Process supervisor

Use launchd for a persistent broker service:

- Label: `ai.agent-os.gmail-broker`
- Runtime user: `gmailbroker`
- Binary/script location: outside `agent` writable paths, for example `/Users/gmailbroker/agent-os-gmail-broker/bin/gmail-broker`
- Working directory: `/Users/gmailbroker/agent-os-gmail-broker`
- Logs: `/Users/gmailbroker/agent-os-gmail-broker/logs/`

The OpenClaw Gateway and Gmail Reader remain under user `agent`. The broker is a separate local service with a narrow capability API.

### Reader-to-broker channel

Preferred channel: Unix domain socket.

- Socket path: `/var/run/agent-os/gmail-broker.sock`
- Directory owner: `root`
- Directory mode: `0755` or tighter if the build creates a dedicated connect group.
- Socket owner: `gmailbroker`
- Socket mode: `0660`
- Socket group: a dedicated group such as `gmailbroker-clients` containing `agent`, or equivalent launchd-supported ACL.

Why a socket is acceptable: the socket is not a credential path. A compromised reader may be able to call the broker, but the broker exposes only fixed semantic Gmail capabilities and never returns tokens, keyring passwords, refresh tokens, or raw Gmail API access.

Fallback channel if Unix socket permissions are operationally awkward: localhost HTTP bound to `127.0.0.1` on a fixed high port plus a broker-client bearer token stored under the `agent` user. This token is not a Gmail credential. It authorizes only the same fixed broker methods. Prefer the socket because filesystem permissions are simpler to audit than another bearer token.

### Reader integration surface

The reader should call a small client wrapper such as:

```text
/Users/agent/.openclaw/scripts/gmail-broker-client.mjs
```

That wrapper:

- Encodes/decodes broker JSON.
- Connects to the Unix socket.
- Adds a `correlation_id`.
- Does not know any Gmail OAuth credential, keyring password, refresh token, or gog home.
- Has no fallback path to `gog`, `gog-gmail-draft-safe`, or the old credential-bearing wrapper.

The client wrapper may be readable by `agent`; that is fine because it contains no secrets and no Gmail implementation.

## 2. Credential Custody

### Broker-owned credential paths

Move Gmail runtime credential custody under the broker user. Proposed layout:

```text
/Users/gmailbroker/agent-os-gmail-broker/
  bin/
    gmail-broker
    gog-gmail-draft-safe
  config/
    gmail-broker.json
    gmail-draft-policy.yaml
  gog-home/
    config/config.json
    data/credentials.json
    data/keyring/*
    oauth-client.json
  secrets/
    gog-keyring-password
  logs/
    audit.jsonl
```

Permissions:

```text
/Users/gmailbroker/agent-os-gmail-broker              gmailbroker:staff 0700
/Users/gmailbroker/agent-os-gmail-broker/gog-home     gmailbroker:staff 0700
/Users/gmailbroker/agent-os-gmail-broker/secrets      gmailbroker:staff 0700
.../secrets/gog-keyring-password                      gmailbroker:staff 0600
.../gog-home/data/keyring/*                           gmailbroker:staff 0600
.../gog-home/oauth-client.json                        gmailbroker:staff 0600
.../gog-home/data/credentials.json                    gmailbroker:staff 0600
```

The old reader-reachable paths must be retired from the reader path:

```text
/Users/agent/.openclaw/gmail-draft-gog
/Users/agent/.openclaw/secrets/gog-keyring-password
```

They may be archived during migration, but after F-A1/F-A2 they must not be required for live Gmail operation and must not be readable by the reader.

### Runtime environment

Only the broker process may receive:

```text
GOG_HOME=/Users/gmailbroker/agent-os-gmail-broker/gog-home
GOG_KEYRING_BACKEND=file
GOG_KEYRING_PASSWORD=<read by broker from broker-owned password file>
```

The reader MUST NOT receive `GOG_KEYRING_PASSWORD` in any environment it controls. The broker client wrapper must not set `GOG_HOME`, `GOG_KEYRING_BACKEND`, or `GOG_KEYRING_PASSWORD`.

Credential-hiding alone is not enough. The broker must enforce semantic operations because `gmail.compose` is send-adjacent.

## 3. Allowed Methods

Transport envelope for every request:

```json
{
  "correlation_id": "uuid-v4-or-caller-provided-id",
  "method": "method_name",
  "params": {}
}
```

Transport envelope for every response:

```json
{
  "correlation_id": "same-id",
  "ok": true,
  "result": {}
}
```

Error response:

```json
{
  "correlation_id": "same-id-if-parseable-else-generated",
  "ok": false,
  "error": {
    "code": "unknown_method|malformed_request|validation_failed|gmail_error|broker_unavailable",
    "message": "sanitized human-readable error"
  }
}
```

No response may contain access tokens, refresh tokens, keyring passwords, OAuth client secrets, raw credential files, raw HTTP headers, or raw gog config.

### `health_check`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "health_check",
  "params": {}
}
```

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "status": "ok",
    "service": "gmail-broker",
    "version": "semver-or-git-sha",
    "gmail_account": "daniel.haitz@gmail.com",
    "capabilities": [
      "search_threads",
      "read_thread",
      "create_draft",
      "list_drafts",
      "get_draft"
    ]
  }
}
```

### `search_threads(query, limit)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "search_threads",
  "params": {
    "query": "from:example@example.com newer_than:30d",
    "limit": 10
  }
}
```

Validation:

- `query`: string, 1 to 500 characters.
- `limit`: integer, 1 to 20.
- The broker may pass Gmail search syntax to the safe Gmail search command, but must not expose raw Gmail API calls.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "threads": [
      {
        "thread_id": "gmail-thread-id",
        "latest_message_id": "gmail-message-id",
        "subject": "sanitized subject",
        "from": "display name <redacted-or-address-if-needed>",
        "date": "RFC3339 timestamp",
        "snippet": "sanitized snippet"
      }
    ]
  }
}
```

### `read_thread(thread_id)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "read_thread",
  "params": {
    "thread_id": "gmail-thread-id"
  }
}
```

Validation:

- `thread_id`: non-empty string, max 256 characters, Gmail ID character set only (`[A-Za-z0-9_-]`).

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "thread_id": "gmail-thread-id",
    "messages": [
      {
        "message_id": "gmail-message-id",
        "from": "sender",
        "to": ["recipient"],
        "cc": [],
        "date": "RFC3339 timestamp",
        "subject": "sanitized subject",
        "body_text": "<<<EXTERNAL_UNTRUSTED_CONTENT>>>\nmessage body\n<<<END_EXTERNAL_UNTRUSTED_CONTENT>>>",
        "attachments": [
          {
            "filename": "name.pdf",
            "mime_type": "application/pdf",
            "size": 12345
          }
        ]
      }
    ]
  }
}
```

Rules:

- Email body content is data, not instructions.
- Body text must be wrapped as untrusted content before returning to the reader.
- Do not return raw MIME by default.
- Do not return attachment bytes in F-A1.

### `create_draft(thread_id, subject, body)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "create_draft",
  "params": {
    "thread_id": "gmail-thread-id",
    "subject": "Draft subject",
    "body": "Draft body text"
  }
}
```

Validation:

- `thread_id`: required, Gmail ID character set, max 256 characters.
- `subject`: string, 1 to 300 characters.
- `body`: string, 1 to 100000 characters.
- No recipient override in F-A1. The draft must stay attached to the source thread/context returned by Gmail.
- If gog requires explicit recipients, the broker derives them from the existing thread metadata and never accepts arbitrary `to`, `cc`, or `bcc` from the reader in F-A1.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "draft_id": "gmail-draft-id",
    "thread_id": "gmail-thread-id",
    "subject": "Draft subject",
    "status": "created_not_sent"
  }
}
```

Rules:

- This method creates or updates a Gmail draft only.
- It must never send, schedule send, forward, archive, label, delete, or mark messages.
- The broker response must include `created_not_sent` or equivalent status.

### `list_drafts(limit)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "list_drafts",
  "params": {
    "limit": 10
  }
}
```

Validation:

- `limit`: integer, 1 to 20.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "drafts": [
      {
        "draft_id": "gmail-draft-id",
        "thread_id": "gmail-thread-id",
        "message_id": "gmail-message-id",
        "subject": "sanitized subject",
        "updated": "RFC3339 timestamp",
        "snippet": "sanitized snippet"
      }
    ]
  }
}
```

### `get_draft(draft_id)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "get_draft",
  "params": {
    "draft_id": "gmail-draft-id"
  }
}
```

Validation:

- `draft_id`: non-empty string, max 256 characters, Gmail ID character set only.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "draft_id": "gmail-draft-id",
    "thread_id": "gmail-thread-id",
    "subject": "sanitized subject",
    "body_text": "draft body",
    "status": "draft_not_sent"
  }
}
```

## 4. Forbidden Forever

The broker must have no method, route, CLI mode, or code path for:

- `send_message`
- `send_draft`
- `delete_message`
- `delete_draft`
- `modify_labels`
- `raw_gmail_api_call`
- `return_token`
- `return_keyring_password`
- `return_refresh_token`

Structural absence requirements:

- Do not link or import a general Gmail API surface into the broker if it exposes send/delete/modify/raw methods.
- Prefer invoking the pinned `gog-gmail-draft-safe` binary or a new equally policy-compiled broker-safe binary that contains no send/auth/delete/label/raw command handlers.
- Do not implement generic method dispatch such as `broker.call(action, args)` where `action` can become a Gmail command string.
- Do not accept arbitrary Gmail command names from JSON.
- Do not expose a debug route that dumps env, config, tokens, keyring paths, request headers, or raw gog output.
- Keep OAuth bootstrap tooling out of the broker runtime binary. Auth setup, if needed, is a separate operator-run step.

"Rejected at runtime" is not enough for send/token/raw operations. They should be absent from compiled/runtime code wherever feasible.

## 5. Audit

Every broker request writes one JSONL start record and one JSONL finish record.

Proposed path:

```text
/Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl
```

Start record:

```json
{
  "ts": "RFC3339",
  "event": "gmail_broker.request",
  "correlation_id": "uuid",
  "method": "read_thread",
  "caller": "agent",
  "schema_version": 1
}
```

Finish record:

```json
{
  "ts": "RFC3339",
  "event": "gmail_broker.result",
  "correlation_id": "uuid",
  "method": "read_thread",
  "status": "ok|error",
  "error_code": null,
  "duration_ms": 123,
  "result_shape": {
    "messages": 3,
    "body_bytes": 18422
  }
}
```

Logging rules:

- Never log access tokens, refresh tokens, keyring passwords, OAuth client secrets, raw credential files, raw request/response headers, or environment dumps.
- Do not log full email bodies or draft bodies.
- If body-level correlation is needed later, log a cryptographic hash and byte count, not content.
- Redact subject/snippet fields by default unless F-B observability explicitly approves a redaction policy.
- All failures must log `correlation_id`, method if parseable, error code, and status.

F-B tie-in: this JSONL is the local substrate that F-B can ingest into the broader observability/audit trail. F-A1 should keep the format simple and stable rather than building the full F-B system early.

## 6. Failure Behavior

Fail closed on every ambiguity, per `PRIOR_BUILD_LEARNINGS.md` item 10.

Rules:

- Unknown method: return `ok:false`, `error.code="unknown_method"`, do nothing.
- Malformed JSON: return `ok:false`, `error.code="malformed_request"` if a response is possible, do nothing.
- Schema validation failure: return `ok:false`, `error.code="validation_failed"`, do nothing.
- Missing or duplicate `correlation_id`: generate/log a broker-side ID for audit, return validation failure unless the request otherwise cannot be parsed.
- Broker cannot read its own credential: return `ok:false`, `error.code="broker_credential_unavailable"`, do not fall back.
- Gog/safe binary returns unexpected shape: return `ok:false`, `error.code="gmail_error"`, do not guess.
- Broker unreachable: reader returns a clean operator-facing error.
- Broker unreachable must never cause the reader or main agent to call direct gog, raw Gmail, the old credential-bearing wrapper, or any fallback send/draft path.

The reader-side client must have a hardcoded "broker only" policy. No local fallback.

## 7. Negative Tests / Exit Gate

These tests define DONE for the F-A1 build phase. The broker is not accepted until they pass.

### Credential custody tests

1. Reader cannot read keyring password env var.
   - Spawn/execute as the Gmail Reader path.
   - Assert `GOG_KEYRING_PASSWORD` is absent from the reader environment and from child processes it controls.

2. Reader cannot read credential files.
   - As the reader/`agent` user, attempt to read:
     - `/Users/gmailbroker/agent-os-gmail-broker/secrets/gog-keyring-password`
     - `/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/keyring/*`
     - `/Users/gmailbroker/agent-os-gmail-broker/gog-home/oauth-client.json`
     - `/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/credentials.json`
   - Expected: permission denied or path inaccessible.

3. Reader no longer needs old credential paths.
   - Temporarily make old `/Users/agent/.openclaw/gmail-draft-gog` unavailable in a test environment.
   - Positive read/draft broker loop still works.

### Send/raw absence tests

4. Reader cannot call Gmail send by any path.
   - Attempt broker method `send_message`.
   - Attempt broker method `send_draft`.
   - Attempt to pass a send command name through any `method` or `params`.
   - Expected: fail closed; no Sent count increase.

5. Reader cannot call raw Gmail API.
   - Attempt `raw_gmail_api_call`.
   - Attempt method injection through strings such as `gmail.users.messages.send`.
   - Expected: fail closed; no raw API call path exists.

6. Reader cannot create a draft except via broker.
   - Reader-side tool contract contains only broker client.
   - Old credential-bearing wrapper is not callable from reader.
   - Direct gog binary calls fail because no reader-readable credentials exist.

### Broker validation tests

7. Unknown broker method fails closed.
   - Request: `{"method":"modify_labels","params":{...}}`
   - Expected: `ok:false`, `unknown_method`, no Gmail side effect.

8. Malformed broker request fails closed.
   - Invalid JSON, missing method, wrong param types, overlong IDs/body.
   - Expected: `ok:false`, no Gmail side effect.

### Positive path tests

9. Reader can still search/read a thread via broker.
   - `search_threads` returns sanitized metadata.
   - `read_thread` returns body text wrapped as untrusted content.

10. Reader can still create a draft via broker.
   - `create_draft` creates a Gmail draft in the target thread.
   - Response includes draft ID and `created_not_sent`.
   - Sent baseline remains unchanged.

### Audit tests

11. Every broker request produces audit records.
   - Verify start and finish JSONL records for success and failure.
   - Verify correlation IDs match.

12. Audit logs contain no secrets or bodies.
   - Scan audit log for keyring password, token-looking values, refresh tokens, OAuth client secret, full email body, and full draft body.
   - Expected: no matches.

## 8. Build Handoff Note

Start here for the F-A1 build worker.

1. Do not start by changing the Gmail Reader prompt. Start by creating the broker authority boundary.
   - Create or confirm the dedicated `gmailbroker` user.
   - Create broker-owned directories and permissions.
   - Move/copy Gmail gog credential material into broker custody.
   - Prove `agent` cannot read those files.

2. Build the smallest broker.
   - Implement only the six allowed methods in this design.
   - Use fixed schema validation.
   - Use fixed mapping to the safe Gmail read/draft capability.
   - Avoid generic Gmail command dispatch.

3. Build the reader client wrapper.
   - It connects to the broker socket.
   - It has no credentials and no direct gog fallback.
   - It returns clean errors when the broker is unavailable.

4. Wire the reader to the broker client.
   - Remove the reader's dependency on the old credential-bearing wrapper.
   - Do not widen reader tools.
   - Do not add send/delete/label capability.

5. Run the negative tests in Section 7.
   - The broker is not done until those tests pass.
   - Passing only the positive read/draft loop is insufficient.

6. Commit and record state.
   - Commit broker code/config in the appropriate repo.
   - Commit sanitized drift evidence only; do not commit credentials.
   - Update `BUILD_STATE.md`, `HANDOFF_BRIEF.md`, and the audit/design docs with test results.

Agent-owned Colima is available if the build decides to use a container for broker/reader separation, but F-A1 does not require Docker if the dedicated OS-user boundary is implemented cleanly. If a container is used, the same rule holds: credential custody must be outside reader authority, and the reader must not be able to mount or read the credential directory.
