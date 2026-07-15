# F-A1 Gmail Capability Broker Design

Status: BROKER FOUNDATION IMPLEMENTED, EXIT GATE CLOSED, AND FOUNDATION HARDENED. Broker closed its 25/25 exit gate on 2026-06-16; durable socket-directory startup ordering was completed and revalidated on 2026-07-14. This status covers the broker's authority, semantic API, credential custody, and approved client path. It does not claim exclusive Gmail routing: a separate Codex Apps Gmail connector surface was confirmed on 2026-07-14 and remains an open F-A4 containment blocker. `CONTROL.md` is authoritative for live state.

Purpose: make Gmail read/draft access structural instead of cooperative. F-A0 proved the Gmail reader currently runs `exec` as Unix user `agent` and can reach the gog keyring, keyring password, wrapper source, and gog config. The broker must move both credential custody and the Gmail action surface outside reader authority.

Non-goal: this does not solve poisoned summaries, search exfiltration, malicious draft content, or egress. Sensitive data remains held until the full F-A0 through F-D gate passes.

## Implemented hardening record (2026-07-14)

- Root-run `ai.agent-os.gmail-broker-rundir` creates `/var/run/agent-os` as `gmailbroker:gmailbroker-clients` mode `0750` before broker startup.
- Unprivileged `ai.agent-os.gmail-broker` remains `UserName=gmailbroker`; its `KeepAlive` is conditional on `PathState[/var/run/agent-os]=true`, closing the independent launchd startup race without widening permissions or changing the broker boundary.
- Live socket is `gmailbroker:gmailbroker-clients` mode `0660`.
- Both launchd plists pass `plutil -lint`; broker is loaded/running; `health_check` and `search_threads` pass; direct main execution remains per-run approval-gated and denial blocks it.
- Rollback backup: `/Library/LaunchDaemons/ai.agent-os.gmail-broker.plist.backup-20260714T203520Z`.
- Boundary qualification: read-only audit found synchronized `codex_apps__gmail` / `mcp__codex_apps__gmail*` tools outside the broker. No live connector call was made during the audit, but broker-only Gmail confinement remains open until that external surface is disabled and negative-tested.

## 1. Placement & Process Model

### Required authority boundary

The broker MUST NOT run as Unix user `agent`.

Reason: F-A0 found the reader has same-UID `exec` authority as the current Gmail credential files. A same-host process under the same user would not close the hole; the reader could still read files, inspect wrapper source, run alternate child processes, or reach same-UID credential material.

Implemented design target:

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

The OpenClaw Gateway runs as `openclawgw`; the broker is a separate local service under `gmailbroker` with a narrow capability API.

### Reader-to-broker channel

Preferred channel: Unix domain socket.

- Socket path: `/var/run/agent-os/gmail-broker.sock`
- Directory owner/group: `gmailbroker:gmailbroker-clients`
- Directory mode: `0750`.
- Socket owner: `gmailbroker`
- Socket mode: `0660`
- Socket group: a dedicated group such as `gmailbroker-clients` containing `agent`, or equivalent launchd-supported ACL.

Why a socket is acceptable: the socket is not a credential path. A compromised reader may be able to call the broker, but the broker exposes only fixed semantic Gmail capabilities and never returns tokens, keyring passwords, refresh tokens, or raw Gmail API access.

Fallback channel if Unix socket permissions are operationally awkward: localhost HTTP bound to `127.0.0.1` on a fixed high port plus a broker-client bearer token stored under the `agent` user. This token is not a Gmail credential. It authorizes only the same fixed broker methods. Prefer the socket because filesystem permissions are simpler to audit than another bearer token.

### Reader integration surface

The reader's current approved execution path calls the root-owned client wrapper:

```text
/Users/agent/.openclaw/scripts/gmail-broker-client.mjs
```

The historical `/usr/local/libexec/agent-os/` path is not the current authority path for this baseline unless later live exec-approval evidence proves otherwise.

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

Retrospective scope note (2026-07-14): the original 25/25 gate proved the broker implementation, credential boundary, and approved reader client. It did not inventory Codex Apps/remote connector surfaces. The later boundary audit found a direct Gmail connector outside the broker, so the F-A1 broker gate remains closed while the broader claim "broker is the only Gmail route" remains open under F-A4.

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

## 8. Historical build handoff — completed

The original build sequence created the dedicated `gmailbroker` authority, migrated credential custody, built the six-method broker, installed the credential-free client, wired the reader, and closed the negative-test gate. Do not re-run that sequence or recreate its users, credentials, directories, or services.

Current live state and the next bounded task are maintained in `CONTROL.md`. The remaining direct Codex Apps Gmail connector is outside this broker implementation and is tracked as an F-A4 containment blocker; removing it must not widen or redesign the broker.
