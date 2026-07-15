# CONTROL.md — Agent OS Current Control State

## Mandatory operator gate

Every human or AI operator must read these mandatory control documents before acting:

- `OPERATING_CONSTITUTION.md`
- `docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md`

## External-agent onboarding gate

A fresh external AI agent receiving only the public raw bundle URL must first follow `docs/AGENT_ONBOARDING_PROTOCOL.md`.

That protocol does not create a second current-state authority. `CONTROL.md` remains authoritative for accepted current state, phase status, blockers, and approved next action.

Live runtime evidence is authoritative for observed facts. `CONTROL.md` records the accepted current state, phase status, blockers, next actions, and verification gates.

No document, including `CONTROL.md`, can create authority that does not exist in live enforcement boundaries.

Durable architecture decisions and technical requirements are recorded in `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md`.
Security obligations that must not disappear during refactoring are tracked in `docs/AGENT_OS_OBLIGATION_REGISTER.md`.

If live state, `CONTROL.md`, or canonical architecture conflict, stop mutation and reconcile them before proceeding.

## Current state

- Documentation baseline before this reconciliation: `351d51afe6ac83afbde7b7a1977d6bd54a0c0c5a`.
- Installed OpenClaw version last verified on 2026-07-14 by live runtime evidence: `OpenClaw 2026.6.11 (e085fa1)`.
- This is the current runtime baseline reconciliation. Runtime changes require reconciliation according to the Change Control Standard.
- OpenClaw `2026.7.1` is not installed or qualified.
- Gateway runs under dedicated OS user `openclawgw` through root LaunchDaemon `ai.openclaw.gateway`.
- Root-owned OpenClaw configuration and approval controls remain part of the F-A4 tamper boundary.
- Current safe network baseline:
  - Gateway running.
  - Managed proxy block removed.
  - pf containment not active.
- Managed proxy and pf integration were previously proven but have not completed permanent acceptance, persistence, and reboot validation.
- Gmail broker foundation is operational:
  - Broker runs as `gmailbroker`.
  - Gmail credentials remain in broker custody.
  - `/var/run/agent-os` is `gmailbroker:gmailbroker-clients 0750`.
  - Gmail broker socket is `gmailbroker:gmailbroker-clients 0660`.
  - Broker `health_check` and `search_threads` succeed.
  - Approved broker client path is `/Users/agent/.openclaw/scripts/gmail-broker-client.mjs`.
  - Direct main broker execution requires per-run approval, and denial blocks execution.
- Gmail credential recovery is governed by `docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md`. Any restoration must return credentials to broker custody only. Restoring agent-readable credentials reopens the Gmail security boundary and requires architecture review.
- Broker-only Gmail mediation is not proven. A synchronized Codex Apps Gmail connector remains a confirmed bypass risk outside the broker.
- The approved Gmail broker path is draft-only/no-send proven. System-wide no-send is not proven while external connector surfaces remain.
- Current model assignment evidence is recorded in ADR-013: `gmail-reader` uses `ollama/qwen3-coder:30b`; `email-researcher` uses `openai/gpt-5.5`.
- F-A4 foundation hardening validation evidence is recorded in `audits/F-A4-foundation-hardening-validation.md`. F-A4 is not closed.
- The selected F-A4 remediation path is operator-owned repair and validation without weakening the root-owned OpenClaw tamper lock:
  - `scripts/fa4-operator-egress-proxy-repair.sh`
  - `scripts/fa4-operator-readonly-validation.sh`
- 2026-07-15 build-lead execution attempt from the non-privileged `agent` context could not run the repair harness because sudo requires an interactive operator password. This is an execution-context boundary, not a bypass target.
- 2026-07-15 operator evidence confirmed the egress proxy can run as `egressproxy:egressproxy`, listen on `127.0.0.1:13128`, allow `chatgpt.com` CONNECT, deny `example.com` CONNECT with `403`, and record both decisions in `proxy.jsonl`.
- The egress proxy repair harness had a confirmed launchd bootout/bootstrap race: immediate bootstrap after bootout could fail with `Bootstrap failed: 5: Input/output error`, while a later manual bootstrap succeeded. The harness correction is prepared and syntax-tested; pf integration and full read-only validation remain pending.
- The external-agent onboarding and session-bootstrap repair is a bounded governance/tooling correction. It does not change F-A4 architecture, phase status, or runtime authority.
- F-A3 evidence is indexed through the root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts plus the F-A4 cutover runbook's F.3 gate. This index does not change F-A3 closure status.
  - Evidence location: root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts; `docs/F-A4_CUTOVER_RUNBOOK.md` F.3 gate
  - Validation date: original validation date pending reconstruction from historical validation artifacts.
  - Runtime baseline: OpenClaw `2026.6.5`.
  - Status: Historical evidence; pending bounded regression on `2026.6.11 (e085fa1)` before F-A4 closure.
- Sensitive-data, autonomous-memory, Command Center mutation, and consequential-action expansion remain on hold.

## Phase evidence index

- F-A0 Platform hardening audit:
  - Evidence location: `audits/F-A0-platform-hardening-audit.md`
  - Validation date: 2026-06-16 remediation re-audit, with historical baseline evidence from 2026-06-12
  - Runtime baseline: OpenClaw `2026.6.5 (5181e4f)` for original evidence; current reconciled runtime baseline is `2026.6.11 (e085fa1)` and requires bounded regression before F-A4 closure.
  - Status: Historical evidence remains accepted for its original boundary; bounded regression is required on `2026.6.11 (e085fa1)` before F-A4 closure.
- F-A1 Gmail capability broker:
  - Evidence location: `audits/F-A1-negative-test-results.md`, `docs/F-A1_GMAIL_BROKER_DESIGN.md`, `docs/F-A1_DEPLOY_LIST.md`
  - Validation date: 2026-06-16 broker exit gate; socket hardening revalidated 2026-07-14
  - Runtime baseline: original broker gate on prior OpenClaw baseline; live broker/socket/client path reconciled on OpenClaw `2026.6.11 (e085fa1)`.
  - Status: Broker exit gate closed; exclusive Gmail routing remains an F-A4 gate.
  - F-A1 validation: 25/25 broker exit-gate tests passed in `audits/F-A1-negative-test-results.md` on 2026-06-16; original runtime baseline predates `2026.6.11`, with socket/client-path reconciliation recorded on 2026-07-14.
- F-A2 Reader credential containment:
  - Evidence location: `docs/F-A2_PROOF_RUNBOOK.md`, `docs/F-A4_CUTOVER_RUNBOOK.md` F.2 gate
  - Validation date: evidence linkage pending reconstruction from historical validation artifacts.
  - Runtime baseline: evidence linkage pending reconstruction from historical validation artifacts; current runtime baseline is OpenClaw `2026.6.11 (e085fa1)`.
  - Status: Provisional pending evidence reconstruction; do not treat F-A2 as newly validated on `2026.6.11` until bounded regression evidence is recorded.
- F-A3 Typed handoff:
  - Evidence location: root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts; `docs/F-A4_CUTOVER_RUNBOOK.md` F.3 gate
  - Validation date: original validation date pending reconstruction from historical validation artifacts.
  - Runtime baseline: OpenClaw `2026.6.5`.
  - Status: Historical evidence; pending bounded regression on `2026.6.11 (e085fa1)` before F-A4 closure.

## Open verification gates

- B1 direct Gmail connector bypass: active blocker `B1`; required Gmail complete-mediation gate.
- B2 permanent proxy and pf integration: active blocker `B2`; required F-A4 containment gate.
- B3 DNS, IPv6, and alternate-transport coverage: active blocker `B3`; required F-A4 containment gate.
- B4 OpenClaw 2026.7.1 qualification: active blocker `B4`; required OpenClaw qualification gate after F-A4 transport reconciliation.
- B5 foundation evidence and durable evidence substrate: active blocker `B5`; required F-B/F-C gates and phase evidence index.
- B6 native validation and runtime-identity regression gaps: active blocker `B6`; required F-A4 foundation validation path.
- Obligation register: unresolved obligations in `docs/AGENT_OS_OBLIGATION_REGISTER.md` must remain classified, owned, referenced, and evidenced.
- Runtime validation: OpenClaw `2026.6.11 (e085fa1)` bounded regression for F-A1/F-A2/F-A3 must be completed and evidence recorded before F-A4 closure.

## Phase status

Completed phases remain closed unless new evidence invalidates prior exit criteria. Discovery of adjacent risks creates a new blocker or change proposal; it does not automatically reopen completed work.

Research findings do not automatically authorize implementation changes.

Research produces proposals. Implementation changes require explicit approval, scoped execution, validation, and documentation reconciliation.

| Phase | Status | Current meaning |
|---|---|---|
| F-A0 Platform hardening audit | CLOSED | Baseline platform hardening exit criteria passed. Revalidation is required after relevant upgrades or boundary changes. |
| F-A1 Gmail capability broker | BROKER EXIT GATE CLOSED | Broker capability, credential custody, socket initialization, and approved client path are proven. Exclusive Gmail routing is a separate gate. |
| F-A2 Reader credential containment | PROVISIONAL PENDING EVIDENCE RECONSTRUCTION | Reader credential custody boundary is historically closed, but closure evidence linkage is pending reconstruction. Reader does not possess Gmail credentials. This does not prove complete Gmail mediation. |
| F-A3 Typed handoff | CLOSED | Main-to-researcher handoff is schema validated and fail-closed. |
| F-A4 Complete mediation and egress | IN BUILD — REMEDIATION PACKAGE PREPARED; NOT CLOSED | 2026-07-15 foundation validation evidence captured. Broker and direct handoff checks passed. Operator-owned egress proxy repair and read-only validation scripts are prepared, but native audit/secrets/sandbox checks, egress proxy, pf evidence, stale launchd version metadata, and runtime-identity regression remain open until operator execution records evidence. |
| OpenClaw 2026.7.1 qualification | PENDING | Qualification follows Gmail connector containment and F-A4 transport reconciliation and precedes F-B/F-C implementation. |
| F-B Observability substrate | DESIGN RECONCILED; IMPLEMENTATION PENDING | Adopt qualified native audit while retaining boundary evidence and adding correlation, delivery evidence, alerts, retention, and coverage reconciliation. |
| F-C Action governance | DESIGN RECONCILED; IMPLEMENTATION PENDING | Use native approvals with a minimal semantic action catalog and deterministic semantic-action enforcement. Unknown actions deny. |
| F-D Generalized dispatch/confirm split | PENDING | Must inherit completed F-A, F-B, and F-C enforcement. |
| Memory autonomy | HOLD | Autonomous promotion is prohibited until the memory-governance gate passes. |
| Capability expansion and Command Center | HOLD | No expansion until applicable foundation gates pass. |
| Financial, administrative, and sensitive workflows | HOLD — LAST | Require additional domain-specific action, approval, recovery, and evidence gates. |

## Phase closure limits

Closed phases remain closed only for the specific properties proven by their exit gates.

- F-A0 proves the baseline platform hardening checks that were validated at closure. It does not prove future OpenClaw versions, plugins, connectors, MCP servers, host updates, or ownership changes preserve the same boundary.
- F-A1 proves the Gmail broker capability foundation, broker-owned credential path, socket initialization, and approved client path. It does not prove exclusive Gmail mediation or absence of connector bypasses.
- F-A2 proves reader-side Gmail credential containment. It does not prove complete exfiltration prevention, OS-level isolation between OpenClaw logical agents, or absence of external Gmail bypasses.
- F-A3 proves typed handoff validation and fail-closed schema handling. It does not prove semantic safety of all content, researcher isolation as an OS principal, or complete prompt-injection resistance.
- F-A4, when closed, proves only the documented mediation and egress controls for the validated runtime state. It does not prove OpenClaw logical agent identities are OS security principals, that gateway-readable secrets are inaccessible to the gateway, or that future plugins, MCP servers, connectors, or apps are safe.

OpenClaw agent identities provide workflow and configuration separation. They must not be represented as OS-level isolation unless live runtime evidence proves separate OS users, process boundaries, permissions, and inaccessible credential paths.

## Active blockers

### B1 — Direct Gmail connector bypass

A synchronized `codex_apps__gmail` / `mcp__codex_apps__gmail*` surface exists outside the approved Gmail broker contract.

Complete Gmail mediation remains open until the surface is disabled for OpenClaw agents and proven unavailable after restart and connector synchronization.

Desktop Codex Gmail access and OpenAI authentication must remain unchanged unless separately approved.

### B2 — Permanent proxy and pf integration

The managed proxy and pf wall are not active in the current safe baseline.

Permanent acceptance, persistence, failure-recovery, and reboot validation remain required.

### B3 — DNS, IPv6, and alternate-transport coverage

The prior pf design did not prove containment across all practical egress paths.

F-A4 must reconcile and validate DNS, IPv4, IPv6, direct-IP, alternate-resolver, TCP, UDP, and QUIC behavior before closure.

### B4 — OpenClaw 2026.7.1 qualification

The installed `2026.6.11` runtime does not expose `openclaw audit`. Its bundled Policy plugin exists but is disabled.
`openclaw security audit --json` is the available security-audit interface for this baseline. The current loopback-only Gateway finding is accepted only while the Gateway is not exposed through a reverse proxy or other external listener.

Version `2026.7.1` requires staged qualification because it changes audit, Codex Apps, approvals, plugins, networking, and recovery surfaces.

### B5 — Foundation evidence

F-B and F-C remain blocked until their enforcement and evidence gates are implemented and validated.

### B6 — Native validation and runtime-identity regression gaps

`audits/F-A4-foundation-hardening-validation.md` captured partial F-A4 foundation evidence on 2026-07-15.

Native OpenClaw audit/secrets/sandbox validation failed from the non-privileged `agent` context because the locked runtime configuration is not readable. The egress proxy can run and enforce allow/deny behavior after operator bootstrap, but the repair harness reload race required correction before it could be treated as repeatable tooling. pf inspection requires an operator-owned read-only validation path. Launchd metadata still reports `OPENCLAW_SERVICE_VERSION=2026.6.5` while the live binary reports `2026.6.11 (e085fa1)`.

F-A4 closure remains blocked until these gaps are remediated or validated through the approved F-A4 operator path without weakening the root-owned tamper lock. The approved path is:

1. Repair/re-run the egress proxy installation with the corrected `scripts/fa4-operator-egress-proxy-repair.sh`.
2. Capture read-only native audit, sandbox, pf, broker, and regression evidence with `scripts/fa4-operator-readonly-validation.sh`.
3. Reconcile the captured evidence into `audits/F-A4-foundation-hardening-validation.md`.

The operator scripts follow the reusable Agent OS operator-action pattern: preflight checks, evidence output, rollback guidance, and validation output.

## Next actions

### Immediate bounded action

Run the prepared F-A4 operator repair/validation path and reconcile the captured evidence without weakening the root-owned tamper lock.

Required results:

1. Native OpenClaw security/secrets/sandbox validation runs through an approved read-only path.
2. The unsupported `openclaw doctor --security` requirement is replaced by the supported `2026.6.11` command surface: `security audit --json`, `security audit --deep --json`, `doctor --lint --json`, `secrets audit --json`, and `sandbox explain --json`.
3. `openclaw secrets audit` no longer fails on `/Users/agent/.openclaw/npm/projects`, or the failure is source-backed as irrelevant to security validation.
4. Corrected egress proxy repair harness runs repeatably, and proxy/pf evidence is captured through the approved operator path.
5. Launchd `OPENCLAW_SERVICE_VERSION` metadata is reconciled with live OpenClaw `2026.6.11 (e085fa1)`.
6. F-A1/F-A2/F-A3 bounded regression is executed for the actual gateway/runtime identity where required by the F-A4 cutover gate.

### Locked sequence after the immediate action

1. Validate broker reliability remains intact: socket directory persistence, ownership, and client path match the hardened live baseline.
2. Prove broker workflow: confined Gmail broker health/search succeeds and durable audit evidence exists.
3. Disable the confirmed Codex Apps Gmail connector surface for OpenClaw agents and prove broker-only Gmail access.
4. Reconcile and approve the F-A4 DNS, IPv6, and alternate-transport design.
5. Reapply the managed proxy and pf containment.
6. Complete bounded OpenClaw `2026.6.11 (e085fa1)` regression for F-A1, F-A2, and F-A3 and record evidence before F-A4 closure.
7. Complete F-A4 acceptance, persistence, failure-recovery, reboot validation, and minimal durable evidence validation.
8. Snapshot OpenClaw state and prove rollback.
9. Qualify OpenClaw `2026.7.1`.
10. Re-prove F-A1 through F-A4 after qualification.
11. Implement the reconciled F-B observability substrate.
12. Implement minimum F-C action governance.
13. Generalize the dispatch/confirm split under F-D.
14. Begin supervised capability expansion only after all applicable gates pass.

Do not reorder this sequence without explicit architecture approval.

## Verification gates

### Gmail complete-mediation gate

- Approved broker operations succeed.
- Gmail credentials remain exclusively in broker custody.
- Direct Gmail connectors and alternate Gmail clients are unavailable to OpenClaw agents.
- No fallback path restores direct Gmail access.
- Direct main broker execution remains approval-gated.
- Denial blocks execution.
- Results survive restart and connector synchronization.

### F-A4 containment gate

- Enforcement remains owned outside the contained Gateway identity.
- Approved network paths work.
- Unapproved network paths fail closed across required address families and transports.
- Broker, Telegram, and approved web operations continue to work.
- Decisions appear in authoritative logs.
- Enforcement survives service restart and host reboot.
- Rollback is documented and proven.
- Minimal durable evidence exists before closure: persistent logs, ownership-controlled evidence storage, retention longer than the validation window, and proof that validation events can be found after service restart and host reboot.

### OpenClaw qualification gate

- Pre-upgrade inventory, snapshot, and rollback proof exist.
- Configuration, approvals, plugins, apps, MCP servers, tools, and connectors are compared.
- Ownership and permission boundaries remain intact.
- F-A1 through F-A4 regression tests pass.
- Native-audit coverage and limitations are measured.
- Approval failure and replay tests fail closed.
- Restart, reboot, and rollback tests pass.

### F-B observability gate

- Runs are correlated end to end.
- Every security-relevant event has an identified authoritative evidence source.
- Terminal outcomes and delivered operator notification are observable.
- Missing events and audit silence are detectable.
- Sensitive content capture remains disabled.
- Retention exceeds the trust-measurement window.
- Native audit is not treated as proof of complete mediation or tamper evidence.

### F-C action-governance gate

- Every effectful operation uses a registered semantic action.
- Unknown actions deny.
- Approval binds to the exact action and expires safely.
- The action is revalidated immediately before execution.
- High-risk actions cannot gain durable approval.
- Interrupted or retried actions cannot duplicate effects.
- No model, memory, UI, prompt, or caller can bypass the enforcement point.

### Memory-autonomy gate

- The memory-governance requirements in `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` are implemented.
- External content cannot autonomously become action-authorizing memory.
- Automated memory processes cannot raise authority.
- Stale, contradictory, malicious, truncated, and revoked-memory tests pass.

### Capability-expansion gate

- Applicable F-A through F-D gates are closed.
- Gather and act paths are structurally separated.
- Effectful operations use registered semantic actions.
- Credential custody and egress are explicitly bounded.
- Positive, negative, injection, replay, restart, and recovery tests pass.
- Documentation is reconciled before commit.
