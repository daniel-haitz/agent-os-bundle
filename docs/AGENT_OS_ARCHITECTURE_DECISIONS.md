# Agent OS Architecture Decisions

**Status:** Approved. Effective upon commit to the canonical repository.

## Purpose and authority

This document records durable Agent OS architecture decisions.

- `CONTROL.md` records current state, phase status, blockers, next actions, and verification gates.
- `AGENT_OS_END_STATE_ARCHITECTURE.md` remains the architecture spine.
- `OPERATING_CONSTITUTION.md` governs operator behavior.
- This document records approved technical direction and the requirements that must be reflected in implementation gates.

No architecture document creates runtime authority. Authority exists only where live enforcement implements the approved design.

This document supersedes research notes and discussion artifacts for approved architecture direction after commit.

## Decision summary

| Decision | Disposition |
|---|---|
| OpenClaw remains the Agent OS runtime | KEEP |
| Domain capability brokers remain load-bearing | KEEP |
| Alternate general agent frameworks replace OpenClaw | REJECT |
| Native OpenClaw audit becomes part of F-B | ADOPT |
| Native audit replaces boundary evidence | REJECT |
| F-B becomes a hybrid evidence substrate | MODIFY |
| F-C uses native approvals plus semantic action governance | MODIFY |
| Unknown actions require confirmation | REJECT |
| Unknown actions deny | ADOPT |
| Autonomous memory promotion before governance | REJECT |
| OpenClaw upgrades occur directly in production | REJECT |
| OpenClaw 2026.7.1 receives staged qualification | ADOPT |
| F-A4 covers only IPv4/TCP proxy paths | REJECT |
| F-A4 covers DNS, IPv6, and alternate transports | ADOPT |
| OpenClaw logical agents are OS security principals by default | REJECT |
| Plugin, MCP, and connector governance is required | ADOPT |
| Current Gmail reader/researcher model assignments documented | ADOPT |
| Change-control standard establishes mandatory reconciliation between runtime state, operational state, evidence, and canonical documentation. | ADOPT |
| Change-control standard is adopted as an enforced operating model. | ADOPT |
| Cedar becomes the initial policy engine | DEFER |
| OPA becomes the initial policy engine | REJECT |

## ADR-001 — OpenClaw remains the runtime

### Decision

OpenClaw remains the Agent OS runtime and orchestration substrate.

### Rationale

OpenClaw already supplies the required agent, delegation, tool, approval, Gateway, channel, plugin, session, task, provider, and local-model surfaces.

Replacing it would introduce a second runtime, duplicate established capabilities, expand the trusted computing base, and require migration of already proven boundaries.

No reviewed alternative demonstrates a material security or scalability advantage sufficient to replace OpenClaw.

### Consequences

- Agent OS hardens OpenClaw instead of rebuilding an agent runtime.
- OpenClaw defaults are not treated as Agent OS security guarantees.
- Security-critical behavior is verified against the installed version.
- Upgrades require formal qualification.

## ADR-002 — Domain capability brokers remain load-bearing

### Decision

The Gmail broker pattern remains the reference architecture for credential-bearing and consequential external capabilities.

A capability broker:

- runs under a dedicated identity where appropriate;
- owns the external credential;
- exposes a narrow semantic API;
- omits forbidden provider operations;
- validates requests deterministically;
- emits domain audit evidence;
- does not reveal a general provider token to callers.

### Rationale

The broker narrows authority at the credential-use boundary. General connectors, broad MCP servers, direct SDK clients, and prompt restrictions do not provide the same structural limitation.

### Consequences

- The Gmail broker remains.
- Future sensitive domains use brokers when general connectors expose excessive authority.
- Broker correctness and complete mediation remain separate gates.
- Credential recovery restores credentials to broker custody only.

## ADR-003 — Alternate frameworks do not replace Agent OS

### Decision

LangGraph, OpenAI Agents SDK, Microsoft Agent Framework, Semantic Kernel, AutoGen, CrewAI, and similar frameworks do not replace OpenClaw or the Agent OS security architecture.

MCP remains an interoperability protocol, not an authorization boundary.

### Rationale

These frameworks provide useful workflow and approval patterns but do not replace:

- OS-user isolation;
- operator-owned controls;
- credential brokers;
- host egress enforcement;
- complete mediation;
- semantic action authorization.

Adoption as a second runtime would add another session, memory, tool, approval, telemetry, and upgrade surface.

### Consequences

Patterns may be adopted without adopting replacement runtimes:

- durable interruption and idempotent side effects;
- approval-time revalidation;
- deterministic workflows for known processes;
- narrow MCP contracts and audience-bound authorization.

A second orchestration runtime requires evidence of a material blocker and explicit architecture approval.

## ADR-004 — Adopt native OpenClaw audit as one evidence source

### Decision

After qualification, native OpenClaw audit becomes the canonical Gateway run/tool index.

It does not replace broker logs, proxy logs, notification-delivery evidence, or domain reconciliation.

### Rationale

Native audit reduces duplicate implementation while retaining stable Gateway metadata.

Its limits include:

- metadata-only records;
- finite retention and bounded storage;
- background writing;
- incomplete coverage outside shared Gateway paths;
- no proof that an unrecorded action did not occur;
- no cryptographic event-log tamper evidence.

### Consequences

- Do not build a duplicate generic Gateway audit database.
- Retain boundary-owned evidence.
- Maintain an audit coverage matrix.
- Export sanitized evidence when longer retention is required.
- Do not claim complete mediation from native audit.

## ADR-005 — F-B is a hybrid evidence substrate

### Decision

F-B combines qualified native OpenClaw telemetry with minimal Agent OS correlation, boundary evidence, notification proof, retention, alerting, and reconciliation.

### Required design

F-B must provide:

- one run ID born at ingress;
- propagation through delegation, broker, proxy, and notification;
- native Gateway run/tool metadata where qualified;
- broker and proxy logs as boundary-authoritative evidence;
- explicit terminal outcomes;
- delivered-notification evidence;
- missing-counterpart detection;
- audit-silence detection;
- sanitized retention longer than the measurement period;
- a coverage and blind-spot matrix;
- integrity checkpoints proportional to the threat model.

Sensitive prompts, emails, tool arguments, and tool results remain excluded unless separately approved.

Replay, where required, uses sanitized decision envelopes and deterministic inputs rather than retained sensitive content.

### Rejected work

F-B will not build:

- a duplicate generic audit database;
- a second full tracing platform;
- a dashboard before native Control UI evaluation;
- raw-content telemetry;
- per-event blockchain-style logging.

## ADR-006 — F-C uses semantic action governance

### Decision

F-C uses:

- native OpenClaw approvals as approval transport;
- plugin permission requests where applicable;
- the Policy plugin for configuration conformance;
- a minimal Agent OS semantic action catalog;
- deterministic enforcement immediately before effect.

The Policy plugin is not a runtime authorization engine.

F-C starts with the minimal semantic action catalog required for approved effectful operations. Full action-envelope machinery, replay controls, nonce binding, and idempotency infrastructure are deferred until act-plane expansion requires them.

Deferral limits implementation scope only. It does not permit effectful operations outside the registered action catalog.

### Minimal action definition

Every effectful action must define:

- stable action ID and version;
- effect class;
- target/resource type;
- canonical target identity;
- canonical normalized arguments;
- sensitivity;
- reversibility;
- scope or quantity limits;
- gate: `auto`, `confirm`, or `deny`;
- permitted approver;
- whether durable approval is permitted;
- policy version/hash;
- expiry when approval is time-bound.

As the act plane expands, actions that can be retried, resumed, replayed, or partially applied must add the required full-envelope controls before they become executable:

- canonical action-envelope hash;
- one-shot nonce where replay is possible;
- idempotency key where duplicate effects are possible;
- result reconciliation for interrupted or retried operations.

Approval binds to the canonical action identity and normalized effect. Changes to target, arguments, version, policy, or expiry invalidate the approval.

The action is revalidated immediately before execution.

### Consequences

- Native approval interfaces are reused.
- Semantic authorization remains under Agent OS control.
- Models cannot approve, broaden, reinterpret, or bypass decisions.
- High-risk actions prohibit durable approval.
- Retried or resumed effectful actions require idempotency and result reconciliation before they are admitted to the executable catalog.
- Cedar remains deferred.
- OPA is not introduced for the current scope.

## ADR-007 — Unknown actions deny

### Decision

Any unregistered or unknown semantic action is denied.

### Rationale

Confirmation is trustworthy only when the system can identify, normalize, render, bind, and enforce the proposed effect.

An unknown action lacks that contract. Human confirmation cannot repair an undefined enforcement boundary.

### Classification

- Registered, low-risk, bounded, reversible action → eligible for `auto`.
- Registered consequential action → `confirm`.
- Registered forbidden action → `deny`.
- Unregistered or unknown action → `deny`.

A new action must be reviewed and registered before it becomes executable.

### Consequences

This replaces the earlier rule that treated unclassified actions as confirm/high-stakes. The auto/confirm/deny architecture remains; its default becomes genuinely fail-closed.

## ADR-008 — Memory cannot create authority

### Decision

Autonomous memory promotion is prohibited until memory governance is implemented.

Conversation history, memory files, summaries, embeddings, dreaming output, inferred commitments, and retrieved context are not authoritative policy.

### Required memory metadata

Action-relevant memory must represent:

- provenance and source;
- observed versus asserted status;
- authority class;
- owner or reviewer;
- creation and observation time;
- freshness and expiry;
- sensitivity;
- scope;
- confidence;
- derivation;
- contradiction state;
- safe-to-act status;
- promotion history;
- revocation or tombstone state.

### Authority tiers

1. **Observed/untrusted:** external content and working notes.
2. **Reviewed knowledge:** operator-reviewed durable facts and preferences.
3. **Authoritative control:** approved control, architecture, configuration, approval, and policy artifacts outside model memory.

Automated processes cannot promote content into authoritative control.

### Consequences

- Native memory may support supervised notes.
- Action-sensitive promotion requires deterministic validation and trusted review.
- Compaction, dreaming, summarization, retrieval, repetition, and embedding cannot raise authority.
- Sensitive remote embedding requires separate approval.
- Memory autonomy remains gated by stale, contradictory, malicious, truncated, and revoked-memory tests.

## ADR-009 — OpenClaw upgrades require qualification

### Decision

OpenClaw upgrades are security-boundary changes and require staged qualification.

OpenClaw `2026.7.1` is qualified after current Gmail complete-mediation and F-A4 transport gaps are addressed and before F-B/F-C implementation.

### Required qualification

- Version pin and release/security review.
- Pre-upgrade inventory.
- Snapshot and proven rollback.
- Staged installation.
- Schema and default comparison.
- Plugin, app, MCP, tool, and connector comparison.
- Ownership and permission verification.
- F-A1 through F-A4 regression.
- Native-audit coverage measurement.
- Policy-plugin conformance evaluation.
- Approval failure, mutation, and replay testing.
- Restart and reboot validation.
- Rollback execution.

### Consequences

- No production upgrade based only on release notes.
- Every relevant boundary reopens for validation after an upgrade.
- Version adoption requires recorded qualification evidence.

## ADR-010 — F-A4 covers expanded transport paths

### Decision

F-A4 covers all practical network paths available to the contained Gateway identity, not only proxied IPv4/TCP traffic.

### Required coverage

F-A4 must address and test:

- raw DNS;
- arbitrary query-name behavior;
- approved resolver identity;
- IPv4;
- IPv6;
- direct-IP connections;
- alternate DNS resolvers;
- TCP outside the proxy;
- UDP outside approved requirements;
- UDP/443 and QUIC;
- proxy-environment bypass;
- proxy or resolver failure;
- service restart and host reboot.

Preferred design: `openclawgw` sends external hostname-bearing traffic only to the loopback operator-owned proxy, and the separately owned proxy performs external resolution.

Any raw Gateway DNS exception must be explicitly justified, destination-constrained, monitored, and negative-tested.

### Rationale

Broad DNS access can permit data exfiltration even when HTTP traffic is forced through a proxy. IPv6 and alternate transports can bypass rules proven only against IPv4/TCP.

### Consequences

- Prior proxy/pf positive-path evidence remains valid but is insufficient for F-A4 closure.
- DNS tightening is an architecture gate.
- IPv4 and IPv6 require equivalent enforcement.
- F-A4 closure requires transport-level negative evidence, persistence testing, and reboot validation.
- F-A4 closure also requires minimal durable evidence: persistent logs, ownership-controlled evidence storage, retention longer than the validation window, and proof that validation events remain findable after service restart and host reboot.
- OpenClaw security-audit loopback-only Gateway findings are accepted only when the Gateway is not exposed through reverse proxy, tunnel, public listener, or other external ingress.

## ADR-011 — OpenClaw logical agents are not OS security principals by default

### Decision

OpenClaw agent identities provide workflow separation, configuration scoping, model/tool selection, and delegation structure.

They must not be described as OS-level isolation unless live runtime evidence proves separate OS users, process boundaries, permissions, and inaccessible credential paths.

### Rationale

Agent names such as `main`, `gmail-reader`, and `researcher` can constrain workflow and tool selection, but that is not equivalent to OS security principal separation.

Gmail safety comes from broker-owned credentials, broker semantic controls, fail-closed execution allowlists, and removal of bypass connectors. It does not come from treating OpenClaw logical agent names as operating-system identities.

### Consequences

- Documentation must avoid claims such as "only the confined reader can access Gmail" unless the claim is scoped to the broker contract and runtime evidence.
- Preferred language: "The Gmail capability is constrained through broker-owned credentials and broker semantic controls."
- Phase exits must distinguish workflow separation from OS-level isolation.
- Future claims of OS isolation require live evidence for users, groups, processes, permissions, credential paths, and denial tests.

## ADR-012 — Plugin, MCP, and connector governance

### Decision

Plugins, MCP servers, apps, connectors, and third-party extensions are capability expansion and trust-boundary changes.

They require explicit governance before installation, enablement, permission expansion, or use in a security-sensitive path.

### Requirements

Before installation, enablement, or permission expansion, the operator must:

- inventory read, write, network, credential, filesystem, and effectful-action scope;
- identify whether the surface bypasses an approved broker;
- classify exposed tools as gather-only or effectful;
- require explicit approval for effectful or credential-bearing surfaces;
- define rollback, disablement, and removal steps;
- include the surface in OpenClaw qualification and F-A regression checks;
- document connector synchronization behavior when it affects complete mediation.

MCP is an interoperability protocol, not an authorization boundary. Plugin permission prompts are useful controls and evidence, but they do not replace Agent OS broker, containment, and semantic-action policy boundaries.

### Consequences

- Direct connectors for brokered domains are bypass risks until proven unavailable to the relevant runtime.
- Third-party extensions are not adopted merely because they expose useful capabilities.
- F-A4 and later qualification must compare plugins, apps, MCP servers, tools, and connectors before and after changes.
- Capability expansion remains blocked until applicable foundation gates pass.

## ADR-013 — Current Gmail reader and researcher model assignments

### Decision

For the current OpenClaw `2026.6.11 (e085fa1)` baseline:

- `gmail-reader` uses `ollama/qwen3-coder:30b`.
- `email-researcher` uses `openai/gpt-5.5`.

### Rationale

The Gmail reader handles broker-mediated mailbox interaction and should remain on a local model path with narrow execution allowlisting, broker-owned Gmail credentials, and no direct Gmail connector authority.

The email researcher handles external research after the F-A3 schema gate and does not receive raw Gmail credentials or raw mailbox access through the broker.

### Security implications

- These assignments are workflow and capability choices, not OS security principal isolation.
- Model assignment does not prove complete mediation; the direct Gmail connector bypass remains an F-A4 blocker until removed and negative-tested.
- Changes to either model assignment require read-only runtime evidence, regression of F-A1/F-A3-relevant gates, and documentation reconciliation.
- The local reader model reduces dependency on external model transport for broker-mediated Gmail reading, but F-A4 egress containment remains required before sensitive-data holds can lift.

## ADR-014 — OpenClaw 2026.6.11 baseline

See `docs/ADR-014_OPENCLAW_2026_6_11_BASELINE.md`.

## ADR-015 — Change Control Standard adoption

### Decision

`docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md` is adopted as mandatory operating control, not advisory documentation.

### Consequences

- Runtime, security, architecture, documentation, and capability changes must follow the required lifecycle.
- Wrap-up and publication tooling must check baseline drift, evidence linkage, open gates, publication manifest coverage, and obligation preservation.
- Documentation changes cannot remove obligations, evidence, blockers, or phase gates without classification.

## Security obligation register references

The obligation register in `docs/AGENT_OS_OBLIGATION_REGISTER.md` is the canonical index for security-critical obligations that must not disappear during document refactoring. The following references preserve prior obligations without expanding current scope:

- Aquaman source audit and native SecretRef comparison remain a Phase 6 secrets-governance obligation before any real SSN or equivalent sensitive secret touches Aquaman or a substitute secret-isolation layer.
- ClawGuard source review remains an F-B observability-governance obligation before ClawGuard or an equivalent hash-chained audit component carries audit-integrity trust.
- Browser fill tool-side SecretRef resolution remains a Phase 6 secrets-governance obligation before browser form-fill may handle real sensitive values.
- OpenAI key plaintext custody remains an F-A4/F-B credential-custody obligation because gateway-readable model-provider credentials are not made safe by documentation or model assignment.
- Gmail recovery passphrase escrow remains a Gmail recovery-governance backlog obligation. The current approved state is operator-held-only passphrase custody in `docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md`; no operational escrow change is authorized by this record.

## OpenClaw Native Capability Reconciliation

Agent OS follows a configure-native-capability-first rule: configure and validate OpenClaw native controls before building custom infrastructure. Custom development is permitted only where native controls do not satisfy Agent OS governance, evidence, or boundary requirements.

| Capability | OpenClaw Native Capability | Agent OS Responsibility |
|---|---|---|
| Credential handling | SecretRef, secret audit, redaction | Governance policy, evidence, unsupported browser credential gaps, and broker custody where provider scopes exceed allowed semantics |
| Tool permissions | Sandbox, filesystem permissions, network controls | Action policy, approval rules, ownership boundaries, and proof that configured controls fail closed |
| Approval workflows | `elevatedAccess` and confirmation controls | Define consequential-action policy, semantic action registration, expiry, and revalidation rules |
| Observability | Activity, OTEL spans, native diagnostics | Evidence model, retention, correlation, boundary-owned logs, and governance interpretation |
| MCP/tool integration | Native MCP capability | Connector governance, approval, complete-mediation checks, and broker-bypass prevention |

Agent OS will not recreate OpenClaw primitives where native capabilities satisfy the control requirement.

Custom development remains limited to:

- governance layer;
- typed handoffs;
- evidence model;
- executive operating logic;
- gaps not solved by OpenClaw.

OpenClaw SecretRef covers supported credential paths. Browser-mediated credential injection remains separate and blocked until a credential firewall capability or equivalent Agent OS-controlled solution is validated.

## F-A4 Final Architecture Decision

F-A4 uses OpenClaw native enforcement primitives where they fit, but the final boundary remains Agent OS-governed and evidence-driven.

| Area | Decision | Rationale |
|---|---|---|
| Credential handling | Gmail broker plus OpenClaw SecretRef/native secrets for supported runtime credentials | SecretRef reduces raw credential exposure for supported paths, but it does not replace broker semantic controls or broker-owned Gmail custody. Browser-mediated credential injection remains blocked until a credential firewall or equivalent Agent OS-controlled solution is validated. |
| Egress | Repair the operator-owned loopback CONNECT proxy with pf backstop | The existing proxy/pf design is still the narrowest F-A4 containment path. Native OpenClaw controls and diagnostics are validation/enforcement primitives, not a complete replacement for the host network boundary. Docker/container egress is not selected for this host. |
| Validation | Operator-owned read-only validation wrapper | The non-privileged `agent` user cannot read locked OpenClaw config by design. Validation must run through an operator-owned path that preserves the root-owned tamper lock and captures evidence as `openclawgw`, `gmailbroker`, or root only where required. |
| Governance | Existing Change Control Standard, wrap-up gates, obligation register, and publication manifest | Governance remains the Agent OS-owned layer that turns runtime facts into traceable closure claims and prevents drift. |

Command Center is not part of F-A4. It remains downstream of F-A4 containment, F-B evidence substrate, and F-C semantic-action governance.

## Resulting roadmap

### KEEP

- OpenClaw runtime.
- Broker architecture.
- OS-user boundaries where live runtime evidence proves them.
- Typed handoffs.
- Operator-owned enforcement.
- Gather/act separation.
- Auto/confirm/deny classification.
- Foundations-first sequence.

### MODIFY

- F-B becomes hybrid native-plus-boundary observability.
- F-C uses native approvals plus minimal semantic action governance.
- Unknown actions deny.
- Memory promotion becomes governed.
- F-A4 expands across relevant network paths.
- OpenClaw logical agents are documented as workflow identities, not OS security principals.
- Plugin, MCP, app, and connector governance becomes explicit.

### REORDER

1. Read-only F-A4 prerequisite validation.
2. Broker reliability validation and repair if drift is found.
3. Broker workflow proof with durable evidence.
4. Direct Gmail connector containment.
5. F-A4 transport reconciliation and completion.
6. OpenClaw `2026.7.1` qualification.
7. Full foundation regression.
8. F-B implementation.
9. Minimum F-C implementation.
10. F-D generalization.
11. Capability expansion.

### REMOVE

Remove planned custom work for:

- a duplicate generic audit database;
- a general policy engine at current scale;
- an observability dashboard before native UI evaluation;
- autonomous memory before governance;
- a second agent runtime.

No completed foundation phase is reopened or removed without new evidence invalidating its exit criteria.

### ADD

- Upgrade qualification.
- Semantic action identity and normalized-effect binding.
- Minimal semantic action catalog before full action-envelope machinery.
- One-shot approval and idempotency when act-plane expansion requires replay or duplicate-effect protection.
- Audit coverage reconciliation.
- Delivered-notification evidence.
- Audit-silence monitoring.
- DNS, IPv6, QUIC, and direct-IP testing.
- Restore and rollback drills.
- Memory-promotion governance.
