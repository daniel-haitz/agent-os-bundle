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
- Static deployment manifest prepared.
- Static cutover package prepared.
- Zero production mutation verified.
- Independent adversarial review completed for published ref `67ac296`.

## Current F-A4 Substatus

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY PRODUCTION SUBSTRATE PROOF: GO`
- `OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `F-A4 STATUS: OPEN`

Rollback scenario fixtures are not executable production rollback proof.

## Active Blockers

- Production transaction is not implemented.
- Executable credential migration is not implemented.
- Executable rollback is not implemented.
- Actual upstream-key custody path not installed.
- Actual production proxy is not installed.
- Production OpenClaw routing is not changed.
- Gmail, Telegram, and Ollama regression must be run during later cutover readiness.
- Cold-start and reboot not proved.
- Real production cutover not authorized.

## Superseded Approaches

- File-backed SecretRef for the real OpenAI static key.
- Exec-backed SecretRef resolver for the real OpenAI static key.
- OpenClaw validator patch as the OpenAI credential-custody solution.

## Latest Publication Baseline

- Private commit entering this reconciliation: `fd54990b7be304ee58ebd2e1992e78ebfd222b9e`.
- Published ref entering this reconciliation: `67ac296 @ 2026-07-16T17:11:12Z`.

## Approved Next Action

Implement the production transaction and executable rollback package for the contained OpenAI proxy path.

The next action may create scripts, manifests, fixtures, dry-run tooling, and rollback tooling. It must not perform production cutover.

The package must follow the substrate proof decision:

- OpenClaw model-network execution runs inside a contained component on an internal Docker/Colima network.
- The OpenAI proxy is a separate contained component dual-homed between the OpenClaw-side network and a constrained upstream egress network.
- Host OpenClaw may orchestrate but must not originate direct OpenAI HTTP traffic after F-A4 closure.
- The local token must not be placed under `/Users/openai-credential-broker/.../local-token/` unless parent traversal and custody are separately proved.
