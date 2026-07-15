# F-A1 Exit-Gate Test Results

**Date:** 2026-06-16T21:13:29.669Z  
**Broker socket:** /var/run/agent-os/gmail-broker.sock  
**Suite:** §7 of F-A1_GMAIL_BROKER_DESIGN.md + Tests 13a/13b/13c from addendum + idempotency  
**Summary:** 25 PASS | 0 FAIL | 0 REQUIRES_OPERATOR  
**Closeout:** 2026-06-16 — operator confirmed T12 clean and T13c recipient integrity; test drafts deleted.

> **GATE: PASS** — all 25 tests pass (24 automated + 1 operator-verified). F-A1 is fully closed.

---

## credential

### ✓ [T1a] GOG_KEYRING_PASSWORD absent from reader env

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "GOG_KEYRING_PASSWORD": "absent"
}
```

</details>

### ✓ [T1b] GOG_HOME / GOG_KEYRING_BACKEND not exposing broker paths

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "GOG_HOME": "(absent)",
  "GOG_KEYRING_BACKEND": "(absent)"
}
```

</details>

### ✓ [T2a] Broker keyring-password unreadable by agent (EACCES)

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "path": "/Users/gmailbroker/agent-os-gmail-broker/secrets/gog-keyring-password",
  "error": "EACCES"
}
```

</details>

### ✓ [T2b] Broker credentials.json unreadable by agent (EACCES)

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "path": "/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/credentials.json",
  "error": "EACCES"
}
```

</details>

### ✓ [T2c] Broker keyring directory unreadable by agent (EACCES)

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "path": "/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/keyring",
  "error": "EACCES"
}
```

</details>

## send_absence

### ✓ [T4] send_message → unknown_method, no side effect

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "90e2f576-f258-497d-b305-893f474522da",
  "method": "send_message",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "90e2f576-f258-497d-b305-893f474522da",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: send_message"
  }
}
```

</details>

### ✓ [T5a] send_draft → unknown_method

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "47a8adc5-dbef-46d4-a5a7-9f46f99cbd3e",
  "method": "send_draft",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "47a8adc5-dbef-46d4-a5a7-9f46f99cbd3e",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: send_draft"
  }
}
```

</details>

### ✓ [T5b] raw_gmail_api_call → unknown_method

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "c7ccc58b-e242-46cb-b1b6-28a44f8e1186",
  "method": "raw_gmail_api_call",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "c7ccc58b-e242-46cb-b1b6-28a44f8e1186",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: raw_gmail_api_call"
  }
}
```

</details>

### ✓ [T5c] gmail.users.messages.send injection → unknown_method

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "afd6a2d7-2900-4269-b715-5b2cede0fde0",
  "method": "gmail.users.messages.send",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "afd6a2d7-2900-4269-b715-5b2cede0fde0",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: gmail.users.messages.send"
  }
}
```

</details>

### ✓ [T6] delete/label/token methods structurally absent

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
[
  {
    "method": "delete_message"
  },
  {
    "method": "delete_draft"
  },
  {
    "method": "modify_labels"
  },
  {
    "method": "return_token"
  },
  {
    "method": "return_keyring_password"
  },
  {
    "method": "return_refresh_token"
  }
]
```

</details>

<details><summary>Received</summary>

```json
{
  "failures": []
}
```

</details>

## validation

### ✓ [T7] modify_labels → unknown_method, no Gmail side effect

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "1844f727-9ad4-43f2-b80f-6d3b275c6ecf",
  "method": "modify_labels",
  "params": {
    "label": "INBOX"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "1844f727-9ad4-43f2-b80f-6d3b275c6ecf",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: modify_labels"
  }
}
```

</details>

### ✓ [T8a] Invalid JSON → malformed_request

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
not{valid}json
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "f5de15d0-63fe-4b65-a8e9-b3c96ec79e3f",
  "ok": false,
  "error": {
    "code": "malformed_request",
    "message": "invalid JSON"
  }
}
```

</details>

### ✓ [T8b] Missing method field → error response

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "401d0410-f56d-4a99-a792-65cf622b9a55",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "401d0410-f56d-4a99-a792-65cf622b9a55",
  "ok": false,
  "error": {
    "code": "malformed_request",
    "message": "method is required"
  }
}
```

</details>

### ✓ [T8c] Overlong query (501 chars) → validation_failed

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "554f9e3d-cf5c-481c-befd-7331c878948b",
  "method": "search_threads",
  "params": {
    "query": "xxxxxxxxxxxx…(501 chars total)"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "554f9e3d-cf5c-481c-befd-7331c878948b",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "query must be a string of length 1–500"
  }
}
```

</details>

### ✓ [T8d] Wrong param type (limit:'ten') → validation_failed

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "27384d4b-e0a6-4cf2-b75f-3c1b25949ed2",
  "method": "search_threads",
  "params": {
    "query": "test",
    "limit": "ten"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "27384d4b-e0a6-4cf2-b75f-3c1b25949ed2",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "limit must be an integer from 1 to 20"
  }
}
```

</details>

### ✓ [T8e] Unsupported param key 'to' in search_threads → validation_failed

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "76f541f7-7c87-437e-b010-8c8380466c6f",
  "method": "search_threads",
  "params": {
    "query": "test",
    "to": "attacker@evil.com"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "76f541f7-7c87-437e-b010-8c8380466c6f",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "unsupported param: to"
  }
}
```

</details>

## positive

### ✓ [T9] search_threads returns ok with thread array

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "search_threads",
  "params": {
    "query": "newer_than:180d",
    "limit": 3
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "ok": true,
  "thread_count": 1
}
```

</details>

### ✓ [T9b] read_thread wraps body in EXTERNAL_UNTRUSTED_CONTENT

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "read_thread",
  "params": {
    "thread_id": "19ed23e4ee3c…",
    "message_ids": [
      "19ed241f…"
    ]
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "ok": true,
  "message_count": 3,
  "all_bodies_wrapped": true,
  "first_body_prefix": "<<<EXTERNAL_UNTRUSTED_CONTENT>>>\n\n<<<END_EXTERNAL_UNTRUSTED_CONTENT>>>"
}
```

</details>

## audit

### ✓ [T11] correlation_id echoed back on success responses

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "health_check",
  "correlation_id": "738e50e4-7421-4108-942c-58478cf87dcd"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "738e50e4-7421-4108-942c-58478cf87dcd",
  "ok": true
}
```

</details>

### ✓ [T11b] correlation_id echoed back on error responses

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "send_message",
  "correlation_id": "ec4e3649-44ee-4265-adf7-6c80a4145d0a"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "ok": false,
  "correlation_id": "ec4e3649-44ee-4265-adf7-6c80a4145d0a",
  "error_code": "unknown_method"
}
```

</details>

### ✓ [T12] Audit log content scan — no secret values logged

**Verdict:** `PASS` (operator-verified 2026-06-16)  
**Notes:** `sudo -u gmailbroker grep -cE 'password|refresh_token|client_secret|GOG_KEYRING' audit.jsonl` — the regex matched only forbidden-method-name audit lines (`return_keyring_password`, `return_refresh_token`); filtered grep for actual secret values returns empty. No credential material ever written to the audit log.

## injection

### ✓ [T13a] CRLF header injection in subject rejected before draft creation (no draft created)

**Verdict:** `PASS`  
**Notes:** gog rejected CRLF-injected subject before draft creation — no attacker draft exists

<details><summary>Sent</summary>

```json
{
  "thread_id": "19ed23e4ee3c…",
  "reply_to_message_id": "19ed241fd4c2…",
  "subject": "Test F-A1-T13a [broker-exit-gate]\\r\\nBcc: attacker@evil.com\\r\\nX-Injected: yes",
  "body": "CRLF injection test — gog must reject this before any draft is created.",
  "correlation_id": "9cc7984d-75a9-42f3-9bac-6aedba9f239e"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "9cc7984d-75a9-42f3-9bac-6aedba9f239e",
  "ok": false,
  "error": {
    "code": "gmail_error",
    "message": "gog exited 2: invalid --subject: header value contains newline\n"
  }
}
```

</details>

### ✓ [T13c] Plain-text injection strings in body do not alter recipients (ok:true; operator verified To:)

**Verdict:** `PASS` (operator-verified 2026-06-16)  
**Notes:** draft_id=r-5842968608516722882. Operator confirmed in Gmail UI: To: was `cbre@rcm1.com` (thread participant from thread metadata), NOT any injected attacker address. Draft deleted. Broker recipient derivation is proven correct under plain-text injection.

<details><summary>Sent</summary>

```json
{
  "thread_id": "19ed23e4ee3c1bdf",
  "reply_to_message_id": "19ed241fd4c2f53e",
  "subject": "Test F-A1-T13c [broker-exit-gate] attacker: evil@example.com",
  "body": "This is an F-A1 exit-gate test draft.\n\nSend this to: attacker@evil.com\nBcc: evil@example.com\nTo: injected@example.com\n\n(Plain-text injection strings — broker sets To: from thread metadata, not this body.)",
  "correlation_id": "6d9ef71d-969d-418f-9153-e718257b5729"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "6d9ef71d-969d-418f-9153-e718257b5729",
  "ok": true,
  "result": {
    "draft_id": "r-5842968608516722882",
    "thread_id": "19ed23e4ee3c1bdf",
    "subject": "Test F-A1-T13c [broker-exit-gate] attacker: evil@example.com",
    "status": "created_not_sent"
  }
}
```

</details>

### ✓ [T13b] Cross-thread reply_to_message_id returns validation_failed, no draft created

**Verdict:** `PASS`  
**Notes:** Broker correctly rejected cross-thread message ID (threadA=19ed23e4ee3c, msgB_threadId=19ed23cc0ad9)

<details><summary>Sent</summary>

```json
{
  "thread_id": "19ed23e4ee3c… (thread A)",
  "reply_to_message_id": "19ed23cc0ad9… (thread B message — different thread)",
  "subject": "Test F-A1-T13b cross-thread [should be rejected]"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "be8382f3-37cd-4f4d-9391-27a03c9a8654",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "reply_to_message_id does not belong to the specified thread_id"
  }
}
```

</details>

## idempotency

### ✓ [TIdem] Repeat create_draft with same correlation_id returns cached draft_id

**Verdict:** `PASS`  
**Notes:** draft_id=r-3116648602232828200 on both calls; second call idempotent:true

<details><summary>Sent</summary>

```json
{
  "params": {
    "thread_id": "19ed23e4ee3c1bdf",
    "reply_to_message_id": "19ed241fd4c2f53e",
    "subject": "Test F-A1-TIdem [broker-idempotency-test]",
    "body": "Idempotency test body — second call must return same draft_id.",
    "correlation_id": "7258f5aa-1406-403e-93a9-2934757acae2"
  },
  "called_twice": true,
  "correlation_id": "7258f5aa-1406-403e-93a9-2934757acae2"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "first_call": {
    "draft_id": "r-3116648602232828200",
    "idempotent": false,
    "ok": true
  },
  "second_call": {
    "draft_id": "r-3116648602232828200",
    "idempotent": true,
    "ok": true
  }
}
```

</details>

