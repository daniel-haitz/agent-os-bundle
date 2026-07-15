# AGENT OS — STATE BUNDLE FOR CLAUDE
_Generated: 2026-07-15T02:32:45Z · commit: bd1fbf3_

This is a sanitized snapshot for Claude.ai review. Secrets are excluded by .gitignore + scan.

---
## CONTROL.md (current state)
```markdown
# CONTROL.md — Agent OS Current Control State

## Mandatory operator gate

Every human or AI operator must read these mandatory control documents before acting:

- `OPERATING_CONSTITUTION.md`
- `docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md`

Live runtime evidence is authoritative for observed facts. `CONTROL.md` records the accepted current state, phase status, blockers, next actions, and verification gates.

No document, including `CONTROL.md`, can create authority that does not exist in live enforcement boundaries.

Durable architecture decisions and technical requirements are recorded in `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md`.
Security obligations that must not disappear during refactoring are tracked in `docs/AGENT_OS_OBLIGATION_REGISTER.md`.

If live state, `CONTROL.md`, or canonical architecture conflict, stop mutation and reconcile them before proceeding.

## Current state

- Documentation baseline before this reconciliation: `351d51afe6ac83afbde7b7a1977d6bd54a0c0c5a`.
- Installed OpenClaw version last verified on 2026-07-14 by live runtime evidence: `OpenClaw 2026.6.11 (e085fa1)`.
- This is the current runtime baseline reconciliation. It does not reopen F-A0 or F-A3 by itself; revalidation is required only after relevant runtime, boundary, plugin, connector, or configuration changes.
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
- F-A3 evidence is indexed through the root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts plus the F-A4 cutover runbook's F.3 gate. This index does not change F-A3 closure status.
  - Evidence location: root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts; `docs/F-A4_CUTOVER_RUNBOOK.md` F.3 gate
  - Validation date: 2026-07-14 evidence index reconciliation; not a new F-A3 validation
  - Runtime baseline: current reconciled runtime baseline OpenClaw `2026.6.11 (e085fa1)`.
- Sensitive-data, autonomous-memory, Command Center mutation, and consequential-action expansion remain on hold.

## Phase evidence index

- F-A0 Platform hardening audit:
  - Evidence location: `audits/F-A0-platform-hardening-audit.md`
  - Validation date: 2026-06-16 remediation re-audit, with historical baseline evidence from 2026-06-12
  - Runtime baseline: OpenClaw `2026.6.5 (5181e4f)` for original evidence; current reconciled runtime baseline is `2026.6.11 (e085fa1)` and requires bounded regression before F-A4 closure.
- F-A1 Gmail capability broker:
  - Evidence location: `audits/F-A1-negative-test-results.md`, `docs/F-A1_GMAIL_BROKER_DESIGN.md`, `docs/F-A1_DEPLOY_LIST.md`
  - Validation date: 2026-06-16 broker exit gate; socket hardening revalidated 2026-07-14
  - Runtime baseline: original broker gate on prior OpenClaw baseline; live broker/socket/client path reconciled on OpenClaw `2026.6.11 (e085fa1)`.
- F-A2 Reader credential containment:
  - Evidence location: `docs/F-A2_PROOF_RUNBOOK.md`, `docs/F-A4_CUTOVER_RUNBOOK.md` F.2 gate
  - Validation date: evidence linkage pending reconstruction from historical validation artifacts.
  - Runtime baseline: evidence linkage pending reconstruction from historical validation artifacts; current runtime baseline is OpenClaw `2026.6.11 (e085fa1)`.
- F-A3 Typed handoff:
  - Evidence location: root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts; `docs/F-A4_CUTOVER_RUNBOOK.md` F.3 gate
  - Validation date: 2026-07-14 evidence index reconciliation
  - Runtime baseline: current reconciled runtime baseline OpenClaw `2026.6.11 (e085fa1)`.

## Open verification gates

- B1 direct Gmail connector bypass.
- B2 permanent proxy and pf integration.
- B3 DNS, IPv6, and alternate-transport coverage.
- B4 OpenClaw 2026.7.1 qualification.
- B5 Foundation evidence and durable evidence substrate.

## Phase status

Completed phases remain closed unless new evidence invalidates prior exit criteria. Discovery of adjacent risks creates a new blocker or change proposal; it does not automatically reopen completed work.

Research findings do not automatically authorize implementation changes.

Research produces proposals. Implementation changes require explicit approval, scoped execution, validation, and documentation reconciliation.

| Phase | Status | Current meaning |
|---|---|---|
| F-A0 Platform hardening audit | CLOSED | Baseline platform hardening exit criteria passed. Revalidation is required after relevant upgrades or boundary changes. |
| F-A1 Gmail capability broker | BROKER EXIT GATE CLOSED | Broker capability, credential custody, socket initialization, and approved client path are proven. Exclusive Gmail routing is a separate gate. |
| F-A2 Reader credential containment | CLOSED | Reader credential custody boundary is closed. Reader does not possess Gmail credentials. This does not prove complete Gmail mediation. |
| F-A3 Typed handoff | CLOSED | Main-to-researcher handoff is schema validated and fail-closed. |
| F-A4 Complete mediation and egress | IN BUILD | Direct Gmail connector containment, permanent proxy/pf integration, expanded transport coverage, persistence, and reboot validation remain. |
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

## Next actions

### Immediate bounded action

Perform read-only F-A4 prerequisite validation before mutation.

Required results:

1. Installed OpenClaw version is verified from live runtime evidence.
2. Broker script ownership and mode are verified.
3. Main, Gmail reader, and researcher workspace and instruction ownership are verified.
4. `/var/run/agent-os` and Gmail broker socket ownership and mode are verified.
5. Current connector, app, MCP, and tool inventory is captured without invoking Gmail.
6. Any observed drift is documented before mutation.

### Locked sequence after the immediate action

1. Repair any broker reliability issue found in validation, limited to socket directory persistence/race and ownership drift.
2. Prove broker workflow: confined Gmail broker health/search succeeds and durable audit evidence exists.
3. Disable the confirmed Codex Apps Gmail connector surface for OpenClaw agents and prove broker-only Gmail access.
4. Reconcile and approve the F-A4 DNS, IPv6, and alternate-transport design.
5. Reapply the managed proxy and pf containment.
6. Complete F-A4 acceptance, persistence, failure-recovery, reboot validation, and minimal durable evidence validation.
7. Snapshot OpenClaw state and prove rollback.
8. Qualify OpenClaw `2026.7.1`.
9. Re-prove F-A1 through F-A4 after qualification.
10. Implement the reconciled F-B observability substrate.
11. Implement minimum F-C action governance.
12. Generalize the dispatch/confirm split under F-D.
13. Begin supervised capability expansion only after all applicable gates pass.

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
```

## Recent git log (20)
```
bd1fbf3 docs: enforce governance reconciliation and publication controls
5aaec3e chore: restore wrap-up script executable mode
917cf68 docs: establish change control and reconcile agent baseline
c52ef32 docs: refine agent governance boundaries and F-C scope
36bb173 docs: reconcile architecture decisions and operational controls
351d51a docs: add Agent OS operating constitution
69cab30 docs: reconcile Gmail broker and containment state
e39d896 [claude-code] Gmail re-auth DONE (token was dead, re-authed Gmail-scoped, verified live mail); keyring-backend gotcha documented; confined-reader allowlist drift root-caused (real fix next session)
57f7656 [claude-code] F-A4: proxy proven innocent + integrates clean; Gmail root cause = missing refresh token (re-auth needed); Lloyd direct-Gmail bypass found; socket-dir race open
49e8801 [codex] F-A4.5: record proxy relock trap
fd5ccba [codex] F-A4.5: correct Gmail broker root cause
a3d31c3 [codex] F-A4.5: record wall proof and Gmail blockers
1f16a5c [codex] F-A4: record Phase 5 half-1 state
0b973f6 [codex] publish: print bundle freshness reference
551aa14 [codex] F-A4: record recovery state in CONTROL
929e2e0 docs: patch cutover runbook — rollback ownership integrity, cert preflight, inline foundation proofs
191b40c docs: assemble F-A4 gateway re-home cutover runbook (draft, operator-by-hand)
5269c64 docs: patch F-A4 Phase 5 — broker UID gate, broker-read proof, cert check, honest close-out
b37299d docs: draft F-A4 egress wall artifacts
85a2403 docs: draft F-A4 gateway LaunchDaemon plist
```

## Repo tree (no node_modules / .secrets / state)
```
.gitignore
00_START_HERE.md
00_TEARDOWN.md
01_PICK_UP_WORK.md
BUILD_STATE.md
CLAUDE.md
CONTROL.md
HANDOFF_BRIEF.md
ITERATION_LOG.md
OPERATING_CONSTITUTION.md
README.md
SETUP.md
WORKER_PROTOCOL.md
audits/2026-06-12-gmail-connector-discovery.md
audits/2026-06-12-hooks-mechanism-audit.md
audits/2026-06-12-killswitch-test.md
audits/2026-06-12-panic-button-test.md
audits/2026-06-12-pre-phase1-audit.md
audits/2026-06-12-sandbox-killswitch-discovery.md
audits/F-A0-platform-hardening-audit.md
audits/F-A1-negative-test-results.md
docs/ADR-014_OPENCLAW_2026_6_11_BASELINE.md
docs/AGENT_OS_ARCHITECTURE_DECISIONS.md
docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md
docs/AGENT_OS_END_STATE_ARCHITECTURE.md
docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md
docs/AGENT_OS_OBLIGATION_REGISTER.md
docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md
docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md
docs/CANONICAL_PUBLICATION_MANIFEST.md
docs/F-A1_DEPLOY_LIST.md
docs/F-A1_GMAIL_BROKER_DESIGN.md
docs/F-A1_GMAIL_BROKER_DESIGN_ADDENDUM.md
docs/F-A2_PROOF_RUNBOOK.md
docs/F-A4_CUTOVER_RUNBOOK.md
docs/F-A4_LOCK_2A_OWNERSHIP_MAP.md
docs/F-A4_LOCK_2A_VERIFY_EGRESS_LOCK.md
docs/F-A4_LOCK_2B_0READ_CREDENTIAL_CUSTODY.md
docs/F-A4_LOCK_2B_LAUNCHDAEMON_PLIST_DRAFT.md
docs/F-A4_LOCK_PHASE5_EGRESS_WALL_DRAFT.md
docs/F-B_OBSERVABILITY_DESIGN.md
docs/OPENCLAW_BUILD_PLAN.md
docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md
docs/OPENCLAW_DEEP_DIVE_CONFIG.md
docs/OPENCLAW_ECOSYSTEM_AND_COVERAGE.md
docs/OPENCLAW_FIELD_NOTES.md
docs/OPENCLAW_RESEARCH_ADDENDUM.md
docs/PHASE_2_EMAIL_ASSISTANT.md
docs/PRIOR_BUILD_LEARNINGS.md
doctrine/COMMUNICATION_STANDARD.md
doctrine/SESSION_CLOSE_PROTOCOL.md
drafts/fa4-phase5/agent-os-egress-proxy.mjs
drafts/fa4-phase5/agent-os-egress.anchor
drafts/fa4-phase5/ai.agent-os-egress-pf.plist
drafts/fa4-phase5/ai.agent-os-egress-proxy.plist
drafts/fa4-phase5/allowlist.txt
drafts/fa4-phase5/pf.conf.fragment
drafts/fa4-phase5/phase5-proof-commands.sh
scripts/bundle-for-claude.sh
scripts/end-session.sh
scripts/observability/q1-silent-failures.mjs
scripts/observability/q2-orphan-correlations.mjs
scripts/observability/q3-unclosed-runs.mjs
scripts/observability/q4-egress-denials.mjs
scripts/observability/q5-out-of-band-drafts.mjs
scripts/secret-scan.sh
scripts/start-session.sh
scripts/start.sh
scripts/wrap-up.sh
src/gmail-broker/f-a1-test-suite.mjs
src/gmail-broker/gmail-broker.mjs
templates/COMMIT_FORMAT.md
templates/DROP_FORMAT.md
```

## Tests status (last run, if recorded)
```
(no TEST_STATUS.txt — run tests and record)
```

## Open verification gates

---
## Canonical publication manifest
```markdown
# Canonical Publication Manifest

## Purpose

Define the exact canonical files and evidence paths published into the sanitized Claude review bundle.

## Published Root Files

- `CONTROL.md`
- `OPERATING_CONSTITUTION.md`

## Published Docs

- `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md`
- `docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md`
- `docs/AGENT_OS_END_STATE_ARCHITECTURE.md`
- `docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md`
- `docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md`
- `docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md`
- `docs/F-A1_GMAIL_BROKER_DESIGN.md`
- `docs/AGENT_OS_OBLIGATION_REGISTER.md`
- `docs/ADR-014_OPENCLAW_2026_6_11_BASELINE.md`

## Published Evidence

- `audits/`

## Machine-Readable Published Paths

```text
CONTROL.md
OPERATING_CONSTITUTION.md
docs/AGENT_OS_ARCHITECTURE_DECISIONS.md
docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md
docs/AGENT_OS_END_STATE_ARCHITECTURE.md
docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md
docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md
docs/F-A1_GMAIL_BROKER_DESIGN.md
docs/AGENT_OS_OBLIGATION_REGISTER.md
docs/ADR-014_OPENCLAW_2026_6_11_BASELINE.md
audits/
```
```

## Canonical published files

### CONTROL.md
```markdown
# CONTROL.md — Agent OS Current Control State

## Mandatory operator gate

Every human or AI operator must read these mandatory control documents before acting:

- `OPERATING_CONSTITUTION.md`
- `docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md`

Live runtime evidence is authoritative for observed facts. `CONTROL.md` records the accepted current state, phase status, blockers, next actions, and verification gates.

No document, including `CONTROL.md`, can create authority that does not exist in live enforcement boundaries.

Durable architecture decisions and technical requirements are recorded in `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md`.
Security obligations that must not disappear during refactoring are tracked in `docs/AGENT_OS_OBLIGATION_REGISTER.md`.

If live state, `CONTROL.md`, or canonical architecture conflict, stop mutation and reconcile them before proceeding.

## Current state

- Documentation baseline before this reconciliation: `351d51afe6ac83afbde7b7a1977d6bd54a0c0c5a`.
- Installed OpenClaw version last verified on 2026-07-14 by live runtime evidence: `OpenClaw 2026.6.11 (e085fa1)`.
- This is the current runtime baseline reconciliation. It does not reopen F-A0 or F-A3 by itself; revalidation is required only after relevant runtime, boundary, plugin, connector, or configuration changes.
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
- F-A3 evidence is indexed through the root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts plus the F-A4 cutover runbook's F.3 gate. This index does not change F-A3 closure status.
  - Evidence location: root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts; `docs/F-A4_CUTOVER_RUNBOOK.md` F.3 gate
  - Validation date: 2026-07-14 evidence index reconciliation; not a new F-A3 validation
  - Runtime baseline: current reconciled runtime baseline OpenClaw `2026.6.11 (e085fa1)`.
- Sensitive-data, autonomous-memory, Command Center mutation, and consequential-action expansion remain on hold.

## Phase evidence index

- F-A0 Platform hardening audit:
  - Evidence location: `audits/F-A0-platform-hardening-audit.md`
  - Validation date: 2026-06-16 remediation re-audit, with historical baseline evidence from 2026-06-12
  - Runtime baseline: OpenClaw `2026.6.5 (5181e4f)` for original evidence; current reconciled runtime baseline is `2026.6.11 (e085fa1)` and requires bounded regression before F-A4 closure.
- F-A1 Gmail capability broker:
  - Evidence location: `audits/F-A1-negative-test-results.md`, `docs/F-A1_GMAIL_BROKER_DESIGN.md`, `docs/F-A1_DEPLOY_LIST.md`
  - Validation date: 2026-06-16 broker exit gate; socket hardening revalidated 2026-07-14
  - Runtime baseline: original broker gate on prior OpenClaw baseline; live broker/socket/client path reconciled on OpenClaw `2026.6.11 (e085fa1)`.
- F-A2 Reader credential containment:
  - Evidence location: `docs/F-A2_PROOF_RUNBOOK.md`, `docs/F-A4_CUTOVER_RUNBOOK.md` F.2 gate
  - Validation date: evidence linkage pending reconstruction from historical validation artifacts.
  - Runtime baseline: evidence linkage pending reconstruction from historical validation artifacts; current runtime baseline is OpenClaw `2026.6.11 (e085fa1)`.
- F-A3 Typed handoff:
  - Evidence location: root-owned `research-handoff-gate.mjs` and `test-research-handoff-gate.mjs` validation scripts; `docs/F-A4_CUTOVER_RUNBOOK.md` F.3 gate
  - Validation date: 2026-07-14 evidence index reconciliation
  - Runtime baseline: current reconciled runtime baseline OpenClaw `2026.6.11 (e085fa1)`.

## Open verification gates

- B1 direct Gmail connector bypass.
- B2 permanent proxy and pf integration.
- B3 DNS, IPv6, and alternate-transport coverage.
- B4 OpenClaw 2026.7.1 qualification.
- B5 Foundation evidence and durable evidence substrate.

## Phase status

Completed phases remain closed unless new evidence invalidates prior exit criteria. Discovery of adjacent risks creates a new blocker or change proposal; it does not automatically reopen completed work.

Research findings do not automatically authorize implementation changes.

Research produces proposals. Implementation changes require explicit approval, scoped execution, validation, and documentation reconciliation.

| Phase | Status | Current meaning |
|---|---|---|
| F-A0 Platform hardening audit | CLOSED | Baseline platform hardening exit criteria passed. Revalidation is required after relevant upgrades or boundary changes. |
| F-A1 Gmail capability broker | BROKER EXIT GATE CLOSED | Broker capability, credential custody, socket initialization, and approved client path are proven. Exclusive Gmail routing is a separate gate. |
| F-A2 Reader credential containment | CLOSED | Reader credential custody boundary is closed. Reader does not possess Gmail credentials. This does not prove complete Gmail mediation. |
| F-A3 Typed handoff | CLOSED | Main-to-researcher handoff is schema validated and fail-closed. |
| F-A4 Complete mediation and egress | IN BUILD | Direct Gmail connector containment, permanent proxy/pf integration, expanded transport coverage, persistence, and reboot validation remain. |
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

## Next actions

### Immediate bounded action

Perform read-only F-A4 prerequisite validation before mutation.

Required results:

1. Installed OpenClaw version is verified from live runtime evidence.
2. Broker script ownership and mode are verified.
3. Main, Gmail reader, and researcher workspace and instruction ownership are verified.
4. `/var/run/agent-os` and Gmail broker socket ownership and mode are verified.
5. Current connector, app, MCP, and tool inventory is captured without invoking Gmail.
6. Any observed drift is documented before mutation.

### Locked sequence after the immediate action

1. Repair any broker reliability issue found in validation, limited to socket directory persistence/race and ownership drift.
2. Prove broker workflow: confined Gmail broker health/search succeeds and durable audit evidence exists.
3. Disable the confirmed Codex Apps Gmail connector surface for OpenClaw agents and prove broker-only Gmail access.
4. Reconcile and approve the F-A4 DNS, IPv6, and alternate-transport design.
5. Reapply the managed proxy and pf containment.
6. Complete F-A4 acceptance, persistence, failure-recovery, reboot validation, and minimal durable evidence validation.
7. Snapshot OpenClaw state and prove rollback.
8. Qualify OpenClaw `2026.7.1`.
9. Re-prove F-A1 through F-A4 after qualification.
10. Implement the reconciled F-B observability substrate.
11. Implement minimum F-C action governance.
12. Generalize the dispatch/confirm split under F-D.
13. Begin supervised capability expansion only after all applicable gates pass.

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
```

### OPERATING_CONSTITUTION.md
```markdown
# Agent OS Operating Constitution

**Status:** Approved mandatory operator guidance. Effective upon approval and commit to the canonical `agent-os` repository.

## 1. Purpose

Agent OS is governed by integrity, security boundaries, auditability, reversibility, and documentation consistency.

This document defines the non-negotiable operating rules for every human or AI operator who observes, documents, changes, validates, or governs Agent OS.

This constitution governs how work is performed. It does not replace `CONTROL.md`, define new product architecture, or authorize any runtime change.

`docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md` is part of the mandatory operating model for runtime, security, architecture, documentation, and capability changes.

## 2. Authority hierarchy

When sources disagree, use this order:

1. **Live runtime state** — authoritative for what the system is actually doing now. Inspect the relevant process, service, configuration, permissions, logs, and validation evidence directly. Never infer current runtime state from Git alone.

   Live runtime state is authoritative for observed facts. It does not authorize undocumented behavior, override approved architecture, or redefine intended security boundaries.
2. **`CONTROL.md`** — authoritative for declared phase state, active blockers, accepted decisions, and the next bounded task. Reconcile it to verified live state whenever drift is found.
3. **Canonical architecture documents** — authoritative for approved end-state design, trust boundaries, invariants, and phase ordering. They constrain implementation but do not prove that an implementation is live.
4. **Historical documents** — useful evidence and context only. Deployment records, handoff snapshots, superseded decisions, old runbooks, backups, and prior test reports are not current instructions unless `CONTROL.md` explicitly reactivates them.

Conflict rules:

- If instructions, documents, agent context, or observed runtime state conflict, stop mutation. Document the conflict, identify the authoritative source, and reconcile before proceeding.
- If live state and `CONTROL.md` disagree, stop implementation, document the observed drift, and reconcile the state record before proceeding.
- If a proposed implementation conflicts with canonical architecture, stop and obtain explicit architecture approval.
- Never use a historical instruction to override live evidence, `CONTROL.md`, or an approved architecture invariant.

## 3. AI operator authority and session state

### AI operator authority boundary

AI operators do not gain authority from model capability, available tools, prior conversations, memory, previous recommendations, or implied user intent. Authority exists only through approved operating scope, current `CONTROL.md` state, and explicit approval boundaries.

### Conversation and session state are not authoritative

Conversation history, agent memory, prior recommendations, drafts, and inferred context are not authoritative system state. Operators must reconcile against live runtime evidence and `CONTROL.md` before acting.

### Interrupted work does not automatically resume

Paused, interrupted, superseded, or abandoned tasks must not resume automatically. Before continuation, the operator must confirm current phase, blockers, approvals, and intended scope.

## 4. Approval boundaries

Approval applies only to the explicitly defined scope, files, systems, and outcomes identified at the time of approval.

Operators must not infer approval for adjacent changes, downstream actions, architecture changes, cleanup work, or discovered improvements unless separately authorized.

## 5. Prime directive

System integrity, security boundaries, auditability, reversibility, and documentation consistency take priority over implementation speed.

No deadline, convenience, apparent simplicity, or successful positive-path test justifies weakening a trust boundary, skipping negative validation, hiding drift, or leaving the canonical record inconsistent with the machine.

## 6. Change discipline

Before any implementation work, the operator must:

1. Identify the exact bounded scope.
2. Identify every affected trust boundary and failure mode.
3. Identify the canonical and operational documents affected by the result.
4. Confirm the authority and approval for the proposed change.
5. Define rollback and validation before mutation.

Every change follows this sequence:

> **Observe → Document → Propose → Approve → Change → Validate → Reconcile docs → Commit**

Meaning:

- **Observe:** inspect live state and collect evidence without mutation.
- **Document:** record the actual condition, including uncertainty and conflicting evidence.
- **Propose:** state the smallest reversible change, security impact, rollback, and validation plan.
- **Approve:** obtain explicit approval for the bounded change and any architecture impact.
- **Change:** perform only the approved mutation.
- **Validate:** run positive, negative, boundary, and rollback-relevant checks proportional to risk.
- **Reconcile docs:** align `CONTROL.md` and affected canonical documents with verified results; do not overclaim.
- **Commit:** commit only the reviewed scope with a clean diff and an evidence-based message.

A successful implementation is not complete until validation and documentation reconciliation are complete.

## 7. Documentation truth rule

Documentation changes that alter authority, phase status, security boundaries, or operational obligations are security-relevant changes and must follow the same **Observe → Document → Propose → Approve → Change → Validate → Reconcile → Commit** lifecycle as runtime changes.

Documentation must describe verified reality, not intended reality.

Future-state designs, proposals, and plans must be clearly labeled as such.

A document update cannot close a security boundary, declare a capability complete, or replace runtime validation.

## 8. Forbidden behaviors

Operators must not:

- Expand scope while executing a bounded task.
- Declare a security boundary closed based on partial evidence, a positive-path result, an agent's narrative, or the absence of an observed failure.
- Modify runtime, configuration, credentials, permissions, services, or external systems during documentation-only work.
- Trust stale documentation over verified live state.
- Introduce or silently adopt an architecture change during implementation without explicit approval.
- Treat cache deletion, prompt wording, or an untested deny rule as proof that a capability is unreachable.
- Recreate retired credentials, fallback paths, or historical deployment state as a convenience.
- Stage, commit, or push files outside the reviewed and approved scope.
- Weaken permissions, approvals, isolation, audit logging, or credential custody to make a test pass.
- Describe an unverified inference as a fact.

## 9. Operator requirements

Before acting, every human or AI operator must:

- Read `OPERATING_CONSTITUTION.md` and `CONTROL.md`.
- Confirm the current phase, immediate bounded task, active blockers, and sensitive-data hold.
- Inspect the live state relevant to the task.
- Distinguish verified facts, historical facts, inferences, and proposals.
- Make the smallest reversible change that can satisfy the approved objective.
- Preserve unrelated user and operator work.
- Report commands, files, backups, validation evidence, failures, uncertainty, and remaining blockers.
- Prefer evidence over confidence and explicit boundaries over implied behavior.

When blocked by ownership, permissions, missing authority, or an architecture choice, stop and request the minimum necessary operator action. Do not route around the boundary.

## 10. No Hero Rule

Do not optimize for cleverness.

The fastest path to a working system is not always the safest path to a trustworthy system.

A smaller verified system is preferable to a larger partially understood system.

Do not fix adjacent problems without authorization.

Do not create new architecture while executing another phase.

Do not turn a bounded repair into a platform redesign, dependency upgrade, ownership rewrite, credential migration, or policy expansion.

The correct operator behavior is disciplined completion of the approved task, followed by an explicit proposal for anything else discovered.

## 11. Evidence and closure standard

A boundary may be declared closed only when:

- The intended enforcement point is identified and owned outside the contained party where required.
- Positive operation succeeds through the approved path.
- Known alternate and fallback paths are inventoried and shown unavailable or disabled.
- Negative tests demonstrate prohibited operations fail closed.
- Permissions, ownership, configuration, and service state match the documented design.
- Validation survives the relevant restart, re-sync, or persistence condition.
- `CONTROL.md` and affected canonical documents state the same qualified conclusion.

If any condition is missing, record the boundary as open, partial, or unproven.

## 12. Commit discipline

Before commit:

- Review `git diff --stat`, the full scoped diff, `git status`, and `git diff --check`.
- Confirm only approved files are modified or staged.
- Confirm the documentation distinguishes completed foundations from remaining containment gaps.
- Confirm no secret, credential, token, private message content, or unnecessary runtime artifact is present.

Commits must be narrow, reviewable, and truthful. A commit records verified state; it does not manufacture completion.
```

### docs/AGENT_OS_ARCHITECTURE_DECISIONS.md
```markdown
# Agent OS Architecture Decisions

**Status:** Approved. Effective upon commit to the canonical repository.

## Purpose and authority

This document records durable Agent OS architecture decisions.

- `CONTROL.md` records current state, phase status, blockers, next actions, and verification gates.
- `AGENT_OS_END_STATE_ARCHITECTURE.md` remains the architecture spine.
- `OPERATING_CONSTITUTION.md` governs operator behavior.
- This document records approved technical direction and the requirements that must be reflected in implementation gates.

No architecture document creates runtime authority. Authority exists only where live enforcement implements the approved design.

This document supersedes research notes and discussion artifacts for approved architecture direction after commit.

## Decision summary

| Decision | Disposition |
|---|---|
| OpenClaw remains the Agent OS runtime | KEEP |
| Domain capability brokers remain load-bearing | KEEP |
| Alternate general agent frameworks replace OpenClaw | REJECT |
| Native OpenClaw audit becomes part of F-B | ADOPT |
| Native audit replaces boundary evidence | REJECT |
| F-B becomes a hybrid evidence substrate | MODIFY |
| F-C uses native approvals plus semantic action governance | MODIFY |
| Unknown actions require confirmation | REJECT |
| Unknown actions deny | ADOPT |
| Autonomous memory promotion before governance | REJECT |
| OpenClaw upgrades occur directly in production | REJECT |
| OpenClaw 2026.7.1 receives staged qualification | ADOPT |
| F-A4 covers only IPv4/TCP proxy paths | REJECT |
| F-A4 covers DNS, IPv6, and alternate transports | ADOPT |
| OpenClaw logical agents are OS security principals by default | REJECT |
| Plugin, MCP, and connector governance is required | ADOPT |
| Current Gmail reader/researcher model assignments documented | ADOPT |
| Change-control standard establishes mandatory reconciliation between runtime state, operational state, evidence, and canonical documentation. | ADOPT |
| Change-control standard is adopted as an enforced operating model. | ADOPT |
| Cedar becomes the initial policy engine | DEFER |
| OPA becomes the initial policy engine | REJECT |

## ADR-001 — OpenClaw remains the runtime

### Decision

OpenClaw remains the Agent OS runtime and orchestration substrate.

### Rationale

OpenClaw already supplies the required agent, delegation, tool, approval, Gateway, channel, plugin, session, task, provider, and local-model surfaces.

Replacing it would introduce a second runtime, duplicate established capabilities, expand the trusted computing base, and require migration of already proven boundaries.

No reviewed alternative demonstrates a material security or scalability advantage sufficient to replace OpenClaw.

### Consequences

- Agent OS hardens OpenClaw instead of rebuilding an agent runtime.
- OpenClaw defaults are not treated as Agent OS security guarantees.
- Security-critical behavior is verified against the installed version.
- Upgrades require formal qualification.

## ADR-002 — Domain capability brokers remain load-bearing

### Decision

The Gmail broker pattern remains the reference architecture for credential-bearing and consequential external capabilities.

A capability broker:

- runs under a dedicated identity where appropriate;
- owns the external credential;
- exposes a narrow semantic API;
- omits forbidden provider operations;
- validates requests deterministically;
- emits domain audit evidence;
- does not reveal a general provider token to callers.

### Rationale

The broker narrows authority at the credential-use boundary. General connectors, broad MCP servers, direct SDK clients, and prompt restrictions do not provide the same structural limitation.

### Consequences

- The Gmail broker remains.
- Future sensitive domains use brokers when general connectors expose excessive authority.
- Broker correctness and complete mediation remain separate gates.
- Credential recovery restores credentials to broker custody only.

## ADR-003 — Alternate frameworks do not replace Agent OS

### Decision

LangGraph, OpenAI Agents SDK, Microsoft Agent Framework, Semantic Kernel, AutoGen, CrewAI, and similar frameworks do not replace OpenClaw or the Agent OS security architecture.

MCP remains an interoperability protocol, not an authorization boundary.

### Rationale

These frameworks provide useful workflow and approval patterns but do not replace:

- OS-user isolation;
- operator-owned controls;
- credential brokers;
- host egress enforcement;
- complete mediation;
- semantic action authorization.

Adoption as a second runtime would add another session, memory, tool, approval, telemetry, and upgrade surface.

### Consequences

Patterns may be adopted without adopting replacement runtimes:

- durable interruption and idempotent side effects;
- approval-time revalidation;
- deterministic workflows for known processes;
- narrow MCP contracts and audience-bound authorization.

A second orchestration runtime requires evidence of a material blocker and explicit architecture approval.

## ADR-004 — Adopt native OpenClaw audit as one evidence source

### Decision

After qualification, native OpenClaw audit becomes the canonical Gateway run/tool index.

It does not replace broker logs, proxy logs, notification-delivery evidence, or domain reconciliation.

### Rationale

Native audit reduces duplicate implementation while retaining stable Gateway metadata.

Its limits include:

- metadata-only records;
- finite retention and bounded storage;
- background writing;
- incomplete coverage outside shared Gateway paths;
- no proof that an unrecorded action did not occur;
- no cryptographic event-log tamper evidence.

### Consequences

- Do not build a duplicate generic Gateway audit database.
- Retain boundary-owned evidence.
- Maintain an audit coverage matrix.
- Export sanitized evidence when longer retention is required.
- Do not claim complete mediation from native audit.

## ADR-005 — F-B is a hybrid evidence substrate

### Decision

F-B combines qualified native OpenClaw telemetry with minimal Agent OS correlation, boundary evidence, notification proof, retention, alerting, and reconciliation.

### Required design

F-B must provide:

- one run ID born at ingress;
- propagation through delegation, broker, proxy, and notification;
- native Gateway run/tool metadata where qualified;
- broker and proxy logs as boundary-authoritative evidence;
- explicit terminal outcomes;
- delivered-notification evidence;
- missing-counterpart detection;
- audit-silence detection;
- sanitized retention longer than the measurement period;
- a coverage and blind-spot matrix;
- integrity checkpoints proportional to the threat model.

Sensitive prompts, emails, tool arguments, and tool results remain excluded unless separately approved.

Replay, where required, uses sanitized decision envelopes and deterministic inputs rather than retained sensitive content.

### Rejected work

F-B will not build:

- a duplicate generic audit database;
- a second full tracing platform;
- a dashboard before native Control UI evaluation;
- raw-content telemetry;
- per-event blockchain-style logging.

## ADR-006 — F-C uses semantic action governance

### Decision

F-C uses:

- native OpenClaw approvals as approval transport;
- plugin permission requests where applicable;
- the Policy plugin for configuration conformance;
- a minimal Agent OS semantic action catalog;
- deterministic enforcement immediately before effect.

The Policy plugin is not a runtime authorization engine.

F-C starts with the minimal semantic action catalog required for approved effectful operations. Full action-envelope machinery, replay controls, nonce binding, and idempotency infrastructure are deferred until act-plane expansion requires them.

Deferral limits implementation scope only. It does not permit effectful operations outside the registered action catalog.

### Minimal action definition

Every effectful action must define:

- stable action ID and version;
- effect class;
- target/resource type;
- canonical target identity;
- canonical normalized arguments;
- sensitivity;
- reversibility;
- scope or quantity limits;
- gate: `auto`, `confirm`, or `deny`;
- permitted approver;
- whether durable approval is permitted;
- policy version/hash;
- expiry when approval is time-bound.

As the act plane expands, actions that can be retried, resumed, replayed, or partially applied must add the required full-envelope controls before they become executable:

- canonical action-envelope hash;
- one-shot nonce where replay is possible;
- idempotency key where duplicate effects are possible;
- result reconciliation for interrupted or retried operations.

Approval binds to the canonical action identity and normalized effect. Changes to target, arguments, version, policy, or expiry invalidate the approval.

The action is revalidated immediately before execution.

### Consequences

- Native approval interfaces are reused.
- Semantic authorization remains under Agent OS control.
- Models cannot approve, broaden, reinterpret, or bypass decisions.
- High-risk actions prohibit durable approval.
- Retried or resumed effectful actions require idempotency and result reconciliation before they are admitted to the executable catalog.
- Cedar remains deferred.
- OPA is not introduced for the current scope.

## ADR-007 — Unknown actions deny

### Decision

Any unregistered or unknown semantic action is denied.

### Rationale

Confirmation is trustworthy only when the system can identify, normalize, render, bind, and enforce the proposed effect.

An unknown action lacks that contract. Human confirmation cannot repair an undefined enforcement boundary.

### Classification

- Registered, low-risk, bounded, reversible action → eligible for `auto`.
- Registered consequential action → `confirm`.
- Registered forbidden action → `deny`.
- Unregistered or unknown action → `deny`.

A new action must be reviewed and registered before it becomes executable.

### Consequences

This replaces the earlier rule that treated unclassified actions as confirm/high-stakes. The auto/confirm/deny architecture remains; its default becomes genuinely fail-closed.

## ADR-008 — Memory cannot create authority

### Decision

Autonomous memory promotion is prohibited until memory governance is implemented.

Conversation history, memory files, summaries, embeddings, dreaming output, inferred commitments, and retrieved context are not authoritative policy.

### Required memory metadata

Action-relevant memory must represent:

- provenance and source;
- observed versus asserted status;
- authority class;
- owner or reviewer;
- creation and observation time;
- freshness and expiry;
- sensitivity;
- scope;
- confidence;
- derivation;
- contradiction state;
- safe-to-act status;
- promotion history;
- revocation or tombstone state.

### Authority tiers

1. **Observed/untrusted:** external content and working notes.
2. **Reviewed knowledge:** operator-reviewed durable facts and preferences.
3. **Authoritative control:** approved control, architecture, configuration, approval, and policy artifacts outside model memory.

Automated processes cannot promote content into authoritative control.

### Consequences

- Native memory may support supervised notes.
- Action-sensitive promotion requires deterministic validation and trusted review.
- Compaction, dreaming, summarization, retrieval, repetition, and embedding cannot raise authority.
- Sensitive remote embedding requires separate approval.
- Memory autonomy remains gated by stale, contradictory, malicious, truncated, and revoked-memory tests.

## ADR-009 — OpenClaw upgrades require qualification

### Decision

OpenClaw upgrades are security-boundary changes and require staged qualification.

OpenClaw `2026.7.1` is qualified after current Gmail complete-mediation and F-A4 transport gaps are addressed and before F-B/F-C implementation.

### Required qualification

- Version pin and release/security review.
- Pre-upgrade inventory.
- Snapshot and proven rollback.
- Staged installation.
- Schema and default comparison.
- Plugin, app, MCP, tool, and connector comparison.
- Ownership and permission verification.
- F-A1 through F-A4 regression.
- Native-audit coverage measurement.
- Policy-plugin conformance evaluation.
- Approval failure, mutation, and replay testing.
- Restart and reboot validation.
- Rollback execution.

### Consequences

- No production upgrade based only on release notes.
- Every relevant boundary reopens for validation after an upgrade.
- Version adoption requires recorded qualification evidence.

## ADR-010 — F-A4 covers expanded transport paths

### Decision

F-A4 covers all practical network paths available to the contained Gateway identity, not only proxied IPv4/TCP traffic.

### Required coverage

F-A4 must address and test:

- raw DNS;
- arbitrary query-name behavior;
- approved resolver identity;
- IPv4;
- IPv6;
- direct-IP connections;
- alternate DNS resolvers;
- TCP outside the proxy;
- UDP outside approved requirements;
- UDP/443 and QUIC;
- proxy-environment bypass;
- proxy or resolver failure;
- service restart and host reboot.

Preferred design: `openclawgw` sends external hostname-bearing traffic only to the loopback operator-owned proxy, and the separately owned proxy performs external resolution.

Any raw Gateway DNS exception must be explicitly justified, destination-constrained, monitored, and negative-tested.

### Rationale

Broad DNS access can permit data exfiltration even when HTTP traffic is forced through a proxy. IPv6 and alternate transports can bypass rules proven only against IPv4/TCP.

### Consequences

- Prior proxy/pf positive-path evidence remains valid but is insufficient for F-A4 closure.
- DNS tightening is an architecture gate.
- IPv4 and IPv6 require equivalent enforcement.
- F-A4 closure requires transport-level negative evidence, persistence testing, and reboot validation.
- F-A4 closure also requires minimal durable evidence: persistent logs, ownership-controlled evidence storage, retention longer than the validation window, and proof that validation events remain findable after service restart and host reboot.
- OpenClaw security-audit loopback-only Gateway findings are accepted only when the Gateway is not exposed through reverse proxy, tunnel, public listener, or other external ingress.

## ADR-011 — OpenClaw logical agents are not OS security principals by default

### Decision

OpenClaw agent identities provide workflow separation, configuration scoping, model/tool selection, and delegation structure.

They must not be described as OS-level isolation unless live runtime evidence proves separate OS users, process boundaries, permissions, and inaccessible credential paths.

### Rationale

Agent names such as `main`, `gmail-reader`, and `researcher` can constrain workflow and tool selection, but that is not equivalent to OS security principal separation.

Gmail safety comes from broker-owned credentials, broker semantic controls, fail-closed execution allowlists, and removal of bypass connectors. It does not come from treating OpenClaw logical agent names as operating-system identities.

### Consequences

- Documentation must avoid claims such as "only the confined reader can access Gmail" unless the claim is scoped to the broker contract and runtime evidence.
- Preferred language: "The Gmail capability is constrained through broker-owned credentials and broker semantic controls."
- Phase exits must distinguish workflow separation from OS-level isolation.
- Future claims of OS isolation require live evidence for users, groups, processes, permissions, credential paths, and denial tests.

## ADR-012 — Plugin, MCP, and connector governance

### Decision

Plugins, MCP servers, apps, connectors, and third-party extensions are capability expansion and trust-boundary changes.

They require explicit governance before installation, enablement, permission expansion, or use in a security-sensitive path.

### Requirements

Before installation, enablement, or permission expansion, the operator must:

- inventory read, write, network, credential, filesystem, and effectful-action scope;
- identify whether the surface bypasses an approved broker;
- classify exposed tools as gather-only or effectful;
- require explicit approval for effectful or credential-bearing surfaces;
- define rollback, disablement, and removal steps;
- include the surface in OpenClaw qualification and F-A regression checks;
- document connector synchronization behavior when it affects complete mediation.

MCP is an interoperability protocol, not an authorization boundary. Plugin permission prompts are useful controls and evidence, but they do not replace Agent OS broker, containment, and semantic-action policy boundaries.

### Consequences

- Direct connectors for brokered domains are bypass risks until proven unavailable to the relevant runtime.
- Third-party extensions are not adopted merely because they expose useful capabilities.
- F-A4 and later qualification must compare plugins, apps, MCP servers, tools, and connectors before and after changes.
- Capability expansion remains blocked until applicable foundation gates pass.

## ADR-013 — Current Gmail reader and researcher model assignments

### Decision

For the current OpenClaw `2026.6.11 (e085fa1)` baseline:

- `gmail-reader` uses `ollama/qwen3-coder:30b`.
- `email-researcher` uses `openai/gpt-5.5`.

### Rationale

The Gmail reader handles broker-mediated mailbox interaction and should remain on a local model path with narrow execution allowlisting, broker-owned Gmail credentials, and no direct Gmail connector authority.

The email researcher handles external research after the F-A3 schema gate and does not receive raw Gmail credentials or raw mailbox access through the broker.

### Security implications

- These assignments are workflow and capability choices, not OS security principal isolation.
- Model assignment does not prove complete mediation; the direct Gmail connector bypass remains an F-A4 blocker until removed and negative-tested.
- Changes to either model assignment require read-only runtime evidence, regression of F-A1/F-A3-relevant gates, and documentation reconciliation.
- The local reader model reduces dependency on external model transport for broker-mediated Gmail reading, but F-A4 egress containment remains required before sensitive-data holds can lift.

## ADR-014 — OpenClaw 2026.6.11 baseline

See `docs/ADR-014_OPENCLAW_2026_6_11_BASELINE.md`.

## ADR-015 — Change Control Standard adoption

### Decision

`docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md` is adopted as mandatory operating control, not advisory documentation.

### Consequences

- Runtime, security, architecture, documentation, and capability changes must follow the required lifecycle.
- Wrap-up and publication tooling must check baseline drift, evidence linkage, open gates, publication manifest coverage, and obligation preservation.
- Documentation changes cannot remove obligations, evidence, blockers, or phase gates without classification.

## Resulting roadmap

### KEEP

- OpenClaw runtime.
- Broker architecture.
- OS-user boundaries where live runtime evidence proves them.
- Typed handoffs.
- Operator-owned enforcement.
- Gather/act separation.
- Auto/confirm/deny classification.
- Foundations-first sequence.

### MODIFY

- F-B becomes hybrid native-plus-boundary observability.
- F-C uses native approvals plus minimal semantic action governance.
- Unknown actions deny.
- Memory promotion becomes governed.
- F-A4 expands across relevant network paths.
- OpenClaw logical agents are documented as workflow identities, not OS security principals.
- Plugin, MCP, app, and connector governance becomes explicit.

### REORDER

1. Read-only F-A4 prerequisite validation.
2. Broker reliability validation and repair if drift is found.
3. Broker workflow proof with durable evidence.
4. Direct Gmail connector containment.
5. F-A4 transport reconciliation and completion.
6. OpenClaw `2026.7.1` qualification.
7. Full foundation regression.
8. F-B implementation.
9. Minimum F-C implementation.
10. F-D generalization.
11. Capability expansion.

### REMOVE

Remove planned custom work for:

- a duplicate generic audit database;
- a general policy engine at current scale;
- an observability dashboard before native UI evaluation;
- autonomous memory before governance;
- a second agent runtime.

No completed foundation phase is reopened or removed without new evidence invalidating its exit criteria.

### ADD

- Upgrade qualification.
- Semantic action identity and normalized-effect binding.
- Minimal semantic action catalog before full action-envelope machinery.
- One-shot approval and idempotency when act-plane expansion requires replay or duplicate-effect protection.
- Audit coverage reconciliation.
- Delivered-notification evidence.
- Audit-silence monitoring.
- DNS, IPv6, QUIC, and direct-IP testing.
- Restore and rollback drills.
- Memory-promotion governance.
```

### docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md
```markdown
# Agent OS Change Control Standard

**Status:** Approved governance standard. Effective upon approval and commit to the canonical repository.

## Purpose

Prevent divergence between:

- live runtime state;
- `CONTROL.md`;
- architecture decisions;
- operational runbooks;
- evidence artifacts.

This standard applies to runtime, security, architecture, documentation, and capability changes that can affect Agent OS authority, trust boundaries, phase status, or operational obligations.

Documentation does not create runtime authority. It records verified state, approved architecture, required gates, and evidence locations.

## Required Change Lifecycle

All runtime, security, architecture, documentation, or capability changes follow:

```text
Observe
→ Document
→ Propose
→ Approve
→ Change
→ Validate
→ Reconcile
→ Commit
```

Meaning:

- **Observe:** inspect relevant live state, repository state, evidence, and prior decisions before mutation.
- **Document:** record verified facts, drift, uncertainty, and affected boundaries.
- **Propose:** state the smallest bounded change, expected effect, rollback, and validation plan.
- **Approve:** obtain explicit approval for the proposed scope.
- **Change:** mutate only approved files, services, policies, credentials, or runtime state.
- **Validate:** prove positive path, negative path, persistence, and evidence proportional to risk.
- **Reconcile:** update `CONTROL.md`, architecture decisions, runbooks, and evidence indexes to match validated reality.
- **Commit:** commit only the reviewed scope with a truthful message and clean status.

Skipping reconciliation is a failed change, even when the runtime behavior works.

## Changes Requiring Reconciliation

The following require documentation and evidence reconciliation before closure:

- OpenClaw version changes;
- model assignments;
- agent configuration;
- connectors;
- MCP servers;
- plugins;
- credentials;
- permissions;
- launchd services;
- sockets;
- proxy/firewall changes;
- security boundary changes;
- approval policy changes;
- broker capability changes;
- runtime identity or ownership changes;
- evidence, logging, audit, or retention changes;
- phase status changes;
- rollback or recovery procedure changes.

## Documentation Migration Rule

No security-relevant item may disappear during refactoring.

Every removed item must be classified as one of:

- **Closed** — with evidence reference.
- **Moved** — with destination reference.
- **Retired** — with approval rationale.
- **Superseded** — with ADR reference.

No silent deletion is allowed.

Security-critical obligations are tracked in `docs/AGENT_OS_OBLIGATION_REGISTER.md`. Refactors must preserve, close, move, retire, or supersede every listed obligation.

If a document is compressed, split, renamed, or converted into an index, every active obligation, open blocker, phase gate, credential boundary, connector risk, approval rule, and runtime baseline must remain discoverable from canonical documents.

## State Migration Rule

When canonical documentation is rewritten, compressed, or reorganized:

- Existing obligations must be migrated explicitly.
- Existing evidence references must be preserved or replaced.
- Existing blockers must remain visible until closed or retired.
- A documentation refactor is treated as a change event, not a formatting event.

A shorter document is not considered equivalent unless all active obligations, decisions, evidence references, and unresolved risks remain traceable.

## `CONTROL.md` Compression Rule

`CONTROL.md` may remain concise.

However, when content moves out of `CONTROL.md`:

- the destination document must be recorded;
- status must remain visible;
- open security obligations cannot disappear;
- phase closure limits must remain visible or directly referenced;
- unresolved blockers must retain owner, status, and next validation gate.

`CONTROL.md` should point to detailed runbooks and ADRs; it must not hide active obligations inside historical notes.

## Evidence Traceability

Phase closures require:

- evidence location;
- commit reference;
- validation date;
- runtime baseline.

Closed status without evidence linkage is provisional.

A phase may remain summarized in `CONTROL.md`, but every closed phase must have a discoverable evidence pointer.

Evidence may live in audit files, runbooks, sanitized logs, operator records, or committed validation summaries. The location must be recorded in canonical documentation.

Evidence must distinguish:

- live runtime proof;
- historical proof;
- inferred status;
- proposed future validation.

## Runtime Authority Rule

For live system state:

```text
Runtime evidence > canonical documentation > historical artifacts > session summaries.
```

Documentation records validated reality but cannot override live runtime evidence.

## Wrap-Up And Publish Requirements

Wrap-up validation should eventually detect:

- broken document references;
- runtime version drift;
- stale paths;
- missing canonical documents;
- disappearance of security-critical gates;
- missing evidence locations for closed phases;
- removed obligations without Closed/Moved/Retired/Superseded classification.

This document defines the requirement only. It does not implement scripts.

## Non-Goals

This standard does not authorize runtime mutation, credential access, connector changes, service restarts, or security-control changes.

It also does not require `CONTROL.md` to carry every detail. It requires that details remain traceable, current, and canonically referenced.
```

### docs/AGENT_OS_END_STATE_ARCHITECTURE.md
```markdown
# Agent OS — End-State Architecture

**Purpose:** define what this system is *for* and the bedrock that makes it safe, so every future phase builds toward a deliberate end state instead of accreting. This is the spine the plan reorganizes around. Companion to the Security Design Standard (prompt-injection patterns) and the Roadmap Best-Practices Brief (per-domain research).

**Status:** v1, drafted [next session]. Supersedes the capability-first phase ordering in the prior plan.

---

## 1. What this is (the destination)

A **personal life-operations agent**: a Command Center that dispatches agents on open-ended tasks and brings results back to Daniel, handling low-stakes things autonomously and proposing higher-stakes things for approval — with the boundary between the two **evolving over time as trust accrues**.

Concretely, the end state can:
- Be sent on open-ended research ("find me better insurance rates," "what's the best way to do X")
- Watch a video / read a long thing and bring back findings
- Triage email and family logistics, help get life in order
- Build budgets from spending, plan vacations
- Fill out forms (gather + draft every field; submission gated)
- Eventually: notice context (e.g. an upcoming vacation) and proactively propose actions (e.g. "shut off the AC while you're away") — **evolving to autonomy on the low-stakes ones**

The defining property is **open-endedness**: Daniel hands a goal, the system figures out the steps. This is what makes it truly agentic — and it's also the single hardest thing to secure. The entire architecture below exists to make open-ended dispatch safe.

**Not required perfect on day one.** Starts fully supervised; capabilities and autonomy accrete over time. The bedrock must be strong enough that this evolution is *additive*, never a rebuild.

---

## 2. The central tension (and its resolution)

**Tension:** The security literature's hardest finding is that you *cannot* secure a general-purpose, open-ended agent against prompt injection with current models — only application-specific agents with defined trust boundaries. But the end state *wants* open-ended dispatch.

**Resolution — the load-bearing law of the whole system:**

> **The open-ended part and the consequential part are permanently separated. Gathering agents can research/read/watch/summarize/propose, but structurally CANNOT act. All action is a separate, gated path.**

Open-ended exploration is safe *because its only output is a proposal to the system, never an action.* A fully-injected research agent that "decides" to wire money or delete a file simply cannot — it has no action path. It can only emit a proposal, which goes through the policy layer (§3.4), which routes anything consequential to Daniel.

The approved broker Gmail path is draft-only/no-send proven. System-wide no-send is not proven while external connector surfaces remain. The approved-path pattern is the template the end state generalizes.

---

## 3. The four foundations (the bedrock)

These are built as **shared substrate underneath all capabilities**, not per-capability. Building them per-capability is the rebuild trap. They must exist (at least in v1 form) before the Command Center.

### 3.1 Foundation 1 — The Dispatch/Confirm Split (structural law)
- **Gather plane:** open-ended agents. Read, research, watch, summarize, draft, propose. No action tools at all. Live behind the egress allowlist (3.2). As "wild" as desired because they cannot act.
- **Act plane:** a *fixed menu* of defined operations (send email, submit form, change a setting, control a device, move money…). Never open-ended. Every action is one of a known set, each with a policy classification (3.4).
- A gathering agent's proposal **cannot** become an action except by passing through the policy layer. There is no bypass. This is structural, not behavioral — not "the agent is told not to act," but "the agent has no capability to act."
- **Why it's foundational:** retrofitting "these agents actually can't act" onto a system that assumed they could is a teardown. Get it in first; every capability inherits it.

### 3.2 Foundation 2 — Containment (the unlock)
Required containment layers (architectural value order is not the live build order):
1. **Network egress allowlist** — default-deny, no wildcards, enforced at tool-execution/network layer (not prompt layer, which barely works). This is what lets gather agents run *wild and unattended* without being an exfiltration risk — a hijacked research agent can't phone home.
2. **Workload isolation** — enforcement owned outside the contained agent. On this host, native Docker sandboxing was disproved as the gateway/web-search egress wall; do not equate a container with the current F-A4 mechanism.
3. **Credential/capability brokers** — agents call a broker that holds secrets and exposes only fixed semantic operations; the agent never sees the raw token or a general provider API. Gmail implements this under dedicated user `gmailbroker`.
- **Why it's foundational + reordered EARLY:** containment is what graduates the system out of "supervised, non-sensitive only." It has leverage no single capability has — it unlocks unattended operation for *everything*. Hence it moves ahead of new capabilities in the sequence.

**Runtime + confinement history (2026-06-14 Path B; superseded for Gmail on 2026-07-14):**
A confinement model is only real if the runtime enforces it, and live testing settled which configurations actually work in OpenClaw 2026.6.5:
- `tools.exec.mode: "allowlist"` is REJECTED by the Codex harness. An `openai/*` ref defaults to Codex.
- The embedded `openclaw` runtime accepts allowlist mode but requires a separate OpenAI **API-key** auth profile (`auth.order.openai`, `agentRuntime.id: "openclaw"`) — NOT the ChatGPT/Codex subscription. (Subscription auth only works through the Codex harness.)
- `tools.exec.mode: "auto"` on Codex was tested and does NOT preserve allowlist confinement: a per-agent approvals allowlist did NOT override `auto` — an off-allowlist command (`ls /`) executed. So "auto + strict approvals" is NOT a safe confinement substitute. [Proven live 2026-06-14.]

**Current Gmail decision:** Local confined reader model; current model tracked in `CONTROL.md`. The reader uses a narrow execution contract with `ask:off`, fail-closed allowlisting, and one approved root-owned broker client. Gmail credentials and semantic authority live under dedicated user `gmailbroker`. The June 14 Codex `auto` Path B result remains historical platform evidence but no longer describes the live Gmail reader.

**Current layered Gmail boundary:**
- (1) **Capability broker** — fixed read/draft semantic operations, no send method, broker-owned credentials.
- (2) **Fail-closed reader execution allowlist** — only the root-owned broker client is approved automatically.
- (3) **Schema-validated research channel** — prevents raw email from entering the research plane; semantic smuggling remains a residual risk.
- (4) **Complete mediation** — OPEN. A synchronized Codex Apps Gmail connector (`codex_apps__gmail` / `mcp__codex_apps__gmail*`) remains outside the broker and must be disabled.
- (5) **Egress control** — F-A4 remains required for exfiltration containment.
- (6) **Dispatch/confirm split + deny-by-default policy** — gate consequential actions system-wide.

The Gmail loop remains **supervised / non-sensitive ONLY** until the direct connector is absent and the full sensitive-data gate passes. Broker completion alone does not lift the hold.

**Platform-mechanics gate (mandatory before any foundation/capability build drop):**
Best-practices/pattern research is necessary but NOT sufficient. Before writing a build drop, also research the OpenClaw-specific mechanics (runtime / exec / sandbox / egress / AUTH) per the Platform Mechanics Reference: how the layer actually enforces this, what silent defaults bite (`openai/*`→Codex; embedded→API-key; `exec.mode=allowlist`→Codex rejection; `auto`→allowlist NOT enforced; sandbox network→`none`; env doesn't inherit into sandbox; self-logging gaps for cron/subagent/heartbeat), and whether the intended config is platform-supported — proven from docs/schema, then VERIFIED against the live install with a read-only diagnostic. The 2026-06-14 runtime saga (allowlist→Codex-reject→embedded→API-key→auto-doesn't-confine→Path B) was a chain of platform dependencies discoverable upfront; finding them via failed live runs is the failure mode this gate prevents. Applies to egress (Foundation 2), observability (Foundation 3), policy/exec (Foundation 4) next — see the Platform Mechanics Reference §9 VERIFY gate.

### 3.3 Foundation 3 — Observability Substrate (the trust gate AND the promotion evidence)
- Correlation IDs on every message, plan, and tool call; full end-to-end trace per run.
- Every run reconstructable from logs; run-replay (rewind, fork with modified input, verify a fix).
- Immutable / append-only enough to be trustworthy.
- **Zero silent failures as a queryable property:** every tool call has a traced result; every failure produces a *delivered* notification; "did anything fail silently in the last N days?" returns a real answer. (The Tiger silent-FAIL bug is the failure this prevents.)
- **Dual role:** this is both the V1 trust gate (is it working?) *and* the evidence base that justifies promoting an action from confirm→auto (§3.4). You don't promote on a hunch; you promote because the trail proves it proposed correctly N times.
- GitHub tooling to evaluate here: `agent-topology-visualizer` (renders trust boundaries), `agent-dashboard` (real-time health). See §6.

### 3.4 Foundation 4 — Evolvable Action-Policy Layer (what makes earned autonomy real)
- **One inspectable definition** of every action class and its current gate: `auto` (execute + notify after), `confirm` (propose, wait for Daniel), or `deny`. Every capability and the Command Center consult this at action time. Actions do **not** each hardcode their own gate.
- **Promotion model:** moving an action from `confirm` → `auto` is a *policy edit*, not a code change. The capability that performs the action never changes; only its classification moves. This is how the system "evolves to autonomy" without a rebuild.
- **Promotion criteria = observability evidence:** an action class earns `auto` when the audit trail shows it proposed correctly over time. Daniel makes the promotion; the trail justifies it.
- **THE PERMANENT INVARIANT — deny-by-default:** any unknown or unregistered action class is denied until it is reviewed and registered. Registered consequential actions route to `confirm`; registered low-risk bounded actions may become `auto`. The failure mode of forgetting to register something is "it does not execute," never "it acted when it shouldn't have." **This default does not evolve. It is a foundational law.**
- High-stakes classes (money movement, deletion, access/permission changes, anything irreversible) **cannot be promoted to `auto`** without an explicit, deliberate Daniel action — and some should be permanently `confirm` regardless of trust.

---

## 4. How the named capabilities decompose onto the split

Each capability = a **safe-gather half** (open-ended, behind containment) + a **gated-act half** (fixed menu, policy-classified). This is the test every future capability must pass.

| Capability | Safe-gather (open-ended, can't act) | Gated-act (menu, policy-classified) |
|---|---|---|
| Insurance hunt | Research rates, compare, summarize, draft recommendation | Switch/purchase a policy → `confirm` (likely permanent) |
| Budget building | Read spending, categorize, model, propose budget | Move money / pay → `confirm` (likely permanent); categorize-only → could earn `auto` |
| Vacation planning | Research, build itinerary, draft bookings | Book/pay → `confirm`; *propose* "shut off AC while away" → starts `confirm`, can earn `auto` |
| Email/family ops | Read threads, triage, draft replies, summarize | Send → `confirm` → low-stakes replies could earn `auto` over time |
| Form completion | Find form, read it, draft every field, show filled draft | Submit → `confirm` (promote per-form-class as trust accrues) |
| Research / watch video | Gather, watch, summarize, bring findings back | (usually no act half — pure gather, safe to run fully unattended early) |
| Home/device control | Detect context, propose action | Execute (e.g. AC off) → `confirm` first, earn `auto` once proven |

The AC-off-for-vacation example end to end: gather agent infers the trip and proposes "turn off AC." Day one, policy has that action class as `confirm` → it asks. After it's proposed correctly enough times and the trail proves it, Daniel edits policy to promote that class to `auto, notify after`. Nothing about the agent or the device capability changes. That's evolution without rebuild.

---

## 5. Corrected phase sequence (foundations-first)

Prior plan was capability-first (email → more capabilities → Command Center). Corrected:

**Built / in progress**
- Phase 2 email assistant — the approved broker Gmail path is draft-only/no-send proven and is the *template* for the dispatch/confirm split. System-wide no-send is not proven while external connector surfaces remain.

**Foundations (before broad capability expansion)**
- **F-A. Containment** — locked live sequence: F-A0 platform audit → F-A1 Gmail capability broker → F-A2 reader credential containment → F-A3 typed handoff → F-A4 egress allowlist. F-A1 through F-A3 are complete; F-A4 remains in build.
- **F-B. Observability substrate** — correlation-ID tracing, run-replay, zero-silent-failure as queryable. Evaluate topology-visualizer/dashboard here.
- **F-C. Action-policy layer** — the auto/confirm/deny registry, deny-by-default invariant, promotion model wired to observability evidence.
- **F-D. Dispatch/confirm split generalized** — promote the email loop's pattern to a system-wide standard every capability and the Command Center inherit. (Includes: every inter-agent handoff is a validated schema enforced by a deterministic check — the research-request validator pattern, made standard. MAST's #1 failure category is spec/coordination; this is the defense.)

**Capability expansion (on top of foundations, additive & safe)**
- Each new capability = safe-gather + gated-act, passing the §4 test and the Security Standard §6 checklist. Calendar, budgets, insurance, vacation, forms, home control — accrete one at a time.

**Command Center (the destination, P2 — still gated)**
- Dispatcher of open-ended gather tasks + confirmation surface for the action menu. Hard-held behind the 8 behavioral tests AND the foundations existing. It must not become a path that bypasses any trust boundary (Roadmap Brief, Theme 4).

**V1 trust milestone** — defined as *measurable properties of the observability substrate*: 30 days of daily use, full audit trails, zero silent failures (queryable, not asserted), and ≥1 action class successfully promoted confirm→auto on the strength of the trail. Not a vague duration — a demonstrated property.

---

## 6. GitHub / ecosystem findings folded in

Out of a 5,400+ skill ecosystem that is overwhelmingly capability-maximalist (the opposite of this architecture's discipline — admire, don't adopt):
- **Adopt-for-evaluation (observability phase F-B):** `agent-topology-visualizer` (SVG architecture/trust-boundary diagrams), `agent-dashboard` (real-time agent health). Directly serve Foundation 3.
- **Shelf as defensive gate (only if community code is ever installed):** `antivirus` / `agent-skills-audit` / `authensor-gateway` (scan skills for malicious patterns). 
- **Cross-check, don't adopt:** `anti-amnesia` (durable agent memory) — pressure-test our hand-rolled canonical-files state discipline against it.
- **Reference:** community hardening guides (the "setup guide I wish I had," NetworkChuck VPS guide) — skim the security-checklist sections as a sanity check.
- **Explicitly declined:** home automation skills (we build our own gated device control), social posting, on-chain/crypto, voice/phone surfaces, n8n bulk-automation, `agent-passport` (third-party consent-gate at our most sensitive boundary — our hand-built confirmation is correct). Each is an unbounded capability with a fresh trust boundary; adopting them trades away the narrowness that is the moat.

---

## 7. The one-paragraph end state

A personal life-operations agent where open-ended agents are dispatched to research, watch, gather, and propose — running wild but safe because they sit behind a containment foundation and *structurally cannot act* — while a single evolvable policy layer decides which proposed actions execute automatically (low-stakes, trust earned via the audit trail) versus which ask Daniel (everything unclassified, by permanent default, and all high-stakes), all observable end-to-end with zero silent failures, so the boundary between "handle it" and "ask me" can move toward autonomy over time without ever rebuilding the bedrock.
```

### docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
```markdown
# OpenClaw Platform Mechanics Reference

**Purpose:** the platform-specific behavior of the current OpenClaw baseline, reconciled to OpenClaw 2026.6.11 — runtime, exec, sandbox, egress, auth, observability, cron — mapped from the docs and issue tracker AHEAD of building, so build drops start from a *verified config recipe* instead of discovering incompatibilities mid-run. This is the artifact that closes the "we keep finding platform answers reactively" gap.

**Status:** v1, 2026-06-14; reconciled 2026-07-14 to OpenClaw 2026.6.11 (e085fa1). Companion to the End-State Architecture (the platform-mechanics gate references this file). Living document — deepen each section before its phase; update when OpenClaw version changes. Historical 2026.6.5 findings remain labeled as historical evidence.

**The rule it enforces:** No build drop for a phase is written until that phase's section here is filled and marked VERIFIED. Principles research ≠ platform research. The landmines below were all discoverable in docs; finding them via failed runs is the failure mode this prevents.

---

## 0. The landmine catalog (silent defaults that bite)

Quick-reference list of platform behaviors that fail silently or surprisingly. Check this before any config change.

1. **`openai/*` model ref → Codex harness by default.** Selecting an OpenAI model silently routes the agent to the Codex app-server runtime unless you pin otherwise.
2. **Codex harness REJECTS `tools.exec.mode: "allowlist"`** outright ("Codex app-server local execution is not available when tools.exec.mode=allowlist"). [Hit live 2026-06-14.]
3. **Embedded `openclaw` runtime needs separate OpenAI API-key auth** — it can't use your Codex/ChatGPT subscription OAuth. Pinning `agentRuntime.id: "openclaw"` without API-key auth → "No API key found for provider openai". [Hit live 2026-06-14.]
4. **Sandbox `docker.network` defaults to `"none"`** — no egress at all. Allowed web tools silently fail; package installs fail. Must set `"bridge"` for outbound. `"host"` is blocked; `"container:<id>"` is break-glass only.
5. **Sandbox has its OWN tool filter** (`tools.sandbox.tools`) separate from agent `tools.allow`. A tool allowed at agent level still fails if the sandbox filter doesn't also permit it.
6. **Env vars do NOT inherit into the sandbox.** Host env (API keys) invisible inside the container; must use `sandbox.docker.env` (which is Docker-inspectable — secret exposure) or a custom image/mounted secret.
7. **macOS Keychain is unreliable headless/over-SSH** (error -50, interaction-required, write-verify timeout). Use gog file keyring for headless. [Hit live, earlier session.]
8. **Self-reported tool logging is honor-system and has gaps** — cron jobs, sub-agents, heartbeat run in isolated contexts and DON'T share the main session's logging. "Zero silent failures" requires gateway-level/OTel logging, not agent self-logging. [GitHub #13131.] **This is the big one for the V1 trust gate.**
9. **`exec.mode=allowlist` rejects shell chaining (`&&`, `||`, `;`) and redirections** unless every segment is allowlisted. Safe-bins reject positional file args / path-like tokens.
10. **EPERM chmod `~/.openclaw/state`** — known managed-sandbox bug on this install; ignore it, re-run outside the managed sandbox.
11. **Whole-agent `agentRuntime` keys are ignored/stripped by doctor** — runtime pins must be model-scoped (`models["provider/model"].agentRuntime.id`).
12. **Sandbox inheritance guard:** a sandboxed requester can't spawn an unsandboxed sub-agent (`sessions_spawn` rejects it). Matters when composing the dispatch/confirm split under sandboxing.

---

## 1. Runtime + auth (VERIFIED 2026-06-14; Gmail live-state correction 2026-07-14)

**Three runtimes, three behaviors:**
- **Codex** (default for `openai/*`): app-server harness. Owns native thread/resume/compaction. REJECTS `exec.mode=allowlist`. Uses Codex/ChatGPT OAuth (your current auth). Maps host-exec misses to Codex Guardian review under `auto` mode.
- **Embedded `openclaw`** (pin `models["..."].agentRuntime.id: "openclaw"`): OpenClaw's own loop. ACCEPTS allowlist mode. BUT needs direct OpenAI API-key auth (`auth.order.openai`), a separate billing path from the Codex subscription.
- **ACP** (`runtime: "acp"`): external harnesses (Claude Code, Gemini, etc.). Runs on host OUTSIDE OpenClaw's sandbox/tool enforcement. Not for confined OpenClaw-native agents.

**Verified outcome (Path B, 2026-06-14):** Run a confined agent on default Codex runtime + `tools.exec.mode: "auto"`. This runs on existing Codex/subscription auth (no API key) BUT does **NOT** enforce OS-level exec-allowlist confinement — TESTED LIVE: with a strict per-agent exec-approvals allowlist still in place, an off-allowlist command (`ls /`) EXECUTED. The "stricter of the two layers" claim did NOT hold; `auto` mode did not defer to the approvals-layer allowlist. So **auto + strict-approvals is NOT a confinement substitute.**

The two configurations that actually exist:
- **Codex + `auto`:** runs on subscription auth, NO OS-level exec confinement (accepted under Path B — confinement comes from OAuth scope + 3-layer no-send + research validator + coming egress, not exec-allowlist).
- **Embedded `openclaw` + `allowlist`:** real OS-level exec confinement, BUT needs separate OpenAI API-key auth (Path A).

The June 14 result remains valid for that tested Codex configuration, but **Path B no longer describes the live Gmail reader**. Current Gmail confinement uses `ollama/qwen3-coder:30b` plus OpenClaw's fail-closed exec approvals, with one root-owned broker client allowlisted and `ask:off`. Do not generalize the old Codex `auto` finding into current Gmail state.

**Do NOT:** claim auto+approvals confines (disproven); pin embedded runtime without provisioning API-key auth.

---

## 2. Exec / approvals model (VERIFIED 2026-06-14)

- **`tools.exec.mode` values:** `deny` | `allowlist` | `ask` | `auto` | `full`. The normalized policy knob.
  - `allowlist`: deterministic matches run; misses STOP and wait for operator. Strict but Codex-incompatible.
  - `auto`: deterministic matches run; misses go to native auto-reviewer (Codex Guardian), then human fallback. Codex-compatible. **Reviewer can auto-approve a low-risk miss** — and a strict approvals layer does NOT reliably block this (disproven live: `ls /` executed under auto). Treat `auto` as NOT confined.
  - `deny`/`full`: block all / run all (full = YOLO).
- **Two layers:** `tools.exec.*` (mode) AND `exec-approvals.json` (per-agent `security`/`ask`/`askFallback`/allowlist). The docs describe effective policy as the *stricter* of the two — but this was DISPROVEN live 2026-06-14 for `auto` mode: an off-allowlist command executed despite a strict approvals-layer allowlist. **Do not rely on "stricter wins" to make `auto` confine.** The only mode that actually enforces allowlist confinement is `allowlist` itself — which the Codex harness rejects (so it requires the embedded runtime + API-key auth). [Landmine #2, #3; the runtime saga.]
- **`askFallback: "deny"`** = unanswered prompts default to denial. **`autoAllowSkills: false`** = don't auto-trust ClawHub skills. Keep both strict regardless (defense-in-depth), but know they do NOT make `auto` confine.
- **Allowlist enforcement:** matches resolved binary paths (no basename match); pin actual script paths, not wildcards (`python3 *` ≈ `full`). Chaining/redirections rejected unless all segments allowlisted.
- **`elevated` mode** bypasses sandbox to host with its own approval gates — keep off for confined agents.

---

## 3. Sandbox / workload isolation (VERIFIED for Foundation 2 — egress)

- **`agents.defaults.sandbox.mode`:** `off` | `non-main` | `all`. ("non-main" keys off session.mainKey, so group/channel sessions count as non-main and get sandboxed.) Your agents currently run `mode: off`.
- **`sandbox.scope`:** how many containers (session vs shared).
- **`sandbox.workspaceAccess`:** `none` mirrors eligible skills into the sandbox workspace.
- **Sandbox is Docker-based.** `readOnlyRoot: true` blocks writes. `user` must be root for installs. Sandbox exec does NOT inherit host `process.env`.
- **Sandbox has its own tool filter** (`tools.sandbox.tools`) — separate gate from agent `tools.allow`. Both must permit a tool. [Landmine #5.]
- **Inheritance guard:** sandboxed requester can't spawn unsandboxed child.
- **What's NEVER sandboxed:** the Gateway process itself; anything in `tools.elevated`.

---

## 4. Egress / network control — Foundation 2 (DECISION AMENDED 2026-06-14b)

> **Amendment note (2026-06-14c):** Plan A (host-side reader + UID-keyed pf-forced proxy) is
> **ELIMINATED on evidence.** The 2026-06-14b decision adopted Plan A *gated behind OPEN VERIFY
> item #1 (pf viability on this macOS build)*. That verify ran (read-only pf-viability drop,
> 2026-06-14) and resolved **NO**: host-pf cannot enforce same-host UID-keyed redirect-to-proxy
> on this macOS version. Plan A is therefore off the table — not on preference, on a failed
> verify gate. Decision status returns to OPEN among the surviving plans. Findings below.

### Verify item #1 result (pf-viability drop, 2026-06-14) — Plan A eliminated
- `pf route-to` performs policy routing, **not** transparent proxy redirection — it changes the
  egress path/interface but does not hand the connection to a local proxy listener.
- `pf rdr` (redirect) **cannot match on UID/user** — the redirect grammar has no user selector;
  only inbound/destination tuples. So "redirect this UID's 443 to the local proxy" is
  unexpressible: the two features that would compose (UID match + redirect) do not compose.
- pf **address translation precedes filtering**, so even a filter-stage UID match cannot drive a
  translation decision.
- There is **no per-agent UID** within one OpenClaw gateway (gateway runs as a single UID;
  per-UID separation needs a *separate gateway/service instance*), so the dedicated-reader-UID
  premise Plan A depended on does not hold without additional infrastructure.
- Net: the UID-keyed-pf mechanism is not viable on this host. Squid/tinyproxy as *engines* remain
  fine; the missing piece is an enforceable, non-bypassable **forced-routing** layer on macOS.

### Why the Docker decision was narrowed (verify-drop findings, 2026-06-14)

The egress-verify drop established that containerizing the confined reader is NOT a config
change — it is a port:
- `gog-gmail-draft-safe` is a **macOS arm64 Mach-O** → cannot execute in a Linux sandbox even
  if mounted; needs a Linux arm64 rebuild of the safe-send binary.
- Node is host Homebrew Mach-O → needs Linux Node in a custom image.
- Wrapper UID-checks the keyring password file (host UID 501 must equal process UID) → fails
  closed on mismatch; container needs deliberate UID handling.
- gog home is a full writable credential store (OAuth client metadata, credentials index,
  encrypted keyring + lock) → needs writable, protected mounts, not a single secret file.
- A Docker bridge gives outbound connectivity but is **not itself an allowlist** — DOCKER-USER
  iptables rules still required on top.

Net: containerizing forces a rebuild AND revalidation of the load-bearing no-send chain (§8:
scope is the load-bearing control; the 3-layer no-send is the proven belt). Re-proving that
through a freshly-built Linux binary is a new attack surface for no current functional gain,
because the reader stays supervised until egress lands regardless.

### Field-standard reality (researched 2026-06-14)

Per-application outbound domain control, everywhere it is done (AWS, GCP, Qovery, Databricks):
**a forward proxy that filters on destination hostname / TLS SNI, default-deny**, app pointed
at it. Squid is the default engine; tinyproxy is the lightweight option. SNI/host-header
filtering keeps TLS end-to-end (no MITM cert to install in the reader).

**The load-bearing distinction:** the proxy allowlists domains; a SEPARATE forced-routing
layer is what stops the app bypassing the proxy. Env-var proxying (`HTTPS_PROXY`,
`NODE_USE_ENV_PROXY`) is **cooperative only** — a hijacked process ignores it and opens a
direct socket. Env vars are a convenience, NOT an exfil control. The enforcement must be a
layer the reader cannot opt out of.

### macOS enforcement mechanism

**(Superseded — see verify item #1 result above: this mechanism was eliminated. Retained only to explain what was attempted.)**

No Linux netns, no NetworkPolicy on macOS. The one host-level chokepoint for same-host
outbound is **pf, keyed on UID** (pf's only usable selector for own-box traffic is user/group,
not PID). The candidate recipe was:
- Run the reader under a **dedicated UID**.
- `route-to lo0` all of that UID's outbound 80/443 → a **local allowlisting forward proxy**.
- Run the proxy under a **DIFFERENT UID** so its own egress is not re-redirected (the UID is
  the filter that prevents the proxy looping its own traffic).

**Note (2026-06-14c):** an earlier pass argued UID-keyed forced routing was the legitimate macOS mechanism. The pf-viability verify (above) supersedes that: the UID-match and redirect features do not compose on this macOS build, so the mechanism is eliminated regardless of standardness. Operational fragility was not even the deciding factor — expressibility was.

### DECISION STATUS (2026-06-14c): OPEN — operator decision required
Plan A eliminated (above). Surviving options:

- **Plan B — separate egress box.** A small always-on box (Pi/spare machine) is the only internet
  route for the reader; allowlist at its interface. Field-standard and robust. Cost: added
  hardware + a network hop + its own setup. **No new software prerequisite on the Mini.**
- **Plan C — Docker container egress (revived from shelf).** Containerize the reader on an
  `internal:true` Docker network with a Squid allowlist forward proxy; enforcement runs inside
  Docker Desktop's Linux VM (iptables/DOCKER-USER), which sidesteps macOS pf entirely — this is
  the field-standard mechanism and the reason Docker keeps recurring. **Hard prerequisite: Docker
  is NOT installed (FLAG), so this path starts with an operator decision to install a container
  runtime.** Also carries the §4 port costs already documented above (Mach-O→Linux rebuild of the
  safe-send binary, gog file-keyring UID handling, writable protected credential mounts, and the
  bind-validator constraint that rejects mounting `~/.openclaw` subdirs — so the reader's keyring/
  wrapper chain must be re-homed or re-proven). **Net answer to the standing §4 VERIFY question
  "does sandboxing the reader break the keyring/wrapper": YES, in the specific ways listed — it
  requires re-homing the credential chain, not a transparent lift-and-shift.**

**This choice is the operator's (Plan B vs install-Docker-for-Plan-C). It is NOT resolved here.**
The next build step cannot proceed until it is made.

#### Considered, NOT adopted (recorded as input only — not decisions)
- *Cooperative env-var proxying alone* (`HTTPS_PROXY`/`NODE_USE_ENV_PROXY`): a hijacked process
  ignores it. Convenience, not an exfil control. Only valid as belt alongside a forced layer.
- *Credential-broker / exec-profile-narrowing as a PRECURSOR to egress*: field research this
  session noted the reader's host `exec` (mode auto) lets a hijacked reader read its own keyring,
  making egress the *last* link rather than the first. Whether to narrow the reader's exec/tool
  profile (or broker the credential) BEFORE building egress is a **sequencing question for the
  operator** — recorded here as an option, explicitly not a change to the foundations-first order
  in CONTROL.md.
## 5. Observability / audit — Foundation 3 (RESEARCHED; critical finding)

**THE key finding for the V1 "zero silent failures" gate:**
- **Agent self-logging is honor-system and has structural gaps:** cron jobs, sub-agents, and heartbeat sessions run in isolated contexts and DON'T share the main session's logging; the agent could skip entries; no centralized view. [GitHub #13131.] **So "zero silent failures" CANNOT be built on agent self-reporting.** It must be built on gateway-level / OTel instrumentation that captures every tool call regardless of session type.
- **Built-in OTel support (v2026.2+):** `diagnostics.otel` config (`enabled`, `endpoint`, `serviceName`, `traces`, `metrics`, `logs`). Emits spans: `openclaw.request` (root, full lifecycle) → `openclaw.agent.turn` → `tool.*` children. This is the spine for correlation-ID tracing and run-replay.
- **Plugin hooks for deeper capture:** `before_tool_call`, `before_agent_reply`, `agent_end`, `subagent_spawned`, `cron_changed`, etc. Hooks include `runId`/`ctx.runId` (and `ctx.jobId` for cron) + a W3C trace context for OTEL correlation. A native plugin captures what a network proxy can't (skill loads, memory recall, sub-agent routing, heartbeat decisions).
- **Existing tooling to evaluate (don't rebuild):** `henrikrexed/openclaw-observability-plugin` (OTel traces/metrics/logs + built-in dashboard), Opik (`opik-openclaw`, self-hostable, LLM-as-judge eval), Arize. Plus the GitHub topology-visualizer/agent-dashboard from the earlier ecosystem scan.

**Verified design direction for Foundation 3:** built-in `diagnostics.otel` for operational metrics + a lifecycle plugin (or existing observability plugin) for tool-call/trace capture across ALL session types (incl. cron/heartbeat/sub-agents) → local OTel collector → queryable store. "Zero silent failures" = a query over gateway-captured tool spans showing every call has a traced result and every failure a delivered notification. NOT agent self-report.

---

## 6. Automation / cron / heartbeat — (RESEARCHED; for autonomy phases)

- **Cron:** precise schedules + one-shot reminders; ALL cron executions create task records (auditable). Exact user-requested reminders belong to cron.
- **Heartbeat:** routine monitoring (inbox/calendar/notifications) batched every ~30 min. This is the mechanism for proactive "notice the vacation, propose AC-off" behavior — but see observability gap (heartbeat runs isolated, needs gateway-level logging).
- **Standing orders:** persistent operating authority in workspace files (AGENTS.md), injected every session — combine with cron for time-based enforcement. This is where the dispatch/confirm doctrine + deny-by-default live operationally once foundations exist.
- **Task Flow / Background Tasks:** durable multi-step orchestration with a task ledger (`openclaw tasks flow list|show|cancel`) — auditable detached work.
- **Cost caution:** heartbeat + cron creep token spend; small config edits compound. Budget/monitor via OTel cost metrics.

---

## 7. Secrets / credentials — (RESEARCHED; for credential-proxy foundation)

- **gog file keyring** for headless (Keychain unreliable over SSH). Tokens encrypted (AES-256-GCM per some guides).
- **Sandbox secret delivery:** env doesn't inherit; `sandbox.docker.env` is Docker-inspectable (metadata exposure) — use custom image / mounted secret file for real secrets.
- **Credential/capability-broker pattern** (Foundation 2/secrets): agent calls a broker that holds the credential and exposes fixed semantic methods. Gmail implements this under dedicated user `gmailbroker`; the approved reader path has no Gmail credentials.
- **Least privilege / dedicated account:** community standard is a dedicated Gmail account for the bot, minimal scope, short-lived where possible.

---

## 8. Field-standard baseline (what OpenClaw Gmail users actually do)

Historical field baseline, retained for comparison rather than as current Gmail state:
- gogcli (`gog`) + OAuth, scopes in OS keyring. (Universal.)
- `gmail.readonly` first, `draft-not-send` forever for most. (Consensus.)
- The live Gmail design is stricter than this baseline: dedicated capability broker, broker-owned credentials, and a fail-closed reader execution allowlist. A synchronized Codex Apps Gmail connector remains an open complete-mediation gap and must not be mistaken for an approved field-standard fallback.
- Cheap always-on box (VPS/Pi/Mac mini). Dedicated bot Gmail account recommended.
- Real failure mode in the wild: agent granted modify/delete scope bulk-deleted email (Meta safety director incident). Lesson: SCOPE is the load-bearing control. Our three-layer no-send is already stronger than the norm.

---

## 9. Per-phase VERIFY gate status

| Phase | Section | Status |
|---|---|---|
| Email loop runtime/exec | §1, §2 | VERIFIED AGAIN 2026-07-14 — local confined reader, one broker-client allowlist, `ask:off`; June 14 Codex `auto` result is historical |
| Foundation 2 — egress/sandbox | §3, §4 | Deferred capability. Required F-A4 dependency. Operator-owned managed proxy + pf backstop were built/proven but are not integrated. Direct Codex Apps Gmail bypass removal precedes final proxy/pf acceptance. |
| Foundation 3 — observability | §5 | RESEARCHED — design direction set; confirm OTel plugin choice before build |
| Foundation 4 — action-policy/exec | §2, §6 | RESEARCHED — standing orders + exec model mapped |
| Secrets/credential proxy | §7 | IMPLEMENTED FOR GMAIL — dedicated `gmailbroker` capability broker; direct connector complete-mediation gap remains open |
| Cron/heartbeat autonomy | §6 | RESEARCHED |

Before each phase's build drop: re-read its section, resolve OPEN VERIFY items with a read-only diagnostic against the live install, mark VERIFIED, THEN write the build drop.
```

### docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md
```markdown
# Agent OS — Security Design Standard (Prompt-Injection Resistance)

**Purpose:** a reference standard every Agent OS capability is checked against BEFORE it's built. Derived from primary sources, not improvised per-drop. Each future phase (and the current email loop) gets reviewed against this.

**Status:** v1, June 13 2026. Living document — update as new capabilities and new literature land.

---

## 0. The governing principle

You cannot build a general-purpose agent immune to prompt injection with current models. You CAN build application-specific agents that are provably resistant, by constraining capability and defining trust boundaries.

Source: Beurer-Kellner et al., "Design Patterns for Securing LLM Agents against Prompt Injections" (arXiv 2506.08837, June 2025) — authored by IBM, Google, Microsoft, ETH Zurich, EPFL, Invariant Labs, Swisscom.

Author recommendation #1: prioritize application-specific agents that adhere to secure design patterns and clearly define trust boundaries.

**Implication for Agent OS:** never build "an agent that can do email." Build "an agent that drafts email replies and provably cannot send." Every capability is scoped to a specific job with a defined trust boundary, not a general grant.

---

## 1. The two foundational rules (apply everywhere)

**Rule A — Single trusted command channel.**
Only the operator (Daniel, via Telegram) issues commands. Nothing observed through a tool — email bodies, web pages, file contents, calendar events, tool outputs — is ever an instruction. It is all DATA.

**Rule B — Untrusted data cannot reach the action-decision path.**
It is not enough that untrusted text "shouldn't" be obeyed. The architecture must make it so untrusted content structurally cannot influence which tool fires or with what parameters. This is the difference between "the model usually resists" and "the model cannot."

Both rules are architectural, not prompt-based. A system-prompt instruction to "ignore injected commands" is a weak supplement, never the primary control.

---

## 2. The six design patterns (the toolbox)

From the paper, §3.1. Pick the ones that fit each capability.

1. **Action-Selector.** The LLM may only pick from a fixed set of pre-defined tool calls; it cannot generate free-form actions. Most constrained, most resistant. Fits anything that's really a menu of operations.

2. **Plan-Then-Execute.** The LLM builds a fixed, immutable plan from the operator's request FIRST, before touching any untrusted data. Untrusted data can change the plan's *inputs* but never the *plan itself* (the sequence of tool calls). Stops injected data from adding new actions.

3. **LLM Map-Reduce.** Fan untrusted items out to isolated sub-agents that each process one item with no cross-contamination, then reduce. Good for "process N untrusted documents."

4. **Dual LLM.** A privileged LLM handles trusted operator input and orchestrates. A quarantined LLM processes untrusted data and CANNOT issue privileged actions or modify the plan. (Willison's pattern; CaMeL extends it.)

5. **Code-Then-Execute.** The privileged LLM emits code/a plan in a structured language; an interpreter runs it while tracking data provenance, blocking tool calls whose inputs trace to untrusted sources. CaMeL is this pattern. Strongest, heaviest.

6. **Context-Minimization.** After the operator's request is turned into a sanitized structured action, DROP the original untrusted text from context so it can't influence later steps (post-processing, formatting, follow-on calls). Cheap, broadly applicable.

**Trade-off, stated by the authors:** these patterns constrain agents to prevent them solving *arbitrary* tasks. That constraint IS the security. Resist the urge to make a capability "more general" — generality is the attack surface.

---

## 3. Email & Calendar Assistant — the paper's own case study (§4.3)

The paper analyzes THIS use case directly. For an email/calendar assistant it endorses three designs, all of which Agent OS should implement in combination:

- **User confirmation** — operator approves before any consequential action (send). In the approved broker path, send is absent and the operator sends manually from Gmail. A separate direct Codex Apps Gmail connector undermines the system-wide claim until it is disabled. Broker path ✓ BUILT; global exclusivity OPEN.
- **Plan-Then-Execute / Code-Then-Execute** — fix the action plan from the operator request before reading email.
- **Dual LLM** — quarantined reader processes email content; privileged plane orchestrates. ✓ BUILT + PROVEN (reader/researcher split with typed handoff).

---

## 4. Coverage scorecard — current email loop vs. the standard

| Control | Pattern | Status |
|---|---|---|
| Operator-only command channel (Telegram) | Rule A | Designed into loop |
| Email content treated as inert data | Rule A / Dual LLM | ✓ BUILT (reader doctrine + typed handoff) |
| Send structurally impossible on approved path | Action-Selector + capability broker restriction | ✓ BUILT + PROVEN for broker (broker exposes no send operation; 3 agent-side layers retained) |
| No alternate Gmail action surface | Complete mediation | OPEN — synchronized Codex Apps Gmail connector exposes operations outside broker contract |
| Operator reviews every broker-created draft | User confirmation | ✓ BUILT (draft-only broker, manual send); not a global guarantee until alternate connector is disabled |
| Quarantined reader / separate research plane | Dual LLM | ✓ BUILT + PROVEN (F-A3) |
| Research agent cannot see raw email | Dual LLM / least-privilege | ✓ BUILT + PROVEN (typed canonical handoff; no raw email) |
| Sanitized structured research questions, raw email dropped | Context-Minimization (strong) | ✓ BUILT + PROVEN at handoff; semantic smuggling remains a residual risk until F-A4 egress closes |
| Provenance tracking (input→action) | Code-Then-Execute / CaMeL | NOT BUILT — future, heavy |
| Egress control (data can't leave) | — | NOT BUILT — explicitly deferred |

---

## 5. Known gaps & residual risks (be honest, track them)

1. **Research-question smuggle path (the gap Codex flagged).** The reader emits "research questions" to the researcher. If the reader is injected, those questions are a potential exfil channel. The standard's fix is *strong context-minimization*: the research question must be a MINIMIZED, STRUCTURED extraction (ideally constrained to a fixed schema / enum of question types), not free-form text. Treat free-form reader→researcher text as a smuggle path until it's schema-constrained.

2. **No provenance tracking.** Agent OS uses agent-separation (Dual LLM), not value-level provenance (Code-Then-Execute/CaMeL). This is a deliberate weight trade-off. It means the boundary is "the researcher never receives raw email," not a cryptographic guarantee no email-derived byte reaches a query. Acceptable for supervised, non-sensitive use; NOT acceptable for unattended sensitive mail.

3. **No egress control.** Nothing yet prevents a compromised plane from exfiltrating via an allowed channel. Loop is therefore gated: supervised, non-sensitive ONLY until egress control is built.

4. **Direct Codex Apps Gmail connector bypass.** Read-only audit on 2026-07-14 found synchronized `codex_apps__gmail` / `mcp__codex_apps__gmail*` tool definitions in every inspected per-agent Codex home, including operations outside the broker contract. Historical state contains direct Gmail tool identifiers. No live connector call was made during the audit, but lazy loading means absence from current thread dynamic-tool tables is not proof of unavailability. Broker-only routing remains open until the connector surface is disabled and negative-tested.

5. **Credential custody — resolved for the broker path.** The Gmail keyring and password are broker-owned under dedicated user `gmailbroker`; the confined reader has no credential-file access and the approved execution path calls only the fixed semantic broker. This closes broker-credential theft, not alternate connector access or exfiltration; F-A4 remains required.

---

## 6. Pre-build checklist (run this against EVERY future capability)

Before any new capability (calendar, more agents, command center) is built, answer:

1. What is the specific, bounded task? (If the answer is "general X," stop — narrow it.)
2. What is the trust boundary — what's the trusted command source, what's untrusted data?
3. Which of the 6 patterns apply? (Name them.)
4. Can untrusted data influence which tool fires or its parameters? (If yes, redesign until no.)
5. What's the most dangerous action this capability can take, and is it structurally unreachable from untrusted input?
6. Does the operator confirm consequential actions?
7. Is untrusted context minimized/dropped before post-processing?
8. What are the residual risks, and is the capability gated (supervised/non-sensitive) until they're closed?
9. Is there an egress path? Is data prevented from leaving via allowed channels?
10. Is there a test that PROVES the injection boundary holds (not just that it's designed)?

A capability doesn't ship until 1–10 are answered and the item 10 test passes.

---

## 7. Primary sources

- Beurer-Kellner et al., "Design Patterns for Securing LLM Agents against Prompt Injections," arXiv:2506.08837 (2025). The six patterns + the email-assistant case study. Authors: IBM, Google, Microsoft, ETH Zurich, EPFL, Invariant Labs, Swisscom.
- Google DeepMind, "Defeating Prompt Injections by Design" (CaMeL), 2025. The code-then-execute / provenance-tracking instantiation.
- Microsoft MSRC, "How Microsoft defends against indirect prompt injection" — Spotlighting (mark untrusted content) + FIDES (information-flow control) + the design-patterns consortium.
- Willison, "The Dual LLM Pattern for Building AI Assistants That Can Resist Prompt Injection."
- OWASP LLM Top 10 — LLM01 Prompt Injection — for compliance-framework mapping.
- Reference implementation: github.com/ReversecLabs/design-patterns-for-securing-llm-agents-code-samples (educational, not production).

---

## 8. The one-line standard

**Every Agent OS capability is an application-specific agent with a defined trust boundary, built from the named patterns, where the most dangerous action is structurally unreachable from untrusted data, the operator confirms consequential actions, and an injection-boundary test PROVES it before ship.**
```

### docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md
```markdown
# Agent OS — Roadmap Best-Practices Brief

**Purpose:** the research pass that should have run before each phase, done up front for the whole remaining vision. Every future drop starts from this instead of improvising. Companion to AGENT_OS_SECURITY_DESIGN_STANDARD.md (which covers prompt-injection specifically); this brief covers the other domains each phase touches.

**Method:** primary sources pulled June 13 2026. Each section = the established patterns, the named failure modes, the load-bearing source, and a pre-build checklist. Update as phases land and literature moves.

---

## How to use this

Before ANY future phase is built:
1. Read the matching section here + the security standard's section-6 checklist.
2. Answer the phase's pre-build checklist in the drop's discovery phase.
3. If the phase introduces a capability the brief doesn't cover, research it first and add a section. No more discovering architecture mid-build.

---

## PHASE THEME 1 — More agents / orchestration (researcher, calendar agent, future roster)

**The decision to make first: do you even need another agent?**
The literature is blunt that multi-agent is over-used. A single agent with a concatenated toolbox is competitive with multi-agent for tasks that fit one context window. Multi-agent is justified in exactly two cases: (1) a **privileged-information boundary** exists between agents (your reader-can't-send, researcher-can't-see-email split — legitimate), or (2) multiple distinct principals/stakeholders. If neither holds, adding an agent adds failure surface for no gain.

**The failure data (your single most useful orchestration source):**
MAST taxonomy — "Why Do Multi-Agent LLM Systems Fail?" (Cemri et al., NeurIPS 2025, arXiv:2503.13657). 1,600+ annotated traces across 7 frameworks, expert-validated (κ=0.88). Production multi-agent systems fail at **41–86.7%** rates. 14 failure modes in 3 root categories:
- **Specification issues (~44%)** — ambiguous agent roles/contracts. The largest category. Your defense: explicit, tight agent contracts (you already write these as AGENTS.md doctrine — keep them schema-precise, not prose-vague).
- **Inter-agent misalignment (~32%)** — agents talk past each other, duplicate work, drop responsibilities. Defense: explicit handoff contracts (every handoff has a defined input/output shape — your schema-constrained research request is exactly this pattern; apply it to every handoff).
- **Verification gaps** — no agent owns quality control. Defense: a dedicated verify step (your Buela validator role; make sure it actually runs, not just exists).

**Hard rules from the literature:**
- **Never let one agent trigger another without a cycle check** in the orchestration layer (prevents runaway spawn loops). Your `requireAgentId: true` + exact `allowAgents` list + no nested spawning is the right shape — keep it.
- One compromised agent propagates downstream ("Agent-in-the-Middle," error cascades — arXiv:2603.04474). Trust boundaries must be at the orchestration layer, not per-agent ad hoc.
- Anthropic's own long-running-agent guidance: the two big failure modes are context-loss incoherence and premature wrap-up near context limits; fix is context reset + structured handoff to a fresh agent. (You already do "fresh gmail-reader run for drafting" — that's this pattern.)

**Pre-build checklist (new agent):**
1. Does a privileged-info boundary or distinct principal justify this agent? If not, use a tool on an existing agent.
2. What is its EXACT input contract and output contract? (Schema, not prose.)
3. Every handoff to/from it: defined shape, validated at the boundary?
4. Who verifies its output? Is that verify step real?
5. Cycle check: can it (directly or transitively) trigger a spawn loop? Prove not.
6. Least privilege: minimal tool set, everything else denied by group?
7. Context: does it get a fresh context for distinct sub-tasks, or accumulate and drift?

---

## PHASE THEME 2 — Egress control (deferred, but the real gate for sensitive use)

**This is the most important deferred item and the literature is unusually clear on it.**

**Load-bearing source:** "Silent Egress: When Implicit Prompt Injection Makes LLM Agents Leak Without a Trace" (arXiv:2602.22450, Feb 2026). Uses observed network traffic as ground truth. Findings:
- Prompt-layer defenses offer **limited protection** against exfiltration.
- **Domain allowlisting blocks ~all attempted egress** (P(egress)≈0 with allowlist vs ≈0.89 without). Because the check runs at **tool-execution time**, it does NOT depend on the model resisting injection. This is the whole point — it's a control that works even when the model is fully compromised.
- 95% of successful exfiltration evades output-based safety checks.
- **Sharded exfiltration**: attackers split data across multiple requests to beat single-request DLP. So per-request content inspection is insufficient; you need the network boundary.

**Directly relevant to your platform:** "Caging the Agents: A Zero Trust Security Architecture for Autonomous AI" (arXiv:2603.17419, Feb 2026) — its hardening progression literally starts from an `openclaw-base` VM image. Four containment layers, in order of value:
1. **Kernel-level workload isolation** (gVisor / container).
2. **Credential proxy sidecar** (agent never holds raw credentials — relevant to your keyring exposure tradeoff).
3. **Network egress policy enforcement** (the allowlist).
4. **Prompt integrity framework** (trusted metadata envelopes + untrusted-content labeling + anti-injection rules — you already have the labeling via gog's `<<<EXTERNAL_UNTRUSTED_CONTENT>>>`).

**The five highest-ROI controls** (Schneider, "From LLM to agentic AI," Apr 2026), in priority order:
1. Outbound network allowlist (most exfil prevented by this one control).
2. Human approval for all write/delete/external-state changes. (You have this for send.)
3. Prompt-injection classifier on external inputs.
4. Audit MCP/tool permissions (list every tool, what it accesses, blast radius if compromised).
5. (defense-in-depth beyond these.)

**Implication for your roadmap:** the current loop remains gated "supervised, non-sensitive until the full foundation gate passes." The locked execution sequence is now F-A0 platform audit → F-A1 capability broker → F-A2 credential containment → F-A3 typed handoff → F-A4 egress. F-A1 through F-A3 are complete; F-A4's operator-owned managed proxy and pf backstop were built/proven but are not integrated. The immediate blocker is disabling the confirmed Codex Apps Gmail bypass, followed by proxy/pf acceptance. Container isolation is not the current egress mechanism on this host.

**Pre-build checklist (egress phase):**
1. What is the COMPLETE list of domains each tool legitimately needs? (Default deny, no wildcards.)
2. Is the allowlist enforced at tool-execution/network layer, not prompt layer?
3. Does the research agent's web_search route through the allowlist? (Search is an egress channel.)
4. Sharded exfil: does the boundary catch slow/split leakage, or only single requests?
5. Is there a credential proxy so a compromised agent can't read raw secrets?
6. Workload isolation: is the agent in a container/VM, not just a user account?

---

## PHASE THEME 3 — Observability, audit trail & the V1 trust gate

**Your V1 milestone (30 days daily use, trustworthy audit trails, zero silent failures) IS an observability problem.** The literature gives you the standard.

**The framing (JetBrains/PyCharm eval+observability guide, May 2026):** evaluation determines if the agent CAN work; observability determines if it IS working. You need both. Your 8 behavioral tests = evaluation. Your audit-trail/zero-silent-failure requirement = observability. Don't let one substitute for the other.

**What "trustworthy audit trail" actually requires (consensus across sources):**
- **Structured logging with correlation IDs** on every message, plan, and tool call, so an end-to-end trace can be reconstructed. (This is how Anthropic does centralized token/trace collection.) Your silent-FAIL-notification bug from the OpenClaw v5 work is exactly the failure this prevents — a tool call whose result wasn't traced.
- **Record per step:** the agent's reasoning, which tool was called with what params, what data came back, how the decision was made. Start-to-finish.
- **Immutable logs / full lineage** for the trail to be trustworthy (can't be silently rewritten).
- **Conversation/run replay** — store complete runs so you can rewind, fork with a modified input, and verify a fix. This is how you debug non-deterministic multi-agent failures, where a stack trace is useless.

**"Zero silent failures" is a specific, achievable spec:** every tool call has a traced result; every FAIL produces a delivered notification (your Tiger silent-FAIL bug was a violation); every run is reconstructable from logs. Make "did anything fail without notifying?" a queryable property of the log, not a hope.

**Offline eval methodology (for your 8 tests — Towards Data Science, Mar 2026):**
- Start with the highest-signal metrics (routing accuracy, factual accuracy), easiest to implement.
- Small dataset (50–100 samples) run manually first to calibrate expectations.
- Every run creates a record (which version, which dataset, what scores, thresholds met y/n) — these accumulate into the audit trail that demonstrates systematic QA over time.
- Define acceptance criteria BEFORE the first run. (Your 8 tests should each have a pre-defined pass threshold, not a judgment call after the fact.)

**Pre-build checklist (any capability, observability side):**
1. Does every tool call this capability makes get logged with a correlation ID?
2. Can a full run be reconstructed from logs alone?
3. Does every failure path produce a DELIVERED notification (no silent FAIL)?
4. Are logs immutable / append-only enough to be trustworthy?
5. For the 8-test gate: does each test have a pre-defined pass threshold and a recorded result?
6. Can you query "did anything fail silently in the last 30 days?" and get a real answer?

---

## PHASE THEME 4 — Command Center (P2, hard-held behind 8 tests)

**Why the hold is correct, in the literature's terms:** a Command Center is a control surface that can trigger many capabilities. That makes it a high-blast-radius node. MAST says the largest failure category is specification/coordination; a central controller multiplies coordination surface. The 8-test gate is your verification-gap defense — don't relax it.

**When you build it, treat it as an orchestration node** and run the Theme-1 checklist on it, plus:
- It must not become a path that bypasses per-capability trust boundaries (e.g. a Command Center "send" button that skips the draft-only discipline).
- Every action it can trigger inherits that capability's own confirmation/egress gates — the Command Center doesn't get to be an exception.
- Cycle check is critical here: a controller that can trigger agents that can trigger the controller is a loop generator.

**Pre-build checklist:** Theme-1 checklist + "does any Command Center action bypass an existing trust boundary? (must be no)."

---

## PHASE THEME 5 — Secrets / credentials at scale

As capabilities grow you'll hold more tokens (Gmail today; calendar, others later). Current Gmail state: the file keyring and password are broker-owned under dedicated user `gmailbroker`; the approved reader path receives neither. A separate Codex Apps Gmail connector surface remains an alternate access path and must be disabled before claiming complete mediation.

**The pattern to generalize (from "Caging the Agents" layer 2):** a **credential/capability broker** — the agent calls a broker that holds the credential and exposes only fixed semantic operations; the agent never sees the raw secret or a general provider API. Gmail now implements this pattern under `gmailbroker`; future capabilities should reuse the principle without reopening a direct connector path.

**Rules (OWASP AI Agent Security cheat sheet + LLM Top 10):**
- Least-privilege, **short-lived tokens**, narrow scopes per tool. OAuth scope alone is insufficient when the provider scope is broader than the allowed action set; the Gmail broker's fixed semantic API is the enforcing layer.
- Human approval for high-risk methods (write/delete/transfer) — never delegated to the model.
- Tenant/context isolation between capabilities (Gmail creds never reachable from the calendar agent, etc.).

**Pre-build checklist (new credential):**
1. Narrowest possible scope? Short-lived if possible?
2. Held by a broker/wrapper, not the agent? (Generalize the draft-safe pattern.)
3. Reachable ONLY by the one capability that needs it (group-denied everywhere else)?
4. Is the high-risk action behind human approval, structurally?

---

## The cross-cutting principles (true for every phase)

1. **Application-specific, not general** — every capability is a bounded job with a trust boundary (security standard §0).
2. **Controls at the system/network layer beat controls at the prompt layer** — because they hold even when the model is compromised. Allowlists, wrappers, validators > "the prompt tells it not to." (Silent Egress; your deterministic research-request validator is a textbook instance.)
3. **Every handoff is a validated contract** — schema, not prose (MAST specification failures).
4. **Every consequential action is human-confirmed** — structurally, not by model choice.
5. **Every run is fully traced; no silent failures** — observability is the V1 gate.
6. **Prove it, don't design it** — each capability ships only when a test PROVES its boundary holds (your no-send proof and injection test are the model for this).

---

## Primary sources

- Cemri et al., "Why Do Multi-Agent LLM Systems Fail?" (MAST taxonomy), arXiv:2503.13657, NeurIPS 2025. — orchestration failure modes.
- "Silent Egress: When Implicit Prompt Injection Makes LLM Agents Leak Without a Trace," arXiv:2602.22450, 2026. — egress is the real control.
- "Caging the Agents: A Zero Trust Security Architecture for Autonomous AI," arXiv:2603.17419, 2026. — four-layer containment, built on OpenClaw VMs.
- Schneider, "From LLM to agentic AI: prompt injection got worse," 2026. — five highest-ROI controls.
- OWASP "AI Agent Security Cheat Sheet" + LLM Top 10 (LLM01). — capability/credential discipline.
- Beurer-Kellner et al., arXiv:2506.08837 (the six patterns) — see security standard.
- Google DeepMind, "Towards a Science of Scaling Agent Systems," Dec 2025. — when multi-agent helps vs hurts.
- JetBrains, "LLM Evaluation and AI Observability for Agent Monitoring," 2026; "Production-Ready LLM Agents: Offline Evaluation," 2026. — eval + audit methodology.
- Anthropic long-running-agent guidance — context reset + structured handoff.
```

### docs/F-A1_GMAIL_BROKER_DESIGN.md
```markdown
# F-A1 Gmail Capability Broker Design

Status: BROKER FOUNDATION IMPLEMENTED, EXIT GATE CLOSED, AND FOUNDATION HARDENED. Broker closed its 25/25 exit gate on 2026-06-16; durable socket-directory startup ordering was completed and revalidated on 2026-07-14. This status covers the broker's authority, semantic API, credential custody, and approved client path. It does not claim exclusive Gmail routing: a separate Codex Apps Gmail connector surface was confirmed on 2026-07-14 and remains an open F-A4 containment blocker. `CONTROL.md` is authoritative for live state.

Purpose: make Gmail read/draft access structural instead of cooperative. F-A0 proved the Gmail reader currently runs `exec` as Unix user `agent` and can reach the gog keyring, keyring password, wrapper source, and gog config. The broker must move both credential custody and the Gmail action surface outside reader authority.

Non-goal: this does not solve poisoned summaries, search exfiltration, malicious draft content, or egress. Sensitive data remains held until the full F-A0 through F-D gate passes.

## Implemented hardening record (2026-07-14)

- Root-run `ai.agent-os.gmail-broker-rundir` creates `/var/run/agent-os` as `gmailbroker:gmailbroker-clients` mode `0750` before broker startup.
- Unprivileged `ai.agent-os.gmail-broker` remains `UserName=gmailbroker`; its `KeepAlive` is conditional on `PathState[/var/run/agent-os]=true`, closing the independent launchd startup race without widening permissions or changing the broker boundary.
- Live socket is `gmailbroker:gmailbroker-clients` mode `0660`.
- Both launchd plists pass `plutil -lint`; broker is loaded/running; `health_check` and `search_threads` pass; direct main execution remains per-run approval-gated and denial blocks it.
- Rollback backup: `/Library/LaunchDaemons/ai.agent-os.gmail-broker.plist.backup-20260714T203520Z`.
- Boundary qualification: read-only audit found synchronized `codex_apps__gmail` / `mcp__codex_apps__gmail*` tools outside the broker. No live connector call was made during the audit, but broker-only Gmail confinement remains open until that external surface is disabled and negative-tested.

## 1. Placement & Process Model

### Required authority boundary

The broker MUST NOT run as Unix user `agent`.

Reason: F-A0 found the reader has same-UID `exec` authority as the current Gmail credential files. A same-host process under the same user would not close the hole; the reader could still read files, inspect wrapper source, run alternate child processes, or reach same-UID credential material.

Implemented design target:

- Create a dedicated non-admin macOS user for the broker, named `gmailbroker` unless the operator chooses a different name at build time.
- The broker process runs as `gmailbroker`.
- Gmail credential files are owned by `gmailbroker`, mode `0600` for files and `0700` for credential directories.
- The `agent` user must not be a member of any group that can read the broker credential directory.
- The broker does not need admin privileges after setup.

Alternative only if user creation is rejected: run the broker as the existing admin user `dannybigdeals`, but this is less clean because it places a high-value service under an admin account. Prefer a dedicated non-admin broker user.

### Process supervisor

Use launchd for a persistent broker service:

- Label: `ai.agent-os.gmail-broker`
- Runtime user: `gmailbroker`
- Binary/script location: outside `agent` writable paths, for example `/Users/gmailbroker/agent-os-gmail-broker/bin/gmail-broker`
- Working directory: `/Users/gmailbroker/agent-os-gmail-broker`
- Logs: `/Users/gmailbroker/agent-os-gmail-broker/logs/`

The OpenClaw Gateway runs as `openclawgw`; the broker is a separate local service under `gmailbroker` with a narrow capability API.

### Reader-to-broker channel

Preferred channel: Unix domain socket.

- Socket path: `/var/run/agent-os/gmail-broker.sock`
- Directory owner/group: `gmailbroker:gmailbroker-clients`
- Directory mode: `0750`.
- Socket owner: `gmailbroker`
- Socket mode: `0660`
- Socket group: a dedicated group such as `gmailbroker-clients` containing `agent`, or equivalent launchd-supported ACL.

Why a socket is acceptable: the socket is not a credential path. A compromised reader may be able to call the broker, but the broker exposes only fixed semantic Gmail capabilities and never returns tokens, keyring passwords, refresh tokens, or raw Gmail API access.

Fallback channel if Unix socket permissions are operationally awkward: localhost HTTP bound to `127.0.0.1` on a fixed high port plus a broker-client bearer token stored under the `agent` user. This token is not a Gmail credential. It authorizes only the same fixed broker methods. Prefer the socket because filesystem permissions are simpler to audit than another bearer token.

### Reader integration surface

The reader's current approved execution path calls the root-owned client wrapper:

```text
/Users/agent/.openclaw/scripts/gmail-broker-client.mjs
```

The historical `/usr/local/libexec/agent-os/` path is not the current authority path for this baseline unless later live exec-approval evidence proves otherwise.

That wrapper:

- Encodes/decodes broker JSON.
- Connects to the Unix socket.
- Adds a `correlation_id`.
- Does not know any Gmail OAuth credential, keyring password, refresh token, or gog home.
- Has no fallback path to `gog`, `gog-gmail-draft-safe`, or the old credential-bearing wrapper.

The client wrapper may be readable by `agent`; that is fine because it contains no secrets and no Gmail implementation.

## 2. Credential Custody

### Broker-owned credential paths

Move Gmail runtime credential custody under the broker user. Proposed layout:

```text
/Users/gmailbroker/agent-os-gmail-broker/
  bin/
    gmail-broker
    gog-gmail-draft-safe
  config/
    gmail-broker.json
    gmail-draft-policy.yaml
  gog-home/
    config/config.json
    data/credentials.json
    data/keyring/*
    oauth-client.json
  secrets/
    gog-keyring-password
  logs/
    audit.jsonl
```

Permissions:

```text
/Users/gmailbroker/agent-os-gmail-broker              gmailbroker:staff 0700
/Users/gmailbroker/agent-os-gmail-broker/gog-home     gmailbroker:staff 0700
/Users/gmailbroker/agent-os-gmail-broker/secrets      gmailbroker:staff 0700
.../secrets/gog-keyring-password                      gmailbroker:staff 0600
.../gog-home/data/keyring/*                           gmailbroker:staff 0600
.../gog-home/oauth-client.json                        gmailbroker:staff 0600
.../gog-home/data/credentials.json                    gmailbroker:staff 0600
```

The old reader-reachable paths must be retired from the reader path:

```text
/Users/agent/.openclaw/gmail-draft-gog
/Users/agent/.openclaw/secrets/gog-keyring-password
```

They may be archived during migration, but after F-A1/F-A2 they must not be required for live Gmail operation and must not be readable by the reader.

### Runtime environment

Only the broker process may receive:

```text
GOG_HOME=/Users/gmailbroker/agent-os-gmail-broker/gog-home
GOG_KEYRING_BACKEND=file
GOG_KEYRING_PASSWORD=<read by broker from broker-owned password file>
```

The reader MUST NOT receive `GOG_KEYRING_PASSWORD` in any environment it controls. The broker client wrapper must not set `GOG_HOME`, `GOG_KEYRING_BACKEND`, or `GOG_KEYRING_PASSWORD`.

Credential-hiding alone is not enough. The broker must enforce semantic operations because `gmail.compose` is send-adjacent.

## 3. Allowed Methods

Transport envelope for every request:

```json
{
  "correlation_id": "uuid-v4-or-caller-provided-id",
  "method": "method_name",
  "params": {}
}
```

Transport envelope for every response:

```json
{
  "correlation_id": "same-id",
  "ok": true,
  "result": {}
}
```

Error response:

```json
{
  "correlation_id": "same-id-if-parseable-else-generated",
  "ok": false,
  "error": {
    "code": "unknown_method|malformed_request|validation_failed|gmail_error|broker_unavailable",
    "message": "sanitized human-readable error"
  }
}
```

No response may contain access tokens, refresh tokens, keyring passwords, OAuth client secrets, raw credential files, raw HTTP headers, or raw gog config.

### `health_check`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "health_check",
  "params": {}
}
```

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "status": "ok",
    "service": "gmail-broker",
    "version": "semver-or-git-sha",
    "gmail_account": "daniel.haitz@gmail.com",
    "capabilities": [
      "search_threads",
      "read_thread",
      "create_draft",
      "list_drafts",
      "get_draft"
    ]
  }
}
```

### `search_threads(query, limit)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "search_threads",
  "params": {
    "query": "from:example@example.com newer_than:30d",
    "limit": 10
  }
}
```

Validation:

- `query`: string, 1 to 500 characters.
- `limit`: integer, 1 to 20.
- The broker may pass Gmail search syntax to the safe Gmail search command, but must not expose raw Gmail API calls.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "threads": [
      {
        "thread_id": "gmail-thread-id",
        "latest_message_id": "gmail-message-id",
        "subject": "sanitized subject",
        "from": "display name <redacted-or-address-if-needed>",
        "date": "RFC3339 timestamp",
        "snippet": "sanitized snippet"
      }
    ]
  }
}
```

### `read_thread(thread_id)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "read_thread",
  "params": {
    "thread_id": "gmail-thread-id"
  }
}
```

Validation:

- `thread_id`: non-empty string, max 256 characters, Gmail ID character set only (`[A-Za-z0-9_-]`).

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "thread_id": "gmail-thread-id",
    "messages": [
      {
        "message_id": "gmail-message-id",
        "from": "sender",
        "to": ["recipient"],
        "cc": [],
        "date": "RFC3339 timestamp",
        "subject": "sanitized subject",
        "body_text": "<<<EXTERNAL_UNTRUSTED_CONTENT>>>\nmessage body\n<<<END_EXTERNAL_UNTRUSTED_CONTENT>>>",
        "attachments": [
          {
            "filename": "name.pdf",
            "mime_type": "application/pdf",
            "size": 12345
          }
        ]
      }
    ]
  }
}
```

Rules:

- Email body content is data, not instructions.
- Body text must be wrapped as untrusted content before returning to the reader.
- Do not return raw MIME by default.
- Do not return attachment bytes in F-A1.

### `create_draft(thread_id, subject, body)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "create_draft",
  "params": {
    "thread_id": "gmail-thread-id",
    "subject": "Draft subject",
    "body": "Draft body text"
  }
}
```

Validation:

- `thread_id`: required, Gmail ID character set, max 256 characters.
- `subject`: string, 1 to 300 characters.
- `body`: string, 1 to 100000 characters.
- No recipient override in F-A1. The draft must stay attached to the source thread/context returned by Gmail.
- If gog requires explicit recipients, the broker derives them from the existing thread metadata and never accepts arbitrary `to`, `cc`, or `bcc` from the reader in F-A1.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "draft_id": "gmail-draft-id",
    "thread_id": "gmail-thread-id",
    "subject": "Draft subject",
    "status": "created_not_sent"
  }
}
```

Rules:

- This method creates or updates a Gmail draft only.
- It must never send, schedule send, forward, archive, label, delete, or mark messages.
- The broker response must include `created_not_sent` or equivalent status.

### `list_drafts(limit)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "list_drafts",
  "params": {
    "limit": 10
  }
}
```

Validation:

- `limit`: integer, 1 to 20.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "drafts": [
      {
        "draft_id": "gmail-draft-id",
        "thread_id": "gmail-thread-id",
        "message_id": "gmail-message-id",
        "subject": "sanitized subject",
        "updated": "RFC3339 timestamp",
        "snippet": "sanitized snippet"
      }
    ]
  }
}
```

### `get_draft(draft_id)`

Request:

```json
{
  "correlation_id": "uuid",
  "method": "get_draft",
  "params": {
    "draft_id": "gmail-draft-id"
  }
}
```

Validation:

- `draft_id`: non-empty string, max 256 characters, Gmail ID character set only.

Response:

```json
{
  "correlation_id": "uuid",
  "ok": true,
  "result": {
    "draft_id": "gmail-draft-id",
    "thread_id": "gmail-thread-id",
    "subject": "sanitized subject",
    "body_text": "draft body",
    "status": "draft_not_sent"
  }
}
```

## 4. Forbidden Forever

The broker must have no method, route, CLI mode, or code path for:

- `send_message`
- `send_draft`
- `delete_message`
- `delete_draft`
- `modify_labels`
- `raw_gmail_api_call`
- `return_token`
- `return_keyring_password`
- `return_refresh_token`

Structural absence requirements:

- Do not link or import a general Gmail API surface into the broker if it exposes send/delete/modify/raw methods.
- Prefer invoking the pinned `gog-gmail-draft-safe` binary or a new equally policy-compiled broker-safe binary that contains no send/auth/delete/label/raw command handlers.
- Do not implement generic method dispatch such as `broker.call(action, args)` where `action` can become a Gmail command string.
- Do not accept arbitrary Gmail command names from JSON.
- Do not expose a debug route that dumps env, config, tokens, keyring paths, request headers, or raw gog output.
- Keep OAuth bootstrap tooling out of the broker runtime binary. Auth setup, if needed, is a separate operator-run step.

"Rejected at runtime" is not enough for send/token/raw operations. They should be absent from compiled/runtime code wherever feasible.

## 5. Audit

Every broker request writes one JSONL start record and one JSONL finish record.

Proposed path:

```text
/Users/gmailbroker/agent-os-gmail-broker/logs/audit.jsonl
```

Start record:

```json
{
  "ts": "RFC3339",
  "event": "gmail_broker.request",
  "correlation_id": "uuid",
  "method": "read_thread",
  "caller": "agent",
  "schema_version": 1
}
```

Finish record:

```json
{
  "ts": "RFC3339",
  "event": "gmail_broker.result",
  "correlation_id": "uuid",
  "method": "read_thread",
  "status": "ok|error",
  "error_code": null,
  "duration_ms": 123,
  "result_shape": {
    "messages": 3,
    "body_bytes": 18422
  }
}
```

Logging rules:

- Never log access tokens, refresh tokens, keyring passwords, OAuth client secrets, raw credential files, raw request/response headers, or environment dumps.
- Do not log full email bodies or draft bodies.
- If body-level correlation is needed later, log a cryptographic hash and byte count, not content.
- Redact subject/snippet fields by default unless F-B observability explicitly approves a redaction policy.
- All failures must log `correlation_id`, method if parseable, error code, and status.

F-B tie-in: this JSONL is the local substrate that F-B can ingest into the broader observability/audit trail. F-A1 should keep the format simple and stable rather than building the full F-B system early.

## 6. Failure Behavior

Fail closed on every ambiguity, per `PRIOR_BUILD_LEARNINGS.md` item 10.

Rules:

- Unknown method: return `ok:false`, `error.code="unknown_method"`, do nothing.
- Malformed JSON: return `ok:false`, `error.code="malformed_request"` if a response is possible, do nothing.
- Schema validation failure: return `ok:false`, `error.code="validation_failed"`, do nothing.
- Missing or duplicate `correlation_id`: generate/log a broker-side ID for audit, return validation failure unless the request otherwise cannot be parsed.
- Broker cannot read its own credential: return `ok:false`, `error.code="broker_credential_unavailable"`, do not fall back.
- Gog/safe binary returns unexpected shape: return `ok:false`, `error.code="gmail_error"`, do not guess.
- Broker unreachable: reader returns a clean operator-facing error.
- Broker unreachable must never cause the reader or main agent to call direct gog, raw Gmail, the old credential-bearing wrapper, or any fallback send/draft path.

The reader-side client must have a hardcoded "broker only" policy. No local fallback.

## 7. Negative Tests / Exit Gate

These tests define DONE for the F-A1 build phase. The broker is not accepted until they pass.

Retrospective scope note (2026-07-14): the original 25/25 gate proved the broker implementation, credential boundary, and approved reader client. It did not inventory Codex Apps/remote connector surfaces. The later boundary audit found a direct Gmail connector outside the broker, so the F-A1 broker gate remains closed while the broader claim "broker is the only Gmail route" remains open under F-A4.

### Credential custody tests

1. Reader cannot read keyring password env var.
   - Spawn/execute as the Gmail Reader path.
   - Assert `GOG_KEYRING_PASSWORD` is absent from the reader environment and from child processes it controls.

2. Reader cannot read credential files.
   - As the reader/`agent` user, attempt to read:
     - `/Users/gmailbroker/agent-os-gmail-broker/secrets/gog-keyring-password`
     - `/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/keyring/*`
     - `/Users/gmailbroker/agent-os-gmail-broker/gog-home/oauth-client.json`
     - `/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/credentials.json`
   - Expected: permission denied or path inaccessible.

3. Reader no longer needs old credential paths.
   - Temporarily make old `/Users/agent/.openclaw/gmail-draft-gog` unavailable in a test environment.
   - Positive read/draft broker loop still works.

### Send/raw absence tests

4. Reader cannot call Gmail send by any path.
   - Attempt broker method `send_message`.
   - Attempt broker method `send_draft`.
   - Attempt to pass a send command name through any `method` or `params`.
   - Expected: fail closed; no Sent count increase.

5. Reader cannot call raw Gmail API.
   - Attempt `raw_gmail_api_call`.
   - Attempt method injection through strings such as `gmail.users.messages.send`.
   - Expected: fail closed; no raw API call path exists.

6. Reader cannot create a draft except via broker.
   - Reader-side tool contract contains only broker client.
   - Old credential-bearing wrapper is not callable from reader.
   - Direct gog binary calls fail because no reader-readable credentials exist.

### Broker validation tests

7. Unknown broker method fails closed.
   - Request: `{"method":"modify_labels","params":{...}}`
   - Expected: `ok:false`, `unknown_method`, no Gmail side effect.

8. Malformed broker request fails closed.
   - Invalid JSON, missing method, wrong param types, overlong IDs/body.
   - Expected: `ok:false`, no Gmail side effect.

### Positive path tests

9. Reader can still search/read a thread via broker.
   - `search_threads` returns sanitized metadata.
   - `read_thread` returns body text wrapped as untrusted content.

10. Reader can still create a draft via broker.
   - `create_draft` creates a Gmail draft in the target thread.
   - Response includes draft ID and `created_not_sent`.
   - Sent baseline remains unchanged.

### Audit tests

11. Every broker request produces audit records.
   - Verify start and finish JSONL records for success and failure.
   - Verify correlation IDs match.

12. Audit logs contain no secrets or bodies.
   - Scan audit log for keyring password, token-looking values, refresh tokens, OAuth client secret, full email body, and full draft body.
   - Expected: no matches.

## 8. Historical build handoff — completed

The original build sequence created the dedicated `gmailbroker` authority, migrated credential custody, built the six-method broker, installed the credential-free client, wired the reader, and closed the negative-test gate. Do not re-run that sequence or recreate its users, credentials, directories, or services.

Current live state and the next bounded task are maintained in `CONTROL.md`. The remaining direct Codex Apps Gmail connector is outside this broker implementation and is tracked as an F-A4 containment blocker; removing it must not widen or redesign the broker.
```

### docs/AGENT_OS_OBLIGATION_REGISTER.md
```markdown
# Agent OS Obligation Register

## Purpose

Prevent security-critical obligations from disappearing during document refactoring, compression, or publication changes.

Every obligation must eventually be classified as:

- Closed
- Moved
- Retired
- Superseded

No silent deletion is allowed.

## Initial Migration Table

| Obligation | Status | Reference |
|---|---|---|
| Aquaman source audit + native SecretRef comparison | Pending classification | |
| ClawGuard source review before audit trust | Pending classification | |
| Browser fill tool-side secret resolution | Moved | `docs/OPENCLAW_BUILD_PLAN.md` |
| OpenAI key plaintext custody flag | Pending classification | |
```

### docs/ADR-014_OPENCLAW_2026_6_11_BASELINE.md
```markdown
# ADR-014 — OpenClaw 2026.6.11 Runtime Baseline

## Decision

OpenClaw `2026.6.11 (e085fa1)` is the current documented runtime baseline.

## Evidence Status

- F-A0 and F-A3 evidence was originally generated on prior OpenClaw runtime baselines.
- The 2026.6.11 reconciliation records current runtime state; it does not by itself revalidate every historical boundary.
- Runtime upgrade requires bounded regression before F-A4 closure.
- No security boundary is considered reopened solely by documentation.

## Consequences

- F-A4 closure must include regression evidence on the 2026.6.11 baseline or any later qualified runtime.
- Documentation may preserve historical version references when they identify the runtime used for original evidence.
- Live runtime evidence overrides documentation when observed state conflicts with recorded state.
```

### audits/2026-06-12-gmail-connector-discovery.md
```markdown
# Gmail Connector Discovery

**Date:** 2026-06-12  
**Installed OpenClaw:** 2026.6.5  
**Verdict:** **NO-GO for the stock setup path.**

**Plain-English answer:** We can authorize Gmail so Google permits reading but
not sending, and we can route incoming mail to a dedicated reader agent.
However, OpenClaw 2026.6.5's stock Gmail setup persists hook authentication
secrets in plaintext in `openclaw.json`. Do not grant Gmail OAuth until that
secret-storage gap and the default main-agent/delivery behavior are remediated.

## 1. Connect mechanism — SETTLED

Gmail is not an OpenClaw chat channel or a Gmail tool plugin. It is a built-in
Gmail Pub/Sub webhook integration:

```text
Gmail API watch -> Google Pub/Sub -> gog gmail watch serve/pull
-> OpenClaw /hooks/gmail -> agent turn
```

The installed command is:

```bash
openclaw webhooks gmail setup --account <email>
```

That command requires `gcloud`, `gog` (`gogcli`), and normally Tailscale. It
creates/enables Google APIs and Pub/Sub resources, starts the Gmail watch,
enables OpenClaw hooks and the Gmail preset, writes `hooks.gmail`, and configures
the push endpoint. It is mutating and was not run.

Current machine discovery:

- `gog`: not installed
- `gcloud`: not installed
- `tailscale`: installed
- `hooks`: not configured

The operator must authorize `gog` separately before OpenClaw can start the
watch. The OpenClaw setup command does not provide a Gmail OAuth-scope flag.

## 2. OAuth scope — SETTLED

`gog auth add` supports both:

```bash
gog auth add <email> --services gmail --readonly
gog auth add <email> --services gmail --gmail-scope readonly
```

Either selects exactly:

```text
https://www.googleapis.com/auth/gmail.readonly
```

plus OIDC identity scopes (`openid`, `email`, and `userinfo.email`). The default
Gmail authorization is not read-only: it requests `gmail.modify` plus Gmail
settings scopes. Therefore the future operator OAuth command must explicitly
select Gmail only and `--gmail-scope readonly` (or `--readonly`).

`gmail.readonly` is provider-enforced: Gmail send, modify, draft-write, label
mutation, and settings operations are outside the token's authority.

For a real Gmail-draft workflow, `gmail.compose` is the narrower applicable
scope: it permits creating and managing drafts, but it also permits sending
mail, including sending those drafts. Therefore `gmail.compose` can support
"agent creates draft, operator sends," but never-send becomes a software
guarantee rather than a provider-enforced boundary. The connector must make
`users.drafts.send` and `users.messages.send` unreachable.

The current `gog` CLI exposes only `full|readonly` through
`--gmail-scope`. Option B would therefore need readonly plus an explicit
additional compose scope, rather than an unsupported
`--gmail-scope compose` value:

```bash
gog auth add <email> \
  --services gmail \
  --gmail-scope readonly \
  --extra-scopes https://www.googleapis.com/auth/gmail.compose
```

## 3. Untrusted data surface — SETTLED

The watcher sends these message fields to OpenClaw:

- message ID and thread ID
- sender and recipient
- subject and date
- snippet
- labels
- optional first `text/plain` body, truncated to `maxBytes`

The installed OpenClaw setup defaults `includeBody` to `true` and `maxBytes` to
20,000. The built-in Gmail mapping renders sender, subject, snippet, and body
into the agent prompt.

Attachments and attachment bytes are not present in the watch payload. Reading
them would require a separate Gmail fetch/attachment command and is outside
this connector-discovery drop.

Gmail hook sessions receive OpenClaw's external-untrusted-content wrapping and
special-token sanitization by default. `hooks.gmail.allowUnsafeExternalContent`
must remain unset/false. This prompt wrapper is defense-in-depth, not a
structural permission boundary.

## 4. Send-disable — SETTLED WITH CONSTRAINTS

The strongest connector-level send denial is the `gmail.readonly` OAuth grant:
it cannot send through Google's API, but it also cannot create Gmail drafts.

With `gmail.compose`, Gmail drafts can be created, but the same scope authorizes
both `users.drafts.send` and `users.messages.send`. Under that option, no-send
must be enforced in software and audited at every executable surface.

`gog` also has `--gmail-no-send`, config `gmail_no_send`, exact command
allowlists, and baked read-only safety-profile binaries. These are useful
additional controls, but the OpenClaw watcher invocation does not add
`--gmail-no-send`. For this integration the read-only OAuth scope is the
provider-enforced wall.

The Gmail hook only receives inbound events; it does not expose a Gmail send
method to the agent. Future on-demand Gmail access must use a restricted reader
surface, not a general `gog` binary reachable through unrestricted exec.

One separate default is unsafe for the planned read-and-report phase:
OpenClaw resolves an omitted hook `deliver` value as `true`. The stock Gmail
preset omits `deliver`, so the build must override the mapping with
`deliver: false`.

### Option B send-path audit — SETTLED WITH CONSTRAINTS

The current `gog` source contains three direct Gmail API send call sites:

- `internal/cmd/gmail_drafts.go`: `GmailDraftsSendCmd` calls
  `svc.Users.Drafts.Send`. Reachable through `gog gmail drafts send`.
- `internal/cmd/gmail_send.go`: `sendGmailBatches` calls
  `svc.Users.Messages.Send`. Reachable through `gog gmail send`; the
  `gmail autoreply` command also reaches this helper.
- `internal/cmd/gmail_forward.go`: `GmailForwardCmd` calls
  `svc.Users.Messages.Send`. Reachable through `gog gmail forward`.

`gog` has a software guard covering the send command paths `gmail.send`,
`gmail.autoreply`, `gmail.forward`, and `gmail.drafts.send` through the
`--gmail-no-send` flag, global `gmail_no_send` config, or per-account no-send
config. Draft create and update are not classified as sends.

The installed OpenClaw Gmail webhook invokes only:

- `gog gmail watch start`
- `gog gmail watch serve`

Those watcher paths fetch Gmail changes and POST inbound events to
`/hooks/gmail`; they do not call any Gmail send API. Therefore the direct
inbound-webhook-only process is not connected to the three send call sites.

This is auditably no-send only while the reader agent cannot execute the general
`gog` CLI or another Gmail-capable tool. Granting `gmail.compose` to a credential
available to unrestricted `gog` remains send-capable despite the webhook path
itself being inbound-only. A future compose build must combine dedicated reader
confinement with `gmail_no_send` defense-in-depth and expose only a narrow
draft-create/update wrapper, never the general `gog` command surface.

Audit-version caveat: `gog` is not installed on this machine yet. The `gog`
findings above are from the current upstream source, while the webhook
reachability findings are from installed OpenClaw 2026.6.5. The exact installed
`gog` version must be pinned and rescanned before Option B is activated.

## 5. Credential storage — OPEN / BLOCKER

Gmail OAuth credentials do stay outside `openclaw.json`:

- OAuth client JSON is stored in the gog config directory.
- Refresh tokens are stored by gog's secret store.
- On macOS the default secret-store backend is Keychain.

This is not OpenClaw SecretRef; it is an external Keychain-backed credential
store, which is acceptable for the OAuth refresh token.

The blocker is OpenClaw hook authentication:

- `openclaw webhooks gmail setup` generates `hooks.token` and
  `hooks.gmail.pushToken`.
- The setup source writes both values directly into `openclaw.json`.
- OpenClaw's SecretRef support matrix explicitly lists both paths as
  unsupported because they are runtime-minted/session-bearing credentials.
- Both schema fields are strings, not SecretRef objects.

Therefore the stock setup violates the existing no-plaintext-secret-at-rest
rule and would put secrets into the git-baselined config. This must be solved
by an OpenClaw version/code change or a reviewed alternative hook-auth design
before OAuth or connector activation.

## 6. Reader-agent confinement — SETTLED WITH REQUIRED OVERRIDE

The stock Gmail preset has no `agentId`, so it falls back to the default agent,
currently `main`.

Hook mappings support:

- explicit `agentId`
- `hooks.allowedAgentIds`
- per-message or static session keys
- `deliver: false`

Custom mappings are evaluated before preset mappings, and the first matching
mapping wins. The build can therefore override `/hooks/gmail` with an explicit
dedicated reader agent and restrict `hooks.allowedAgentIds` to that reader.
The reader must hold no secrets and have no host-action, session, gateway,
message-send, or general exec capability.

The current `heartbeat` agent definition demonstrates the multi-agent pattern,
but a separate email reader has not been created in this drop.

## Build entry conditions

Do not perform Gmail OAuth until a reviewed build drop provides all of:

1. Choose explicitly between structurally no-send `gmail.readonly`, or
   `gmail.compose` plus reviewed software controls for real Gmail drafts.
2. No plaintext `hooks.token` or `hooks.gmail.pushToken` in tracked config.
3. A dedicated restricted reader agent.
4. An explicit Gmail mapping to that reader with `deliver: false`.
5. `hooks.allowedAgentIds` restricted to the reader.
6. External-content safety wrapping left enabled.

No OAuth grant, dependency installation, connector activation, config write,
email read, or email send occurred during this discovery.

## Sources inspected

- Installed OpenClaw CLI help, configuration schema, docs, and compiled source
  for `webhooks gmail`, Gmail watcher setup, hook mapping, external-content
  wrapping, routing, and SecretRef support.
- Official gogcli source:
  - <https://github.com/openclaw/gogcli/blob/main/internal/googleauth/service.go>
  - <https://github.com/openclaw/gogcli/blob/main/internal/cmd/auth_add.go>
  - <https://github.com/openclaw/gogcli/blob/main/internal/cmd/gmail_no_send.go>
  - <https://github.com/openclaw/gogcli/blob/main/internal/secrets/store.go>
  - <https://github.com/openclaw/gogcli/blob/main/docs/watch.md>
```

### audits/2026-06-12-hooks-mechanism-audit.md
```markdown
# Hooks Mechanism Audit — Notify Tier

**Date:** 2026-06-12  
**Installed version:** OpenClaw 2026.6.5  
**Result:** **GO, with mandatory design constraints.**

The installed typed plugin-hook surface is sufficient to build Notify safely, but a
naive hook is not sufficient. The build must never forward hook arguments, results,
errors, session keys, or call IDs. It must construct a fixed, allowlisted notification
from non-sensitive metadata and use a persistent local outbox with retries and a visible
terminal-failure state. Native `after_tool_call` execution is fire-and-forget and only
logs delivery failures, so it does not itself provide a non-silent notification guarantee.

**Central finding:** Yes, a hook can notify without forwarding secret material and
without silently losing failures, but only if the plugin deliberately excludes sensitive
event fields and adds durable delivery tracking. The native hook plus one direct Telegram
send does not meet the second requirement by itself.

## 1. What `after_tool_call` Can See — SETTLED

The correct surface is the typed plugin lifecycle hook registered with
`api.on("after_tool_call", ...)`, not an internal `HOOK.md` automation event.

The installed type declares these event fields:

- `toolName`
- `params`
- `runId`
- `toolCallId`
- `result`
- `error`
- `durationMs`

The hook context also includes `agentId`, `sessionKey`, `sessionId`, `runId`, and
`toolCallId`. Runtime source confirms that the hook receives the adjusted tool arguments
and the sanitized tool result after execution.

`sanitized` does not mean secret-redacted. The result remains the model-visible tool
result and can include file contents, command output, environment values, or other secret
material. Arguments can likewise contain secrets, message bodies, paths, URLs, or inline
code. Error strings can echo arguments, paths, or returned data.

Safe notification fields:

- A plugin-owned fixed action label or classification
- A normalized tool name, only when the classification policy permits it
- Success/failure as a boolean
- A coarse duration bucket, if useful
- A plugin-generated notification ID with no relationship to session or tool-call IDs

Must never be forwarded:

- `params`
- `result`
- `error`
- `sessionKey` / `sessionId`
- `runId` / `toolCallId`
- Raw paths, commands, message bodies, URLs, headers, environment values, or file content

The hook may inspect the minimum fields needed to classify an action, but the outbound
message must be generated from a separate allowlisted structure rather than by redacting
or serializing the event.

Evidence:

- `dist/plugin-sdk/hook-types-DgRt3F-m.d.ts:624`
- `dist/selection-But6hGR0.js:2554`
- `dist/selection-But6hGR0.js:2860`
- `docs/plugins/hooks.md` — `after_tool_call` observes results, errors, and duration

## 2. Notification Path and Failure Behavior — SETTLED

### Installed outbound path

A trusted native plugin can load the Telegram outbound adapter directly:

```text
api.runtime.channel.outbound.loadAdapter("telegram")
```

It can then call the adapter's `sendText({ cfg, to, text, accountId?, threadId? })`.
The bundled `device-pair` plugin uses this exact path. This is preferable to invoking the
agent `message` tool or launching another agent turn.

The target must be an explicit owner Telegram ID from plugin configuration, not a value
taken from tool arguments or an untrusted inbound event. Plugin configuration belongs
under `plugins.entries.<id>.config`; credentials remain in the existing Telegram channel
SecretRef and are not copied into plugin config.

### Failure behavior

`after_tool_call` is a void hook. Hook handlers run in parallel, and the tool completion
path calls the hook runner without awaiting it. Handler errors and timeouts are caught and
logged. The original tool action has already completed and is not rolled back or marked
failed because notification delivery failed.

Therefore, network failure, Telegram failure, adapter absence, plugin timeout, gateway
shutdown, or process crash can leave the operator unnotified while the original action
still succeeds. A direct send can throw or return a delivery result, but native hook
orchestration provides no durable retry or operator-visible failure guarantee.

Required build behavior:

1. Persist a minimal, secret-free notification record before attempting delivery.
2. Retry with bounded backoff and idempotency/deduplication.
3. Mark delivery success only after the adapter returns success.
4. Preserve a terminal failure record and expose it through doctor/status or another
   independently inspectable local signal.
5. Drain pending records on gateway/plugin startup.

This makes delivery failure non-silent in durable state even when Telegram is unavailable.
The action itself remains non-blocking; Notify is observation, not approval.

### Loop risk

Direct adapter delivery is outbound channel I/O, not an agent tool call, so it does not
re-enter `after_tool_call`. It may participate in outbound message lifecycle hooks, but
that does not create an `after_tool_call` loop.

Using the agent `message` tool, a gateway-triggered agent run, or a subagent to send the
notification would create avoidable recursion risk and is rejected for the Notify design.
The plugin should also ignore the `message` tool explicitly as defense in depth.

Evidence:

- `dist/plugin-sdk/types-Dk6viGJ9.d.ts:6228` — outbound adapter loader
- `dist/extensions/device-pair/index.js:552` — bundled direct Telegram send
- `dist/hook-runner-global-Ck8dmI0_.js:352` — void hooks run in parallel
- `dist/hook-runner-global-Ck8dmI0_.js:746` — `after_tool_call` is fire-and-forget
- `dist/selection-But6hGR0.js:2873` — caller does not await; failure is logged

## 3. Registration, Scope, and Scheduling — SETTLED

Notify should be a normal non-channel OpenClaw plugin created with `definePluginEntry`.
It is installed with `openclaw plugins install <local-path-or-pinned-package>`, enabled as
needed, and configured under:

```text
plugins.entries.<plugin-id>.config
```

The runtime handler is registered with:

```text
api.on("after_tool_call", handler, { priority?, timeoutMs? })
```

Registration options provide priority and timeout only. There is no declarative tool-name,
action-class, or agent filter on `api.on`.

Scoping must therefore be internal and fail closed:

- Return immediately unless `ctx.agentId === "main"`.
- Return unless the tool/action matches an explicit Notify classification table.
- Do not run for the dedicated `heartbeat` agent.
- Default unknown tools and unknown argument shapes to no notification until classified.
- Keep classification and outbound rendering separate so inspected arguments cannot leak
  into the notification.

The handler is asynchronous relative to the agent/tool path. Multiple void-hook handlers
run in parallel; OpenClaw waits inside the hook runner for each handler or timeout, but the
tool completion caller does not await that runner. Notify cannot block or undo the action.

Evidence:

- `docs/tools/plugin.md:50` — plugin install paths
- `docs/tools/plugin.md:71` — plugin config path
- `docs/tools/plugin.md:225` — typed hooks use `api.on`
- `dist/plugin-sdk/types-Dk6viGJ9.d.ts:8601` — only priority/timeout registration options

## 4. Safe-List Drift Detection

**SETTLED.** `~/.openclaw/exec-approvals.json` was inspected directly and scanned for the
repo's secret patterns. It contains policy fields and four Git allowlist patterns only;
the socket object is empty. No token, credential, private key, API key, or secret-shaped
assignment was found. The file remains mode `0600`.

It is now tracked alongside `openclaw.json` in the separate `~/.openclaw` repository.
Baseline commit:

```text
b77a0f8 baseline: track exec-approvals.json (safe-list under drift detection)
```

Tracked drift for both files is clean. The state directory still contains intentionally
untracked operational data and secrets; those were not added.

## Build Entry Conditions for DROP 1.2b-build

- Use a typed native plugin and `api.on("after_tool_call")`.
- Filter to `agentId === "main"` and an explicit Notify action table.
- Emit only fixed allowlisted metadata; never forward event arguments, results, errors,
  session identifiers, commands, paths, or message content.
- Deliver through `api.runtime.channel.outbound.loadAdapter("telegram").sendText`.
- Use an explicit configured owner target.
- Add a durable secret-free outbox, retry/deduplication, startup drain, and visible terminal
  failure state.
- Do not use the agent `message` tool, a subagent, or an agent turn for delivery.
- Test success, Telegram outage, restart with pending delivery, duplicate events, malformed
  arguments, secret-bearing arguments/results, heartbeat exclusion, and loop resistance.
```

### audits/2026-06-12-killswitch-test.md
```markdown
# Kill-Switch Live Test

**Date:** 2026-06-12  
**Installed version:** OpenClaw 2026.6.5  
**Verdict:** **NO-GO as an in-flight host-process panic button.**

OpenClaw's abort surfaces stop the tracked agent run, but the live test proved that
`sessions.abort` does not terminate an already-running host shell process. The Gateway
reported the run aborted in about one second while the inert counter continued to its
natural completion.

## Stop Mechanisms

### `/stop`

- Type or send `/stop` as a standalone command in the active Telegram/chat session.
- It targets that chat session's current run.
- It clears queued follow-ups, calls the embedded/reply-run abort primitive, records the
  abort, and cascades cancellation to tracked child subagents.
- It is a chat command, not a standalone CLI command.

### `/queue interrupt`

- Send `/queue interrupt` as a standalone command in the target chat session to store
  interrupt mode for that session.
- The next inbound message for that session aborts the active run, waits for run shutdown,
  and starts the newest message.
- There is no `openclaw queue` CLI command in 2026.6.5.
- Source shows it calls the same embedded-run abort primitive used by `/stop`.

### `sessions.abort`

Direct Gateway API:

```bash
openclaw gateway call sessions.abort \
  --params '{"key":"<session-key>","runId":"<run-id>","agentId":"<agent-id>"}'
```

It accepts `{key, runId?}`, `{runId}`, and optional `agentId`. This is the most precise
operator/API surface because it can bind both session and run.

There is no `openclaw sessions abort` subcommand in 2026.6.5.

## Live Test

### Baseline

An isolated test session ran a bounded shell loop that appended a counter and epoch
timestamp to `/tmp/killtest_20260612.log` once per second for 120 iterations.

Proof:

- Tool duration: 122,084 ms
- Final marker: `120 1781301423`
- The baseline confirmed that the command was a real long-running exec.

### Abort run

A second bounded loop wrote to `/tmp/killtest_20260612_run2.log`.

- First marker: `1 1781302403`
- Abort fired: epoch `1781302414`
- `sessions.abort` returned at epoch `1781302415`
- API result: `{"abortedRunId":"killtest-20260612-run2","status":"aborted"}`
- `agent.wait` reported the run ended at `1781302415646`, `stopReason: "rpc"`

The underlying process did not stop:

- At epoch `1781302422`: 20 lines, final marker `20 1781302422`
- At epoch `1781302428`: 25 lines, final marker `25 1781302427`
- Natural completion: `120 1781302524`

The counter continued for roughly 109 seconds after the abort command. Halt latency is
therefore **not applicable: the process was not halted**.

Both `/tmp` marker files were removed after the test, and no test process remains.

## Tested vs. Not Tested

| Scenario | Status | Finding |
| --- | --- | --- |
| Long-running exec | **LIVE TESTED** | `sessions.abort` stopped run tracking/model flow but did not kill the shell process |
| Model generation | **NOT LIVE TESTED** | Docs/source indicate abort signals the active run, but no measured proof in this drop |
| Subagent task | **NOT LIVE TESTED** | `/stop` has a tracked-subagent cascade, but no live proof that a subagent's in-flight host process dies |
| `/stop` independently | **NOT LIVE TESTED** | Source-equivalent abort primitive plus queue clearing/subagent cascade |
| `/queue interrupt` independently | **NOT LIVE TESTED** | Source-equivalent abort primitive, followed by newest-message execution |

Only one inert test workload was used. Additional live runs were not created after the
direct API established that the shared abort primitive does not kill in-flight exec.

## Recommended Daily Command

From the phone, use standalone `/stop` in the affected Telegram chat. It is the fastest
available user-facing command, clears queued work, and cascades to tracked subagents.

Limitation: `/stop` must be treated as **stop the agent run and prevent further steps**,
not as a guaranteed kill of an already-running host process. For exact automation/API
targeting, use `sessions.abort` with both session key and run ID, with the same limitation.

Do not use `/queue interrupt` as the panic button: it is replacement-message behavior and
starts new work after aborting the old run.

## C.5 / C.6 Decision

The receive-vs-interrupt split does **not** collapse. OpenClaw can receive and acknowledge
an abort while an in-flight host process continues. A real C.6 mechanism still needs
process-group ownership and verified TERM/KILL escalation for exec children, plus equivalent
handling for nested/subagent processes.

## Configuration and Drift

No OpenClaw configuration was changed. The tracked drift baseline remains clean at
`b77a0f8` for `openclaw.json` and `exec-approvals.json`.

`openclaw config validate` passed. `openclaw doctor` again hit the existing
`EPERM: chmod ~/.openclaw/state` issue; this was pre-existing and is already flagged in
`CONTROL.md`.
```

### audits/2026-06-12-panic-button-test.md
```markdown
# Gateway Panic-Button Live Test

**Date:** 2026-06-12  
**Installed version:** OpenClaw 2026.6.5  
**Verdict:** **GO WITH A CLIENT-RETRY CONSTRAINT.**

`launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway` killed the
gateway-owned in-flight shell and launchd immediately replaced the gateway.
However, the `openclaw agent` CLI used to originate this test automatically
fell back to an embedded agent after the Gateway WebSocket closed and replayed
the prompt. The gateway kill is therefore a verified process-tree kill, but a
panic procedure must also stop or disable any initiating client that can retry
work outside the gateway.

## Recovery Baseline

- LaunchAgent: `ai.openclaw.gateway`
- `KeepAlive`: `true`
- `RunAtLoad`: `true`
- Initial gateway PID: `57469`
- Initial launchd run count: `29`
- Gateway process owner: `agent`, UID `501`

The service was loaded and listening on loopback before the test.

## Live Test

One bounded shell loop appended a counter and epoch timestamp to
`/tmp/panictest_20260612.log` once per second, with a 120-iteration limit.

Before the panic command:

- Counter marker: `11 1781308918`
- Gateway PID: `57469`

After:

```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

the original sequence ended at:

- Final original marker: `18 1781308925`
- New gateway start timestamp: approximately `1781308929`
- New gateway PID: `65509`
- New launchd run count: `30`
- First recovery poll: already `state = running`

The original gateway-owned counter did not produce marker `19`. This proves the
gateway restart terminated that in-flight child process. Launchd replaced the
gateway by the first poll, effectively within one polling interval.

The gateway health RPC subsequently returned `ok: true`; Telegram was enabled,
running, connected, and had no restart pending. The system was not left in
bootout limbo.

## Embedded-Fallback Constraint

The originating `openclaw agent` process reported:

```text
EMBEDDED FALLBACK: Gateway agent failed; running embedded agent:
gateway closed (1012): service restart
```

It then started the same bounded prompt again outside the newly restarted
gateway, producing a fresh sequence beginning at counter `1`. That fallback
was stopped with Ctrl-C; its marker remained unchanged across a five-second
check.

This was a client-side replay, not survival of the original gateway child.
For Telegram-originated work there is no attached `openclaw agent` CLI fallback,
but any CLI, supervisor, or other caller with retry/fallback behavior must be
stopped as part of an emergency response.

## Verified Panic Sequence

For normal Telegram-originated work:

```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

For work originated by an attached CLI or automation:

1. Stop the initiating CLI, supervisor, or retry source.
2. Run the launchd kickstart command above.
3. Confirm `launchctl print gui/$(id -u)/ai.openclaw.gateway` shows a new PID.
4. Confirm `openclaw gateway call health --json` returns `ok: true`.

Do not use `openclaw gateway stop` or `openclaw gateway restart` on this Mac;
those paths can boot out the LaunchAgent instead of preserving launchd
registration. Standalone Telegram `/stop` remains a reasoning/run-state halt,
not a guaranteed kill of an in-flight host process.

## EPERM Diagnosis

The recurring error is:

```text
EPERM: operation not permitted, chmod '/Users/agent/.openclaw/state'
```

There is no ownership or permission mismatch:

- `~/.openclaw`: owner `agent:staff`, UID/GID `501:20`, mode `0700`
- `~/.openclaw/state`: owner `agent:staff`, UID/GID `501:20`, mode `0700`
- Gateway runtime: user `agent`, UID `501`
- State database and sidecars: owner `agent:staff`, mode `0600`

OpenClaw 2026.6.5 calls `ensureOpenClawStatePermissions()` during CLI bootstrap.
For the default database it unconditionally runs:

```js
chmodSync(dir, 0o700)
```

even when the directory is already `0700`. The managed repo-only filesystem
sandbox rejects that metadata write outside its writable roots. The same
read-only `openclaw status --json` command succeeds when run outside that
sandbox, proving this is execution-context policy, not Unix ownership drift.

### Recommended fix

Do not run `chown`, `chmod`, or `doctor --fix`; ownership and modes are already
correct, and those commands do not address this failure.

The durable fix is to upgrade to an OpenClaw release that avoids unconditional
chmod, or patch `ensureOpenClawStatePermissions()` so it only calls `chmodSync`
when the observed mode differs from `0700` and treats `EPERM` as acceptable
only after re-stat confirms the correct owner and mode. Until then, run affected
OpenClaw CLI commands outside the repo-only managed sandbox. A future apply
drop should implement or consume that code fix, not alter state-directory
permissions.

## Cleanup and Drift

- The fallback process was stopped.
- `/tmp/panictest_20260612.log` and the temporary status capture were removed.
- No OpenClaw configuration changed.
- Tracked `openclaw.json` and `exec-approvals.json` remain clean at baseline
  `b77a0f8`.

```

### audits/2026-06-12-pre-phase1-audit.md
```markdown
# Phase 1 Pre-Phase Audit

**Date:** 2026-06-12
**Installed version:** OpenClaw 2026.6.5 (5181e4f)
**Scope:** Read-only audit of the Phase 0 baseline; no live tool run and no OpenClaw mutation.

## Gate

**NO-GO — do not execute the current Phase 1 plan unchanged.**

The native approval engine is a viable Phase 1 foundation, but the installed facts require
four plan corrections before configuration begins:

1. Phase 1.1 must explicitly set restrictive exec policy and `askFallback: deny`; the
   installed default is currently YOLO (`security=full`, `ask=off`, `askFallback=full`),
   not fail-closed.
2. Phase 1.2 must design a custom typed plugin/hook for Notify-tier delivery. OpenClaw
   exposes tool-observation hooks and telemetry, but no declarative native
   "run this reversible action and notify the operator" tier.
3. Phase 1.5 must test the actual interrupt surfaces (`/stop`, `/queue interrupt`, and
   `sessions.abort`). `/approve ... deny`, `/steer`, and goal state are not a combined
   running-task kill switch.
4. Phase 1.6 must enable native loop detection and add controls for the uncovered doctrine
   requirements: a total iteration cap, a true cost circuit breaker, and durable trip state.

After a revised Claude drop incorporates those changes, Phase 1.1 may proceed.

## Central Question

> Can any inbound message, malicious page, replayed event, or misconfiguration cause an
> unintended action or a secret leak under the trust model we are about to configure?

**Current baseline answer: yes.** A message accepted from the paired Telegram owner reaches
an unsandboxed main agent whose effective host exec policy is `full/off/full`. The agent can
also use filesystem and session tools. Phase 1 is therefore required before adding untrusted
content paths, shared senders, browser work, or sensitive secrets.

No malicious-page path exists yet because the browser tool is denied by the current coding
profile. SecretRefs keep configured gateway and Telegram tokens out of model-readable config,
but unrestricted host exec could still read files available to the user account.

## Evidence Read

Installed documentation:

- `docs/tools/exec-approvals.md`
- `docs/tools/exec-approvals-advanced.md`
- `docs/tools/exec.md`
- `docs/tools/permission-modes.md`
- `docs/channels/telegram.md`
- `docs/help/faq-first-run.md`
- `docs/tools/loop-detection.md`
- `docs/concepts/queue.md`
- `docs/concepts/queue-steering.md`
- `docs/tools/steer.md`
- `docs/tools/goal.md`
- `docs/tools/slash-commands.md`
- `docs/automation/hooks.md`
- `docs/plugins/hooks.md`
- `docs/tools/multi-agent-sandbox-tools.md`
- `docs/gateway/sandboxing.md`
- `docs/gateway/protocol.md`

Read-only commands:

- `openclaw --version`
- `openclaw config get agents --json`
- `openclaw config get tools --json`
- `openclaw config get channels.telegram --json`
- `openclaw config get commands --json`
- `openclaw sandbox explain --agent main --json`
- `openclaw approvals get --json`
- `openclaw exec-policy show --json`
- `openclaw cron list --json`
- `openclaw hooks list --json`
- `openclaw doctor`
- `git -C ~/.openclaw status`, `diff`, `log`, and `ls-files`

## 1. Native Approval Engine

### Finding 1.1 — Engine surface: SETTLED

OpenClaw 2026.6.5 supports:

- `exec.security`: `deny`, `allowlist`, or `full`.
- `exec.ask`: `off`, `on-miss`, or `always`.
- `askFallback`: `deny`, `allowlist`, or `full` when an approval prompt cannot be
  delivered or answered.
- `approvals.exec`: optional forwarding of approval prompts to configured chat targets.
- `channels.telegram.execApprovals`: Telegram-native approval client behavior, including
  approver IDs, DM/channel target, and agent/session filters.

The host exec gate is the effective intersection of requested `tools.exec` policy and the
host-local `~/.openclaw/exec-approvals.json`. Chat approval settings route and render
decisions; they are not the execution gate.

Tool policy is evaluated before the model call. A denied tool is removed from the model's
available schema and cannot be restored by sandbox or elevated settings.

### Finding 1.2 — Current main-agent posture: SETTLED, HIGH RISK

Current effective state:

| Control | Effective value |
|---|---|
| Tool profile | `coding`, plus `message` |
| Sandbox | `off` |
| Exec host | `auto` |
| Exec security | `full` |
| Exec ask | `off` |
| Ask fallback | `full` |
| Host approvals file | absent |
| `approvals.exec` | absent |
| `channels.telegram.execApprovals` | absent; native auto-resolution may use owner IDs once approvals exist |
| Elevated | unavailable to the current sender/config, but not needed for unsandboxed full exec |

`openclaw sandbox explain` shows `exec`, `process`, read/write/edit/apply-patch, and
session tools available. It shows browser, cron, and gateway denied by the current profile.

The current posture is OpenClaw's documented default host behavior, described by its docs
as YOLO. It is not the strict baseline described in the build plan.

### Finding 1.3 — Telegram approval roles: SETTLED

Normal Telegram access and approval authority are separate:

- Telegram is enabled with `dmPolicy: pairing` and groups disabled.
- The command owner is `telegram:8745949064`.
- There are no pending Telegram pairing requests.
- `channels.telegram.allowFrom`/pairing controls normal inbound access.
- Exec approvers resolve from explicit numeric approvers or, when safely available,
  `commands.ownerAllowFrom`.
- Pending exec approvals expire after 30 minutes by default.

## 2. Fail-Closed and Approval Binding

### Finding 2.1 — Ask fallback default: SETTLED, PLAN CLAIM MUST CHANGE

The general docs say that a request which must prompt and has no reachable UI resolves
through `askFallback`, and their restrictive example uses `deny`.

However, the installed effective default on this machine and version is:

```text
security=full ask=off askFallback=full
```

The installed runtime source also resolves an absent approval-file fallback to `full`.
Therefore the plan must not claim that the unconfigured product is fail-closed. Phase 1.1
must explicitly configure `askFallback: deny` in the enforceable host approval policy,
along with restrictive requested exec policy.

Once explicitly configured to `deny`, an unavailable approval client blocks the command.

### Finding 2.2 — Approval context and TOCTOU binding: PARTLY SETTLED

Installed docs explicitly guarantee for approved **node-host** runs:

- canonical cwd;
- exact argv;
- bound environment when present;
- pinned executable path when applicable;
- best-effort binding of one concrete script/interpreter file operand;
- denial if that bound file changes after approval and before execution;
- refusal to mint an approval-backed run when exactly one bindable file cannot be
  identified.

This is not a complete semantic model of every loader path. Inline interpreter evaluation
needs `strictInlineEval: true` for stronger coverage.

**OPEN — owner Phase 1.5:** the installed docs do not state the same canonical
cwd/argv/env/file-binding guarantee as explicitly for gateway-host execution. Confirm the
chosen Phase 1 execution target hands-on.

Test design for Phase 1.5, not executed here:

1. Use a disposable workspace and harmless script that writes only to a temporary marker.
2. Set the test agent to `ask: always`, `askFallback: deny`, and the intended host.
3. Request the script and wait for an approval ID without approving it.
4. Change the script contents, then approve the original ID.
5. Require a denial and prove the marker was not written.
6. Repeat with changed argv, cwd, and a bound environment value.
7. Repeat on every intended host type; verify inline eval is approval-only.

## 3. Three `[VERIFY]` Items

### 3a. Notify-Tier Mechanism: SETTLED — CUSTOM BUILD REQUIRED

There is no declarative native Notify tier equivalent to:

> execute a reversible side effect without approval, then send an operator notification.

Available native surfaces are components, not a complete policy:

- `after_tool_call` is a typed plugin observation hook.
- internal hooks do not expose tool execution events.
- diagnostic events/OTel are telemetry, not a policy or operator-notification route.
- system events inject text into an agent session/heartbeat; they are not direct operator
  notifications.
- exec lifecycle messages exist for approved asynchronous exec runs, not as a configurable
  notification policy for arbitrary reversible tools.

**Direction change:** Phase 1.2 must include a custom typed plugin/hook that classifies the
configured Notify-tier tools/actions and emits a sanitized Telegram/operator notification
after execution. It must not include secrets or unrestricted tool output. Delivery failure
semantics and audit correlation must be specified before implementation.

### 3b. Kill-Switch Semantics: SETTLED FOR DOCS; HANDS-ON TEST OPEN

The proposed combination does not collapse the old receive/record and interruption split:

- `/approve <id> deny` prevents that pending command from running. It does not abort other
  work already running.
- `/steer` injects guidance at the next supported runtime/model boundary. It explicitly
  does not interrupt an in-flight tool call.
- Goal commands alter durable objective state. Goal pause/block/complete is not a run
  cancellation mechanism.
- `/stop` aborts the current run.
- `/queue interrupt` aborts the active run, then starts the newest message.
- Gateway `sessions.abort`/`chat.abort` are explicit active-run abort APIs.
- Task cancellation kills child sessions for ACP/subagent tasks, but CLI-tracked task
  cancellation may only record cancellation because no child runtime handle exists.

**OPEN — owner Phase 1.5:** hands-on test `/stop`, `/queue interrupt`, and `sessions.abort`
during (a) model generation, (b) a long-running exec, and (c) delegated/subagent work.
Measure whether the child OS process is terminated and whether any already-issued side
effect completes before cancellation. Do not represent `/steer`, goal status, or approval
denial as a hard interrupt.

### 3c. Loop-Prevention Depth: SETTLED — PARTIAL NATIVE COVERAGE

Current config has no `tools.loopDetection` block:

- rolling-history detectors are disabled by default;
- the post-compaction guard remains enabled while the master flag is unset;
- no rolling detector protects normal current runs.

Doctrine mapping:

| Control | Native coverage | Finding |
|---|---|---|
| Iteration cap | No general total tool/turn cap | **GAP** |
| Hash detector | Same tool+params, identical outcome hashes, ping-pong, and post-compaction `(tool,args,result)` hashes | **NATIVE** |
| No-progress oracle | Repeated identical outcomes, known polling without state change, unknown-tool retry, ping-pong | **NATIVE HEURISTIC**, not semantic proof |
| Cost circuit breaker | `globalCircuitBreakerThreshold` counts no-progress calls; it is not monetary/token cost. Goal token budgets are explicitly not billing caps | **GAP** |
| Persistent state on trip | Loop reason is logged/recorded for the run, but no documented durable trip latch blocks later runs until operator reset | **GAP** |
| Stuck detection | Warning, suppression, critical blocking, unknown-tool, polling, ping-pong, and compaction-loop abort | **NATIVE** |

**Direction change:** Phase 1.6 must explicitly enable rolling loop detection and add a
custom iteration/cost budget plus durable tripped-state handling. Native detectors should
remain the first line for repetitive/no-progress patterns.

## 4. Config Self-Modification Defense

### Finding 4.1 — Per-agent hard deny: SETTLED

`agents.list[].tools.deny` can further restrict an agent after global/profile policy.
Earlier denied tools cannot be granted back by later policy levels. Exact tool IDs can
hard-block `gateway`, `cron`, and individual `sessions_*` tools. Tool-group shorthands can
cover broader groups, but the Phase 1 design should list exact session tools where least
privilege matters.

The current main agent already has `gateway` and `cron` denied by the effective coding
profile, but session tools remain available. Phase 1 must make the intended restrictions
explicit rather than depend on profile contents.

### Finding 4.2 — Config drift baseline: SETTLED

- `~/.openclaw` HEAD is `e59160b baseline`.
- The only tracked file is `openclaw.json`.
- Working-tree and staged diffs for `openclaw.json` are clean.
- `git status` lists runtime/state directories and backups as untracked. They are not
  configuration drift and must not be added to this repository.

No tracked config drift exists.

## 5. Inbound Threat Pass

### Telegram messages to `@LLoyd_entouragebot`: SETTLED, CURRENTLY HIGH RISK

- Direct messages require pairing; groups are disabled.
- The paired owner can submit natural-language prompts and authorized slash commands.
- With sandbox off and exec `full/off`, a crafted or mistaken accepted prompt can cause
  unapproved host execution, filesystem writes, process activity, outbound messages, or
  session manipulation.
- Browser, cron, gateway, and other channel tools are currently removed by policy, which
  narrows but does not eliminate host risk.
- Because this is a personal-assistant trust model, pairing authenticates the sender; it
  does not make prompt content safe. Forwarded malicious instructions or prompt injection
  supplied by the owner remain actionable content.

### Approval replies: SETTLED, LOW CURRENT EXPOSURE / FUTURE HIGH AUTHORITY

- No exec approvals are currently generated because exec is `full/off`.
- There is no explicit forwarding config and no pending pairing request.
- Once Phase 1 enables approvals, only authorized numeric approvers should resolve them.
- Approval IDs expire, and a denial prevents the pending command from running.
- Replayed or stale approval IDs should fail after resolution/expiry, but live replay and
  wrong-sender negative tests belong in Phase 1.3.
- Approval replies are not a kill switch for unrelated or already-running actions.

### Heartbeat turns: SETTLED, CONTROLLED PROMPT BUT OVER-PRIVILEGED AGENT

- Runs every 30 minutes in an isolated, light-context session on local Qwen with a
  180-second timeout.
- `HEARTBEAT.md` currently says to reply exactly `HEARTBEAT_OK` and not call tools.
- There are no due tasks or external event text observed in this audit.
- The instruction is behavioral, not a mechanical tool restriction. If the heartbeat file,
  injected system events, workspace instructions, or model behavior changes, the heartbeat
  agent inherits the current permissive tool posture and could execute host actions.
- Phase 1 must give heartbeat a mechanically restricted tool set, not rely on prompt text.

### Cron: SETTLED

- `openclaw cron list --json` reports zero jobs.
- There is currently no cron-triggered inbound execution path.
- Future cron jobs are headless. Their approval/fallback and tool policy must be designed
  explicitly because they cannot wait indefinitely for interactive approval.

### Malicious pages and other channels: SETTLED FOR CURRENT BASELINE

- Telegram is the only enabled external messaging channel in the inspected config.
- Group Telegram input is disabled.
- Browser is denied by effective tool policy, so no malicious-page ingestion path is
  currently active.
- No network webhook or additional inbound integration was identified in the scoped Phase 0
  configuration.

## Doctor and Residual Operational Notes

`openclaw doctor` completed with no channel security warning, missing skill requirement, or
plugin error. It reported 27 orphan transcript files and offered a mutating archive fix;
this audit did not run that fix.

This doctor result does not make the current execution policy safe. The effective-policy
inspection is authoritative for this gate.

## Entry Conditions for the Next Claude Drop

The Phase 1.1 drop must:

1. Treat `full/off/full`, sandbox off, and unrestricted heartbeat/session tools as the
   explicit starting risk.
2. Configure both requested exec policy and host-local approval policy, with
   `askFallback: deny`; verify the effective merge after configuration.
3. Preserve Telegram pairing and require explicit numeric approval authority.
4. Add the Notify-tier custom plugin/hook design before Phase 1.2 implementation.
5. Replace the kill-switch claim with `/stop`, `/queue interrupt`, and `sessions.abort`
   tests in Phase 1.5.
6. Enable native rolling loop detection and define custom iteration, cost, and persistent
   trip controls for Phase 1.6.
7. Explicitly deny config/self-modification tools per agent, including required
   `sessions_*` IDs, rather than relying on a profile.
8. Mechanically restrict heartbeat tools.

**Audit conclusion:** OpenClaw's native policy and approval primitives are suitable, but the
existing plan overstates default fail-closed behavior and native coverage for Notify,
interruption, and loop prevention. Revise the plan/drop first; then proceed to Phase 1.1.
```

### audits/2026-06-12-sandbox-killswitch-discovery.md
```markdown
# Sandbox and Container Kill-Switch Discovery

**Date:** 2026-06-12  
**Installed OpenClaw version:** 2026.6.5  
**Verdict:** **NO-GO — Docker prerequisite absent.**

The Docker presence gate failed. Per DROP 1.4-discovery's hard-gate rule, technical
discovery stopped after Task 1. No sandbox was enabled, no container was created, no
OpenClaw configuration changed, and no permission repair was attempted.

## Task 0 — Pending Push

**SETTLED.** Commit `ea1e3f0` (Phase 1.5 kill-switch verification) was pushed to
`origin/main`. The branch was clean and synchronized immediately after the push.

## Task 1 — Docker Presence Gate

**SETTLED: ABSENT.**

Observed:

- `command -v docker` returned no path.
- `docker version`, `docker info`, `docker ps`, and `docker images` all failed with
  `command not found: docker`.
- `/var/run/docker.sock` does not exist.
- There is therefore no accessible Docker daemon and no Docker-backed OpenClaw sandbox
  image to inspect.
- `openclaw sandbox list --json` could not run because the existing
  `EPERM: chmod ~/.openclaw/state` regression stopped CLI startup. This does not alter
  the Docker conclusion: both the binary and daemon socket are absent independently.

## Blocked Work

The following work was not performed because the drop explicitly required stopping after
the Docker gate:

- **Container kill-switch live test:** not run. There was no container runtime in which
  to start or kill the inert workload.
- **Sandbox configuration map:** not continued. The rogue-container and Codex nesting
  questions remain open for a future discovery pass after a container runtime exists.
- **EPERM root-cause diagnostic:** not continued. The known EPERM flag remains unresolved;
  no `chmod` or `chown` was run.
- **Tracked `openclaw.json` secret inspection:** not continued in this drop. Prior Phase 0
  SecretRef work and audits remain the current evidence, but Task 5 was not re-verified.

## Prerequisite Decision

Before Phase 1.4 can proceed, the operator must choose whether to install and operate a
Docker-compatible runtime on the mini. Installation is explicitly outside this drop.

After that decision and installation, rerun 1.4 discovery from Task 1 and complete:

1. Daemon/socket/access verification.
2. Throwaway-container `docker kill` proof against an in-flight inert process.
3. Exact OpenClaw sandbox mode/scope/exec-host mapping.
4. Codex nested-sandbox compatibility assessment.
5. Host-home mount isolation confirmation.
6. EPERM ownership/mode diagnosis.
7. Tracked-config secret re-verification.

## State and Cleanup

- No sandbox or OpenClaw config was changed.
- No container or `/tmp` test artifact was created.
- No permission mutation was applied.
- The previously tracked OpenClaw drift baseline remained clean before the Docker gate.
```

### audits/F-A0-platform-hardening-audit.md
```markdown
# F-A0 Platform Hardening Audit

Date: 2026-06-16
Scope: AUDIT ONLY. No config changes, installs, skills, broker work, sandbox enablement, or reader/no-send changes.

Session labels:
- Codex session: commands run from this Codex task in `/Users/agent/agent-os`.
- Plain agent SSH session: attempted only for commands that failed in Codex; SSH authentication was not available from this session.

## Result Summary

| Item | Status | Finding |
| --- | --- | --- |
| OpenClaw version / install / runtime user | PASS | OpenClaw `2026.6.5 (5181e4f)`, user install under `/Users/agent/.local/openclaw`, gateway LaunchAgent running as `agent`. |
| `openclaw security audit --deep` | REMEDIATED / OPEN WARNS | Codex execution failed, but plain agent SSH output was captured separately: 1 critical, 2 warn, 1 info. F-A0 remediation removed the critical; current audit is 0 critical, 2 warn, 2 info. |
| `openclaw secrets audit --check` | PASS | Clean: `plaintext=0, unresolved=0, shadowed=0, legacy=0`. |
| Channels and Telegram allowlist | PASS | Telegram is enabled with pairing DM policy and sender allowlist `telegram:8745949064`; groups disabled. |
| Per-agent tool surfaces | FAIL | Gmail Reader is contractually narrowed, but still has `exec` with `mode=auto` as the same Unix user that owns Gmail credentials. |
| Elevated / privileged tools | PASS | `sandbox explain` reports elevated subsystem enabled, but not allowed by config; no configured `tools.elevated` grant found. |
| Installed skills | PASS | No enabled skills in config; configured skill catalog entries are disabled; no local `SKILL.md` found under `~/.openclaw` at audit depth. |
| Installed hooks | PASS | No OpenClaw hooks configured; only git sample hook files found. |
| Gateway WebSocket auth | PASS | `gateway.auth.mode="token"` with redacted token in sanitized config. |
| Gateway bind / exposure | PASS | Gateway listens on loopback only: `127.0.0.1:18789` and `[::1]:18789`; Tailscale mode off. |
| Browser-control exposure | RESOLVED / PASS | `browser=null`; no agent browser grant found. Native audit's "enabled" wording means subsystem-available, not actually reachable by a configured agent in current evidence. |
| Gmail credential/keyring exposure | FAIL | Current wrapper passes `GOG_KEYRING_PASSWORD` to child env and all credential files are same-UID readable by `agent`; Gmail Reader `exec` can reach the wrapper/keyring path. |
| Places Gmail Reader can see secrets/config | FAIL | Same-UID `exec` can reach wrapper, password file, keyring, gog config, oauth-client metadata, service env files, and OpenClaw config paths unless future broker/sandbox removes that authority. |

## Evidence

### 1. OpenClaw Version, Install Method, Runtime User

Status: PASS

Command, Codex session:

```sh
openclaw --version
which openclaw
ls -l $(which openclaw)
readlink $(which openclaw) || true
id
whoami
```

Output:

```text
OpenClaw 2026.6.5 (5181e4f)
/Users/agent/.local/bin/openclaw
lrwxr-xr-x  1 agent  staff  43 ... /Users/agent/.local/bin/openclaw -> /Users/agent/.local/openclaw/bin/openclaw
/Users/agent/.local/openclaw/bin/openclaw
uid=501(agent) gid=20(staff) groups=20(staff),12(everyone),61(localaccounts),100(_lpoperator),701(com.apple.sharepoint.group.1)
agent
```

Command, Codex session:

```sh
launchctl print gui/$(id -u)/ai.openclaw.gateway 2>&1 | sed -n '1,220p'
```

Output excerpt:

```text
path = /Users/agent/Library/LaunchAgents/ai.openclaw.gateway.plist
state = running
program = /Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
arguments = {
        /Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node
        /Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/index.js
        gateway
        --port
        18789
}
working directory = /Users/agent/.openclaw
umask = 77
```

Command, Codex session:

```sh
lsof -nP -iTCP:18789 -sTCP:LISTEN 2>&1 || true
```

Output:

```text
COMMAND  PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node    1331 agent   18u  IPv4 ...              0t0  TCP 127.0.0.1:18789 (LISTEN)
node    1331 agent   19u  IPv6 ...              0t0  TCP [::1]:18789 (LISTEN)
```

Interpretation: user-space OpenClaw install under `~/.local/openclaw`, launched as the `agent` user's LaunchAgent, with bundled Node.

### 2. OpenClaw Security Audit

Status: REMEDIATED / OPEN WARNS

Command, Codex session:

```sh
openclaw security audit --help
openclaw security audit --deep
```

Output:

```text
Usage: openclaw security audit [options]

run security posture audit

Options:
  --auth <mode>  override auth mode for the emitted plan (token|password|none)
  --deep         include local network/service inspection
  --fix          apply safe config-only fixes after showing the plan
  --json         output JSON
  --password     derive a gateway password hash from OPENCLAW_GATEWAY_PASSWORD
  --token        generate and persist a gateway token (default behavior)
  -h, --help     display help for command

[openclaw] Could not start the CLI.
[openclaw] Reason: EPERM: operation not permitted, chmod '/Users/agent/.openclaw/state'
[openclaw] Debug: set OPENCLAW_DEBUG=1 to include the stack trace.
[openclaw] Try: openclaw doctor
[openclaw] Help: openclaw --help
```

Plain SSH retry command:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null agent@localhost 'openclaw security audit --deep'
```

Output:

```text
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
agent@localhost: Permission denied (publickey,password,keyboard-interactive).
```

Finding from Codex: the audit command exists in this OpenClaw version, but no trustworthy audit output was produced from Codex.

#### Native deep-audit (plain agent SSH, 2026-06-16)

Status: CLOSED / FAIL

Summary recorded from plain agent SSH output: 1 critical, 2 warn, 1 info.

Findings:

- CRITICAL `models.small_params`: `qwen2.5-coder:14b` appears at `agents.defaults.model.fallbacks` while web-capable tools are available and sandbox mode is off. This is a small-model prompt-injection risk. The heartbeat agent's Qwen path is not the issue because heartbeat is separately restricted with web off. This is also not the email-reader path: `gmail-reader` and `email-researcher` use `openai/gpt-5.5`, and `email-researcher` explicitly denies `web_fetch`. The risk is the default fallback/provider path.
- WARN `exec-not-read-only`: independently confirms the Gmail Reader same-UID `exec` finding in this audit. Owned by F-A1/F-A2; no separate F-A0 reader-exec remediation is proposed.
- WARN `trusted_proxies`: benign in this deployment because Gateway is loopback-only and there is no reverse proxy in front of it. Note and ignore unless the Gateway is later exposed through a proxy.
- INFO trust model: OpenClaw reports a personal assistant trust boundary, not a hostile multi-tenant boundary. Platform-level implication: OpenClaw is the runtime/harness, not the Agent OS trust boundary. This validates the reconciled spine. Relevant wording: "one trusted operator boundary per gateway" and "not a hostile multi-tenant security boundary."

#### F-A0 remediation re-audit (Codex unsandboxed local, 2026-06-16)

Plain agent SSH retry from this Codex session failed:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 agent@Danny-Mac-Mini.local 'PATH=/Users/agent/.local/bin:$PATH openclaw security audit --deep'
```

Output:

```text
agent@danny-mac-mini.local: Permission denied (publickey,password,keyboard-interactive).
```

Because plain SSH was unavailable from Codex, the re-audit was run as the local `agent` user outside the Codex filesystem sandbox:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw security audit --deep
```

Output:

```text
OpenClaw security audit
Summary: 0 critical · 2 warn · 2 info
Run deeper: openclaw security audit --deep

WARN
gateway.trusted_proxies_missing Reverse proxy headers are not trusted
tools.exec.fs_tools_disabled_but_exec_enabled Filesystem tool policy does not make exec read-only

INFO
summary.attack_surface Attack surface summary
  browser control: enabled
  trust model: personal assistant (one trusted operator boundary), not hostile multi-tenant on one shared gateway
models.small_params Small models require sandboxing and web tools disabled
  Small models (<=300B params) detected:
- ollama/qwen2.5-coder:14b (14B) @ agents.defaults.model.fallbacks (ok; sandbox=off; web=[off])
- ollama/qwen2.5-coder:14b (14B) @ agents.list.heartbeat.model.primary (ok; sandbox=off; web=[off])
No web/browser tools detected for these models.
```

Result: the prior CRITICAL `models.small_params` finding is gone. It is now INFO with `web=[off]` for both Qwen paths.

### 3. OpenClaw Secrets Audit

Status: PASS

Command, Codex session:

```sh
openclaw secrets audit --help
openclaw secrets audit --check
```

Output:

```text
Usage: openclaw secrets audit [options]

scan config for plaintext/unresolved/shadowed secret values

Options:
  --allow-exec  also allow command-backed secret providers
  --check       exit non-zero if issues are found
  --json        output JSON
  -h, --help    display help for command

Secrets audit: clean. plaintext=0, unresolved=0, shadowed=0, legacy=0.
```

### 4. Channels and Telegram Allowlist

Status: PASS

Command, Codex session:

```sh
jq '{channels, gateway, browser, hooks}' /Users/agent/.openclaw/openclaw.sanitized.json
```

Output:

```json
{
  "channels": {
    "telegram": {
      "botToken": "__REDACTED__",
      "dmPolicy": "pairing",
      "enabled": true,
      "groupPolicy": "disabled",
      "name": "LLoyd_entouragebot"
    }
  },
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "__REDACTED__"
    },
    "bind": "loopback",
    "mode": "local",
    "port": 18789,
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    }
  },
  "browser": null,
  "hooks": null
}
```

Command, Codex session:

```sh
jq '{commands, session}' /Users/agent/.openclaw/openclaw.sanitized.json
jq . /Users/agent/.openclaw/devices/telegram-default-allowFrom.json
```

Output:

```json
{
  "commands": {
    "ownerAllowFrom": [
      "telegram:8745949064"
    ]
  },
  "session": {
    "dmScope": "per-channel-peer"
  }
}
{
  "version": 1,
  "allowFrom": [
    "8745949064"
  ]
}
```

Interpretation: Telegram is the only configured channel found in sanitized config. Groups are disabled. The sender allowlist exists and contains numeric Telegram sender ID `8745949064`.

### 5. Per-Agent Tool Surface

Status: FAIL

Command, Codex session:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw agents list --json
```

Output:

```json
[
  {
    "id": "main",
    "workspace": "/Users/agent/.openclaw/workspace",
    "agentDir": "/Users/agent/.openclaw/agents/main/agent",
    "model": "openai/gpt-5.5",
    "bindings": 0,
    "isDefault": true
  },
  {
    "id": "heartbeat",
    "name": "Restricted Heartbeat",
    "workspace": "/Users/agent/.openclaw/workspace",
    "agentDir": "/Users/agent/.openclaw/agents/heartbeat/agent",
    "model": "ollama/qwen2.5-coder:14b",
    "bindings": 0,
    "isDefault": false
  },
  {
    "id": "gmail-reader",
    "name": "Confined Gmail Reader",
    "workspace": "/Users/agent/.openclaw/workspace-gmail-reader",
    "agentDir": "/Users/agent/.openclaw/agents/gmail-reader/agent",
    "model": "openai/gpt-5.5",
    "bindings": 0,
    "isDefault": false
  },
  {
    "id": "email-researcher",
    "name": "Isolated Email Researcher",
    "workspace": "/Users/agent/.openclaw/workspace-email-researcher",
    "agentDir": "/Users/agent/.openclaw/agents/email-researcher/agent",
    "model": "openai/gpt-5.5",
    "bindings": 0,
    "isDefault": false
  }
]
```

Command, Codex session:

```sh
jq '{agents: .agents, tools: .tools}' /Users/agent/.openclaw/openclaw.sanitized.json
```

Output excerpt:

```json
{
  "tools": {
    "alsoAllow": [
      "message"
    ],
    "exec": {
      "security": "allowlist"
    },
    "profile": "coding"
  },
  "agents": {
    "defaults": {
      "model": "ollama/qwen2.5-coder:14b",
      "primary": "openai/gpt-5.5",
      "workspace": "/Users/agent/.openclaw/workspace"
    },
    "list": [
      {
        "id": "main",
        "subagents": {
          "allowAgents": [
            "gmail-reader",
            "email-researcher"
          ],
          "requireAgentId": true
        },
        "tools": {
          "alsoAllow": [
            "sessions_spawn",
            "sessions_yield",
            "subagents",
            "agents_list"
          ],
          "deny": [
            "gateway",
            "cron",
            "sessions_list",
            "sessions_history",
            "sessions_send",
            "session_status"
          ],
          "exec": {
            "security": "allowlist",
            "strictInlineEval": true
          }
        }
      },
      {
        "id": "gmail-reader",
        "tools": {
          "allow": [
            "exec"
          ],
          "deny": [
            "process",
            "read",
            "write",
            "edit",
            "apply_patch",
            "group:sessions",
            "gateway",
            "cron",
            "message"
          ],
          "exec": {
            "mode": "auto",
            "security": "allowlist",
            "strictInlineEval": true
          },
          "profile": "minimal"
        },
        "workspace": "/Users/agent/.openclaw/workspace-gmail-reader"
      },
      {
        "id": "email-researcher",
        "tools": {
          "alsoAllow": [
            "web_search"
          ],
          "deny": [
            "session_status",
            "group:runtime",
            "group:fs",
            "group:messaging",
            "group:sessions",
            "group:agents",
            "web_fetch",
            "x_search",
            "browser",
            "gateway",
            "cron"
          ],
          "profile": "minimal"
        },
        "workspace": "/Users/agent/.openclaw/workspace-email-researcher"
      }
    ]
  }
}
```

Interpretation:
- Main can spawn/yield to the two subagents and has a constrained shell allowlist.
- Gmail Reader denies file tools but allows `exec` with `mode=auto`; because it runs as Unix user `agent`, process-level file authority still reaches same-UID credential material.
- Email Researcher has web search only and denies filesystem/runtime/session/messaging groups in config.

Bounded remediation task: F-A1 must move Gmail operations behind a semantic capability broker; F-A2 must ensure the reader cannot read Gmail credentials or call raw Gmail tooling by same-UID `exec`.

### 6. Elevated / Privileged Tools

Status: PASS

Command, Codex session:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent gmail-reader --json
```

Output excerpt:

```json
{
  "sandbox": {
    "mode": "off",
    "scope": "agent",
    "workspaceAccess": "none",
    "workspaceRoot": "/Users/agent/.openclaw/sandboxes",
    "sessionIsSandboxed": false
  },
  "elevated": {
    "enabled": true,
    "allowedByConfig": false,
    "alwaysAllowedByConfig": false,
    "allowFrom": {},
    "failures": []
  }
}
```

The same elevated status was returned for `main` and `email-researcher`. No explicit `tools.elevated` grant was found in sanitized config.

### 7. Installed Skills

Status: PASS

Command, Codex session:

```sh
jq '{skills: .skills, plugins: .plugins}' /Users/agent/.openclaw/openclaw.sanitized.json
find /Users/agent/.openclaw -maxdepth 4 \( -name 'SKILL.md' -o -name 'skill.json' -o -name 'plugin.json' \) -print | sort
```

Output summary:

```text
Config contains many catalog skill entries, all with "enabled": false.
Enabled plugins in config: codex, ollama, openai.
No SKILL.md, skill.json, or plugin.json files were found under ~/.openclaw at maxdepth 4.
```

Interpretation: no installed/enabled community or local OpenClaw skills were found in the live OpenClaw config. Provider plugins `codex`, `ollama`, and `openai` are enabled.

### 8. Installed Hooks

Status: PASS

Command, Codex session:

```sh
find /Users/agent/.openclaw -maxdepth 4 -type f \( -iname '*hook*' -o -path '*/hooks/*' -o -path '*/plugins/*' \) -print | sort
```

Output:

```text
/Users/agent/.openclaw/.git/hooks/applypatch-msg.sample
/Users/agent/.openclaw/.git/hooks/commit-msg.sample
/Users/agent/.openclaw/.git/hooks/fsmonitor-watchman.sample
/Users/agent/.openclaw/.git/hooks/post-update.sample
/Users/agent/.openclaw/.git/hooks/pre-applypatch.sample
/Users/agent/.openclaw/.git/hooks/pre-commit.sample
/Users/agent/.openclaw/.git/hooks/pre-merge-commit.sample
/Users/agent/.openclaw/.git/hooks/pre-push.sample
/Users/agent/.openclaw/.git/hooks/pre-rebase.sample
/Users/agent/.openclaw/.git/hooks/pre-receive.sample
/Users/agent/.openclaw/.git/hooks/prepare-commit-msg.sample
/Users/agent/.openclaw/.git/hooks/push-to-checkout.sample
/Users/agent/.openclaw/.git/hooks/sendemail-validate.sample
/Users/agent/.openclaw/.git/hooks/update.sample
```

Interpretation: only git sample hooks were found. OpenClaw `hooks` config is `null`.

### 9. Gateway WebSocket Auth

Status: PASS

Evidence from sanitized config:

```json
"gateway": {
  "auth": {
    "mode": "token",
    "token": "__REDACTED__"
  },
  "bind": "loopback",
  "mode": "local",
  "port": 18789
}
```

Interpretation: Gateway auth is enabled in token mode. The token value was redacted by the sanitized config and was not printed.

### 10. Gateway Bind / Exposure

Status: PASS

Evidence:

```json
"gateway": {
  "bind": "loopback",
  "mode": "local",
  "port": 18789,
  "tailscale": {
    "mode": "off",
    "resetOnExit": false
  }
}
```

`lsof` confirmed only loopback listeners:

```text
TCP 127.0.0.1:18789 (LISTEN)
TCP [::1]:18789 (LISTEN)
```

Interpretation: no public internet bind was found; Gateway is local loopback only. Tailscale gateway exposure is off in config.

### 11. Browser-Control Exposure

Status: RESOLVED / PASS

Evidence:

```json
"browser": null
```

Command, Codex session:

```sh
find /Users/agent/.openclaw -maxdepth 4 -type f \( -iname '*browser*' -o -iname '*canvas*' -o -iname '*gateway*' -o -iname '*session*' \) -not -path '*/state/*' -not -path '*/workspaces/*' -print | sort
```

Output:

```text
/Users/agent/.openclaw/agents/gmail-reader/sessions/sessions.json
/Users/agent/.openclaw/agents/heartbeat/sessions/sessions.json
/Users/agent/.openclaw/agents/main/sessions/sessions.json
/Users/agent/.openclaw/gateway-supervisor-restart-handoff.json
/Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
/Users/agent/.openclaw/service-env/ai.openclaw.gateway.env
/Users/agent/.openclaw/tmp/openclaw-501/gateway.cf4b7e92.lock
```

Additional read-only diagnosis, Codex session:

```sh
jq '{browser, tools, agents: .agents}' /Users/agent/.openclaw/openclaw.sanitized.json
rg -n 'browser|web_fetch|web_search|group:web|tools\.byProvider|byProvider|qwen|ollama' /Users/agent/.openclaw/openclaw.sanitized.json /Users/agent/.openclaw/workspace/TOOLS.md /Users/agent/.openclaw/workspace-gmail-reader/TOOLS.md /Users/agent/.openclaw/workspace-email-researcher/TOOLS.md
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent main --json
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent gmail-reader --json
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent email-researcher --json
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent heartbeat --json
```

Output summary:

```text
browser=null
No tools.byProvider entry exists in sanitized config.
rg found browser only in deny/context locations:
  email-researcher denies web_fetch and browser
  email-researcher TOOLS.md says not to use browser/web_fetch
Sandbox explain for main, gmail-reader, email-researcher, and heartbeat lists browser in the default deny set.
No explicit agent browser allow/alsoAllow grant was found.
```

Interpretation: no browser-control config, browser-control state file, or agent browser grant was found. The native audit's "browser control: enabled" wording is therefore resolved as subsystem-available-but-ungranted, not actually reachable by a configured agent in the current evidence.

### 12. Gmail Credential / Keyring Exposure Path

Status: FAIL

Commands, Codex session:

```sh
rg -n 'GOG_HOME|GOG_KEYRING|SAFE_|gmail-no-send|enable-commands|wrap-untrusted|no-send' /Users/agent/.openclaw/scripts/gmail-draft-safe.mjs
stat -f '%Sp %Su:%Sg %z %N' /Users/agent/.openclaw/secrets/gog-keyring-password /Users/agent/.openclaw/gmail-draft-gog/config/config.json /Users/agent/.openclaw/gmail-draft-gog/oauth-client.json /Users/agent/.openclaw/gmail-draft-gog/data/credentials.json
find /Users/agent/.openclaw/gmail-draft-gog/data/keyring -maxdepth 1 -type f -print -exec stat -f '%Sp %Su:%Sg %z %N' {} \;
```

Evidence:

```text
Wrapper path: /Users/agent/.openclaw/scripts/gmail-draft-safe.mjs
SAFE_GOG_BIN=/Users/agent/.local/bin/gog-gmail-draft-safe
SAFE_GOG_HOME=/Users/agent/.openclaw/gmail-draft-gog
SAFE_ACCOUNT=daniel.haitz@gmail.com
SAFE_KEYRING_PASSWORD_FILE=/Users/agent/.openclaw/secrets/gog-keyring-password
Wrapper child env includes:
  GOG_HOME=SAFE_GOG_HOME
  GOG_KEYRING_BACKEND=file
  GOG_KEYRING_PASSWORD=<password read from file>
Wrapper exact commands include:
  gmail.drafts.create,gmail.drafts.update,gmail.drafts.list,gmail.drafts.get,gmail.messages.search,gmail.get
Wrapper safe flags include:
  --gmail-no-send --no-input --wrap-untrusted --json --results-only
```

Credential file metadata, contents not printed:

```text
-rw------- agent:staff 15 /Users/agent/.openclaw/secrets/gog-keyring-password
-rw------- agent:staff ... /Users/agent/.openclaw/gmail-draft-gog/config/config.json
-rw------- agent:staff 409 /Users/agent/.openclaw/gmail-draft-gog/oauth-client.json
-rw------- agent:staff 93 /Users/agent/.openclaw/gmail-draft-gog/data/credentials.json
-rw------- agent:staff ... /Users/agent/.openclaw/gmail-draft-gog/data/keyring/_gogcli_key_v1_...
```

Command, Codex session:

```sh
sed -n '1,220p' /Users/agent/.openclaw/workspace-gmail-reader/TOOLS.md
```

Output:

```text
# Gmail Reader Tools

Use only the confined wrapper:

/Users/agent/.openclaw/scripts/gmail-draft-safe.mjs

Its permitted actions are:

- message-search
- message-get
- draft-list
- draft-get
- draft-create
- draft-update

The second argument is the wrapper's base64url JSON payload. There is no send,
forward, delete, auth, configuration, or unrestricted gog command.
```

Interpretation: no-send is currently enforced by cooperative wrapper, compiled safe binary, and policy. It is not structural against the reader process because the reader runs with same-UID process authority and `exec` access.

Bounded remediation task: F-A1 must implement a Gmail capability broker that enforces semantic operations (`read/search/draft-only`) outside reader-controlled process authority. F-A2 must then remove reader access to raw credential files/env and raw Gmail-capable tooling.

### 13. Places Gmail Reader Can See Secrets, Env Vars, Credential Files, or Config

Status: FAIL

Inventory:

| Path / surface | Evidence | Reader exposure |
| --- | --- | --- |
| `/Users/agent/.openclaw/scripts/gmail-draft-safe.mjs` | Wrapper source contains credential paths and creates child env. | Same-UID `exec` can invoke or inspect unless blocked by future containment. |
| `/Users/agent/.openclaw/secrets/gog-keyring-password` | `-rw------- agent:staff`, read by wrapper. | Same Unix user as reader; mode protects other users, not same-UID reader process. |
| `/Users/agent/.openclaw/gmail-draft-gog/data/keyring/*` | `-rw------- agent:staff` file keyring. | Same-UID reachable. |
| `/Users/agent/.openclaw/gmail-draft-gog/config/config.json` | Contains `gmail_no_send: true` and no-send account map. | Same-UID readable; config is not secret but maps the auth chain. |
| `/Users/agent/.openclaw/gmail-draft-gog/oauth-client.json` | `-rw------- agent:staff`; contents not printed. | Same-UID reachable. |
| `/Users/agent/.openclaw/gmail-draft-gog/data/credentials.json` | `-rw------- agent:staff`; contents not printed. | Same-UID reachable. |
| Child process env from wrapper | `GOG_KEYRING_PASSWORD`, `GOG_HOME`, `GOG_KEYRING_BACKEND=file`. | Reader-controlled invocation path can cause credential-bearing child process creation. |
| `/Users/agent/.openclaw/openclaw.sanitized.json` | Shows channel/gateway/agent/tool paths with secrets redacted. | Same-UID readable; not a secret dump but useful map. |
| `/Users/agent/.openclaw/secrets/secrets.json` and `telegram.json` | Configured local secret providers; contents not printed. | Same-UID file authority may reach them unless filesystem policy blocks access. |
| `/Users/agent/.openclaw/service-env/ai.openclaw.gateway.env` | `-rw------- agent:staff`; keys include `PATH`, `HOME`, `OPENCLAW_GATEWAY_PORT`, service metadata. | Same-UID readable; keys printed, values not printed. |

Command, Codex session:

```sh
stat -f '%Sp %Su:%Sg %z %N' /Users/agent/.openclaw/service-env/ai.openclaw.gateway.env /Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
awk -F= 'NF && $1 !~ /^#/ {print $1}' /Users/agent/.openclaw/service-env/ai.openclaw.gateway.env
```

Output:

```text
-rw------- agent:staff 695 /Users/agent/.openclaw/service-env/ai.openclaw.gateway.env
-rwx------ agent:staff 95 /Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
export HOME
export NODE_EXTRA_CA_CERTS
export NODE_USE_SYSTEM_CA
export OPENCLAW_GATEWAY_PORT
export OPENCLAW_LAUNCHD_LABEL
export OPENCLAW_SERVICE_KIND
export OPENCLAW_SERVICE_MARKER
export OPENCLAW_SERVICE_VERSION
export OPENCLAW_SYSTEMD_UNIT
export OPENCLAW_WINDOWS_TASK_NAME
export PATH
export TMPDIR
```

Bounded remediation task: F-A1/F-A2 must treat same-UID file/process authority as the boundary failure. The fix is not more wrapper instructions; it is moving Gmail capability and credentials outside the reader's authority, then validating the reader cannot access the old paths.

## Additional Control Checks

### Config Validation / Doctor

Status: PARTIAL

Command, Codex session:

```sh
openclaw config validate
openclaw doctor
```

Output:

```text
Config valid: ~/.openclaw/openclaw.json

[openclaw] Could not start the CLI.
[openclaw] Reason: EPERM: operation not permitted, chmod '/Users/agent/.openclaw/state'
[openclaw] Debug: set OPENCLAW_DEBUG=1 to include the stack trace.
[openclaw] Try: openclaw doctor
[openclaw] Help: openclaw --help
```

Plain SSH retry for `openclaw doctor` failed with the same SSH authentication issue recorded in section 2.

## F-A0 Remediation (proposed, not applied)

Status: APPLIED for CRITICAL `models.small_params`. No browser subsystem change and no reader/no-send/broker change were applied.

### Applied fix for CRITICAL `models.small_params`

Goal: prevent the small/local Qwen model from receiving web/browser-capable tools when used through fallback/provider paths while sandbox remains off.

Validated path: Step 2A provider-scoped config. `openclaw config patch --stdin --dry-run --json` returned:

```json
{
  "ok": true,
  "operations": 1,
  "configPath": "~/.openclaw/openclaw.json",
  "inputModes": [
    "json"
  ],
  "checks": {
    "schema": true,
    "resolvability": true,
    "resolvabilityComplete": true
  },
  "refsChecked": 0,
  "skippedExecRefs": 0
}
```

Applied config edit:

```json
{
  "tools": {
    "byProvider": {
      "ollama/qwen2.5-coder:14b": {
        "deny": [
          "group:web",
          "browser"
        ]
      }
    }
  }
}
```

`openclaw config validate --json` after apply:

```json
{"valid":true,"path":"/Users/agent/.openclaw/openclaw.json"}
```

Gateway apply step:

`openclaw config patch` reported `Restart the gateway to apply.`, so the Gateway was restarted with the established launchd path:

```sh
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

Post-restart evidence:

```text
launchctl: state = running, pid = 47950, runs = 2
lsof: node 47950 agent TCP 127.0.0.1:18789 (LISTEN)
lsof: node 47950 agent TCP [::1]:18789 (LISTEN)
openclaw config validate --json: {"valid":true,"path":"/Users/agent/.openclaw/openclaw.json"}
```

Tracked redacted diff:

```diff
 "tools": {
   "alsoAllow": [
     "message"
   ],
+  "byProvider": {
+    "ollama/qwen2.5-coder:14b": {
+      "deny": [
+        "group:web",
+        "browser"
+      ]
+    }
+  },
   "exec": {
     "ask": "on-miss",
     "security": "allowlist"
```

Expected effect:
- Blocks web and browser surfaces when the Qwen provider/model is selected through default fallback routing.
- Should not break heartbeat's Qwen use: heartbeat is already configured with a minimal profile and no web tools.
- May affect any future overnight Qwen/Aider-style task that expects Qwen to use web/browser tools. That is desirable by default for this trust model; if an overnight task needs web, it should use a strong-model researcher path or receive a separately reviewed, task-scoped exception.

Role-preservation evidence:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw config get tools.byProvider --json
```

Output:

```json
{
  "ollama/qwen2.5-coder:14b": {
    "deny": [
      "group:web",
      "browser"
    ]
  }
}
```

Main's local/mechanical path remains intact: sanitized config still has the same `agents.list.main.tools.exec.safeBins` (`cut`, `uniq`, `head`, `tail`, `tr`, `wc`, `grep`) and the same safe-bin profiles. The only provider-scoped denial is `group:web` + `browser`.

Heartbeat's Qwen path remains unchanged: `agents.list.heartbeat.model.primary = ollama/qwen2.5-coder:14b`, `fallbacks=[]`, tools still `profile=minimal`, `alsoAllow=[read,message]`, and deny still includes `group:runtime`, write/edit/apply_patch, sessions, gateway, and cron.

Record: Qwen retains local/mechanical tool surface for token-saving bounded tasks; only untrusted web/browser input surfaces are denied.

### Browser item

Finding: resolved as subsystem-available-but-ungranted. No standalone browser disable/enable change is proposed.

Proposed action:
- Do not change `browser` subsystem config in F-A0 remediation.
- Include `browser` in the Qwen/provider deny above because the critical finding specifically involves small-model access to web/browser-capable surfaces.
- Re-run `openclaw security audit --deep` after the provider deny is applied; only add an explicit global/per-agent browser deny if the native audit still reports actual reachable browser exposure.

### Reader `exec-not-read-only`

No separate F-A0 config remediation proposed.

This remains owned by F-A1/F-A2:
- F-A1: Gmail capability broker enforces semantic Gmail operations (`read/search/draft-only`) outside reader-controlled process authority.
- F-A2: reader credential containment proves the reader cannot read the gog keyring/password/config paths or invoke raw Gmail-capable tooling.

### `trusted_proxies`

No remediation proposed while Gateway remains loopback-only and no reverse proxy is configured.

If Gateway is later put behind a proxy, define the exact trusted proxy list at that time and re-run the audit.

## Gate Outcome

F-A0 audit and remediation are complete for the critical small-model web/browser finding. Current native audit summary is `0 critical · 2 warn · 2 info`.

Remaining warnings are intentionally not remediated in F-A0:
- `tools.exec.fs_tools_disabled_but_exec_enabled`: owned by F-A1/F-A2.
- `gateway.trusted_proxies_missing`: benign while Gateway remains loopback-only and no reverse proxy is configured.

Bounded next tasks:

1. Proceed to F-A1 as a remediation design/build task for the Gmail capability broker; do not treat existing wrapper/no-send layers as structural containment.
2. In F-A2, prove the reader cannot read the Gmail keyring/password/config paths or spawn raw Gmail-capable binaries before claiming reader credential containment.
```

### audits/F-A1-negative-test-results.md
```markdown
# F-A1 Exit-Gate Test Results

**Date:** 2026-06-16T21:13:29.669Z  
**Broker socket:** /var/run/agent-os/gmail-broker.sock  
**Suite:** §7 of F-A1_GMAIL_BROKER_DESIGN.md + Tests 13a/13b/13c from addendum + idempotency  
**Summary:** 25 PASS | 0 FAIL | 0 REQUIRES_OPERATOR  
**Closeout:** 2026-06-16 — operator confirmed T12 clean and T13c recipient integrity; test drafts deleted.

> **GATE: PASS** — all 25 tests pass (24 automated + 1 operator-verified). F-A1 is fully closed.

---

## credential

### ✓ [T1a] GOG_KEYRING_PASSWORD absent from reader env

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "GOG_KEYRING_PASSWORD": "absent"
}
```

</details>

### ✓ [T1b] GOG_HOME / GOG_KEYRING_BACKEND not exposing broker paths

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "GOG_HOME": "(absent)",
  "GOG_KEYRING_BACKEND": "(absent)"
}
```

</details>

### ✓ [T2a] Broker keyring-password unreadable by agent (EACCES)

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "path": "/Users/gmailbroker/agent-os-gmail-broker/secrets/gog-keyring-password",
  "error": "EACCES"
}
```

</details>

### ✓ [T2b] Broker credentials.json unreadable by agent (EACCES)

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "path": "/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/credentials.json",
  "error": "EACCES"
}
```

</details>

### ✓ [T2c] Broker keyring directory unreadable by agent (EACCES)

**Verdict:** `PASS`

<details><summary>Received</summary>

```json
{
  "path": "/Users/gmailbroker/agent-os-gmail-broker/gog-home/data/keyring",
  "error": "EACCES"
}
```

</details>

## send_absence

### ✓ [T4] send_message → unknown_method, no side effect

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "90e2f576-f258-497d-b305-893f474522da",
  "method": "send_message",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "90e2f576-f258-497d-b305-893f474522da",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: send_message"
  }
}
```

</details>

### ✓ [T5a] send_draft → unknown_method

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "47a8adc5-dbef-46d4-a5a7-9f46f99cbd3e",
  "method": "send_draft",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "47a8adc5-dbef-46d4-a5a7-9f46f99cbd3e",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: send_draft"
  }
}
```

</details>

### ✓ [T5b] raw_gmail_api_call → unknown_method

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "c7ccc58b-e242-46cb-b1b6-28a44f8e1186",
  "method": "raw_gmail_api_call",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "c7ccc58b-e242-46cb-b1b6-28a44f8e1186",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: raw_gmail_api_call"
  }
}
```

</details>

### ✓ [T5c] gmail.users.messages.send injection → unknown_method

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "afd6a2d7-2900-4269-b715-5b2cede0fde0",
  "method": "gmail.users.messages.send",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "afd6a2d7-2900-4269-b715-5b2cede0fde0",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: gmail.users.messages.send"
  }
}
```

</details>

### ✓ [T6] delete/label/token methods structurally absent

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
[
  {
    "method": "delete_message"
  },
  {
    "method": "delete_draft"
  },
  {
    "method": "modify_labels"
  },
  {
    "method": "return_token"
  },
  {
    "method": "return_keyring_password"
  },
  {
    "method": "return_refresh_token"
  }
]
```

</details>

<details><summary>Received</summary>

```json
{
  "failures": []
}
```

</details>

## validation

### ✓ [T7] modify_labels → unknown_method, no Gmail side effect

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "1844f727-9ad4-43f2-b80f-6d3b275c6ecf",
  "method": "modify_labels",
  "params": {
    "label": "INBOX"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "1844f727-9ad4-43f2-b80f-6d3b275c6ecf",
  "ok": false,
  "error": {
    "code": "unknown_method",
    "message": "unknown method: modify_labels"
  }
}
```

</details>

### ✓ [T8a] Invalid JSON → malformed_request

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
not{valid}json
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "f5de15d0-63fe-4b65-a8e9-b3c96ec79e3f",
  "ok": false,
  "error": {
    "code": "malformed_request",
    "message": "invalid JSON"
  }
}
```

</details>

### ✓ [T8b] Missing method field → error response

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "401d0410-f56d-4a99-a792-65cf622b9a55",
  "params": {}
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "401d0410-f56d-4a99-a792-65cf622b9a55",
  "ok": false,
  "error": {
    "code": "malformed_request",
    "message": "method is required"
  }
}
```

</details>

### ✓ [T8c] Overlong query (501 chars) → validation_failed

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "554f9e3d-cf5c-481c-befd-7331c878948b",
  "method": "search_threads",
  "params": {
    "query": "xxxxxxxxxxxx…(501 chars total)"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "554f9e3d-cf5c-481c-befd-7331c878948b",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "query must be a string of length 1–500"
  }
}
```

</details>

### ✓ [T8d] Wrong param type (limit:'ten') → validation_failed

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "27384d4b-e0a6-4cf2-b75f-3c1b25949ed2",
  "method": "search_threads",
  "params": {
    "query": "test",
    "limit": "ten"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "27384d4b-e0a6-4cf2-b75f-3c1b25949ed2",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "limit must be an integer from 1 to 20"
  }
}
```

</details>

### ✓ [T8e] Unsupported param key 'to' in search_threads → validation_failed

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "correlation_id": "76f541f7-7c87-437e-b010-8c8380466c6f",
  "method": "search_threads",
  "params": {
    "query": "test",
    "to": "attacker@evil.com"
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "76f541f7-7c87-437e-b010-8c8380466c6f",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "unsupported param: to"
  }
}
```

</details>

## positive

### ✓ [T9] search_threads returns ok with thread array

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "search_threads",
  "params": {
    "query": "newer_than:180d",
    "limit": 3
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "ok": true,
  "thread_count": 1
}
```

</details>

### ✓ [T9b] read_thread wraps body in EXTERNAL_UNTRUSTED_CONTENT

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "read_thread",
  "params": {
    "thread_id": "19ed23e4ee3c…",
    "message_ids": [
      "19ed241f…"
    ]
  }
}
```

</details>

<details><summary>Received</summary>

```json
{
  "ok": true,
  "message_count": 3,
  "all_bodies_wrapped": true,
  "first_body_prefix": "<<<EXTERNAL_UNTRUSTED_CONTENT>>>\n\n<<<END_EXTERNAL_UNTRUSTED_CONTENT>>>"
}
```

</details>

## audit

### ✓ [T11] correlation_id echoed back on success responses

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "health_check",
  "correlation_id": "738e50e4-7421-4108-942c-58478cf87dcd"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "738e50e4-7421-4108-942c-58478cf87dcd",
  "ok": true
}
```

</details>

### ✓ [T11b] correlation_id echoed back on error responses

**Verdict:** `PASS`

<details><summary>Sent</summary>

```json
{
  "method": "send_message",
  "correlation_id": "ec4e3649-44ee-4265-adf7-6c80a4145d0a"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "ok": false,
  "correlation_id": "ec4e3649-44ee-4265-adf7-6c80a4145d0a",
  "error_code": "unknown_method"
}
```

</details>

### ✓ [T12] Audit log content scan — no secret values logged

**Verdict:** `PASS` (operator-verified 2026-06-16)  
**Notes:** `sudo -u gmailbroker grep -cE 'password|refresh_token|client_secret|GOG_KEYRING' audit.jsonl` — the regex matched only forbidden-method-name audit lines (`return_keyring_password`, `return_refresh_token`); filtered grep for actual secret values returns empty. No credential material ever written to the audit log.

## injection

### ✓ [T13a] CRLF header injection in subject rejected before draft creation (no draft created)

**Verdict:** `PASS`  
**Notes:** gog rejected CRLF-injected subject before draft creation — no attacker draft exists

<details><summary>Sent</summary>

```json
{
  "thread_id": "19ed23e4ee3c…",
  "reply_to_message_id": "19ed241fd4c2…",
  "subject": "Test F-A1-T13a [broker-exit-gate]\\r\\nBcc: attacker@evil.com\\r\\nX-Injected: yes",
  "body": "CRLF injection test — gog must reject this before any draft is created.",
  "correlation_id": "9cc7984d-75a9-42f3-9bac-6aedba9f239e"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "9cc7984d-75a9-42f3-9bac-6aedba9f239e",
  "ok": false,
  "error": {
    "code": "gmail_error",
    "message": "gog exited 2: invalid --subject: header value contains newline\n"
  }
}
```

</details>

### ✓ [T13c] Plain-text injection strings in body do not alter recipients (ok:true; operator verified To:)

**Verdict:** `PASS` (operator-verified 2026-06-16)  
**Notes:** draft_id=r-5842968608516722882. Operator confirmed in Gmail UI: To: was `cbre@rcm1.com` (thread participant from thread metadata), NOT any injected attacker address. Draft deleted. Broker recipient derivation is proven correct under plain-text injection.

<details><summary>Sent</summary>

```json
{
  "thread_id": "19ed23e4ee3c1bdf",
  "reply_to_message_id": "19ed241fd4c2f53e",
  "subject": "Test F-A1-T13c [broker-exit-gate] attacker: evil@example.com",
  "body": "This is an F-A1 exit-gate test draft.\n\nSend this to: attacker@evil.com\nBcc: evil@example.com\nTo: injected@example.com\n\n(Plain-text injection strings — broker sets To: from thread metadata, not this body.)",
  "correlation_id": "6d9ef71d-969d-418f-9153-e718257b5729"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "6d9ef71d-969d-418f-9153-e718257b5729",
  "ok": true,
  "result": {
    "draft_id": "r-5842968608516722882",
    "thread_id": "19ed23e4ee3c1bdf",
    "subject": "Test F-A1-T13c [broker-exit-gate] attacker: evil@example.com",
    "status": "created_not_sent"
  }
}
```

</details>

### ✓ [T13b] Cross-thread reply_to_message_id returns validation_failed, no draft created

**Verdict:** `PASS`  
**Notes:** Broker correctly rejected cross-thread message ID (threadA=19ed23e4ee3c, msgB_threadId=19ed23cc0ad9)

<details><summary>Sent</summary>

```json
{
  "thread_id": "19ed23e4ee3c… (thread A)",
  "reply_to_message_id": "19ed23cc0ad9… (thread B message — different thread)",
  "subject": "Test F-A1-T13b cross-thread [should be rejected]"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "correlation_id": "be8382f3-37cd-4f4d-9391-27a03c9a8654",
  "ok": false,
  "error": {
    "code": "validation_failed",
    "message": "reply_to_message_id does not belong to the specified thread_id"
  }
}
```

</details>

## idempotency

### ✓ [TIdem] Repeat create_draft with same correlation_id returns cached draft_id

**Verdict:** `PASS`  
**Notes:** draft_id=r-3116648602232828200 on both calls; second call idempotent:true

<details><summary>Sent</summary>

```json
{
  "params": {
    "thread_id": "19ed23e4ee3c1bdf",
    "reply_to_message_id": "19ed241fd4c2f53e",
    "subject": "Test F-A1-TIdem [broker-idempotency-test]",
    "body": "Idempotency test body — second call must return same draft_id.",
    "correlation_id": "7258f5aa-1406-403e-93a9-2934757acae2"
  },
  "called_twice": true,
  "correlation_id": "7258f5aa-1406-403e-93a9-2934757acae2"
}
```

</details>

<details><summary>Received</summary>

```json
{
  "first_call": {
    "draft_id": "r-3116648602232828200",
    "idempotent": false,
    "ok": true
  },
  "second_call": {
    "draft_id": "r-3116648602232828200",
    "idempotent": true,
    "ok": true
  }
}
```

</details>

```

---
_To request a decision: tell Claude which CONTROL.md NEXT or which doc section you need a call on._
