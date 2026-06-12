# OPENCLAW_BUILD_PLAN.md

**Project:** Agent OS on OpenClaw — clean rebuild
**Author of plan:** Claude (reviewer/architect thread)
**For:** Daniel Haitz
**Version:** v1.0 (2026-06-11)
**Status:** Pre-Phase-0. Nothing built yet on OpenClaw. Prior custom `agent-os` Python build torn down.

---

## 0. How to use this document

This is the master plan, same role `AGENT_OS_PLAN.md` played before. It is the source of truth. It is portable: any worker (Claude.ai, ChatGPT, Claude Code on the mini, local Qwen via Aider) reads this plus the three live state files and continues without needing session memory.

**The relay still works exactly as before.** Four canonical files, filenames constant, version inside:

- `OPENCLAW_BUILD_PLAN.md` — this file. Written rarely, deliberately.
- `BUILD_STATE.md` — current phase/step/blockers. Updated end of every work session.
- `HANDOFF_BRIEF.md` — last session summary. Overwritten each session.
- `ITERATION_LOG.md` — append-only. Decisions, learnings, scope changes.

Worker protocol unchanged: read the four files → work → update `BUILD_STATE.md` + `HANDOFF_BRIEF.md` → append to `ITERATION_LOG.md` if a real decision/learning happened → commit → push.

**What changed from the old plan:** the *foundation*. You are no longer hand-building the agent harness in Python. OpenClaw is the harness. Your work is now configuration, skills, doctrine, and one genuinely custom piece (the Command Center). This collapses what was Phases A–C into mostly configuration, and lets your real IP (Closure Doctrine, capability tiers, lifestream model, eval cases) sit on top where it belongs.

**Grounding note:** every capability claim in this plan is tagged. `[VERIFIED]` = confirmed against OpenClaw docs read on 2026-06-11. `[VERIFY]` = plausible from docs but must be confirmed hands-on or in a doc not yet read. Do not treat `[VERIFY]` items as settled. The entire reason the prior build went sideways was confident claims over unverified facts; this plan refuses to repeat that.

---

## 1. Decision: why OpenClaw, and what survives the teardown

### 1.1 The decision

Adopt OpenClaw as the foundation (Outcome A from the evaluation). Port the doctrine layer on top. This was always the intent — "greenfield" meant "a clean OpenClaw setup with better doctrine," not "rebuild OpenClaw's internals in Python." The Python rebuild was a misread that has been corrected and torn down.

### 1.2 What OpenClaw gives you natively (so you stop rebuilding it)

`[VERIFIED]` from docs read 2026-06-11:

- **Gateway + agent loop + channels.** One long-lived Gateway owns all messaging surfaces, supervised by launchd/systemd. This is your old Phase A + most of Phase C.
- **Telegram approval ingestion.** `approvals.exec` + `channels.telegram.execApprovals` deliver approval prompts to your phone with `/approve <id> allow-once|allow-always|deny`. Pending approvals expire after 30 min by default. This is your entire C.4/C.5 — the thing you spent days building and proving live — as a config block.
- **Per-agent capability tiers.** `exec.security` (`deny`/`allowlist`/`full`) × `exec.ask` (`off`/`on-miss`/`always`), per agent. This is your Free/Notify/Approve model.
- **Fail-closed by default.** Ask-fallback defaults to `deny` when no approver UI is reachable. Approved runs bind exact argv/cwd/env; if a bound file changes between approval and execution, the run is denied (TOCTOU protection your old build did not have).
- **Sandboxing.** Docker-backed isolation with fail-closed bind validation, blocked credential roots (`~/.ssh`, `~/.aws`, etc.), masked browser observer tokens.
- **Skills system.** AgentSkills-compatible `SKILL.md` folders — the exact convention from your plan. Per-agent allowlists, load-time gating, `disable-model-invocation` for reference-only docs.
- **Secrets indirection.** SecretRef contract (`env`/`file`/`exec` sources), exec-provider integration with 1Password/Vault/sops, eager fail-fast activation, `openclaw secrets audit` tooling.
- **Sophisticated secrets surface.** Resolved into an in-memory snapshot, atomic swap on reload, last-known-good retained on failure. Outbound paths read the snapshot, not re-resolved per send.
- **Automation.** Cron jobs, standing orders, TaskFlow/ClawFlow, background tasks.
- **Gmail PubSub** native automation (your morning-brief integration).
- **Web search** across 13 providers (Brave, Exa, Perplexity, Tavily, SearXNG, Ollama, etc.) — a capability you did NOT have and now get free.
- **Browser tool** (managed + sandboxed), browser-login, browser-control API.
- **Multi-provider models** including Codex via OAuth and Ollama for local — your Codex+Qwen routing.
- **Observability.** OpenTelemetry export, Prometheus metrics, trajectory bundles, `openclaw doctor`, `openclaw security audit`.
- **Tool-loop detection** (dedicated subsystem) — your six loop-prevention controls, at least partly native.

### 1.3 What is genuinely yours and ports on top

- **Closure Doctrine** — your behavioral IP. Becomes `SOUL.md` personality/operating guidance + a reference skill + eval cases.
- **Capability tier *philosophy*** — the specific tier assignments and the propose-then-commit discipline. Maps to per-agent `exec`/`approvals` config, but the *policy decisions* are yours.
- **Lifestream model** (Home, Money, Career, Family, Side Projects, System, Health) — becomes memory/workspace organization + skill structure. No OpenClaw equivalent; pure custom mapping.
- **Eval cases** (`closure_doctrine_001–003` and beyond) — port onto OpenClaw's personal-agent benchmark pack / QA-E2E harness.
- **Command Center** (your 7-surface v4 mockup) — the one real bespoke build. Either on OpenClaw's Canvas or as a separate web app on the Gateway WebSocket API.
- **The relay workflow + canonical files** — foundation-agnostic, keep as-is.
- **Operational discipline** (BUILD_STATE/HANDOFF/ITERATION_LOG, negative-path test strategy, pre-phase audits) — keep as-is.

### 1.4 What gets torn down / archived

Already torn down: the custom `agent-os` Python build (gateway, approval store, telegram poller, audit writer, notification subsystem, safeguards). Per your note, it is gone. That is fine — it was a faithful implementation of OpenClaw's internals, which OpenClaw already provides. **Its value was always the specification it taught you, not the code.**

Archive (do not delete): keep the old `agent-os` repo as read-only reference. The doctrine markdown, eval YAMLs, Command Center mockup, and the *tested behavioral specifications* are the seed corn for the skills and config you will write here. Tag the final commit `pre-openclaw-archive` and leave it.

### 1.5 The one genuine tension to hold onto

OpenClaw's *default* posture is "tools run on host for the main session; you are trusted once authenticated." Your end-state (an agent filling web forms with your SSN) demands stricter-than-default. OpenClaw *can* be configured to your standard — the approval engine, sandboxing, and SecretRefs are all there — but the defaults are more permissive than your doctrine. **You must actively harden, not just accept defaults.** This plan does that explicitly in Phase 1 and Phase 6.

---

## 2. Architecture mapping — old plan element → OpenClaw primitive

| Your plan element | OpenClaw primitive | Verdict | Phase |
|---|---|---|---|
| Single-agent loop, role-tagged phases | Agent runtime + agent loop | `[VERIFIED]` native | 0 |
| Capability tiers (Free/Notify/Approve) | `exec.security` × `exec.ask` per-agent | `[VERIFIED]` config | 1 |
| Propose-then-commit, fail-closed | Default ask-fallback=deny + approval file-binding | `[VERIFIED]` native default | 1 |
| Telegram approval ingestion (C.4/C.5) | `approvals.exec` + `channels.telegram.execApprovals` | `[VERIFIED]` config | 1 |
| Stop/halt kill switch | `/approve <id> deny` + `steer`/`goal` tools | `[VERIFY]` likely native | 1 |
| Loop prevention (6 controls) | Tool-loop detection subsystem | `[VERIFY]` depth unknown | 1 |
| Constitution in system prompt | `SOUL.md` + `AGENTS.md` | `[VERIFIED]` native | 2 |
| Closure Doctrine (behavioral IP) | `SOUL.md` + reference skill + eval cases | `[VERIFIED]` skill+custom | 2 |
| Doctrine-as-reference (not rules agent reads) | `disable-model-invocation: true` frontmatter | `[VERIFIED]` native | 2 |
| Skills system | AgentSkills `SKILL.md`, ClawHub registry | `[VERIFIED]` native | 2 |
| Append-only immutable audit | Trajectory bundles + OTel + hooks | `[VERIFY]` — possible real gap | 2 |
| Secrets never touch LLM | SecretRef indirection + sandbox env scoping | `[VERIFIED]` native, `[VERIFY]` for form-fill | 1, 6 |
| Local LLM routing (Qwen via Ollama) | Models providers (Ollama) + Codex OAuth | `[VERIFIED]` native | 0 |
| Cron / scheduled autonomy | Cron jobs + standing orders + TaskFlow | `[VERIFIED]` native | 3 |
| Gmail morning brief | Gmail PubSub automation | `[VERIFIED]` native | 3 |
| Web search | 13 search providers | `[VERIFIED]` native (NEW capability) | 3 |
| Lifestream model | Memory engine + workspace/skill structure | `[VERIFIED]` harness, custom mapping | 3 |
| Memory with provenance | Builtin memory / QMD / inferred commitments | `[VERIFIED]` native | 3 |
| Browser + form-fill (Phase G) | Managed/sandboxed browser + browser-control | `[VERIFIED]` native, `[VERIFY]` masking | 6 |
| Command Center (7 surfaces) | Canvas + Control UI, or custom WS app | `[VERIFY]` — biggest custom build | 4 |
| Eval suite | Personal-agent benchmark pack + QA-E2E | `[VERIFY]` harness shape | 5 |
| launchd autostart | `openclaw onboard --install-daemon` | `[VERIFIED]` native | 0 |
| Observability/tracing | OTel export + Prometheus + trajectory | `[VERIFIED]` native | 5 |
| External reviewer access | Public mirror (unchanged from old plan gap) | carry forward | 5 |

**The three real watch-items (where custom work or hard verification lives):**
1. **Append-only immutable audit** — verify whether trajectory bundles + hooks meet your tamper-evident standard, or whether you write a hook that emits your audit format. (Phase 2)
2. **Command Center** — your biggest bespoke build; Canvas vs. separate WS app is an open design decision. (Phase 4)
3. **Form-fill secrets masking** — your SSN end-state; the browser tool's screenshot/DOM masking must be verified adversarially before any high-tier secret goes near it. (Phase 6)

---

## 3. Hardware, identity, and the clean-start decision

### 3.1 Reused from the prior setup

- **Mac mini:** M4 base, 24GB, macOS 26.5, `Danny-Mac-Mini.local`, Tailscale `100.96.231.45`. Unchanged.
- **`agent` standard user** at `/Users/agent/`. Reused — but OpenClaw installs under `~/.openclaw/` and a workspace dir, not the old `agent-os` repo.
- **Ollama + Qwen models:** `qwen2.5-coder:14b`, `qwen3-coder:30b`, `OLLAMA_MAX_LOADED_MODELS=1`. **Still needed** — OpenClaw uses them as a local model provider for routing/bounded tasks. Do not remove them.
- **Tailscale, SSH, the agent login Keychain** (created during the graphical-login episode) — all reused.

### 3.2 Clean start — everything else is new

Per your explicit instruction: **new bot, new tokens, new everything. Do not reuse Jeeves.**

- **New Telegram bot** via BotFather — new name, new token, new chat binding. Jeeves is retired.
- **New secrets** — nothing carried from `.secrets/telegram.env`. Fresh SecretRefs.
- **New workspace** — OpenClaw's `~/.openclaw/` + workspace dir, not the old repo.
- **New git repo** (or a clean branch) for the canonical files + your custom skills/Command Center. The old `agent-os` repo is archived read-only.

### 3.3 Why clean-start is the right call here

You are changing foundations. Carrying the old bot/tokens/secrets into a new system risks importing stale config and muddying the "is this OpenClaw's behavior or my leftover wiring?" question. A clean bot with a clean token, bound through OpenClaw's own onboarding, means every behavior you observe is OpenClaw's — no confound. Costs ten minutes, saves hours of "why is it doing that."

---

## 4. The phased build

Phases are sized so each is a coherent, reviewable unit with a clear exit gate. The relay workflow runs throughout. After each phase: update `BUILD_STATE.md`, append learnings to `ITERATION_LOG.md`, and (for phases touching real external systems or secrets) run a pre-phase audit the way you did before C.4/C.5.

---

### PHASE 0 — Clean stand-up (foundation)

**Goal:** OpenClaw running as a supervised daemon on the mini, reachable from your phone via a new Telegram bot, with Codex (OAuth) as primary model and Ollama/Qwen as local fallback. One real message round-trips end to end.

**This replaces:** old Phase A (entire core loop) + Mac mini Day 0 + most of old Phase C plumbing.

**Steps:**

0.1 — **Install.** On the mini as `agent`:
```
npm install -g openclaw@latest
openclaw --version
```
(Node 20 is already in place from prior setup; verify with `node --version`.)

0.2 — **Onboard.** Run interactive onboarding, which walks model auth, channel setup, and daemon install:
```
openclaw onboard --install-daemon
```
`[VERIFIED]` `--install-daemon` installs the launchd user service so the Gateway stays running. This is your old "wire poller to launchd" open item, native.

0.3 — **New Telegram bot.** Via BotFather: `/newbot`, new name (NOT Jeeves), new username ending in `bot`. Capture the token. Send `/start` to it from your phone. Bind it through OpenClaw's Telegram channel config (onboarding prompts for this, or configure `channels.telegram` after).

0.4 — **Model providers.** Codex via OAuth (`[VERIFIED]` OpenClaw supports OpenAI/ChatGPT/Codex OAuth subscriptions). Ollama as a local provider pointing at your existing Qwen models. Set routing so Codex handles heavy reasoning and Qwen handles bounded/local tasks (mirrors your old plan's intent).

0.5 — **Secrets the right way from the start.** Do NOT paste the bot token as plaintext in `openclaw.json`. Use a SecretRef. Given your prior Keychain work, the cleanest fit is an `exec` provider that reads from macOS Keychain, OR the `file` provider against a `0600` JSON file. Run:
```
openclaw secrets audit --check
openclaw secrets configure
openclaw secrets audit --check
```
`[VERIFIED]` the audit flags plaintext-at-rest. Target: a clean audit before Phase 0 exit. **This is the lesson from the token-in-logs incident, applied up front** — secrets indirected, never plaintext, audited mechanically.

0.6 — **Smoke test.** From your phone, message the bot. Confirm a round-trip reply. Confirm `openclaw health` / `openclaw status` are green. Confirm the daemon restarts on its own (`launchctl` list shows it; reboot test optional).

**Exit gate:** Daemon supervised and auto-restarting. New bot round-trips a message. `openclaw secrets audit --check` clean. Codex + Ollama both reachable as providers. `openclaw doctor` clean.

**Pre-phase audit:** light. This is stand-up, not yet acting on the world.

---

### PHASE 1 — Trust model as configuration (your doctrine's spine)

**Goal:** Encode your capability-tier discipline and propose-then-commit safety as OpenClaw config. This is where your *philosophy* meets OpenClaw's *engine*. This is the most important phase for your specific standard, because OpenClaw's defaults are more permissive than your doctrine.

**This replaces:** old Phases C.1–C.5 (approval persistence, severity notifications, Telegram ingestion, the whole poller you built and proved live). All of it is config here.

**Steps:**

1.1 — **Set the baseline to strict.** `agents.defaults` with `exec.security: allowlist` (not `full`), `exec.ask: on-miss` or `always` for the main agent depending on how much friction you want. Your "Approve tier" = `ask: always`. `[VERIFIED]` per-agent, fail-closed default.

1.2 — **Tier mapping (your policy decisions — this is your IP, not OpenClaw's):**
- **Free tier** (read, search, low-risk): allowlisted bins, `ask: off`.
- **Notify tier** (writes, side-effecting but reversible): allowlisted, but routed so you get a notification. `[VERIFY]` exact mechanism — likely a hook or the system-events stream.
- **Approve tier** (irreversible, sensitive): `ask: always` → Telegram `/approve`.
- **Never tier** (passwords, OAuth, MFA): tool-policy `deny`, never allowlisted, manual only. `[VERIFIED]` tool-policy deny hard-blocks regardless of sandbox.

1.3 — **Telegram approvals.** Configure `approvals.exec` (`enabled: true`, `mode`, `agentFilter`, `targets` with your new chat) + `channels.telegram.execApprovals` for native delivery. Confirm `/approve <id> allow-once|deny` works from your phone. `[VERIFIED]` this is your entire C.5, as config. The 8-char id correlation, the allowlist, the ack — all native.

1.4 — **Sandboxing.** Enable Docker-backed sandbox. Start `mode: non-main` (main chat on host for low friction, everything else sandboxed) — but **reconsider toward `mode: all`** before Phase 6, given your SSN end-state. `workspaceAccess: none` or `ro` by default. `[VERIFIED]` fail-closed bind validation, blocked credential roots.

1.5 — **Kill switch.** Verify stop/halt: `[VERIFY]` whether `/approve deny`, the `steer` tool, and `goal` cancellation cover your "stop a running task" requirement. Your old C.5/C.6 split (receive+record+ack vs. actual interruption) may collapse if OpenClaw's steer/cancel actually interrupts. Confirm hands-on.

1.6 — **Loop prevention.** Read the tool-loop-detection doc (`[VERIFY]` not yet read). Map your six controls (iteration cap, hash detector, no-progress oracle, cost circuit breaker, persistent-state-on-trip, stuck detection) against what's native; write a skill or hook for any genuine gap.

**Exit gate:** Approve-tier action prompts your phone and only proceeds on `/approve`. Deny leaves it un-run. A "never" tier tool is hard-blocked. Sandbox enabled and `openclaw sandbox explain` shows expected policy. Kill-switch behavior verified and documented.

**Pre-phase audit:** REQUIRED. This is the safety spine. Audit the way you audited before C.4 — adversarial, "can any inbound cause an unintended execution," fail-closed everywhere.

---

### PHASE 2 — Doctrine as skills + the audit question

**Goal:** Port your behavioral IP (Closure Doctrine, tier philosophy, operating rules) into OpenClaw's skill/SOUL system, and resolve the one real possible gap: append-only immutable audit.

**This replaces:** old Phase B (constitution, closure doctrine, capability hooks, trust dial, skills).

**Steps:**

2.1 — **SOUL.md.** Author OpenClaw's personality/operating guide with your constitution-level doctrine — the short, always-loaded behavioral core. `[VERIFIED]` native concept.

2.2 — **Doctrine skills.** For each doctrine area (closure, tiers, trust), author a `SKILL.md`. Use `disable-model-invocation: true` for pure reference docs (the agent doesn't read them as rules every turn) and normal skills for triggered procedures. `[VERIFIED]` this is exactly your old "constitution loads / doctrine is human-reference / skills load on trigger" distinction — and it's a frontmatter flag, not a code system.

2.3 — **Gate skills properly.** Use `metadata.openclaw.requires` (bins/env/config/os) so skills only load when their dependencies exist. Mind the token cost: `[VERIFIED]` ~24 tokens + field lengths per eligible skill in the prompt. Keep descriptions tight.

2.4 — **The audit question — RESOLVE IT.** Read trajectory-bundles, hooks, and logging docs (`[VERIFY]` not yet read). Determine whether OpenClaw's trajectory + OTel + system-events give you tamper-evident, append-only audit to your standard. **Two outcomes:**
   - If yes: configure it, write an eval that asserts audit completeness, done.
   - If no: this is where your custom code earns its keep. Write a hook (OpenClaw has a hooks system) that emits your append-only JSONL audit format on every tool execution. This may be the single most valuable piece of custom code you carry from the old build's *design* (not its code).

2.5 — **Skill Workshop (optional, powerful).** `[VERIFIED]` the Skill Workshop plugin can generate workspace skills from observed agent procedures, with pending-approval safety. Start with pending-approval mode only. This is a capability your old build never had: the system improving its own skills over time — directly serving your "expands its capabilities over time" goal.

**Exit gate:** Doctrine loads correctly (constitution in prompt, reference docs not invoked as rules, procedures trigger on demand). Audit question resolved one way or the other, with a test asserting audit coverage. Token cost of loaded skills measured and acceptable.

**Pre-phase audit:** medium. Focus on the audit-completeness claim and doctrine-enforcement (is a tier rule actually mechanically enforced, or just written in a skill the model may ignore?).

---

### PHASE 3 — Integrations + memory + lifestreams (daily utility)

**Goal:** The system becomes useful day-to-day. Gmail morning brief, cron-driven autonomy, web search, and your lifestream model as memory/workspace structure.

**This replaces:** old Phase D integrations (minus the eval infra, which moves to Phase 5).

**Steps:**

3.1 — **Gmail morning brief.** Configure Gmail PubSub automation. `[VERIFIED]` native. This is your front-loaded daily-utility integration, exactly as the old plan front-loaded it.

3.2 — **Cron + standing orders.** Your autonomous routines (morning brief, end-of-day summary, self-assignment patterns) as cron jobs and standing orders. `[VERIFIED]` native. TaskFlow/ClawFlow for multi-step autonomous sequences.

3.3 — **Web search.** Enable one or more of the 13 providers. `[VERIFIED]` — a NEW capability. Pick based on cost/quality (Brave, Tavily, Perplexity, or local Ollama-search for zero-cost). This alone is a meaningful upgrade over your old build.

3.4 — **Memory + lifestreams.** Configure the memory engine (builtin / QMD / inferred-commitments). Map your seven lifestreams (Home, Money, Career, Family, Side Projects, System, Health) onto memory organization + workspace/skill structure. `[VERIFIED]` memory native; `[VERIFY]` best mapping of lifestreams — this is custom design work, the lifestream model has no direct OpenClaw equivalent.

3.5 — **Inferred commitments / dreaming.** `[VERIFIED]` OpenClaw has inferred-commitments and a "dreaming" compaction concept. Evaluate whether these serve your closure-doctrine "nothing falls through" goal. Possibly a strong fit.

**Exit gate:** Morning brief arrives on schedule. At least one autonomous cron routine runs unattended overnight and reports cleanly. Web search works. Lifestream structure exists and the agent files things into it correctly.

**Pre-phase audit:** medium. Focus on the overnight autonomous run — containment, branch discipline, no runaway loops, clean morning review.

---

### PHASE 4 — Command Center (the real custom build)

**Goal:** Your 7-surface v4 mockup, on top of OpenClaw. This is the largest genuinely-bespoke effort and the place your design IP becomes a product surface.

**This replaces:** old Phase E (full custom Express+React).

**Open design decision (resolve at phase start):**
- **Option A — Canvas.** `[VERIFIED]` OpenClaw serves an agent-editable Canvas at `/__openclaw__/canvas/`. If your surfaces can be expressed as agent-rendered HTML/CSS/JS, this is dramatically less work than a separate app — the agent itself maintains the Command Center.
- **Option B — Separate WS app.** Build your Express+React+Tailwind+shadcn app as originally mocked, talking to the Gateway's typed WebSocket API (`[VERIFIED]` documented protocol: connect handshake, req/res, events). Full control, more work.
- **Option C — Control UI + Canvas hybrid.** `[VERIFIED]` OpenClaw ships a Control UI (Nodes, Exec approvals editing, etc.). Use it for ops surfaces (Approval Queue, Audit) and Canvas/custom for your bespoke surfaces (Intake, Operations Board, Lifestream views).

**Recommendation:** Start with **C**. The Control UI already gives you Approval Queue and exec-approval management for free — two of your seven surfaces, native. Build only the genuinely-custom surfaces (Intake, Operations Board, Lifestream/Recurring views, Trust Dial) on Canvas or as a small WS app. This could cut your Command Center scope by half versus the old "build all seven from scratch" plan.

**Steps:**
4.1 — Decide A/B/C against the actual mockup surfaces.
4.2 — Map each of the 7 surfaces to native (Control UI), Canvas, or custom.
4.3 — Build only the custom ones.
4.4 — Wire to live Gateway state (WS events: `agent`, `chat`, `presence`, `health`).

**Exit gate:** All seven surfaces reachable and showing live state. Approval Queue actions actually approve/deny via the real approval engine. Intake files into lifestreams.

**Pre-phase audit:** light-to-medium (UI, lower blast radius — but verify the Command Center can't bypass the approval engine).

---

### PHASE 5 — Evals, observability, reviewer access (hardening)

**Goal:** Your behavioral guarantees become mechanically tested; the system is observable; external review is wired.

**This replaces:** old Phase D eval infra + the A.8 reviewer-access gap.

**Steps:**
5.1 — **Eval cases.** Port `closure_doctrine_001–003` and expand onto OpenClaw's personal-agent benchmark pack / QA-E2E automation (`[VERIFY]` exact harness shape — read the QA docs). Negative-path adversarial, your house style.
5.2 — **Observability.** Enable OTel export + Prometheus. `[VERIFIED]` native. Optionally self-host a collector (Langfuse/Grafana) as your old plan intended.
5.3 — **Reviewer access.** The old gap: how does Claude.ai/ChatGPT read the setup for review? Wire a sanitized public mirror or a bundle script (`[VERIFIED]` your old `create_review_bundle.sh` pattern still applies — keep secret-scanning on generate).
5.4 — **Security audit.** Run `openclaw security audit` and address findings. `[VERIFIED]` native. Read the MITRE-ATLAS threat-model doc and the formal-verification doc — OpenClaw publishes both; use them.

**Exit gate:** Eval suite runs and gates changes. OTel traces visible. `openclaw security audit` clean or findings triaged. Reviewer can read the setup without manual file-pulling.

**Pre-phase audit:** medium.

---

### PHASE 6 — Sensitive form-fill (the SSN end-state — gated, last, most careful)

**Goal:** The agent fills web forms with high-tier secrets (SSN, DOB, etc.) without exposing them to the LLM or logs. This is your founding end-state and the highest-risk phase.

**This replaces:** old Phases G/H (browser + sensitive secrets).

**DO NOT START until Phases 1, 2, and 5 are solid.** This phase stacks on the trust model, the audit, and the eval suite. It is gated.

**Steps:**
6.1 — **Read the browser docs adversarially.** `[VERIFY]` browser tool, browser-control, browser-login — not yet read in full. The critical question: does the browser tool mask sensitive DOM/screenshots so the LLM never sees typed secrets? Your old Layer-3 design (Playwright `mask`, redacted `get_page_text`) — does OpenClaw provide equivalent? **This is the make-or-break verification.** If OpenClaw's browser tool screenshots the page and feeds it to the LLM unmasked, that's the httpx-token-leak failure mode at SSN scale. Verify before any secret goes near it.
6.2 — **SecretRef for high-tier secrets.** Store SSN-class secrets as SecretRefs (`exec` provider → Keychain/1Password/Vault). `[VERIFIED]` the indirection exists. Confirm the form-fill path resolves the ref at execution inside the tool, never returning the value to the LLM.
6.3 — **Sandbox the browser.** `mode: all` for browser sessions, dedicated network, masked observer tokens. `[VERIFIED]` sandboxed browser with conservative Chromium flags and password-protected noVNC.
6.4 — **Tiered approval on submit.** High-tier secret use → Approve tier → Telegram confirm before form submission. Every access audited. `[VERIFIED]` approval engine + (Phase 2) audit.
6.5 — **Adversarial test.** Before trusting it with a real SSN: a full red-team pass. Can a malicious page prompt-inject the agent into exfiltrating the secret? Does the secret appear in ANY log, trajectory, screenshot, or notification? This is the audit that actually matters.

**Exit gate:** A test form filled with a *fake* SSN, end-to-end, with proof the fake value never appeared in any log/trajectory/screenshot/LLM-context, and submission gated behind Telegram approval. Only after that proof do real secrets get configured.

**Pre-phase audit:** MAXIMUM. This is the highest-stakes phase. Treat the secret-leak surface the way the prior session's token-in-logs finding should have taught you: runtime output is a secret surface the source scanner doesn't cover.

---

## 5. The relay workflow (unchanged, foundation-agnostic)

Same as before. Portable across Claude.ai, ChatGPT, Claude Code on the mini, and Aider+Qwen.

**Session-start protocol (every worker):**
1. Read `OPENCLAW_BUILD_PLAN.md` (this file), `BUILD_STATE.md`, `HANDOFF_BRIEF.md`, recent `ITERATION_LOG.md`.
2. For Claude Code on the mini: `security unlock-keychain ~/Library/Keychains/login.keychain-db` before `claude` (lesson from prior session — avoids repeated re-login).
3. Work.
4. Update `BUILD_STATE.md` (current phase/step/blockers) + overwrite `HANDOFF_BRIEF.md` (what I did, what's next, open questions).
5. Append to `ITERATION_LOG.md` if a real decision/learning happened.
6. Commit, push.

**Worker division (unchanged intent):**
- **Claude.ai (this thread's role):** architecture, plan, hard design, independent review. Rare, high-value. NOT ops debugging (it burns tokens on cheap problems — the prior session's clearest lesson).
- **ChatGPT (controller/sequencer):** drafts bounded prompts for implementation/review workers, runs ops/config/setup work.
- **Claude Code on the mini:** actual config edits, skill authoring, Command Center build.
- **Aider + Qwen:** overnight bounded tasks.

**Portability note:** because OpenClaw config is JSON5/markdown and skills are `SKILL.md`, the artifacts are pasteable and diff-able exactly like the old build. The relay is, if anything, *cleaner* on OpenClaw because there's less bespoke code to hold in context.

---

## 6. Pre-phase audit pattern (carried forward)

Before any phase that touches real external systems or secrets (Phases 1, 3, 6 especially), run an independent audit the way you ran the pre-C.4 and pre-C.5 audits: a worker with no build context reads the config + docs and produces a single audit file under `audits/` with enumerated entry conditions. The central question is always the same shape: *can any inbound message, malicious page, replayed event, or misconfiguration cause an unintended action or a secret leak?* Findings get folded into `BUILD_STATE.md` as entry conditions before the phase merges.

This pattern was working well in the old build — it caught real issues. Keep it.

---

## 7. Open questions / parking lot

These are `[VERIFY]` items that need a doc read or hands-on confirmation before the relevant phase. Logged here so they're not lost.

1. **Append-only immutable audit** (Phase 2) — do trajectory bundles + hooks + OTel meet your tamper-evident standard, or do you write a custom audit hook? READ: trajectory, hooks, logging docs.
2. **Kill-switch semantics** (Phase 1) — does `/approve deny` + `steer` + `goal`-cancel actually interrupt a running task, collapsing your old C.5/C.6 split? CONFIRM hands-on.
3. **Loop prevention depth** (Phase 1) — does tool-loop detection cover all six of your controls? READ: loop-detection doc.
4. **Lifestream mapping** (Phase 3) — best way to express seven life-area containers in OpenClaw's memory/workspace model. DESIGN work.
5. **Command Center A/B/C** (Phase 4) — Canvas vs. custom WS app vs. Control-UI hybrid, mapped against the actual seven surfaces. DECIDE at phase start.
6. **Browser secret masking** (Phase 6) — THE critical one. Does the browser tool mask DOM/screenshots so the LLM never sees typed secrets? READ: browser, browser-control, browser-login docs. VERIFY adversarially.
7. **Notify-tier mechanism** (Phase 1) — exact way to get a notification (not approval) on reversible side-effecting actions. Likely a hook or system-events subscription. VERIFY.
8. **Eval harness shape** (Phase 5) — how the personal-agent benchmark pack / QA-E2E automation actually structures cases. READ: QA docs.

---

## 8. What "done" looks like

A supervised OpenClaw daemon on the mini, controlled from your phone via a new Telegram bot, that:
- runs a single disciplined agent loop with Codex + local Qwen routing;
- enforces your capability tiers and propose-then-commit discipline through the native approval engine, fail-closed;
- carries your Closure Doctrine as SOUL + skills, mechanically enforced where it matters;
- delivers a Gmail morning brief and runs autonomous cron routines overnight, contained;
- searches the web (new capability);
- organizes everything into your seven lifestreams;
- surfaces a Command Center (Control UI + custom surfaces) for approvals, audit, intake, and operations;
- is observable (OTel/Prometheus) and mechanically eval-gated;
- and — last, gated, adversarially proven — fills web forms with high-tier secrets that never touch the LLM, the logs, or any screenshot.

And — crucially, the thing the custom build could never do well — it **expands its own capabilities over time** via the skill system, ClawHub, and Skill Workshop, maintained by a large community rather than by you alone.

---

## 9. Decision log (seed)

| Date | Decision | Rationale |
|---|---|---|
| 2026-06-11 | Adopt OpenClaw as foundation (Outcome A); port doctrine on top | OpenClaw provides natively what the custom build was reimplementing; doctrine is the real IP and ports cleanly |
| 2026-06-11 | Tear down / archive custom `agent-os` Python build | Faithful reimplementation of OpenClaw internals; value was the specification it taught, not the code |
| 2026-06-11 | Clean start — new bot, new tokens, new everything; retire Jeeves | Avoid confounding OpenClaw behavior with leftover wiring; per owner instruction |
| 2026-06-11 | Keep Ollama/Qwen models | Still needed as OpenClaw local model provider for routing/bounded tasks |
| 2026-06-11 | Secrets via SecretRef from Phase 0; audit clean before exit | Apply the token-in-logs lesson up front — never plaintext, mechanically audited |
| 2026-06-11 | Command Center: start Control-UI + custom hybrid (Option C) | Control UI gives Approval Queue + exec management free; build only genuinely-custom surfaces — possibly halves scope |
| 2026-06-11 | Form-fill (SSN end-state) gated to Phase 6, after trust model + audit + evals | Highest-risk; depends on browser-masking verification that is not yet done |

---

*End of plan v1.0. This is the source of truth. Update version + changelog inside the file; never rename it. `[VERIFY]` items are not settled — confirm before relying on them.*
