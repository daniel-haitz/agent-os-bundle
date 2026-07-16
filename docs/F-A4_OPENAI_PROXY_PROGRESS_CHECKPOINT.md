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
- Static deployment manifest prepared.
- Static cutover package prepared.
- Zero production mutation verified.
- Independent adversarial review completed for published ref `67ac296`.

## Current F-A4 Substatus

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY SUBSTRATE PROOF (TEMPORARY FIXTURES): GO`
- `OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: PARTIAL`
- `OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED`
- `F-A4 STATUS: OPEN`

Rollback scenario fixtures and the transaction fixture suite are not executable production rollback proof.

## Active Blockers

- Contained OpenClaw model-network placement decision is invalid as written and must be reopened.
- Installed OpenClaw `2026.6.11` does not expose a supported model-network sidecar/worker boundary for moving only provider transport into containment while the host Gateway remains authoritative.
- Gmail broker host Unix-socket boundary is not compatible with the rejected contained component without a separately reviewed bridge or socket-mount design.
- Host Ollama loopback routes for `heartbeat` and `gmail-reader` are not compatible with a host-escape-denied contained component without a separately reviewed narrow bridge.
- Local-token single-file design is invalid as written for both `openclawgw` and proxy UID `540`.
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

## Latest Publication Baseline

- Private commit entering this reconciliation: `cfd66dcdea6149f286b640ea6478120e40a9505e`.
- Published ref entering this reconciliation: `0fcde94 @ 2026-07-16T20:06:19Z`.

## Approved Next Action

Reopen the OpenAI proxy placement decision and produce a bounded architecture alternative that preserves the proven host OpenClaw Gateway, host Gmail broker Unix-socket boundary, and host Ollama loopback routes while still structurally denying direct OpenAI egress from the process that performs OpenAI model transport.
