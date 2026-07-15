# Agent OS Obligation Register

## Purpose

Prevent security-critical obligations from disappearing during document refactoring, compression, or publication changes.

Every obligation is classified as:

- Closed
- Moved
- Retired
- Superseded

No silent deletion is allowed.

## Initial Migration Table

| Obligation | Status | Owner | Canonical Reference | Evidence |
|---|---|---|---|---|
| Aquaman source audit + native SecretRef comparison | Moved | Phase 6 secrets governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — Security obligation register references | `docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md` records ADOPT-PENDING-VERIFY and source-audit/native-SecretRef comparison requirement. |
| ClawGuard source review before audit trust | Moved | F-B observability governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — Security obligation register references | `docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md` records ADOPT-PENDING-VERIFY before audit integrity reliance. |
| Browser fill tool-side secret resolution | Moved | Phase 6 secrets governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — Security obligation register references | `docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md` and `docs/OPENCLAW_BUILD_PLAN.md` record the browser-fill SecretRef verification gate. |
| OpenAI key plaintext custody flag | Moved | F-A4 credential custody governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — Security obligation register references | `docs/F-A4_LOCK_2B_0READ_CREDENTIAL_CUSTODY.md` and ADR-013 record gateway-readable credential implications and model-assignment constraints. |
| Gmail recovery passphrase escrow posture | Moved | Gmail recovery governance | `docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md` | Recovery runbook records operator-held-only passphrase custody and explicitly defers operational escrow changes. |
