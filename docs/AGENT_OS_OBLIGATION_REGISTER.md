# Agent OS Obligation Register

## Purpose

Prevent security-critical obligations from disappearing during document refactoring, compression, or publication changes.

Allowed statuses:

- Open
- Closed
- Moved
- Retired
- Superseded

Rules:

- Open requires owner, canonical reference, and evidence or tracking location.
- Closed requires completion evidence.
- Moved requires a destination canonical reference.
- Retired requires approval rationale.
- Superseded requires an ADR or canonical replacement reference.

No silent deletion is allowed.

## Initial Migration Table

| Obligation | Status | Owner | Canonical Reference | Evidence |
|---|---|---|---|---|
| Aquaman source audit + native SecretRef comparison | Open | Phase 6 secrets governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — OpenClaw Native Capability Reconciliation | `docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md` records ADOPT-PENDING-VERIFY and source-audit/native-SecretRef comparison requirement. |
| ClawGuard source review before audit trust | Open | F-B observability governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — Security obligation register references | `docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md` records ADOPT-PENDING-VERIFY before audit integrity reliance. |
| Browser fill tool-side secret resolution | Open | Phase 6 secrets governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — OpenClaw Native Capability Reconciliation | `docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md` and `docs/OPENCLAW_BUILD_PLAN.md` record the browser-fill SecretRef verification gate. |
| OpenAI key plaintext custody flag | Open | F-A4 credential custody governance | `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` — Security obligation register references | `docs/F-A4_LOCK_2B_0READ_CREDENTIAL_CUSTODY.md` and ADR-013 record gateway-readable credential implications and model-assignment constraints. |
| Gmail recovery passphrase escrow posture | Open | Gmail recovery governance | `docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md` | Recovery runbook records operator-held-only passphrase custody and explicitly defers operational escrow changes. |
| OpenClaw Security and Release Monitoring | Open | Platform maintenance governance | `docs/F-A4_CUTOVER_RUNBOOK.md` — Native OpenClaw Security Baseline Validation | OpenClaw evolves rapidly; Agent OS requires recurring validation of security advisories, runtime upgrades, and breaking changes before qualification or closure claims. |
