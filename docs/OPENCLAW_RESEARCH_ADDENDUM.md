# OPENCLAW_RESEARCH_ADDENDUM.md

**Companion to:** `OPENCLAW_BUILD_PLAN.md` v1.0
**Author:** Claude (reviewer/architect thread)
**Version:** v1.0 (2026-06-11)
**Purpose:** Close the `[VERIFY]` gaps in the build plan with findings grounded in OpenClaw primary docs + the GitHub repo. Read this alongside the plan. Where this addendum and the plan disagree, this addendum is newer and wins.

**Docs read for this addendum (2026-06-11):** `gateway/security`, `gateway/secrets`, `gateway/sandboxing`, `tools/exec-approvals`, `tools/skills`, `concepts/architecture`, `tools/browser`, `automation` + the hooks docs, plus the GitHub repo README. Third-party guides (SFAI Labs, team400, lumadock) used only to corroborate, never as sole source.

---

## TL;DR — what changed in my recommendation after deep research

1. **The audit gap is CLOSED, and better than expected.** OpenClaw ships a `command-logger` hook that writes every command event to a centralized JSONL audit file, and a full event-driven hooks system you can extend. Your append-only audit requirement is native + extensible. You do NOT need to rebuild your custom audit writer. (Detail §1)

2. **The single biggest correction to the whole project's premise:** OpenClaw's security model is explicitly a **single-trusted-operator** model, and its *default* is `exec.security: "full", ask: "off"` — full host access, no prompts. The docs call this "intentional UX, not a vulnerability." **Your entire doctrine is a deliberate hardening away from this default.** This is GOOD news (you were right that strict-by-default matters and OpenClaw lets you get there) but it reframes the work: you are not "configuring OpenClaw," you are "hardening OpenClaw against its own permissive defaults." Phase 1 is therefore the most important phase, not a formality. (Detail §2)

3. **The SSN form-fill end-state has a real, specific risk that needs design, not just config.** OpenClaw's browser tool drives real Chromium via Playwright and can take screenshots + extract DOM text that go into model context. There is redaction (`logging.redactSensitive`) and external-content sanitization, but the *model can see the page it's filling*. This is the httpx-token-leak failure mode at SSN scale, and it is the one place your custom thinking still earns real design work. (Detail §3 — read this one carefully)

4. **A genuinely important safety finding for your threat model:** OpenClaw's docs are explicit that **prompt injection is not solved** and that *content the agent reads* (web pages, emails, docs) is a threat surface even when only you can message it. For an SSN-filling agent that also browses the web, this is the central risk. The mitigation pattern (reader-agent isolation) is documented and you should adopt it. (Detail §4)

5. **Specific leading-class repos/tools to use** are identified in §7 — including the one OpenClaw itself uses for browser automation (Vercel's `agent-browser`, which cuts browser token usage 60-93%).

---

## §1 — The audit question: CLOSED (native + extensible)

**Verdict:** Your "append-only immutable audit JSONL" requirement is met natively and is extensible via hooks. Do not rebuild the custom audit writer.

What OpenClaw provides `[VERIFIED]`:

- **`command-logger` bundled hook** — writes every command event to `~/.openclaw/logs/commands.log` as structured JSON (one event per line — i.e., JSONL). Example line: `{"timestamp":"...","action":"new","sessionKey":"agent:main:main","senderId":"...","source":"telegram"}`. This is your append-only command audit, native.
- **The hooks system itself** — internal event handlers (TypeScript) running in the Gateway process, subscribing to events like `command:new`, `gateway:startup`, `tool_result_persist`. Hook execution is itself recorded in audit logs. This is the mechanism for any custom audit format you want.
- **`tool_result_persist` event** — this is the key one. A hook on this event sees every tool execution and can append your exact audit record. This is your old "AuditEntry on every tool call" design, as a ~30-line hook instead of a subsystem.
- **Background Tasks ledger** — "Tasks automatically track all detached work so you can inspect and audit it."
- **Trajectory bundles** — full execution traces.
- **OTel + Prometheus** — structured observability export.

**What this means for the plan:** Phase 2's audit step collapses from "possibly write a custom subsystem" to "enable `command-logger`, and write one custom hook on `tool_result_persist` that emits your audit schema if the native format isn't sufficient." Your old C.3 immutable-audit work — the thing you were proud of — becomes a small hook. The *design* (what to log, append-only, tamper-evidence) carries; the *code* shrinks by 95%.

**One caveat `[VERIFY hands-on]`:** "append-only" in OpenClaw means "the hook appends lines to a log file." It is not cryptographically tamper-evident (hash-chained) out of the box. If your threat model needs tamper-evidence (detect after-the-fact log editing), that hash-chaining is the ONE piece of genuinely-custom audit code worth keeping from your old design — implement it inside the `tool_result_persist` hook. For most personal-use threat models, file permissions (`600`) + the native JSONL is sufficient; hash-chaining is for "prove to a third party the log wasn't altered," which you likely don't need yet. Decide deliberately.

---

## §2 — The trust model: OpenClaw is permissive-by-default; your doctrine is the hardening

**This is the most important finding in the addendum. Read it twice.**

`[VERIFIED]` directly from the security doc: *"OpenClaw's product default for trusted single-operator setups is that host exec on gateway/node is allowed without approval prompts (`security="full"`, `ask="off"` unless you tighten it). That default is intentional UX, not a vulnerability by itself."*

And: *"This guidance assumes one trusted operator boundary per gateway (single-user, personal-assistant model). OpenClaw is not a hostile multi-tenant security boundary."*

**What this means, plainly:**

- Out of the box, OpenClaw trusts you completely and runs anything without asking. That is the opposite of your propose-then-commit doctrine.
- Your Closure Doctrine / capability tiers / approve-before-act discipline is therefore a **deliberate departure from OpenClaw's defaults** — you are hardening *toward* friction on purpose, because your end-state (SSN form-fill, autonomous overnight runs) has a blast radius that the default trusts too freely.
- **You were right all along** that strict-by-default matters. OpenClaw gives you every knob to get there. But the knobs default to "open," so Phase 1 (trust model as config) is the load-bearing phase, not a checkbox.

**The exact config to harden to your doctrine** `[VERIFIED]` from the docs' own hardened baseline:

```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",                 // your mini is tailnet-reachable; keep gateway loopback, use Tailscale Serve
    auth: { mode: "token", token: "<long-random>" },
  },
  session: { dmScope: "per-channel-peer" },
  tools: {
    profile: "messaging",             // minimal tool surface by default
    deny: ["gateway", "cron", "sessions_spawn", "sessions_send"],  // deny control-plane tools for any untrusted-content path
    fs: { workspaceOnly: true },
    exec: { security: "deny", ask: "always" },   // YOUR Approve-tier default: deny + always-ask, NOT full/off
    elevated: { enabled: false },     // no sandbox escape hatch unless deliberately enabled
  },
}
```

Then selectively *widen* per agent. This is the inverse of how most OpenClaw users run it (they start permissive). You start locked and open deliberately — which is exactly your doctrine, now expressed as config.

**Additional hardening the docs surface that maps to your old plan:**

- `tools.exec.strictInlineEval: true` — if you allowlist `python`/`node`, inline eval (`python -c`) still requires approval. This is your "side-effecting must be gated" rule, native.
- The agent-facing `gateway` tool **refuses to rewrite `tools.exec.ask` or `tools.exec.security`** — the model cannot widen its own approval policy. This is a native enforcement of "doctrine the agent can't disable," which your old plan worked hard to achieve in code. It's built in.
- `agent config.apply` edits are fail-closed by default; only low-risk runtime tuning is agent-tunable. The agent cannot escalate its own privileges via config.
- Heredoc parameter-expansion is rejected in allowlist review (your old shell-quoting pain, hardened at the security layer).

**Plan impact:** Phase 1 gets MORE important and slightly bigger. It's not just "set up Telegram approvals." It's "invert OpenClaw's default trust posture to match your doctrine, per-agent, and verify the model can't widen it." Run `openclaw security audit` as the exit gate — it specifically flags `security="full"` drift.

---

## §3 — The SSN form-fill end-state: the one place real design work remains

**Verdict:** Possible, but this is the highest-risk surface and OpenClaw does NOT fully solve it for you. Your old four-layer secret design still has value here as *design guidance*, even though the implementation is different.

What OpenClaw provides `[VERIFIED]`:

- **Managed/sandboxed browser** — dedicated isolated Chromium profile, never your personal profile. Sandboxed browser runs in Docker with conservative flags, password-protected noVNC observer, masked token URLs.
- **SecretRef indirection** — SSN stored as a SecretRef (`exec` provider → Keychain/1Password/Vault), resolved into the in-memory snapshot, never plaintext at rest.
- **`logging.redactSensitive: "tools"` (default on)** + `logging.redactPatterns` for custom patterns (you'd add your SSN pattern).
- **Browser SSRF policy strict by default** — private/internal destinations blocked unless explicitly allowlisted. Good for "agent can only reach the form's real domain."
- **Tool-policy + approval gating** — form submit can be Approve-tier → Telegram confirm.

**The unresolved risk `[VERIFIED as a real concern]`:**

The browser tool *drives a real page and can screenshot it and extract its DOM text into model context*. From the SFAI Labs corroboration and the OpenClaw docs: the recommended pattern is explicitly *"keeping credentials out of the model context"* and *"gating sensitive actions behind explicit user confirmation"* — which tells you the platform does NOT automatically guarantee the model never sees a typed secret. It's a discipline you must impose.

**So here is the actual design you need for Phase 6 (this is your IP applied correctly):**

1. **Never let the model type the secret.** The model issues a "fill field X with secret-ref `ssn`" instruction; the *tool* resolves the ref and types it. The model's context shows `{ssn}`, never the value. `[VERIFY hands-on]` whether OpenClaw's browser `fill` action supports a secret-ref value that resolves tool-side without returning to the model. If it does → native. If it doesn't → this is a small custom skill/tool wrapper you write. **This is THE thing to verify before Phase 6.**
2. **Redaction patterns for the SSN format** in `logging.redactPatterns` so even if it lands in a log, it's masked. (Lesson from your httpx-token incident: assume it WILL hit a log; redact at the pattern layer.)
3. **No screenshots of pages containing the secret**, or screenshots only after masking. `[VERIFY]` whether the browser screenshot action can be told to skip/mask sensitive fields.
4. **Submit behind Approve-tier** → Telegram `/approve` before the form posts.
5. **A dedicated, sandboxed, single-domain-allowlisted agent** for form-fill — not your main agent. SSRF-allowlist it to the exact form domain. Sandbox `mode: all`. No web_search/web_fetch on that agent (so it can't be injected by a malicious page into exfiltrating).

**Bottom line:** OpenClaw gives you the primitives (SecretRef, sandbox, redaction, approval, SSRF allowlist). It does NOT give you a turnkey "secret never touches the model" form-fill. That last mile is your design — and it's exactly the four-layer model you already designed in the old plan. **Your old secret-handling design was not wasted; it's the spec for the Phase 6 skill.** Phase 6 stays gated to last, with a maximum-rigor adversarial audit, and the fake-SSN proof gate stands.

---

## §4 — Prompt injection via content (the threat your SSN agent actually faces)

`[VERIFIED]` — a finding worth elevating because it's the realistic attack on your end-state:

The docs are explicit: *"Even if only you can message the bot, prompt injection can still happen via any untrusted content the bot reads (web search/fetch results, browser pages, emails, docs, attachments)."* And: *"prompt injection is not solved."*

For an agent that browses the web AND holds SSN-class secrets, the attack is: a malicious page injects instructions, the agent is manipulated into exfiltrating the secret. OpenClaw's mitigations `[VERIFIED]`:

- **External-content sanitization** — strips chat-template special tokens from fetched/read content before it reaches the model (closes the tokenizer-forgery bypass).
- **Content wrapped in untrusted-input delimiters** with `<<<EXTERNAL_UNTRUSTED_CONTENT>>>` markers.
- **Reader-agent pattern (the key one for you):** *"Use a read-only or tool-disabled reader agent to summarize untrusted content, then pass the summary to your main agent."* — i.e., the agent that browses has NO secret access; the agent that holds secrets never touches raw web content.
- **Strong-model requirement:** "Do not run tool-enabled agents on weak/small model tiers — prompt-injection risk is too high." **This has a direct consequence for your Qwen routing:** local Qwen 14B is fine for bounded/offline tasks, but the docs explicitly warn against weak models for tool-enabled agents touching untrusted content. **Your SSN/browser agent must run on Codex (strong), not local Qwen.** Route accordingly.

**Plan impact:** Add to Phase 6 a hard architecture rule — **separate the browsing agent from the secret-holding agent** (reader-agent isolation), and pin the secret-holding agent to a strong model (Codex), never local Qwen. This is a multi-agent split that OpenClaw supports natively via per-agent tool policy. It's one of the few places multi-agent genuinely earns its cost — exactly your old "multi-agent only where it earns the 15x" principle, vindicated.

---

## §5 — Loop prevention, kill switch, memory: resolved

**Loop prevention `[VERIFIED partial]`:** OpenClaw has native **tool-loop detection** (dedicated subsystem). Combined with exec approvals (which bound what can run) and cost/iteration controls, this covers most of your six controls. `[VERIFY hands-on]` the exact knobs vs. your six — but you almost certainly do NOT need to rebuild all six; enable native loop-detection and add a hook for any specific control (e.g., your no-progress oracle) that isn't covered.

**Kill switch `[VERIFIED]`:** Native and better than your old C.5/C.6 split. `/approve <id> deny` denies a pending action. For a *running* task, OpenClaw has `steer` and `goal`-cancellation tools, and the `process` tool tracks background work you can stop. The Background Tasks ledger makes detached work inspectable and stoppable. Your old "receive+record+ack now, enforce later" split likely **collapses** — OpenClaw can actually interrupt. `[VERIFY hands-on]` the exact stop semantics, but plan for kill-switch being native, not a two-phase custom build.

**Memory + lifestreams `[VERIFIED harness, custom mapping]`:** OpenClaw has a memory engine, the `session-memory` hook (dated markdown memory files under `~/.openclaw/workspace/memory/`), inferred commitments (memory-like follow-up check-ins — a strong fit for your closure-doctrine "nothing falls through"), and a "dreaming"/compaction concept. Your seven lifestreams map to memory organization + workspace structure + skill grouping. This is custom *design* (no OpenClaw "lifestream" primitive) but the substrate is rich. The inferred-commitments feature is genuinely aligned with Closure Doctrine — evaluate it early.

---

## §6 — Command Center: the path is clearer now

`[VERIFIED]`:

- **Control UI** — ships native, includes Nodes, **Exec approvals editing** (your Approval Queue + Trust Dial surfaces, partially free), config editing.
- **Canvas host** at `/__openclaw__/canvas/` — arbitrary agent-rendered HTML/JS. **Security note from the docs:** treat canvas content as untrusted, don't expose it to untrusted networks, don't share origin with privileged surfaces. So Canvas is for *your* surfaces, kept tailnet-only.
- **Dashboard + WebChat + TUI** — additional native surfaces.
- **Gateway WebSocket API** at `ws://127.0.0.1:18789` — typed protocol for a custom app.

**Refined recommendation (was Option C, now firmer):** Use **Control UI for Approval Queue + Audit + Trust Dial** (largely native), and **Canvas for your bespoke surfaces** (Intake, Operations Board, Lifestream/Recurring views). Build a separate WS app ONLY if Canvas can't express a surface. This likely cuts your 7-surface build to ~3-4 genuinely-custom surfaces. Keep all of it loopback/tailnet — never expose the canvas or Control UI publicly (the docs are emphatic).

---

## §7 — Leading-class repos, tools, and practices to adopt

Grounded recommendations, not generic:

1. **`agent-browser` (Vercel Labs)** — `github.com/vercel-labs/agent-browser`. OpenClaw uses this as the default CLI for interactive browser automation because it returns compact element refs (`@e1`, `@e2`) instead of raw DOM, cutting browser token usage **60-93%**. Use it for any browser skill. `[VERIFIED]` it's the documented default.

2. **ClawHub (`clawhub.ai`)** — the public skills registry. Before writing ANY skill, search ClawHub — your morning-brief, web-research, etc. likely already exist as community skills with security scan states (VirusTotal/ClawScan). Install with `openclaw skills install <slug>`. **Treat third-party skills as untrusted code — read before enabling** (the docs are explicit). Pin versions.

3. **Skill Workshop plugin** — generates workspace skills from observed agent procedures, with pending-approval safety. This is your "system expands its own capabilities over time" goal, native. Start in pending-approval mode only.

4. **Secrets via `exec` provider → Keychain** — you already have the agent login Keychain working. Wire an `exec` SecretRef provider that calls `security find-generic-password`. The docs show 1Password/Vault/sops patterns; macOS Keychain via a small wrapper script fits the same `exec` shape. This is your prior Keychain work, reused correctly.

5. **`openclaw security audit --deep` + `openclaw doctor`** — run both as standing CI/health checks. The audit catches exactly the drift your doctrine cares about (exec-security drift, browser exposure, permission hygiene). Wire `audit` into your eval/CI gate.

6. **The MITRE-ATLAS threat model + formal-verification docs** — OpenClaw publishes both (`/security/THREAT-MODEL-ATLAS`, `/security/formal-verification`). Read them before Phase 6. A project that publishes a formal security-model doc and an ATLAS threat model is taking this seriously; use their work rather than re-deriving it.

7. **`contextVisibility: "allowlist"`** — even in your single-user setup, set this so supplemental context (quoted replies, fetched history) is filtered. Defense-in-depth against injected context.

8. **Reader-agent pattern** (from §4) — architectural, not a repo, but it's the leading-class pattern for secret-holding agents that also read untrusted content. Adopt it for Phase 6.

---

## §8 — Net changes to the build plan (apply these to v1.1)

1. **Phase 1 is now THE load-bearing phase** — reframed from "set up approvals" to "invert OpenClaw's permissive default trust posture to match your doctrine, per-agent, verified by `security audit`." Bigger and more important than the plan implied.

2. **Phase 2 audit step collapses** — enable `command-logger` + write one `tool_result_persist` hook for your schema. Optional hash-chaining only if you need third-party tamper-evidence. Your old audit subsystem is now ~30 lines.

3. **Phase 6 gains a hard architecture rule** — reader-agent isolation: the browsing agent has no secrets and runs on a strong model (Codex); the secret-holding agent never touches raw web content. Never run the tool-enabled/secret agent on local Qwen. The fake-SSN proof gate + max-rigor audit stand.

4. **The make-or-break Phase 6 verification is now specific:** does OpenClaw's browser `fill` action accept a secret-ref that resolves tool-side without returning the value to the model? Verify this one thing before any SSN work. If no → write a small custom fill-tool wrapper (your four-layer design as a skill).

5. **Loop prevention + kill switch shrink** — enable native loop-detection + use `steer`/`goal`/`process` for stop. Likely no custom build; the old C.5/C.6 split probably collapses.

6. **Model routing rule added** — strong model (Codex) for any tool-enabled or untrusted-content-reading agent; local Qwen only for bounded/offline/trusted-input tasks. This is a doctrine-level rule, not just a perf choice — it's a prompt-injection safety requirement per the docs.

7. **Adopt the named tools** (§7): `agent-browser`, ClawHub (search before building), Skill Workshop, exec-provider Keychain secrets, `security audit` in CI, `contextVisibility: allowlist`.

---

## §9 — Remaining hands-on verifications (the honest residual)

These genuinely require running OpenClaw; no doc settles them. Do them in the first hands-on session, before committing the relevant phase:

1. **Browser `fill` + secret-ref tool-side resolution** (Phase 6 gate) — THE critical one.
2. **Browser screenshot masking** — can sensitive fields be excluded/masked from screenshots fed to the model?
3. **Exact kill-switch semantics** — does `steer`/`goal`-cancel actually interrupt a mid-flight tool run, or only stop the next turn?
4. **Native loop-detection knobs** vs. your six controls — which need a supplementary hook.
5. **`command-logger` / `tool_result_persist` schema** — is the native JSONL sufficient, or do you write the custom-schema hook?
6. **Codex-OAuth + Ollama dual-provider routing** — confirm per-agent model pinning works as the docs imply (strong model for secret agent, Qwen for bounded).
7. **Lifestream → memory/workspace mapping** — design work, validated by trying it.

Everything else in the plan is now grounded in primary docs. These seven are the real residual, and they're all "run it and look," not "research more."

---

*End of addendum v1.0. Fold §8 into `OPENCLAW_BUILD_PLAN.md` as v1.1 when you next touch the plan. The seven items in §9 are the only genuine unknowns left, and they're hands-on, not research.*
