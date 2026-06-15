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

**Implication for your roadmap:** your current loop is correctly gated "supervised, non-sensitive until egress control exists." This brief confirms that gate is not conservatism — it's the documented requirement. The egress phase (macOS `pf` allowlist → container isolation) is what unlocks unattended and sensitive use. Until then the loop stays supervised. Order of build when you get there: network allowlist FIRST (highest ROI), then workload isolation, then credential proxy.

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

As capabilities grow you'll hold more tokens (Gmail today; calendar, others later). Current state: file keyring, password injected into the safe binary's child env, same-user exposure accepted.

**The pattern to move toward (from "Caging the Agents" layer 2):** a **credential proxy sidecar** — the agent calls a broker that holds the credential and makes the authenticated call; the agent never sees the raw secret. This is the same principle as your draft-safe wrapper (the wrapper holds Gmail capability, the reader never gets the token), generalized to all secrets.

**Rules (OWASP AI Agent Security cheat sheet + LLM Top 10):**
- Least-privilege, **short-lived tokens**, narrow scopes per tool. (Your gmail.compose-only is this.)
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
