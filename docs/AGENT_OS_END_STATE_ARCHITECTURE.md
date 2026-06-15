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

This is the same pattern as the existing draft-only email loop (reader drafts, can't send), generalized to the whole system. The template is already built; the end state generalizes it.

---

## 3. The four foundations (the bedrock)

These are built as **shared substrate underneath all capabilities**, not per-capability. Building them per-capability is the rebuild trap. They must exist (at least in v1 form) before the Command Center.

### 3.1 Foundation 1 — The Dispatch/Confirm Split (structural law)
- **Gather plane:** open-ended agents. Read, research, watch, summarize, draft, propose. No action tools at all. Live behind the egress allowlist (3.2). As "wild" as desired because they cannot act.
- **Act plane:** a *fixed menu* of defined operations (send email, submit form, change a setting, control a device, move money…). Never open-ended. Every action is one of a known set, each with a policy classification (3.4).
- A gathering agent's proposal **cannot** become an action except by passing through the policy layer. There is no bypass. This is structural, not behavioral — not "the agent is told not to act," but "the agent has no capability to act."
- **Why it's foundational:** retrofitting "these agents actually can't act" onto a system that assumed they could is a teardown. Get it in first; every capability inherits it.

### 3.2 Foundation 2 — Containment (the unlock)
Built in value order (per "Caging the Agents," arXiv:2603.17419, and "Silent Egress," arXiv:2602.22450):
1. **Network egress allowlist** — default-deny, no wildcards, enforced at tool-execution/network layer (not prompt layer, which barely works). This is what lets gather agents run *wild and unattended* without being an exfiltration risk — a hijacked research agent can't phone home.
2. **Workload isolation** — agents in a container/VM, not just a user account.
3. **Credential proxy** — agents call a broker that holds secrets and makes the authenticated call; the agent never sees the raw token. (Generalizes the draft-safe wrapper to all secrets.)
- **Why it's foundational + reordered EARLY:** containment is what graduates the system out of "supervised, non-sensitive only." It has leverage no single capability has — it unlocks unattended operation for *everything*. Hence it moves ahead of new capabilities in the sequence.

**Runtime + confinement law for agents (resolved 2026-06-14 after live testing — Path B):**
A confinement model is only real if the runtime enforces it, and live testing settled which configurations actually work in OpenClaw 2026.6.5:
- `tools.exec.mode: "allowlist"` is REJECTED by the Codex harness. An `openai/*` ref defaults to Codex.
- The embedded `openclaw` runtime accepts allowlist mode but requires a separate OpenAI **API-key** auth profile (`auth.order.openai`, `agentRuntime.id: "openclaw"`) — NOT the ChatGPT/Codex subscription. (Subscription auth only works through the Codex harness.)
- `tools.exec.mode: "auto"` on Codex was tested and does NOT preserve allowlist confinement: a per-agent approvals allowlist did NOT override `auto` — an off-allowlist command (`ls /`) executed. So "auto + strict approvals" is NOT a safe confinement substitute. [Proven live 2026-06-14.]

**Decision — confined agents run the field-standard way (Path B):** default Codex runtime on the existing subscription, `tools.exec.mode: "auto"`. We do NOT enforce OS-level exec-allowlist on the reader. This matches what every OpenClaw Gmail setup does; the exec-allowlist was a non-standard belt that fought the platform and required a separate API-billing relationship.

**Why this is correct, not a compromise:** the confinement that matters is layered and runtime-independent, and the gap Path B leaves is temporary and closes as the foundations land:
- (1) **OAuth scope** (readonly+compose, no send/modify/delete) — the load-bearing control, per the field and the wild failure cases.
- (2) **Three-layer software no-send** — proven, runtime-independent; a hijacked reader CANNOT send/forward email regardless of exec mode.
- (3) **Schema-validated research channel** — blocks exfil-via-research-query.
- (4) **Egress control (Foundation 2, next)** — the real exfil defense; holds at the network layer even when the model is fully hijacked. This is what closes the serious half of the Path B gap (a hijacked reader could run read-oriented shell commands, but cannot get data OFF the machine once egress is locked).
- (5) **Workload isolation (Foundation 2, later)** — moves confined-agent shell execution into a throwaway container, closing the host-exposure half of the gap.
- (6) **Dispatch/confirm split + deny-by-default policy (Foundations 1 & 4)** — gate any action a hijacked agent could propose.

**The Path B gap, stated honestly + its expiry:** today, a reader hijacked by a malicious email could run read-oriented shell commands on the host (proven: `ls /` executes under `auto`). It CANNOT send email (blocked 3 ways) and CANNOT exfiltrate once egress lands. The reader therefore stays **supervised / non-sensitive ONLY until egress + isolation land**, at which point this gap closes more completely than an exec-allowlist ever would. This is a sequenced decision with a defined expiry, not a permanent accepted risk. **Revisit trigger:** if any confined agent must handle sensitive data unsupervised before egress/isolation exist, OR reconsider OS-level confinement (Path A: embedded runtime + API key) at that point.

**Implication:** egress (Foundation 2) is now the highest-leverage next foundation — it is both the planned exfil defense AND the control that retroactively closes the Path B gap and graduates the system out of supervised-only operation. Exec-allowlist is downgraded from a Foundation law to optional hardening, superseded by egress + isolation for the confined-agent threat.

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
- **THE PERMANENT INVARIANT — deny-by-default:** any action class not explicitly classified is treated as **confirm/high-stakes** until Daniel says otherwise. The failure mode of forgetting to classify something is "it asks unnecessarily," never "it acted when it shouldn't have." **This default does not evolve. It is a foundational law.**
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
- Phase 2 email assistant (draft-only, proven no-send, injection-resistant loop) — this is the *template* for the dispatch/confirm split, already instantiated for one capability.

**Foundations (before broad capability expansion)**
- **F-A. Containment** — egress allowlist (first), then workload isolation, then credential proxy. *The unlock; reordered early.*
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
