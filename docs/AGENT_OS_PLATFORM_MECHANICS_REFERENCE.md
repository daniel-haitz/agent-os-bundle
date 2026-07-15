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
