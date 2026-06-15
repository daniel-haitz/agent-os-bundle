# AGENT OS — STATE BUNDLE FOR CLAUDE
_Generated: 2026-06-15T15:17:05Z · commit: cae8910_

This is a sanitized snapshot for Claude.ai review. Secrets are excluded by .gitignore + scan.

---
## CONTROL.md (current state)
```markdown
# CONTROL.md — Single Source of Truth

## Canonical references — read before building
Read these at the start of any build session. Architecture and phase ordering defer to these over anything below in this file or the plan.
- docs/AGENT_OS_END_STATE_ARCHITECTURE.md — what we're building (personal life-ops agent), the four foundations, dispatch/confirm split, deny-by-default policy. The spine; phase order follows this.
- docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md — how OpenClaw 2026.6.5 actually enforces runtime, exec, sandbox, egress, auth, and observability. Resolve its §9 VERIFY items before any foundation build drop.
- docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md — prompt-injection patterns; run the §6 checklist before any new capability.
- docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md — per-domain research + per-phase pre-build checklists.

## System state (where the built system actually is)
The PLAN lives here (agent-os, pushed to origin). The BUILT SYSTEM lives in ~/.openclaw on the mini — LOCAL-ONLY, no remote, never pushed. A fresh session must read ~/.openclaw directly on the mini; it is not in any remote.
Current drift state: committed at b20dda1, which includes the verified Path B reader config and the completed Part C live + injection tests.

**This is the ONLY state file. Every worker reads this first and updates it last.**
**If it's not in this file, it didn't happen. The repo is truth, not any prompt or any brain's memory.**

---

## NOW (where we are this exact moment)

> Phase 2 email-assistant workstream (as tracked in live state) is COMPLETE and injection-tested under Path B: sanitized local drift tracking, `gmail.readonly` + `gmail.compose`, draft-only wrapper, pinned safe gog binary, file keyring, three-layer no-send proof, isolated reader/researcher delegation, schema-constrained research validation, and real-thread draft tests. This does not mark the legacy numbered `PHASE 2 — Doctrine as skills` in the build plan complete.

**FLAG:** A full Mac reboot was not tested (only a controlled daemon restart) — verify auto-start on next reboot.
**FLAG:** Sandbox remains off; do not add untrusted inbound paths before later Phase 1 hardening.
**FLAG:** Phase 1.4 must isolate `~/.ssh`, `~/.aws`, and secrets paths; OpenClaw 2026.6.5 has no exec/tool path-deny control.
**FLAG:** Heartbeat agent replied `NO_REPLY` instead of `HEARTBEAT_OK` on its first restricted run — verify the output is interpretable as a health signal in a later check.
**FLAG:** `EPERM: chmod ~/.openclaw/state` is caused by OpenClaw 2026.6.5 unconditionally chmodding an already-correct `agent:staff` 0700 directory inside a repo-only managed sandbox; pending fix is an OpenClaw code/version fix, not chmod/chown.
**FLAG:** VERIFIED emergency stop: first stop any attached CLI/supervisor retry source, then run `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`; do not use `openclaw gateway stop`/`restart` on this Mac. Telegram `/stop` remains reasoning-halt only.
**FLAG:** Docker is not installed and `/var/run/docker.sock` is absent; Phase 1.4 sandbox discovery/build is blocked pending an operator container-runtime decision.
**FLAG:** Egress control is DEFERRED and gates the sensitive-data tier: outbound network access is currently unrestricted. Resolve the Platform Mechanics §4 VERIFY items before choosing host `pf`, sandbox networking, or a layered mechanism.
**FLAG:** Instruction/memory-file drift detection is DEFERRED: add `HEARTBEAT.md` and all SOUL/AGENTS-equivalent files to the `~/.openclaw` baseline so persistent instruction edits trip the drift check.
**FLAG:** THREE-WALL SENSITIVE-DATA GATE: do not expose SSN-class data until action-policy/exec controls [PARTIAL — Path B reader has no OS-level exec allowlist], isolation/sandbox [DEFERRED — Docker], and egress control [DEFERRED — mechanism under §4 verification] all exist; prompt instructions are not a structural wall.
**FLAG:** Notify-tier build (`1.2b-build`) is DEFERRED and non-urgent; the hooks mechanism audit and safe design constraints are recorded.
**FLAG:** `~/.openclaw` is a local-only drift repo at `b20dda1`; live `openclaw.json` is ignored, the redacted snapshot and security policy files are tracked, and the root `.gitignore` is an allowlist.
**FLAG:** Gmail uses `gmail.compose`; never-send is a three-layer software guarantee, not a scope boundary. The operator reviews and sends every draft manually.
**FLAG:** Gmail is on-demand pull. Pub/Sub, gcloud, webhook delivery, and real-time push are DEFERRED.
**FLAG:** Draft deletion is not exposed by the safe wrapper; test and unwanted drafts are removed manually in Gmail UI.
**FLAG:** Headless Gmail auth uses gog's file keyring; the password is stored under ignored `~/.openclaw/secrets/` and is visible to same-user processes only while injected into the safe child environment. This exposure is accepted.
**FLAG:** Email instruction/data separation follows the CaMeL dual-plane pattern: paired Telegram operator instructions are commands; email content is inert untrusted data.
**FLAG:** Agent separation is containment, not formal DLP. Research-question smuggling remains a residual injection risk; the loop is supervised-use and non-sensitive ONLY until egress control exists.
**FLAG:** KNOWN ISSUE — sub-agent completion delivery: parent `main` session yields before the delegated reader's result surfaces, causing a recovery re-run and, in Part C Test 2, a duplicate draft. Benign under supervision; must be fixed before unsupervised operation. The same yield-before-child-result behavior occurred in the earlier failed run.

---

## NEXT (the single bounded task the next worker does)

> **F-A Containment/egress — DECISION POINT (operator).** §4 verify item #1 resolved: host-pf is NON-VIABLE on this macOS build (Plan A eliminated on evidence — see §4). Surviving fork: **Plan B (separate egress box)** vs **Plan C (install Docker → container + Squid egress)**. The build cannot proceed until the operator picks one. Once chosen: read-only verify the chosen path, then build.

**PARKED (do after egress decision):** Publish-hygiene fix — bundle-for-claude.sh couples generate+commit+push with no review gate and didn't keep the public mirror current (18-commit drift surfaced this session). Diagnose why the existing end-session/bundle wiring didn't fire; add a review/dry-run mode and ensure publish actually runs at session end.

**FLAG:** When Foundations 1 (dispatch/confirm split) and 4 (action-policy + deny-by-default) are built, migrate those invariants from docs/ into live agent doctrine (workspace AGENTS.md / doctrine/) so the running system enforces them, not just the plan. Not now — enforcing mechanism doesn't exist yet.

---

## DONE (reverse chronological — newest first, one line each)

<!-- Workers append here. Format: YYYY-MM-DD | worker | what shipped | commit -->
- 2026-06-14 | codex | Phase 2 email-assistant workstream — Verified Path B on live threads; read/draft loop, three-layer no-send, injection handling, research-query boundary, and unchanged Sent folder all passed | ~/.openclaw b20dda1
- 2026-06-13 | codex | Gmail compose connection — Granted only readonly + compose + OIDC, verified reads and real Gmail drafts, and proved sending blocked at wrapper, baked-binary, and `gmail_no_send` layers | a2065e8
- 2026-06-13 | codex | Gmail confinement — Built pinned gogcli v0.25.0 production/auth binaries, strict draft wrapper, file-keyring injection, and live-token-safe local drift tracking | a2065e8
- 2026-06-13 | codex | Sanitized drift repo — Replaced live-config tracking with a redacted deterministic snapshot and root allowlist `.gitignore`; secrets and runtime state cannot enter unscoped staging | a2065e8
- 2026-06-12 | codex | 2.A-discovery — Scoped the safe email assistant; Gmail `gmail.readonly` and reader routing are available, but stock setup is NO-GO because hook secrets persist plaintext | this commit
- 2026-06-12 | codex | 1.5b — Verified launchd kickstart kills gateway-owned in-flight exec and auto-recovers; diagnosed EPERM as unconditional chmod versus managed-sandbox policy | this commit
- 2026-06-12 | codex | 1.4-discovery — NO-GO at hard gate: Docker binary and daemon socket absent; container kill and sandbox mapping deferred | this commit
- 2026-06-12 | codex | 1.5 — Live-tested kill switch: Gateway aborts run state in about 1s but does not kill an in-flight host exec; C.5/C.6 remain separate | this commit
- 2026-06-12 | codex | 1.2b-discovery — GO with constraints: settled hook payload, direct Telegram delivery, failure, scope, and async behavior; safe-list now drift-tracked | this commit
- 2026-06-12 | codex | 1.2a — Seeded Free-tier Git allowlist and hardened safe bins; enabled strict inline eval and Never-tier tool denies | this commit
- 2026-06-12 | codex | 1.1c — Routed heartbeat to a dedicated local-Qwen agent with mechanically restricted tools; re-baselined config | this commit
- 2026-06-12 | codex | 1.1 — Set and effectively verified strict exec baseline `allowlist` / `on-miss` / `deny`; corrected fail-closed plan claim | this commit
- 2026-06-12 | codex | DROP 1.0 pre-Phase-1 audit — NO-GO until fail-closed defaults, custom Notify, real abort tests, and loop gaps are incorporated | this commit
- 2026-06-11 | codex | 0.8 — Installed Clawhatch and scored a test skill | e59160b
- 2026-06-11 | codex | 0.7 — Git-baselined only `openclaw.json` in `~/.openclaw` | e59160b
- 2026-06-11 | codex | 0.6 — Configured isolated light-context heartbeat on local Qwen | e59160b
- 2026-06-11 | codex | 0.5 — Stored gateway and Telegram tokens as 0600 file SecretRefs; audit clean | e59160b
- 2026-06-11 | codex | 0.4 — Configured Codex OAuth primary, local Qwen fallback, and maxConcurrent 3 | e59160b
- 2026-06-11 | codex | 0.3 — Created, paired, and round-trip tested @LLoyd_entouragebot | e59160b
- 2026-06-11 | codex | 0.2 — Installed and verified the supervised OpenClaw launchd daemon | e59160b
- 2026-06-11 | codex | 0.1 — Installed OpenClaw 2026.6.5 user-space with Node 22.22.0 | e59160b

---

## DECISIONS LOG (only real decisions / direction changes — not routine progress)

<!-- Format: YYYY-MM-DD | decision | one-line why -->
- 2026-06-15 | Plan A (host-pf UID-keyed proxy) eliminated for egress | pf-viability verify resolved NO: route-to≠proxy-redirect, rdr can't match UID, translation precedes filtering, no per-agent UID in one gateway. Egress decision now open: Plan B separate-box vs Plan C Docker (needs install).
- 2026-06-14 | Confined reader runs Path B: default Codex runtime with `tools.exec.mode="auto"`; OS-level exec allowlisting is not enforced | Live testing proved `auto` does not preserve the approvals-layer allowlist and embedded runtime requires a separate OpenAI API key. Accepted confinement is OAuth scope + three-layer no-send + research validator + coming egress; the reader remains supervised/non-sensitive until egress and isolation close the temporary host-shell gap. Reconsider Path A if sensitive unsupervised use is needed first.
- 2026-06-14 | Phase order changed to foundations-first per end-state architecture; egress/containment moved ahead of new capabilities | Containment is the unlock for unattended use; capability-first leaves capabilities stuck in supervised-mode and risks per-capability rebuild
- 2026-06-13 | Gmail draft-only uses `gmail.readonly` + `gmail.compose` with a three-layer software no-send barrier | Readonly cannot create Gmail drafts; wrapper allowlisting, a policy-compiled gog v0.25.0 binary, and `gmail_no_send` all independently block send paths
- 2026-06-13 | Gmail authentication and runtime use separate binaries and a file keyring | The auth bootstrap has no Gmail commands, the production binary has no auth/send commands, and macOS Keychain was unreliable in the headless session
- 2026-06-13 | Gmail remains on-demand pull; Pub/Sub/gcloud push is deferred | Pull satisfies the supervised workflow without adding webhook secrets, public ingress, or cloud infrastructure
- 2026-06-13 | Email automation follows a CaMeL-style dual-plane model and remains supervised/non-sensitive until egress control exists | Email is untrusted data, Telegram is the command plane, but agent separation cannot formally prevent injected text from being smuggled into a research query
- 2026-06-13 | `~/.openclaw` tracks a sanitized snapshot and explicit security artifacts under a root allowlist | Live config, credentials, workspaces, and runtime state remain ignored while meaningful drift stays reviewable
- 2026-06-12 | SUPERSEDED 2026-06-13: stock webhook Gmail setup was rejected | It wrote plaintext hook secrets and introduced unnecessary push ingress; the implemented design uses on-demand pull through the confined wrapper
- 2026-06-12 | SUPERSEDED 2026-06-13: read-only OAuth and macOS Keychain were the initial target | Real Gmail drafts require compose scope, and headless Keychain access proved unreliable; the live design uses three-layer software no-send plus a protected file keyring
- 2026-06-12 | SUPERSEDED 2026-06-13: dedicated webhook routing was the initial reader plan | The implemented on-demand design delegates from the paired Telegram main agent to restricted reader and research agents
- 2026-06-12 | Emergency panic sequence is stop any initiating retry/fallback client, then `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`; do not use OpenClaw gateway stop/restart on this Mac | Live proof showed the original gateway-owned counter halted at 18, PID changed `57469` to `65509`, launchd recovered immediately, and an attached CLI separately replayed through embedded fallback
- 2026-06-12 | Fix the state-dir EPERM in OpenClaw code/version, not with chown/chmod | State dir is already owned by runtime UID 501 at 0700; 2026.6.5 unconditionally chmods it during CLI bootstrap and the repo-only managed sandbox rejects that metadata write
- 2026-06-12 | Phase 1.4 is blocked pending an operator decision to install a Docker-compatible runtime | Docker binary and `/var/run/docker.sock` are absent, so neither OpenClaw sandboxing nor container-kill proof can run
- 2026-06-12 | Daily panic command is standalone `/stop` in the affected Telegram chat, but it is only a run/future-step stop until process-group kill enforcement exists | Live `sessions.abort` returned in about 1s while the inert shell continued for about 109s; `/stop` and queue interrupt share the same embedded-run abort primitive
- 2026-06-12 | Keep C.5 receive/acknowledge separate from C.6 interrupt/terminate | The live test proved OpenClaw can acknowledge abort while an in-flight host process continues
- 2026-06-12 | Notify uses typed `after_tool_call`, filters internally to main + explicit action classes, and sends fixed metadata through the direct Telegram outbound adapter | The hook sees secret-bearing args/results and has no declarative tool/agent scope; direct delivery avoids a message-tool loop
- 2026-06-12 | Notify requires a persistent secret-free outbox, retry/deduplication, startup drain, and visible terminal-failure state | Native `after_tool_call` is fire-and-forget and logs send failures without affecting the completed action
- 2026-06-12 | Track `exec-approvals.json` with `openclaw.json` at baseline `b77a0f8` | The safe-list is security state and must participate in drift detection; direct scan confirmed no secrets
- 2026-06-12 | Main Free seed is exact `git status` / `git diff` / `git log` / `git show`; safe bins are `cut`, `uniq`, `head`, `tail`, `tr`, `wc`, and hardened `grep`; `strictInlineEval` is true; Never denies `gateway`, `cron`, and `sessions_*` | Off-list commands remain `on-miss`; phone “allow always” is the durable path for intentional safe-list growth
- 2026-06-12 | Defer `~/.ssh`, `~/.aws`, and secrets path isolation to Phase 1.4 sandboxing | OpenClaw 2026.6.5 tool deny rules match tool IDs, not host filesystem paths
- 2026-06-12 | Use explicit `agents.list[]` entries for `main` and specialized agents; heartbeat uses `tools.profile: minimal`, adds `read`/`message`, and denies `group:runtime`, `write`, `edit`, `apply_patch`, `group:sessions`, `gateway`, and `cron` | Per-agent heartbeat blocks route heartbeats exclusively to those agents; this became the template for the Phase 2 email-assistant reader split
- 2026-06-12 | Main-agent exec uses `allowlist` / `on-miss` / `deny`; fail-closed is configured, not default | DROP 1.0 proved OpenClaw 2026.6.5 otherwise resolves to `full` / `off` / `full`
- 2026-06-12 | Phase 1.6 must combine enabled native loop detection with custom iteration, cost, and durable-trip controls | Native coverage has hash/no-progress/stuck detectors but no general iteration cap, true cost breaker, or persistent trip latch
- 2026-06-12 | Phase 1.5 kill-switch tests target `/stop`, `/queue interrupt`, and `sessions.abort` | Approval denial blocks one pending command, steer waits for a boundary, and goal state does not cancel a run
- 2026-06-12 | Build a custom typed Notify-tier plugin/hook before Phase 1.2 | OpenClaw has tool observation and telemetry but no declarative notify-only side-effect tier
- 2026-06-12 | Explicitly configure `askFallback: deny` in Phase 1.1 | OpenClaw 2026.6.5 currently resolves the unconfigured host exec baseline to `full/off/full`
- 2026-06-11 | Git-baseline OpenClaw config separately in `~/.openclaw` at e59160b | Tracks config drift without committing the state directory
- 2026-06-11 | Keep the real OpenClaw config in SecretRef object form despite Clawhatch compatibility bug | The Clawhatch bug was logged; security was not weakened to accommodate it
- 2026-06-11 | Raise heartbeat timeout to 180s | Qwen completes locally in about 47s instead of falling back to paid Codex
- 2026-06-11 | Store gateway and Telegram tokens as 0600 file SecretRefs | Keeps plaintext secrets out of `openclaw.json`
- 2026-06-11 | Reuse existing Codex CLI OAuth | Enables Codex runtime without storing a plaintext API credential
- 2026-06-11 | Install OpenClaw user-space with its own Node 22.22.0 | Homebrew installation path was unwritable
- 2026-06-11 | Adopt OpenClaw as foundation; doctrine ports on top | OpenClaw provides natively what the old custom build reimplemented
- 2026-06-11 | Repo-as-truth workflow; Codex-primary; Claude-as-consultant | Old flow made the human the integration layer — slow, drift-prone

---

## OPEN VERIFICATION GATES (must not be skipped — security-critical)

- [ ] **Aquaman source audit + native-SecretRef comparison** (Phase 6) — before ANY real SSN.
- [ ] **ClawGuard source read** (legacy numbered Phase 2 doctrine/audit inventory) — before it carries audit integrity. Custom hash-chain fallback ready.
- [ ] **Browser `fill` tool-side secret resolution test** (Phase 6) — does fill resolve a SecretRef without returning the value to the LLM?

---

## LEGACY NUMBERED PHASE MAP (detail inventory in docs/OPENCLAW_BUILD_PLAN.md; execution order is foundations-first)

- **0** Clean stand-up: install, onboard, new bot, Codex+Qwen routing, secrets audit, git-baseline config
- **1** Trust model as config: tiers, approvals, sandbox, reader-agent split designed, config-self-mod defenses
- **2** Doctrine as skills: SOUL/AGENTS, Steinberger orchestrator pattern, ClawGuard audit, Skill Workshop. This remains open and is distinct from the completed Phase 2 email-assistant workstream.
- **3** Integrations: Gmail brief, cron, web search, memory/lifestreams, Inferred Commitments
- **4** Command Center: custom WS app per v4 mock (7 surfaces) + Recurring Registry awareness layer
- **5** Evals + observability (Opik/OTel) + reviewer access
- **6** Sensitive form-fill (SSN): Aquaman-or-native, reader-agent isolation live, max-rigor proof gate

---

## HOW TO UPDATE THIS FILE (workers read this)

1. When you START: read NOW + NEXT. That's your task. Don't invent scope.
2. When you FINISH: move NEXT→DONE (one line), write the new NEXT (one bounded step), update NOW.
3. If you made a real decision: add to DECISIONS LOG.
4. Commit with the structured message (see templates/COMMIT_FORMAT.md).
5. Never leave this file stale. `end-session.sh` enforces this.
```

## Recent git log (20)
```
cae8910 control: record §4 Plan-A elimination, open egress fork, park publish-hygiene fix
53f146b platform-mechanics §4: reconcile leftover Plan-A-adopted text with elimination (internal consistency)
556b8c9 platform-mechanics §4: amend egress decision (host-side reader + UID-keyed pf proxy; Docker→Plan B) per egress-verify findings
a6ae107 [codex] reconcile Path B state and platform references
7f08680 [codex] harden cross-repo handoff state
07c103c [codex] establish canonical references and foundations-first plan
4436f63 [codex] document live Gmail architecture and supervised email loop
2124365 gmail discovery: correct compose-scope analysis + send-path reachability audit
6d11758 [codex] 2.A: scope Phase 2 email assistant; Gmail connector read-only discovery + go/no-go
49d5f8e [codex] H.2: push verified work; record deferred plan items (egress, instruction-file drift, three-wall SSN gate)
614fbf6 [codex] 1.5b: verified panic button (kickstart-kill + auto-recover); EPERM root cause diagnosed
9ffa2c3 [codex] 1.4-discovery: sandbox/kill-switch feasibility + EPERM root cause + config secret check
ea1e3f0 [codex] 1.5: kill-switch verified live against inert task; panic-button command documented
0fdde55 [codex] 1.2b-discovery: hooks mechanism audit; safe-list now git-tracked
e9c9304 [codex] 1.2a: Free/Never tiers — allowlist seed, deny-list, strictInlineEval; pending batch pushed; config re-baselined
8c526f0 [codex] 1.1c: dedicated restricted heartbeat agent; heartbeat routed off main; config re-baselined
da10378 [codex] 1.1: strict exec baseline allowlist/on-miss/deny, verified effective; plan-doc fail-closed claim corrected
4435816 [codex] fix end-session: add --no-push opt-out (push coupling bug)
a94ddbb [codex] 1.0: pre-Phase-1 trust audit - NO-GO
2b15fce [codex] fix bundle: sync docs + cache-bust URL
```

## Repo tree (no node_modules / .secrets / state)
```
.gitignore
00_TEARDOWN.md
01_PICK_UP_WORK.md
BUILD_STATE.md
CONTROL.md
HANDOFF_BRIEF.md
ITERATION_LOG.md
README.md
SETUP.md
WORKER_PROTOCOL.md
audits/2026-06-12-gmail-connector-discovery.md
audits/2026-06-12-hooks-mechanism-audit.md
audits/2026-06-12-killswitch-test.md
audits/2026-06-12-panic-button-test.md
audits/2026-06-12-pre-phase1-audit.md
audits/2026-06-12-sandbox-killswitch-discovery.md
docs/AGENT_OS_END_STATE_ARCHITECTURE.md
docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md
docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md
docs/OPENCLAW_BUILD_PLAN.md
docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md
docs/OPENCLAW_DEEP_DIVE_CONFIG.md
docs/OPENCLAW_ECOSYSTEM_AND_COVERAGE.md
docs/OPENCLAW_FIELD_NOTES.md
docs/OPENCLAW_RESEARCH_ADDENDUM.md
docs/PHASE_2_EMAIL_ASSISTANT.md
docs/PRIOR_BUILD_LEARNINGS.md
scripts/bundle-for-claude.sh
scripts/end-session.sh
scripts/secret-scan.sh
scripts/start-session.sh
templates/COMMIT_FORMAT.md
templates/DROP_FORMAT.md
```

## Tests status (last run, if recorded)
```
(no TEST_STATUS.txt — run tests and record)
```

## Open verification gates
## OPEN VERIFICATION GATES (must not be skipped — security-critical)

- [ ] **Aquaman source audit + native-SecretRef comparison** (Phase 6) — before ANY real SSN.
- [ ] **ClawGuard source read** (legacy numbered Phase 2 doctrine/audit inventory) — before it carries audit integrity. Custom hash-chain fallback ready.
- [ ] **Browser `fill` tool-side secret resolution test** (Phase 6) — does fill resolve a SecretRef without returning the value to the LLM?

---

---
_To request a decision: tell Claude which CONTROL.md NEXT or which doc section you need a call on._
