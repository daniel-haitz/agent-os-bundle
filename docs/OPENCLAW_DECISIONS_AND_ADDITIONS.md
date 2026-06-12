# OPENCLAW_DECISIONS_AND_ADDITIONS.md

**Companion to:** the five prior OpenClaw documents (build plan, research addendum, field notes, ecosystem/coverage, deep-dive config)
**Author:** Claude (reviewer/architect thread)
**Version:** v1.0 (2026-06-11)
**Purpose:** Lock the adopt/build decisions upfront so the build runs smoothly without re-litigating each tool mid-phase. Every item from the consider-and-add list gets a decision here: ADOPT, ADOPT-PENDING-VERIFY, BUILD-CUSTOM, or DEFER — with reasoning and the phase it lands in.

**Honesty note on evaluations:** For the security/secrets tools (ClawGuard, ClawBands, Aquaman), my evaluation is based on their documented descriptions + ecosystem corroboration, NOT a full source read. Where a tool will touch your audit integrity or your SSN secrets, the decision is ADOPT-PENDING-VERIFY: the call is made, but it MUST be confirmed by a hands-on/source read at the relevant phase before it carries real weight. For a system holding your SSN, a README is not sufficient to bless a credential layer. This is the same discipline that should have been applied to OpenClaw itself from the start.

---

## DECISION TABLE (the upfront locks)

| Item | Decision | Phase | Confidence |
|---|---|---|---|
| Steinberger `agent-scripts` orchestrator pattern | ADOPT (pattern, not repo) | 2 | High |
| `isolatedSession` heartbeats + cheap-model cron | ADOPT | 0/1 | High (doc-verified) |
| Git-baseline config drift detection | ADOPT | 0 | High |
| Clawhatch (skill scanner) | ADOPT | standing | High |
| Web search (native, 13 providers) | ADOPT | 3 | High (doc-verified) |
| Skill Workshop | ADOPT (pending-approval mode) | 2 | High |
| Opik observability | ADOPT | 5 | Medium-High |
| Reader-agent isolation (architecture) | ADOPT | 6 | High (doc-verified) |
| Inferred Commitments (native) | ADOPT | 3 | Medium-High |
| ClawGuard (hash-chained audit) | ADOPT-PENDING-VERIFY | 2 | Medium |
| ClawBands (approval interception) | EVALUATE → likely BUILD-CUSTOM | 1 | Medium |
| Aquaman (credential isolation) | ADOPT-PENDING-VERIFY | 6 | Medium-High |
| Recurring Registry awareness layer | ADOPT (custom build) | 4 | High |
| Community dashboards (Studio/TenacitOS) | REFERENCE-ONLY | 4 | High |

---

## THE EVALUATIONS (the "evaluate before committing" items, decided)

### ClawGuard (hash-chained audit logging) → ADOPT-PENDING-VERIFY (Phase 2)

**What it is:** Permission manifests, runtime enforcement, sandboxing, audit logging with hash-chaining.

**The evaluation:** Your v4 Command Center Audit Log shows "append-only · WAL mode · chain integrity: ok." That's a tamper-evident hash-chained audit — exactly what ClawGuard provides and exactly what you'd otherwise hand-build (it was the one piece of your C.3 design worth keeping per research-addendum §1). The native `command-logger` + `tool_result_persist` hook gives you append-only JSONL, but NOT hash-chaining. So there's a real gap ClawGuard fills.

**The decision and the caveat:** ADOPT as the hash-chain layer feeding your Audit Log surface — BUT verify at Phase 2 by reading its source, because: (a) it's a third-party security tool that intercepts your audit path, which is itself a trust-sensitive position; (b) you need to confirm its hash-chain survives OpenClaw's compaction/rotation; (c) confirm it doesn't itself become an injection or tampering vector. **If the source read raises flags, fall back to a custom `tool_result_persist` hook that hash-chains your own JSONL** — that's ~50 lines and fully under your control. Net: adopt the capability, verify the specific tool, have a custom fallback ready.

### ClawBands (tool-execution interception + human-in-loop approval) → EVALUATE, leaning BUILD-CUSTOM (Phase 1)

**What it is:** Security middleware that intercepts tool execution and inserts human-in-the-loop approval for dangerous actions.

**The evaluation:** This overlaps heavily with what OpenClaw *already does natively* — `exec.security`/`exec.ask` + `approvals.exec` + Telegram `/approve` IS tool-execution interception with human approval (deep-dive §1, research-addendum §2). ClawBands would be a *third* approval layer on top of the native one. For your specific case, the native approval engine + your custom pre-mortem presentation layer (Approval Queue surface) likely covers it. Adding ClawBands risks two approval systems fighting.

**The decision:** Do NOT adopt ClawBands by default. The native approval engine is your approval mechanism; your Command Center Approval Queue is the presentation. BUILD-CUSTOM the pre-mortem layer (which native doesn't have) on top of native exec-approvals. Only revisit ClawBands if, at Phase 1, the native engine proves insufficient for a specific gate your doctrine needs. **Reasoning: don't stack a redundant security layer that could conflict with the native one.** Simpler is safer here.

### Aquaman (credential isolation proxy) → ADOPT-PENDING-VERIFY (Phase 6)

**What it is:** API keys/secrets never enter the agent process. Stored in Keychain/1Password/Vault/encrypted-file, injected via Unix domain socket. Process-level isolation, NOT detection/redaction.

**The evaluation:** This is the strongest single find for your SSN end-state, and it's categorically better than your original four-layer redaction design. Redaction tries to scrub secrets *after* they reach context (fragile — the httpx-token leak you hit is exactly this failure mode). Aquaman makes the secret *unreachable by the agent process at all*. For an agent filling forms with your SSN, "the process literally cannot read it" beats "we redact it from logs."

**But — this is the highest-stakes trust decision in the entire build.** You are considering routing your SSN through a third-party proxy. That demands the deepest verification of anything here:
- Full source read of Aquaman before any real secret touches it.
- Confirm the Unix-socket injection actually keeps the value out of the LLM's tool-result context (the whole premise).
- Confirm it integrates with OpenClaw's SecretRef contract (deep-dive references SecretRefs; Aquaman must not fight them).
- Confirm the proxy itself isn't a new attack surface (a credential proxy is a high-value target).
- Cross-check against OpenClaw's own native secrets model — it's possible native SecretRef + sandbox `workspaceAccess: none` + the browser `fill` tool-side resolution (the make-or-break Phase-6 verify) is *sufficient* without Aquaman.

**The decision:** ADOPT-PENDING-VERIFY as the leading candidate for the Phase-6 secrets layer, explicitly gated behind a full source audit AND a comparison against native-SecretRef-only. **Do not put a real SSN near anything — Aquaman or native — until the fake-SSN adversarial proof gate passes (build-plan Phase 6).** This is the one place where "I read the README" is dangerously insufficient, and I'm flagging it as such rather than blessing it.

### Inferred Commitments (native OpenClaw feature) → ADOPT (Phase 3)

**What it is:** OpenClaw natively detects implied follow-ups/commitments from conversations and surfaces them as check-ins (memory-like, with provenance).

**The evaluation:** This is a near-perfect mechanical fit for your Closure Doctrine's founding principle — "nothing falls through the cracks." Your Operations Board's "Watchlist" bucket (awaiting external trigger) and the closure engine are *exactly* this pattern. Inferred Commitments could populate Watchlist items automatically. It's native, low-risk (read/surface, doesn't act), and does work you were going to build.

**The decision:** ADOPT in Phase 3, wired to feed your Watchlist + closure engine. Lower verification bar because it's native and non-acting (surfaces, doesn't execute). Evaluate during Phase 3 whether its provenance model maps cleanly to your owner-attribution (Daniel/Agent/Shared).

---

## NEW CAPABILITIES — all ADOPT (decided)

### Web search → ADOPT (Phase 3)
Native, 13 providers. Start with a zero-cost option (Ollama-search or a free Brave tier) and upgrade if quality demands. Pure addition — you had nothing here. Wire it to the reader-agent (NOT the secret-holder agent, per reader-agent isolation).

### Skill Workshop → ADOPT, pending-approval mode only (Phase 2)
Generates workspace skills from observed agent procedures. This is your "expands capabilities over time" goal, native. **Hard constraint: pending-approval mode only** — never let it auto-write skills into a workspace that matters (a self-writing skill is a self-modification vector, field-notes §1.3). Every generated skill goes through your review + Clawhatch scan before activation.

### Opik observability → ADOPT (Phase 5)
Drop-in trace export (cost/token/error/behavior) for OpenClaw. Cleaner than the Langfuse self-host your greenfield plan assumed. Medium-high confidence — verify at Phase 5 that it captures what your eval suite needs; if not, native OTel + Prometheus is the fallback (also already planned).

---

## HIGH-CONVICTION ADOPTS (decided, low controversy)

### Steinberger `agent-scripts` orchestrator pattern → ADOPT the pattern (Phase 2)
Study his `maintainer-orchestrator` + `github-project-triage` SKILL.md structure and his wake-every-N-minutes-route-to-threads loop as the template for your single-loop orchestrator. His planning cadence (morning/daily/Friday/Sunday-3-lane/monthly) is your recurring-cadence reference. **Adopt the pattern and structure, write your own files against your doctrine.** Do not fork his repo wholesale.

### isolatedSession heartbeats + cheap-model cron → ADOPT (Phase 0/1)
`heartbeat.isolatedSession: true` + `lightContext: true` + `model: ollama/qwen2.5-coder:14b`. Cron jobs route routine work to cheap/local models, reserve Codex for reasoning + untrusted-content. The 20-50× cost lever. Doc-verified syntax in deep-dive §2. Set from day one.

### Git-baseline config drift detection → ADOPT (Phase 0)
`cd ~/.openclaw && git init && git add openclaw.json && git commit -m baseline`. Then `git diff` catches any config self-modification (the #28-30 attack class). Free, fits your git discipline. Note: version ONLY `openclaw.json` in an isolated repo — never the whole `~/.openclaw/` state dir (contains secrets).

### Clawhatch skill scanner → ADOPT (standing rule)
128-check pre-install scan, scores 0-100, <1 second. Run on EVERY skill before install (1-in-7 malicious rate). Standing rule, not a phase. Pair with: read source before enabling, pin versions, tight per-agent skill allowlists.

### Reader-agent isolation → ADOPT as architecture (Phase 6, designed from Phase 1)
The browsing/email-reading agent holds NO secrets and runs on Codex (strong, injection-resistant). The secret-holding agent NEVER touches raw web/email content. Native enforcement via sandbox-inheritance guard (deep-dive §5). This is the one place multi-agent earns its cost — for security, backed by the real Snyk email-exfiltration incident. Design the split from Phase 1; it goes live in Phase 6.

---

## RECURRING REGISTRY AWARENESS LAYER → ADOPT (custom build, Phase 4)

**Decision: ADOPT as a custom Command Center surface.** This is genuinely yours — no OpenClaw equivalent, no community tool does it. The model: an *awareness layer* over external sources of truth (Apple Reminders, Google Calendar, vendor portals), showing that each obligation exists, where it's tracked, and whether it's currently healthy (coverage detection — the "HVAC filter 47d overdue" gap). **Doing happens in the source tool; the registry only surfaces existence + health.**

**What this requires (newly scoped — wasn't in your greenfield plan as integration work):**
- **Read-integrations into external sources:** Apple Reminders + Calendar (via the `Apple-PIM-Agent-Plugin` from the ecosystem list, or khal/vdirsyncer), Google Calendar (native Gmail/Calendar integration), vendor portals (custom per-vendor, lowest priority).
- **A coverage-health engine:** compares expected cadence vs. last-completed, flags gaps (overdue, missing, gap-forming). This is custom logic — likely a cron job + a hook that writes registry state.
- **The registry UI surface:** grouped by lifestream, with the ok/gap/missing status badges from your v4 mock.

**Phasing note:** The read-integrations are the long pole. Apple PIM + Google Calendar first (covers most obligations in your mock); vendor portals later/manual. The coverage-health engine is the novel custom piece — scope it as its own workstream within Phase 4.

---

## COMMUNITY DASHBOARDS → REFERENCE-ONLY (Phase 4)

**Decision: study, don't fork.** Given the Command Center is mostly-custom (your seven surfaces have no native equivalent), OpenClaw Studio / TenacitOS / Mission Control are **reference implementations for how to talk to the Gateway WebSocket API** — not bases to adopt. Read their WS-integration code, learn the protocol patterns, then build your own surfaces against your v4 mock. Adopting their UI would mean inheriting their data model, which isn't yours.

---

## NET CHANGES TO THE BUILD PLAN (fold into v1.1)

**Phase 0** gains: git-baseline config; isolatedSession heartbeat config; version pin ≥2026.2.12; Clawhatch installed as standing pre-install gate.

**Phase 1** gains: reader-agent split DESIGNED (goes live Phase 6); ClawBands evaluated-and-likely-declined (native engine + custom pre-mortem instead); the config-self-modification defenses (deny gateway/cron/sessions_* for untrusted-content agents).

**Phase 2** gains: Steinberger orchestrator pattern as template; ClawGuard ADOPT-PENDING-VERIFY for hash-chained audit (custom fallback ready); Skill Workshop in pending-approval mode.

**Phase 3** gains: web search (to reader-agent); Inferred Commitments → Watchlist/closure engine.

**Phase 4** gains: Command Center is a CUSTOM Gateway-WS app per v4 mock (corrected from "mostly native"); Recurring Registry awareness layer as a scoped workstream WITH external read-integrations (Apple PIM + Google Calendar); community dashboards as reference-only.

**Phase 5** gains: Opik observability (OTel/Prometheus fallback).

**Phase 6** gains: Aquaman ADOPT-PENDING-VERIFY as secrets-layer candidate, gated behind full source audit + native-SecretRef comparison + fake-SSN adversarial proof. Reader-agent isolation goes live.

---

## THE THREE THINGS THAT STILL NEED VERIFICATION (carry forward, do NOT skip)

1. **Aquaman source audit + native-SecretRef comparison** (Phase 6) — before any real SSN. Highest-stakes trust decision in the build.
2. **ClawGuard source read** (Phase 2) — before it carries your audit integrity. Custom hash-chain fallback ready.
3. **Browser `fill` tool-side secret resolution** (Phase 6, from research-addendum §9) — does OpenClaw's browser fill a field from a SecretRef without returning the value to the LLM? THE make-or-break Phase-6 verification, independent of Aquaman.

These three are "run it and read the source," not "research more." They're the genuine residual, all at the security-critical edge, all decided in principle but requiring confirmation before they touch real secrets or real audit integrity.

---

*End of decisions document v1.0. Every consider-and-add item is now decided upfront. The build can proceed without re-litigating tool choices — with three explicit verification gates at the security-critical edges that must not be skipped. Fold the "net changes" into OPENCLAW_BUILD_PLAN.md as v1.1 when you next touch it.*
