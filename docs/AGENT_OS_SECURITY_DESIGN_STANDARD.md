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

## Native Enforcement Preference

Agent OS uses OpenClaw native enforcement mechanisms where available. Custom security controls exist only where governance requirements exceed runtime capability or OpenClaw does not provide an equivalent control.

Native controls to configure and validate first include:

- SecretRef;
- sandboxing;
- `elevatedAccess`;
- MCP controls;
- security audit.

SecretRef covers supported credential types. Browser-mediated credential automation remains blocked until a credential firewall capability exists or an equivalent Agent OS-controlled solution is validated.

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
| Egress control (data can't leave) | — | Deferred capability. Required F-A4 dependency; managed proxy and pf evidence is not accepted until connector bypass removal, transport coverage, persistence, reboot validation, and durable evidence gates pass. |

---

## 5. Known gaps & residual risks (be honest, track them)

1. **Research-question smuggle path (the gap Codex flagged).** The reader emits "research questions" to the researcher. If the reader is injected, those questions are a potential exfil channel. The standard's fix is *strong context-minimization*: the research question must be a MINIMIZED, STRUCTURED extraction (ideally constrained to a fixed schema / enum of question types), not free-form text. Treat free-form reader→researcher text as a smuggle path until it's schema-constrained.

2. **No provenance tracking.** Agent OS uses agent-separation (Dual LLM), not value-level provenance (Code-Then-Execute/CaMeL). This is a deliberate weight trade-off. It means the boundary is "the researcher never receives raw email," not a cryptographic guarantee no email-derived byte reaches a query. Acceptable for supervised, non-sensitive use; NOT acceptable for unattended sensitive mail.

3. **Egress control remains deferred.** Nothing currently accepted prevents a compromised plane from exfiltrating via an allowed channel. Loop is therefore gated: supervised, non-sensitive ONLY until F-A4 connector containment, transport coverage, persistence, reboot validation, and durable evidence gates pass.

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
