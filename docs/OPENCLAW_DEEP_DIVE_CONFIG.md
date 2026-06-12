# OPENCLAW_DEEP_DIVE_CONFIG.md

**Companion to:** the build plan + research addendum + field notes + ecosystem/coverage file
**Author:** Claude (reviewer/architect thread)
**Version:** v1.0 (2026-06-11)
**Purpose:** The deep, syntax-level pass you asked for. Exact config (JSON5) for every subsystem your build touches, captured from full reads of the heaviest config docs (`config-agents`, `configuration`, `model-providers`, `models`, `cron-jobs`, `config-channels` excerpts, Control UI / Dashboard / Canvas). Plus the operator gotchas that only show up in GitHub issues and practitioner writeups. This converts the plan from "architecturally complete" to "syntax-complete, copy-pasteable."

**Confidence:** Tier-A. Every config block here is from official docs read in full or corroborated across the official doc + 2+ practitioner sources. Where a behavior comes from a GitHub issue (real bug/gotcha), it's marked `[ISSUE]`.

---

## §1 — Model routing: your Codex + Qwen setup, exact syntax

This was the biggest Tier-C gap. Here's the complete, correct way to do your dual-provider routing.

### The core rule
Model refs are `provider/model`. `agents.defaults.models` is BOTH the catalog AND the allowlist for `/model`. **Runtime selection is separate from model selection** — `openai/gpt-5.5` runs through the **Codex app-server runtime by default** when using the official OpenAI provider (this is how you get Codex-via-OAuth without API billing).

### Your exact config (Codex primary + Qwen local, per-agent runtime)
```json5
{
  models: {
    providers: {
      openai: {
        agentRuntime: { id: "codex" },   // OpenAI models run via Codex harness (OAuth, not API billing)
      },
      ollama: {
        baseUrl: "http://localhost:11434/v1",
      },
    },
  },
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.5": { alias: "codex" },
        "ollama/qwen3-coder:30b": { alias: "qwen", agentRuntime: { id: "openclaw" } },
        "ollama/qwen2.5-coder:14b": { alias: "qwen-fast", agentRuntime: { id: "openclaw" } },
      },
      model: {
        primary: "openai/gpt-5.5",            // Codex for heavy reasoning + tool-enabled work
        fallbacks: ["ollama/qwen3-coder:30b"],
      },
      maxConcurrent: 3,                        // M4 24GB — keep modest
      contextTokens: 200000,
    },
  },
}
```

**Key facts captured from the docs:**
- `agentRuntime.id`: `"codex"` (bundled Codex plugin), `"claude-cli"` (Anthropic CLI backend), `"openclaw"` (the embedded runtime — use for Ollama/Qwen), or `"auto"`.
- **Runtime precedence:** exact `provider/model` policy > `provider/*` wildcard > `models.providers.<provider>.agentRuntime`. So you can pin Codex provider-wide and override Qwen per-model.
- **In Codex runtime mode, `openai/gpt-*` does NOT imply API billing** — auth comes from your Codex account / OpenAI OAuth profile. This is exactly your "no new spend" constraint, native.
- Built-in aliases (`opus`, `sonnet`, `gpt`, `gemini`, etc.) only apply when the model is in `agents.defaults.models`. Your custom aliases always win.
- `--strict-json --merge` on `config set` adds allowlist entries without removing existing ones (safe edits).
- **`maxConcurrent`** (default 4) caps parallel agent runs — a soft spend/resource control. Drop it for the M4.

### The security-grounded routing rule (from field-notes §1.6, now with exact mechanism)
Your SSN/browser/tool-enabled agent must use Codex (strong). Qwen is for bounded/offline. Pin this per-agent:
```json5
{
  agents: {
    list: [
      { id: "main", model: "openai/gpt-5.5" },          // strong, tool-enabled
      { id: "overnight", model: "ollama/qwen3-coder:30b", model: { primary: "ollama/qwen3-coder:30b", fallbacks: [] } }, // bounded, offline, strict
    ],
  },
}
```
Note: per-agent `model` as a STRING = strict (no fallback). Use `{ primary, fallbacks: [] }` to make strict explicit, or add fallbacks to opt in.

---

## §2 — Heartbeat & cron: the cost levers, quantified, with exact syntax

This is where operators burn money. Now I have the exact knobs.

### Heartbeat — the `isolatedSession` flag is the big cost lever
```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",                 // "0m" disables. Default 30m (API) / 1h (OAuth)
        model: "ollama/qwen2.5-coder:14b",  // run heartbeat on CHEAP local model
        isolatedSession: true,        // ← drops cost from ~100K to ~2-5K tokens per heartbeat
        lightContext: true,           // keeps only HEARTBEAT.md from bootstrap files
        skipWhenBusy: true,           // defer when agent's subagent/nested work is active
        timeoutSeconds: 45,
      },
    },
  },
}
```
**The quantified win:** `isolatedSession: true` + `lightContext: true` is the difference between a heartbeat costing ~100K tokens (full context every 30 min, 24/7) and ~2-5K. On OAuth/subscription this is rate-limit headroom; on API it's the single biggest bill driver. **Set both.** Also: heartbeats run FULL agent turns, and **if ANY agent defines `heartbeat`, only those agents run heartbeats** — so define it deliberately.

### Cron — exact job structure + the delivery rules
```json5
// Stored at ~/.openclaw/cron-jobs.jsonl (note: jsonl, one job per line)
{
  name: "Morning brief",
  schedule: { kind: "cron", expr: "0 7 * * *", tz: "America/Chicago" },
  sessionTarget: "isolated",          // isolated = fresh context (USE THIS for most jobs)
  payload: { kind: "agentTurn", message: "Summarize inbox + calendar for today." },
  delivery: { mode: "announce", channel: "telegram", to: "<your-chat-id>" },
  enabled: true,
}
```
CLI form (often easier):
```
openclaw cron add --name "Morning brief" --cron "0 7 * * *" --tz "America/Chicago" \
  --session isolated --message "Summarize inbox + calendar." --announce --channel telegram --to "<chat-id>"
```

**Cron rules captured:**
- `sessionTarget: "isolated"` = fresh session, no history. **Use for almost everything** (briefings, monitoring, backups). Cheap, no context pollution.
- `sessionTarget: "main"` = full conversation history. **Rare** — only when the job genuinely needs your DM context. The practitioner consensus: "if you keep reaching for main, move the context into workspace files instead."
- `delivery.mode: "announce"` is **only valid for isolated jobs**. `webhook` works for both.
- Telegram topics: encode as `to: "-1001234567890:topic:123"`.
- `--stagger 30s` for sub-minute staggering; `--at` for one-shots (auto-delete after success).
- Isolated cron resolves model: Gmail-hook override → per-job `--model` → stored cron-session override → agent/default.

### THREE operator gotchas that will bite you `[ISSUE]`
1. **Isolated cron sessions only see GLOBAL skills (`~/.openclaw/skills/`), NOT main-agent workspace skills** (GitHub #32927). **This is critical for your doctrine:** if your Closure Doctrine skills live in the main agent's workspace, your overnight isolated cron jobs WON'T see them. **Put any skill that cron/overnight work needs into `~/.openclaw/skills/` (global), not the workspace.** Plan your skill placement around this.
2. **`sessionTarget: "isolated"` + `payload.kind: "agentTurn"` had a bug where jobs never fired** (#11994, v2026.2.3) — `nextRunAtMs` kept advancing, `{"ran": false, "reason": "not-due"}`. Verify your version is past the fix; test every isolated cron job actually fires before trusting it.
3. **Cron `sessionTarget` only accepts `"main"` or `"isolated"`** — no arbitrary session keys yet (#13892 is an open feature request). For agent-to-agent async wakeups, you'd use `sessions_send` (synchronous) instead.

### Cron job-chaining (for your multi-stage pipelines) — RFC, partial
`schedule.kind: "after"` (run Job B when Job A completes, success/failure/any) is an RFC (#28584) — check if it's landed in your version. If not, chain via the orchestrator-skill pattern (Steinberger's approach) instead of native chaining.

---

## §3 — Compaction & memory: exact syntax for your lifestream model

### Compaction with Qwen-pinned flush (the cost-correct setup)
```json5
{
  agents: {
    defaults: {
      compaction: {
        mode: "safeguard",            // chunked summarization for long histories
        reserveTokensFloor: 24000,
        keepRecentTokens: 50000,
        memoryFlush: {
          enabled: true,
          model: "ollama/qwen3:8b",   // flush runs on LOCAL model — cheap
          softThresholdTokens: 6000,
          prompt: "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store.",
        },
      },
    },
  },
}
```
**Captured facts:** memory flush is a silent agentic turn before auto-compaction; **skipped if workspace is read-only** (so your memory-keeping agent needs write access — sandbox the TOOL sessions, not the memory-keeper). `notifyUser: true` sends "Compacting..." notices (off by default). `postCompactionSections: ["Session Startup", "Red Lines"]` re-injects named AGENTS.md sections after compaction — useful for keeping your doctrine's hard rules alive across compaction.

### Two-layer memory (your lifestreams), exact paths
- **`MEMORY.md`** — compact curated layer, injected at session start. Durable facts, standing decisions. NOT a transcript. → Your **lifestream curated state**.
- **`memory/YYYY-MM-DD.md`** — working layer, indexed for `memory_search`/`memory_get`, NOT injected every turn. → Your **daily lifestream activity**.
- The agent distills daily → curated over time (heartbeat/generated-instructions do this).
- **Char limits (now exact):** `bootstrapMaxChars: 20000` per file, `bootstrapTotalMaxChars: 60000` total (note: the security repo said 180K; the config default is **60K total** — tunable up to 300K per-agent, but 60K is the shipped default). `skills.limits.maxSkillsPromptChars: 18000` for the skills list.
- **Context budget ownership map** (don't confuse these): `bootstrapMaxChars` (workspace files), `startupContext.*` (reset prelude incl. recent daily memory), `skills.limits.*` (skills list), `contextLimits.*` (runtime excerpts), `memory.qmd.limits.*` (memory-search snippets). Five separate budgets — tune the right one.

### Bootstrap files — the full set + your doctrine mapping
Nine files, each a distinct role (file role discipline):
- `AGENTS.md` → operating rules / what needs approval → **your Closure Doctrine + capability tiers**
- `SOUL.md` → tone/persona → **your agent's voice**
- `USER.md` → facts about you
- `TOOLS.md` → env/tool notes
- `IDENTITY.md` → name/theme/emoji/avatar
- `HEARTBEAT.md` → cron checklist (loads every scheduled run — keep SHORT)
- `BOOTSTRAP.md`, `MEMORY.md`, `memory.md`
- `contextInjection: "continuation-skip"` skips re-injecting bootstrap on safe continuation turns (saves tokens); `"always"` (default) re-injects every turn.
- **Subagent mitigation:** subagents only get `AGENTS.md` + `TOOLS.md` (2 of 9) — limits the bootstrap-injection attack surface (field-notes §1.3).

---

## §4 — Sandboxing: the complete hardening surface (Phase 6 critical)

The config-agents page gave the FULL Docker sandbox config — far more than the sandboxing page alone. For your SSN agent:
```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "all",                  // sandbox everything for the secret agent
        backend: "docker",
        scope: "agent",
        workspaceAccess: "none",
        docker: {
          readOnlyRoot: true,
          tmpfs: ["/tmp", "/var/tmp", "/run"],
          network: "none",            // no egress by default; "bridge" only if needed
          user: "1000:1000",
          capDrop: ["ALL"],           // drop all Linux capabilities
          pidsLimit: 256,
          memory: "1g",
          memorySwap: "2g",
          cpus: 1,
          seccompProfile: "/path/to/seccomp.json",
          apparmorProfile: "openclaw-sandbox",
        },
        browser: {
          enabled: true,              // sandboxed Chromium for form-fill
          network: "openclaw-sandbox-browser",
          cdpSourceRange: "172.21.0.1/32",
          allowHostControl: false,    // CANNOT touch your real browser
        },
      },
    },
  },
}
```
**Hardening facts captured:** `capDrop: ["ALL"]`, `readOnlyRoot`, `pidsLimit`, `memory`/`cpus` limits, `seccompProfile`, `apparmorProfile` — full container hardening. `network: "host"` is blocked; `container:<id>` blocked unless break-glass. noVNC observer uses a short-lived token URL (not password-in-URL). `allowHostControl: false` is the wall between the sandboxed browser and your real logged-in browser. **This is your Phase-6 form-fill containment, exact.** Note: browser sandboxing + `docker.binds` are Docker-only (not SSH/OpenShell).

---

## §5 — Multi-agent: the reader-agent split, exact config

Your security-critical reader-agent isolation (research-addendum §4, field-notes §1.1) as real config:
```json5
{
  agents: {
    list: [
      {
        id: "reader",                 // browses web / reads email — NO secrets
        model: "openai/gpt-5.5",      // strong (untrusted content needs it)
        sandbox: { mode: "all", scope: "agent", workspaceAccess: "none" },
        tools: { allow: ["web_search", "web_fetch", "browser", "read"], deny: ["gateway", "cron", "exec", "process"] },
      },
      {
        id: "secret-holder",          // holds SSN-class secrets — NEVER touches raw web content
        model: "openai/gpt-5.5",
        sandbox: { mode: "all", scope: "agent", workspaceAccess: "none" },
        tools: { allow: ["browser"], deny: ["web_search", "web_fetch", "gateway", "cron"] },
      },
    ],
  },
  bindings: [
    { agentId: "secret-holder", match: { channel: "telegram", peer: { kind: "direct", id: "<you>" } } },
  ],
}
```
**Captured:** `subagents.allowAgents` controls which agents can be spawned (`["*"]` = any; default = same agent only). **Sandbox inheritance guard:** a sandboxed session's `sessions_spawn` REJECTS targets that would run unsandboxed — so a sandboxed reader can't spawn an unsandboxed helper. Use `sessions_spawn` with `sandbox: "require"` to fail-fast if the child isn't sandboxed. This is real, native reader-agent isolation enforcement.

---

## §6 — Command Center: MORE is native than estimated

Critical update to Phase 4. The Control UI (Lit + Vite SPA, served at `:18789/`) ships these pages **natively**:
- **Chat** (ChatGPT-style, real-time streaming)
- **Sessions** (management/monitoring) → maps to part of your Operations Board
- **Config** (schema-aware live editor, path-based field docs, **patch mode**, **diff preview**, **auto-restart on change**)
- **Nodes** (device/exec-approvals management) → **your Approval Queue + Trust Dial**
- **Logs** (live tail, filter, export) → **your Audit surface**
- **Skills** (management)
- **Cron** (full scheduler view — create/edit jobs in UI)
- **Dashboard** (a **widget canvas you arrange freely** — resize/reposition widgets)

Plus **Canvas** (`/__openclaw__/canvas/`) — agent-driven HTML/JS for charts, dashboards, interactive UI, rendered across web/macOS/iOS/Android.

**Revised Phase 4 verdict:** Your 7-surface mockup is now **mostly native**. Approval Queue + Trust Dial ≈ Nodes/exec-approvals view; Audit ≈ Logs view; Operations Board ≈ Sessions + Dashboard widgets + Cron view. Your genuinely-custom surfaces shrink to: **Intake** (lifestream filing) and **Lifestream/Recurring views** — buildable on Canvas or as small additions. **Phase 4 likely drops from "build 7 surfaces" to "configure the native UI + build 2 custom Canvas surfaces."** This is a major scope reduction versus your original greenfield plan.

**Security (captured):** Control UI is an **admin surface** — chat, config, exec approvals. **Never expose publicly.** It needs a secure context (HTTPS or localhost). **Device pairing:** connecting from a new browser/device requires one-time approval EVEN on the same Tailnet (`openclaw devices list` / `approve <id>`) — you'll hit "disconnected (1008): pairing required" on first connect; that's expected. It's a PWA (installable, Web Push for notifications even when tab closed).

---

## §7 — Session management: exact reset/isolation config

```json5
{
  session: {
    dmScope: "per-channel-peer",      // defense-in-depth even single-user
    reset: { mode: "daily", atHour: 4 },   // fresh session daily at 4am
    maintenance: {
      mode: "enforce",
      pruneAfter: "30d",
      maxEntries: 500,
      maxDiskBytes: "500mb",
    },
  },
}
```
**Captured:** `dmScope` options: `main` (all DMs one session) / `per-peer` / `per-channel-peer` (recommended) / `per-account-channel-peer`. `reset.mode`: `daily` (at `atHour`) or `idle` (after `idleMinutes`); whichever expires first wins. `resetByType` lets you set different policies for `direct`/`group`/`thread`. Session store: `~/.openclaw/agents/{agentId}/sessions/sessions.json`. **Background writes (heartbeat, cron, exec notifications) update `updatedAt` but do NOT keep daily/idle sessions fresh** — so a heartbeat won't accidentally prevent your daily reset.

---

## §8 — Messages / delivery: noise control (the "Telegram floods" fix)

```json5
{
  messages: {
    responsePrefix: "auto",           // or "🦞" or "" to disable
    queue: { mode: "followup", debounceMs: 500, cap: 20, drop: "summarize" },
    inbound: { debounceMs: 2000 },    // batch rapid messages into one turn
    statusReactions: { enabled: true }, // lifecycle reactions (thinking/tool/done/error)
  },
}
```
**Captured:** `queue.mode`: `steer` / `followup` / `collect` / `interrupt`. `inbound.debounceMs` batches rapid text into a single agent turn (media flushes immediately, commands bypass). Status reactions give you visible lifecycle feedback (queued→thinking→tool→done) without message spam. `responsePrefix: "auto"` derives `[{identity.name}]` for provenance.

---

## §9 — The complete env-var and path map (operational reference)

- `OPENCLAW_HOME` — base directory for path resolution
- `OPENCLAW_STATE_DIR` — overrides where state files live
- `OPENCLAW_CONFIG_PATH` — points to a specific config file
- `OPENCLAW_WORKSPACE_DIR` — default agent workspace
- Config: `~/.openclaw/openclaw.json` (chmod 600), state dir `~/.openclaw` (chmod 700)
- Cron jobs: `~/.openclaw/cron-jobs.jsonl`
- Sessions: `~/.openclaw/agents/<id>/sessions/*.jsonl` + `sessions.json`
- Skills (global, cron-visible): `~/.openclaw/skills/`
- Skills (workspace, main-only): `<workspace>/skills/`
- Memory: `<workspace>/MEMORY.md` + `<workspace>/memory/*.md`
- Secrets (file provider): `~/.openclaw/secrets.json`
- Default port: `18789` (WebSocket + HTTP multiplexed)

---

## §10 — Net additions to the plan (v1.3) from the deep dive

1. **Model routing is now exact (§1).** Fold the Codex-runtime + Qwen-per-model config into Phase 0. The "no API billing via Codex OAuth" mechanism is confirmed.
2. **Heartbeat cost-control is quantified (§2).** `isolatedSession: true` + `lightContext: true` + cheap model = ~20-50× heartbeat cost reduction. Non-negotiable for 24/7.
3. **The skill-placement gotcha is critical (§2).** Doctrine/overnight skills MUST go in `~/.openclaw/skills/` (global) or isolated cron won't see them. This affects how you structure Phase 2.
4. **Command Center scope drops hard (§6).** Native UI covers ~5 of your 7 surfaces. Phase 4 becomes "configure native + 2 Canvas surfaces." Re-scope it.
5. **Sandbox hardening is fully specced (§4).** The Phase-6 container config is now copy-pasteable with full cap-drop/seccomp/apparmor.
6. **Reader-agent split is real config with native enforcement (§5).** The sandbox-inheritance guard means OpenClaw mechanically prevents a sandboxed reader from spawning an unsandboxed helper. Your isolation is enforced, not just configured.
7. **Device pairing is a Phase-0 step (§6).** First Control-UI connect needs `openclaw devices approve` even on Tailnet. Document it so you're not confused by "1008: pairing required."

---

## §11 — Updated coverage status

After this deep-dive pass, doc coverage is now:
- **Read in full:** architecture, skills, exec-approvals, sandboxing, secrets, security, memory, automation/hooks, **config-agents (the densest page), configuration, model-providers, models, cron-jobs, Control UI, Dashboard, Canvas** + the openclaw README, awesome-list, explain-openclaw security repo.
- **Read via strong excerpt (2+ sources):** channels detail, providers detail (Codex/OpenAI/Ollama specifics), config-channels, multi-agent, session-types, the GitHub issues for cron gotchas.
- **Still Tier-C (lower-weight, implementation-time):** nodes/media (camera/audio — you likely don't need), TTS/voice detail (optional), formal-verification + MITRE-ATLAS threat-model pages (worth reading before Phase 6 but architecture-neutral), gateway protocol/bridge-protocol (only if building a custom WS app vs. using native UI — and §6 suggests you mostly won't), OpenShell/SSH-sandbox (you're Docker-local), exposure-runbook/secure-file-ops (covered by security page).
- **Still Tier-D (unreachable by me):** Reddit threads, Discord, FB groups, primary YouTube/X — structural limits, better closed by you.

**Honest completeness call:** the config syntax for everything your build actually does — model routing, agents, sandbox, cron, heartbeat, compaction, memory, sessions, messages, multi-agent, Command Center — is now captured at copy-pasteable depth. The remaining Tier-C is genuinely peripheral (voice/camera/Apple-PIM/OpenShell) or pre-Phase-6 reading (threat-model docs). There are no foundational unknowns left in the official docs. The only material residual is the closed-community color (Reddit/Discord/FB/YouTube), which is corroboration-and-war-stories, not architecture.

---

*End of deep-dive config addendum v1.0. This is the syntax-complete layer. With the four prior documents, the picture is now exhaustive at the architecture, security, capability, AND configuration levels — with an honest, narrow residual that is peripheral or community-color, not foundational.*
