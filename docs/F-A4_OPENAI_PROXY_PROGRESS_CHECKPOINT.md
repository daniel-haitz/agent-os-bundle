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
- Rollback scenario fixture: `7/7 PASS`.
- Static deployment manifest prepared.
- Static cutover package prepared.
- Zero production mutation verified.
- Independent adversarial review completed for published ref `67ac296`.

## Current F-A4 Substatus

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY PRODUCTION SUBSTRATE READY: NO-GO`
- `OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `F-A4 STATUS: OPEN`

Rollback scenario fixtures are not executable production rollback proof.

## Active Blockers

- Exact production topology unresolved.
- Real temporary Colima substrate proof not completed.
- OpenClaw containment placement unresolved.
- UID/GID mapping inside Colima unresolved.
- Local-token path and traversal permissions unresolved.
- Actual upstream-key custody path not installed.
- Executable credential migration not implemented.
- Executable rollback not implemented.
- Actual network enforcement not implemented.
- Gmail, Telegram, and Ollama network matrix not proved.
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

Build and run a temporary, isolated Colima/internal-network substrate proof using fixture containers and temporary networks only.

The proof must:

- prove the OpenClaw-side fixture can reach only the proxy;
- prove the OpenClaw-side fixture cannot directly reach OpenAI hostname, direct IP, or IPv6;
- prove the proxy fixture alone can reach the approved synthetic upstream;
- prove the proxy cannot reach arbitrary destinations;
- prove DNS, SNI/TLS, and restart behavior at the actual container-network layer where possible;
- verify host-network mode is not used;
- record UID/GID and mount behavior;
- tear down all temporary resources;
- change no live OpenClaw state, credentials, launchd services, `pf`, production proxy policy, or production network.

Do not run operator cutover dry-run or production cutover.
