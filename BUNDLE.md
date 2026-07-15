# AGENT OS — STATE BUNDLE FOR CLAUDE
_Generated: 2026-07-15T02:09:43Z · commit: 5aaec3e_

This is a sanitized snapshot for Claude.ai review. Secrets are excluded by .gitignore + scan.

---
## CONTROL.md (current state)
```markdown
# CONTROL.md — Agent OS Current Control State

## Mandatory operator gate

Every human or AI operator must read `OPERATING_CONSTITUTION.md` before acting.

Live runtime evidence is authoritative for observed facts. `CONTROL.md` records the accepted current state, phase status, blockers, next actions, and verification gates.

No document, including `CONTROL.md`, can create authority that does not exist in live enforcement boundaries.

Durable architecture decisions and technical requirements are recorded in `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md`.

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
- Sensitive-data, autonomous-memory, Command Center mutation, and consequential-action expansion remain on hold.

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
ec771af docs: verify F-A4 credential custody
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
docs/AGENT_OS_ARCHITECTURE_DECISIONS.md
docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md
docs/AGENT_OS_END_STATE_ARCHITECTURE.md
docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md
docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md
docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md
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
## Canonical reference docs (inlined — all four, ~98KB total)

### AGENT_OS_END_STATE_ARCHITECTURE.md
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

### AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
```markdown
# OpenClaw Platform Mechanics Reference

**Purpose:** the platform-specific behavior of OpenClaw 2026.6.5 — runtime, exec, sandbox, egress, auth, observability, cron — mapped from the docs and issue tracker AHEAD of building, so build drops start from a *verified config recipe* instead of discovering incompatibilities mid-run. This is the artifact that closes the "we keep finding platform answers reactively" gap.

**Status:** v1, 2026-06-14. Companion to the End-State Architecture (the platform-mechanics gate references this file). Living document — deepen each section before its phase; update when OpenClaw version changes (mechanics are version-specific — this is 2026.6.5).

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
| Foundation 2 — egress/sandbox | §3, §4 | IN BUILD — operator-owned managed proxy + pf backstop built/proven; not integrated. Direct Codex Apps Gmail bypass removal precedes final proxy/pf acceptance. |
| Foundation 3 — observability | §5 | RESEARCHED — design direction set; confirm OTel plugin choice before build |
| Foundation 4 — action-policy/exec | §2, §6 | RESEARCHED — standing orders + exec model mapped |
| Secrets/credential proxy | §7 | IMPLEMENTED FOR GMAIL — dedicated `gmailbroker` capability broker; direct connector complete-mediation gap remains open |
| Cron/heartbeat autonomy | §6 | RESEARCHED |

Before each phase's build drop: re-read its section, resolve OPEN VERIFY items with a read-only diagnostic against the live install, mark VERIFIED, THEN write the build drop.
```

### AGENT_OS_SECURITY_DESIGN_STANDARD.md
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

### AGENT_OS_ROADMAP_BEST_PRACTICES.md
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

---
_To request a decision: tell Claude which CONTROL.md NEXT or which doc section you need a call on._
