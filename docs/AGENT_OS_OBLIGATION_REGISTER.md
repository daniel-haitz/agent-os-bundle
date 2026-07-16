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
| OpenAI key plaintext custody flag | Open | F-A4 credential custody governance | `docs/ADR-015_OPENAI_CREDENTIAL_PROXY.md`, `docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md`, and `docs/F-A4_OPENAI_PROXY_CUTOVER_PACKAGE.md` | Operator inventory in `audits/F-A4-openai-proxy-production-inventory.json` records one direct OpenAI credential source. The reduced objective requires the real credential to move out of OpenClaw-readable state during a later authorized cutover. |
| OpenAI proxy production cutover execution | Open | F-A4 egress governance | `docs/F-A4_OPENAI_PROXY_CUTOVER_PACKAGE.md`, `audits/F-A4-openai-proxy-architecture-reconciliation.md`, `audits/F-A4-openai-proxy-architecture-alternatives.md`, and `docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md` | ADR-016 formally accepts residual compromised-Gateway direct-network risk and moves full structural OpenAI egress denial to future hardening. Live production cutover, cold-start, reboot, executable rollback, and regression evidence remain open and unauthorized. |
| Gmail recovery passphrase escrow posture | Open | Gmail recovery governance | `docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md` | Recovery runbook records operator-held-only passphrase custody and explicitly defers operational escrow changes. |
| OpenClaw Security and Release Monitoring | Open | Platform maintenance governance | `docs/F-A4_CUTOVER_RUNBOOK.md` — Native OpenClaw Security Baseline Validation | OpenClaw evolves rapidly; Agent OS requires recurring validation of security advisories, runtime upgrades, and breaking changes before qualification or closure claims. |
