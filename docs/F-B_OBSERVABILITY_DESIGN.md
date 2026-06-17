# F-B Observability Substrate — Design

**Status:** Design only. No live wiring. Query scripts in `scripts/observability/` run against
the existing broker audit log but do not touch any running service.

**Derived from:** broker source `src/gmail-broker/gmail-broker.mjs` (lines 290–688),
roadmap brief Theme 3, and the F-A1 exit-gate test runs (known log content).
Broker audit log read required `sudo -u gmailbroker` (agent cannot read directly);
schema below is derived from source code and verified against known test output.

---

## A. Canonical Event Schema

### A.1 What the broker emits today

The broker's `audit()` function (line 290) writes newline-delimited JSON to
`/Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl`. Three event types:

**`gmail_broker.request`** — emitted at the start of every dispatch:
```json
{
  "ts": "2026-06-16T21:13:29.669Z",
  "event": "gmail_broker.request",
  "correlation_id": "uuid-or-caller-provided",
  "method": "create_draft",
  "schema_version": 1
}
```

**`gmail_broker.result`** — emitted at the end of every dispatch (success or error):
```json
{
  "ts": "2026-06-16T21:13:30.102Z",
  "event": "gmail_broker.result",
  "correlation_id": "uuid-or-caller-provided",
  "method": "create_draft",
  "status": "ok",
  "error_code": null,
  "duration_ms": 433,
  "result_shape": {
    "draft_id_present": true,
    "idempotent": false
  }
}
```
On error: `"status": "error"`, `"error_code": "unknown_method"|"validation_failed"|"gmail_error"|"malformed_request"|"broker_credential_unavailable"`, `"result_shape": null`.

**`gmail_broker.idempotent_hit`** — emitted when a cached draft is returned:
```json
{
  "ts": "2026-06-16T21:14:45.003Z",
  "event": "gmail_broker.idempotent_hit",
  "correlation_id": "uuid-or-caller-provided",
  "method": "create_draft",
  "draft_id": "r-3116648602232828200",
  "thread_id_hash": "1a2b3c4d"
}
```

### A.2 Canonical event shape (F-B superset)

The following is the TARGET schema. Fields marked ✓ already exist in broker
output; fields marked GAP are missing today.

```json
{
  "ts": "2026-06-16T21:13:29.669Z",       // ✓ present (broker field: "ts")
  "schema_version": 1,                     // ✓ present on request events only; GAP on result/idempotent_hit
  "event": "gmail_broker.result",          // ✓ present — maps to event_type
  "correlation_id": "run-abc123...",       // ✓ present — maps to correlation_id
  "phase": "F-A1",                         // GAP — which foundation phase emitted this event
  "agent": "gmail-broker",                 // GAP — component identifier
  "method": "create_draft",               // ✓ present — maps to method_or_tool
  "policy_decision": "allow",             // GAP — see mapping below
  "result": {                              // ✓ partial — broker has result_shape + status
    "status": "ok",
    "shape": { "draft_id_present": true, "idempotent": false }
  },
  "duration_ms": 433,                     // ✓ present on result events; GAP on request/idempotent_hit
  "operator_notified": false,             // GAP — was the operator informed of this result?
  "secret_redaction_applied": false       // GAP — were any secret fields redacted before logging?
}
```

### A.3 `policy_decision` field mapping

The broker today conflates "policy decision" with outcome. This table derives
the canonical value from existing fields:

| `status` | `error_code`                      | `policy_decision` |
|----------|-----------------------------------|-------------------|
| ok       | null                              | `allow`           |
| error    | `unknown_method`                  | `deny`            |
| error    | `validation_failed`               | `validation_failed` |
| error    | `malformed_request`               | `deny`            |
| error    | `gmail_error`                     | `gmail_error`     |
| error    | `broker_credential_unavailable`   | `fail`            |

The query scripts use this mapping to derive `policy_decision` from existing logs.

### A.4 Gap summary for current broker events

| Required field          | Broker today              | Gap?            |
|-------------------------|---------------------------|-----------------|
| `ts`                    | `ts` ✓                    | —               |
| `schema_version`        | `schema_version` (request only) | partial   |
| `event` (event_type)    | `event` ✓                 | —               |
| `correlation_id`        | `correlation_id` ✓        | —               |
| `phase`                 | absent                    | **GAP**         |
| `agent`                 | absent                    | **GAP**         |
| `method` (method_or_tool)| `method` ✓               | —               |
| `policy_decision`       | derivable from status+error_code | partial    |
| `result`                | `result_shape` + `status` ✓ | —             |
| `duration_ms`           | `duration_ms` (result only) ✓ | —            |
| `operator_notified`     | absent                    | **GAP**         |
| `secret_redaction_applied` | absent               | **GAP**         |

**Backward compatibility:** Existing broker logs conform to the F-B superset by
omission — the canonical schema does not remove or rename any existing field.
Adding `phase`, `agent`, `policy_decision`, `operator_notified`, and
`secret_redaction_applied` to the broker's `audit()` call is a pure addition.

---

## B. Event Type Taxonomy

Complete list of events required for run reconstructability. For each: which
component emits it, and whether that component exists yet.

### B.1 System / run lifecycle

| Event type                  | Component      | Exists? | Notes |
|-----------------------------|----------------|---------|-------|
| `system.run_started`        | main agent     | **NO**  | Born when Telegram request received. Carries run_id. |
| `system.run_completed`      | main agent     | **NO**  | Final success state. |
| `system.run_failed`         | main agent     | **NO**  | Final failure state. Must always accompany operator notification. |
| `system.operator_notified`  | main agent     | **NO**  | Delivery confirmation of Telegram reply. Closes the silent-failure loop. |

### B.2 Orchestration / delegation

| Event type                        | Component  | Exists? | Notes |
|-----------------------------------|------------|---------|-------|
| `orchestrator.delegation_started` | main agent | **NO**  | Emitted when gmail-reader is spawned. Carries run_id and task type. |
| `orchestrator.delegation_result`  | main agent | **NO**  | Reader returned; captures output shape and success/fail. |
| `orchestrator.delegation_failed`  | main agent | **NO**  | Reader did not return within budget or errored. |

### B.3 Broker (Gmail capability layer)

| Event type                   | Component    | Exists? | Notes |
|------------------------------|--------------|---------|-------|
| `gmail_broker.request`       | broker       | **YES** ✓ | Emitted at dispatch start. |
| `gmail_broker.result`        | broker       | **YES** ✓ | Emitted at dispatch end (ok or error). |
| `gmail_broker.idempotent_hit`| broker       | **YES** ✓ | Emitted on idempotency cache hit. |

### B.4 Policy / validation

| Event type                         | Component    | Exists? | Notes |
|------------------------------------|--------------|---------|-------|
| `broker.method_denied`             | broker       | partial | Captured as `gmail_broker.result` with `error_code=unknown_method`. No distinct event type. |
| `broker.validation_failed`         | broker       | partial | Captured as `gmail_broker.result` with `error_code=validation_failed`. |
| `broker.credential_fail`           | broker       | partial | Captured as `gmail_broker.result` with `error_code=broker_credential_unavailable`. |
| `research_handoff.request`         | reader       | **NO**  | F-A3. Reader emits research request to researcher. |
| `research_handoff.validated`       | validator    | **NO**  | F-A3. Schema validator accepted the request. |
| `research_handoff.denied`          | validator    | **NO**  | F-A3. Validator rejected (potential injection). |

### B.5 Egress

| Event type       | Component       | Exists? | Notes |
|------------------|-----------------|---------|-------|
| `egress.allowed` | egress enforcer | **NO**  | F-A4. Outbound request permitted by allowlist. |
| `egress.denied`  | egress enforcer | **NO**  | F-A4. Outbound request blocked. CRITICAL event — must trigger operator notification. |

### B.6 Draft / action

| Event type             | Component | Exists? | Notes |
|------------------------|-----------|---------|-------|
| `draft.created`        | broker    | partial | Subsumed in `gmail_broker.result` for `create_draft` with `status=ok`. No distinct type. |
| `draft.idempotent`     | broker    | partial | Subsumed in `gmail_broker.idempotent_hit`. |

---

## C. Correlation-ID Propagation Spec

### C.1 Where correlation_id is BORN today

At the broker (line 616–619 of `gmail-broker.mjs`):
```javascript
const corrId =
  typeof request?.correlation_id === "string" && request.correlation_id.length > 0
    ? request.correlation_id   // caller-provided
    : randomUUID();            // broker-generated fallback
```

The broker accepts an inbound `correlation_id` and uses it; otherwise generates
a fresh UUID per request. The `gmail-broker-client.mjs` passes through whatever
`correlationId` the caller provides to `callBroker()`, or generates its own
`randomUUID()` if absent (line 17–19 of the client).

The CLI entry point added in F-A2 calls `callBroker(method, params)` without a
`correlationId` argument — so every CLI call today uses a broker-generated UUID.

### C.2 Where correlation_id STOPS today

The correlation_id is born and dies in the broker. It appears in:
- The audit log (both request and result events)
- The socket response (`{ correlation_id, ok, result }`)
- The reader's stdout (via the CLI)

It does NOT appear in:
- Any main-agent log
- Any Telegram request
- Any delegation context
- The researcher's context

### C.3 The propagation gap

```
Telegram request
      │
      │  [NO run_id born here]
      ▼
main agent
      │
      │  [NO run_id passed in delegation]
      ▼
gmail-reader
      │
      │  [NO correlation_id passed to CLI]
      ▼
gmail-broker-client.mjs CLI
      │
      │  callBroker(method, params)  ← no corrId
      ▼
broker socket
      │
      │  randomUUID() generated HERE  ← run context is lost
      ▼
audit log  [N orphan UUIDs, one per broker call, unconnected to the run]
```

### C.4 Target propagation (spec, no wiring)

```
Telegram request received
  → run_id = first 16 hex chars of SHA-256(msg_id + ts)
  → emit: system.run_started { correlation_id: run_id }
      │
      │  run_id in delegation context
      ▼
gmail-reader spawned
  → reads run_id from delegation context (e.g. env var AGENT_RUN_ID)
      │
      │  passes run_id as correlation_id to broker CLI
      ▼
gmail-broker-client.mjs CLI
  → node gmail-broker-client.mjs search_threads {...} --correlation-id $AGENT_RUN_ID
      │
      ▼
broker socket
  → uses caller-provided correlation_id (already accepted, no code change needed)
      │
      ▼
audit log  [all broker events share run_id → full trace reconstructable]
```

### C.5 What each component needs to add (spec, no code now)

| Component                     | Change needed |
|-------------------------------|---------------|
| Main agent                    | Generate `run_id` on Telegram request receipt; pass in delegation context |
| Reader AGENTS.md / runtime    | Read `AGENT_RUN_ID` from env or delegation context; pass to broker CLI |
| `gmail-broker-client.mjs` CLI | Accept `--correlation-id <id>` flag; pass to `callBroker()` |
| Broker server                 | No change needed — already accepts caller correlation_id |
| Researcher                    | Same as reader — receive run_id, pass through any sub-calls |

---

## D. Silent-Failure Queries

Queries are in `scripts/observability/`. Each accepts a log-file path argument
or reads from stdin.

**To run against the live broker log (requires gmailbroker privileges):**
```bash
sudo -u gmailbroker node /Users/agent/agent-os/scripts/observability/q1-silent-failures.mjs \
  /Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl
```
Or pipe:
```bash
sudo -u gmailbroker cat /Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl \
  | node /Users/agent/agent-os/scripts/observability/q1-silent-failures.mjs -
```

The five queries and their current status against the broker's existing log:

| Query | Script | Answerable today? |
|-------|--------|-------------------|
| Q1: Did any run fail without notifying the operator? | `q1-silent-failures.mjs` | Partial — lists broker errors; cannot verify notification delivery (system.operator_notified not yet emitted) |
| Q2: Did any broker call lack a correlation_id? | `q2-orphan-correlations.mjs` | Yes — verifies every event has a non-null correlation_id |
| Q3: Did any run start without a matching run_completed/run_failed? | `q3-unclosed-runs.mjs` | No — system.run_started not yet emitted; returns 0 + gap explanation |
| Q4: Did any egress denial occur? | `q4-egress-denials.mjs` | No — F-A4 not yet implemented; returns 0 + explicit "egress enforcement not active" warning |
| Q5: Did any draft get created outside the broker? | `q5-out-of-band-drafts.mjs` | Partial — enumerates broker-created drafts; cannot detect out-of-band without Gmail API comparison |

---

## E. Gap Table

What F-B can verify TODAY vs what requires future instrumentation:

### E.1 Verifiable today (broker events)

| Property | Query | Confidence |
|----------|-------|------------|
| Every broker request has a response | Q2 (request/result pairing) | HIGH |
| Every broker event has a correlation_id | Q2 | HIGH |
| Broker error events enumerated | Q1 | HIGH |
| All broker-created drafts listed | Q5 | HIGH |
| Broker errors by type (unknown_method / validation_failed / gmail_error) | Q1 | HIGH |
| Idempotent hit count and draft IDs | Q5 | HIGH |
| Broker request latency distribution | derived from duration_ms | HIGH |

### E.2 Not yet verifiable (requires future components)

| Property | Blocking requirement | When available |
|----------|----------------------|----------------|
| End-to-end run trace | Main agent emits system.run_started/completed/failed | After F-A3/F-B wiring |
| Silent failure detection (confirmed) | system.operator_notified events | After main agent wired |
| Run-level correlation (Telegram → broker) | run_id propagation through delegation | After C.4 spec implemented |
| Research handoff injection detection | research_handoff.validated/denied events | F-A3 |
| Egress denial detection | egress.allowed/denied events | F-A4 |
| Out-of-band draft detection (definitive) | Gmail API comparison or exclusive broker path proof | F-A2 Part 2 + egress |
| Unclosed run detection | system.run_started with TTL-based open-run check | After F-A3/F-B wiring |

### E.3 The V1 milestone gap

The roadmap's V1 specification is "30 days daily use, trustworthy audit trails,
zero silent failures." Against the current state:

- **Trustworthy audit trail:** Broker events are append-only JSONL with structured
  schema. HIGH confidence for broker layer. Zero for system/orchestration layer.
- **Zero silent failures:** Cannot be a queryable property until `system.operator_notified`
  events are emitted. Currently: broker errors are visible in the log but delivery
  confirmation is absent.
- **Run reconstructability:** Impossible today — no run_started/completed events,
  no correlated delegation events, all broker calls are orphaned UUIDs.

F-B is complete when Q1–Q5 all return real answers (not "not yet emitted"). That
requires the components in E.2 to emit their events with `correlation_id` propagated
from the run's born `run_id`.
