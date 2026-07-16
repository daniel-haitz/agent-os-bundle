# F-A4 OpenAI Proxy Progress Checkpoint

## Governing Rules

- `CONTROL.md` is authoritative for accepted current state, blockers, and next action.
- `OPERATING_CONSTITUTION.md` and `docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md` govern conduct.
- Live runtime evidence is authoritative for observed facts.
- Historical handoff/status documents are context only.
- Do not claim F-A4 closure from partial evidence.

## Runtime Baseline

- Installed OpenClaw baseline: `2026.6.11 (e085fa1)`.
- Gateway identity: `openclawgw`.
- Gmail broker identity: `gmailbroker`.
- OpenAI credential broker identity: `openai-credential-broker` (`uid=540`, `gid=740`).
- `pf` remains disabled and must not be enabled by the OpenAI proxy package workstream.

## Current Phase

- Phase: `F-A4 Complete mediation and egress`.
- Status: `OPEN`.
- Production OpenAI proxy cutover: not authorized.

## Completed Evidence

- Exact OpenAI Responses transport feasibility is proven for `openai/gpt-5.5`.
- Forwarding-proxy architecture direction is approved.
- Proxy HTTP/security fixture: `39/39 PASS`.
- Live OpenAI credential and route inventory is complete.
- Synthetic contained-egress fixture: `23/23 PASS`.
- Real temporary Colima/internal-network substrate proof: `GO`.
- Rollback scenario fixture: `7/7 PASS`.
- Production transaction dry-run package exists, but independent review rejected it as a production implementation.
- Credential-migration, residue-scan, and rollback fixtures are synthetic/fixture evidence only.
- Architecture alternatives review completed in `audits/F-A4-openai-proxy-architecture-alternatives.md`.
- Formal reduced-objective risk acceptance recorded in `docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md`.
- Static deployment manifest prepared.
- Static cutover package prepared.
- Zero production mutation verified.
- Independent adversarial review completed for published ref `67ac296`.

## Current F-A4 Substatus

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY SUBSTRATE PROOF (TEMPORARY FIXTURES): HISTORICAL EVIDENCE`
- `F-A4 SECURITY OBJECTIVE: FORMALLY REDUCED WITH RESIDUAL RISK ACCEPTED`
- `OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: REQUIRES REVISION`
- `OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED`
- `F-A4 STATUS: OPEN`

Rollback scenario fixtures and the transaction fixture suite are not executable production rollback proof.

## Active Blockers

- Revised-objective transaction and executable rollback package has not been implemented.
- The former structural-denial requirement for every possible direct OpenAI network connection from a fully compromised host Gateway is moved to future hardening.
- Local-token implementation must use the ADR-016 two-file identity-owned model.
- Actual upstream-key custody path not installed.
- Actual production proxy is not installed.
- Production OpenClaw routing is not changed.
- Live credential migration is not executed.
- Cold-start and reboot not proved.
- Real production cutover not authorized.

## Superseded Approaches

- File-backed SecretRef for the real OpenAI static key.
- Exec-backed SecretRef resolver for the real OpenAI static key.
- OpenClaw validator patch as the OpenAI credential-custody solution.

## Latest Publication Baseline Entering Reduced-Objective Decision

- Private commit entering this decision pass: `610be2bf5a97c50ae60170737bb4b96c8156f072`.
- Published ref entering this decision pass: `6e5cbf9 @ 2026-07-16T21:41:50Z`.

## Approved Next Action

Implement the revised-objective proxy transaction and executable rollback package, with production execution still disabled.

Do not perform production execution, operator dry-run, production cutover, credential migration, or runtime changes from this step.
