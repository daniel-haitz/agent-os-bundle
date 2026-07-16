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
| OpenAI key plaintext custody flag | Open | F-A4 credential custody governance | `docs/ADR-015_OPENAI_CREDENTIAL_PROXY.md` and `docs/F-A4_OPENAI_PROXY_CUTOVER_PACKAGE.md` | Operator inventory in `audits/F-A4-openai-proxy-production-inventory.json` records one direct OpenAI credential source. The proxy package has static readiness and synthetic proof only; the real credential remains in OpenClaw until a later authorized cutover. |
| OpenAI proxy production substrate proof | Open | F-A4 egress governance | `docs/F-A4_OPENAI_PROXY_CUTOVER_PACKAGE.md` and `deploy/openai-proxy/openai-proxy-deployment-manifest.json` | Independent review of published ref `67ac296` found actual Colima networking, container DNS, IPv4/IPv6 denial, direct-IP denial, host-network escape resistance, restart persistence, and proxy-only upstream access unproved. |
| Gmail recovery passphrase escrow posture | Open | Gmail recovery governance | `docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md` | Recovery runbook records operator-held-only passphrase custody and explicitly defers operational escrow changes. |
| OpenClaw Security and Release Monitoring | Open | Platform maintenance governance | `docs/F-A4_CUTOVER_RUNBOOK.md` — Native OpenClaw Security Baseline Validation | OpenClaw evolves rapidly; Agent OS requires recurring validation of security advisories, runtime upgrades, and breaking changes before qualification or closure claims. |
