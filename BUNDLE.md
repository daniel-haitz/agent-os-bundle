# Agent OS Gmail Containment Tranche - Independent Review Bundle

Generated: `2026-07-21T20:31:05Z`

Source repository: `git@github.com:daniel-haitz/agent-os.git`

Source commit: `a2a45413f24a1e079b9428f22483b875640fa3d1`

Source commit subject: `test(f-a4): prove broker-only gmail mediation`

Canonical OpenClaw baseline: `2026.6.11 (e085fa1)`

Review purpose: independent evidence and architecture review of the completed Agent OS Gmail-containment tranche before the next implementation phase.

This bundle is documentation and evidence packaging only. It must not be treated as production authorization, connector authorization, runtime authorization, OAuth authorization, or permission to begin the next implementation phase.

## Reviewer Instructions

Claude is asked to independently evaluate whether the committed repository evidence supports the completed Gmail-containment tranche and whether any finding must block the next implementation phase.

Review the bundle as a closed evidence packet. Do not execute changes, do not request live Gmail access, do not call connectors, and do not provide implementation drops unless explicitly requested later.

The review should answer:

1. Whether locked-sequence items 1 through 3 are actually supported by committed evidence.
2. Whether code, audits, and canonical status agree.
3. Whether any claims exceed their evidence boundary.
4. Whether accepted architecture contains a concrete security or operability defect.
5. Whether the remaining F-A4 to F-B to F-C to F-D roadmap is properly sequenced.
6. Why the item-2 OAuth/recovery effort became excessively iterative.
7. What process controls should prevent similar overengineering in future milestones.

## Authority Hierarchy

The governing hierarchy is taken from `OPERATING_CONSTITUTION.md` and `CONTROL.md`:

1. Live runtime state is authoritative for observed facts, but this bundle does not perform live runtime inspection.
2. `CONTROL.md` is authoritative for declared phase state, blockers, accepted decisions, and the next bounded task.
3. Canonical architecture documents govern approved end-state design, trust boundaries, invariants, and phase ordering.
4. Historical documents are evidence and context only unless `CONTROL.md` reactivates them.

Relevant authority paths at source commit `a2a45413f24a1e079b9428f22483b875640fa3d1`:

- `CONTROL.md`
- `OPERATING_CONSTITUTION.md`
- `docs/ADR-015_OPENAI_CREDENTIAL_PROXY.md`
- `docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md`
- `docs/F-A4_OPENAI_PROXY_PROGRESS_CHECKPOINT.md`
- `docs/F-A4_OPENAI_PROXY_CUTOVER_PACKAGE.md`
- `docs/AGENT_OS_OBLIGATION_REGISTER.md`
- `docs/AGENT_OS_END_STATE_ARCHITECTURE.md`
- `docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md`
- `docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md`
- `docs/OPENCLAW_BUILD_PLAN.md`

Conflict handling for this review: if any bundle statement conflicts with `CONTROL.md`, treat `CONTROL.md` as authoritative and report the conflict as a finding. Do not silently reconcile.

## Current Status

Canonical posture at the source commit:

- F-A4: `OPEN`
- F-A4A / ADR-016: `ACTIVE`
- F-A4B: `PAUSED`
- Locked-sequence item 1: `COMPLETE`
- Locked-sequence item 2: `COMPLETE`
- Locked-sequence item 3: `COMPLETE`
- Known Gmail connector/broker mediation tranche: `COMPLETE within its stated evidence boundary`
- Production executable: `NO-GO`
- Operator OpenAI cutover dry-run: `NOT AUTHORIZED`
- Production cutover: `NO`

Approved current action:

> Freeze the completed Gmail containment tranche and prepare the canonical Agent OS bundle for independent Claude review before beginning the next implementation phase.

No production authorization is introduced by this bundle.

## Accepted Architecture

### Threat Model Summary

Agent OS treats broad agent access to provider tools, credentials, email content, and network egress as security boundaries. The accepted design requires specific capability brokers, constrained execution surfaces, documented evidence, and confirmation gates rather than general-purpose "agent can do email" access.

The Gmail-related target is not universal Gmail impossibility. The completed tranche is bounded to:

- broker reliability metadata;
- confined Gmail broker `health_check` and bounded `search_threads`;
- known Codex Apps Gmail connector unavailability at the tested OpenClaw inventory boundary;
- continued broker availability after the connector-negative proof.

### Credential-Broker Boundary

The Gmail path uses a dedicated `gmailbroker` custody boundary. Gmail credentials remain outside ordinary agent custody. The approved OpenClaw-facing path uses a fixed broker client and a broker socket, not raw Gmail credentials.

Canonical supporting references:

- `docs/AGENT_OS_END_STATE_ARCHITECTURE.md`: Gmail implements the credential/capability broker pattern under dedicated user `gmailbroker`.
- `docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md`: the broker path is built and proven for no-send broker behavior, while alternate connector surfaces remain part of F-A4 evidence boundary.
- `CONTROL.md`: Gmail credentials remain in broker custody and the known connector surface is unavailable at the tested inventory boundary.

### Draft-Only / No-Send Enforcement

The approved Gmail broker path is draft-only/no-send. The completed tranche does not claim every possible Gmail access path has been universally removed. It confirms the known Codex Apps Gmail connector surface was unavailable to OpenClaw at the tested inventory boundary and that the confined broker remained available.

### Schema-Constrained Reader-To-Researcher Handoff

F-A3 historical evidence remains accepted for its original boundary. It uses typed, canonical handoff between reader and researcher. `CONTROL.md` records that bounded regression on OpenClaw `2026.6.11 (e085fa1)` remains required before F-A4 closure.

### Egress-Control Posture

F-A4 remains open. The completed Gmail tranche is not F-A4 closure. DNS, IPv6, alternate transport, `pf`, persistence, reboot, and production cutover remain later gates.

### ADR-016 Residual Risk

`docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md` accepts a reduced OpenAI objective for the current platform release:

- the real upstream OpenAI credential must be outside OpenClaw-readable state after authorized cutover;
- normal OpenAI provider traffic routes through a credential-injecting proxy;
- alternate authenticated direct OpenAI credential sources are removed or verified absent;
- the proxy strips caller credentials and injects broker-owned upstream credentials;
- Gmail, Ollama, Telegram, and research/web functionality remain intact;
- structural denial of every possible direct OpenAI network connection from a fully compromised host Gateway is not claimed.

### F-A4A And F-A4B

- F-A4A / ADR-016 is the active host-native reduced-objective lane.
- F-A4B Agent Cell is paused as a research and hardening lane. It is not failed and not production-authorized.
- No future operator should reopen F-A4B merely because a new OpenClaw version, plugin, or speculative control appears.

## Completed Item 1 - Broker Reliability Metadata

Milestone commit: `fce612918eb340cf8957199b5cfc133300e81166`

Primary evidence:

- `audits/F-A4-broker-reliability-validation.md`
- implementation/test reference: `scripts/fa4-broker-reliability-readonly.mjs`

Objective:

> Validate broker reliability remains intact: socket directory persistence, ownership, and client path match the hardened live baseline.

Evidence summary:

- Broker runtime directory `/var/run/agent-os`: `gmailbroker:gmailbroker-clients 0750`
- Broker socket `/var/run/agent-os/gmail-broker.sock`: `gmailbroker:gmailbroker-clients 0660`
- Approved broker client path `/Users/agent/.openclaw/scripts/gmail-broker-client.mjs`: `root:openclawgw 0640`
- Launchd label `system/ai.agent-os.gmail-broker`: running as `gmailbroker`
- PathState `"/var/run/agent-os" => true`
- Result: `4/4 PASS`
- Classification: `read-only-live-broker-metadata`
- `productionEvidence: false`
- `broker operation executed: false`
- `credentialAccess: false`
- `runtimeMutation: false`

Evidence boundary:

Item 1 proves live metadata only. It does not prove broker workflow, Gmail health/search, exclusive Gmail mediation, connector disablement, restart persistence, reboot persistence, live OpenAI proxy cutover, production credential custody, live broker integration, or containment closure.

## Completed Item 2 - Confined Gmail Broker Workflow

Milestone commit: `6fb52acbf0a134af99433ff06cfe1e9a84d13342`

Primary evidence and scripts:

- `audits/F-A4-gmail-broker-workflow-validation.md`
- `scripts/fa4-gmail-broker-audit-witness.py`
- `scripts/fa4-gmail-broker-workflow-readonly.mjs`
- `scripts/run-fa4-gmail-broker-witness.sh`

Finalized script hashes:

- Witness: `fd4f1605baefe5dbe47a9c4c1f631ebf122ab7b5da61cf527b371b8b4076d6ca`
- Workflow: `531150502c8e6eb721e10e6e88ef46366f7cfc30fbee23caad9a9f04fd0a8714`
- Launcher: `0508c22061612058a0f039ab58ac4347ac3563d8386798e09dd5ad3c82a2d319`

Objective:

> Prove broker workflow: confined Gmail broker `health_check` and bounded `search_threads` succeed through the approved client path and durable broker audit evidence exists.

Successful evidence:

- Run root: `/private/tmp/fa4-gmail-broker-workflow-E0621484-3327-4A60-A3D0-5C5740E2CDCF`
- Evidence path: `/private/tmp/fa4-gmail-broker-workflow-E0621484-3327-4A60-A3D0-5C5740E2CDCF/gmail-broker-workflow-evidence.json`
- Evidence owner/group/mode: `agent:staff 0600`
- Evidence file SHA-256: `071ff92af8db66d15bce9b7444ada26834b7045a31566cf329d6994de53a6e07`
- Internal evidence hash: `934a50af46e98b3b3b597f4c79bb146a096e730b1cc9bd7f5e675e6ffe32e3a5`

Validated workflow:

1. `health_check`
2. `search_threads`

Bounded search:

- Query class: `relative-recency-1d`
- Source-bound query: `newer_than:1d`
- Requested limit: `1`

Durable audit sequence:

1. `health_check` request
2. `health_check` result, status `ok`
3. `search_threads` request
4. `search_threads` result, status `ok`

The item-2 evidence states that request/result correlations matched within each method pair and no third broker method was accepted.

Recorded posture flags:

- `productionEvidence: false`
- `credentialAccess: false`
- `gmailMutation: false`
- `rawGmailApiAccess: false`
- `connectorAccess: false`
- `serviceMutation: false`

Non-live closeout validation:

- Python witness compile: PASS
- Node workflow syntax check: PASS
- Shell launcher syntax check: PASS
- Launcher preflight: PASS
- Ordinary workflow self-test: `42/42 PASS`
- Elevated witness self-test: `100/100 PASS`
- `git diff --check`: PASS
- Targeted secret scan: PASS

Evidence boundary:

Item 2 is classified as `read-only-live-gmail-broker-workflow`. It is not production evidence, exclusive Gmail mediation proof, connector disablement proof, production OpenAI proxy validation, production credential custody proof, containment closure, restart persistence proof, or reboot persistence proof.

### Item-2 OAuth Recovery Context

Before the successful workflow proof, the operator completed a one-time Gmail read-only OAuth recovery under the `gmailbroker` custody boundary.

This recovery is prerequisite context only. It is not evidence that OAuth was the historical root cause of earlier `gmail_error` failures. The accepted historical diagnosis remains `PRECISE_REASON_UNAVAILABLE`.

No OAuth URL, callback, authorization code, account address, credential, keyring password, client secret, token, or Gmail message content is recorded in committed evidence. The recovery itself performed no Gmail data operation.

## Completed Item 3 - Known Gmail Connector Unavailability And Broker Availability

Milestone commit: `a2a45413f24a1e079b9428f22483b875640fa3d1`

Primary evidence:

- `audits/F-A4-gmail-connector-disablement-validation.md`
- `audits/F-A4-gmail-connector-negative-proof.json`
- `audits/F-A4-gmail-broker-only-workflow-evidence.json`

Required evidence hashes:

- Connector-negative evidence: `9e93a7a91bd732366129dd21f4f628edf1a73b055682ca81c11ba4a8277117e6`
- Broker workflow evidence: `bc3c3d23a9eadd999772ae358fcfd200917071ba9b9ba788279ebf1d85de329c`

Known connector identities:

- App: `gmail`
- Connector id: `connector_2128aebfecb84f64a069897515042a44`
- Remote plugin id: `plugin_connector_1p_95d39881713c8191931482a62d6edff9`
- Historical tool namespaces: `codex_apps__gmail`, `mcp__codex_apps__gmail*`

Authoritative OpenClaw configuration:

- Path: `/Users/agent/.openclaw/openclaw.json`
- Expected metadata: `root:openclawgw 0440`, regular file, non-symlink

Item-3 result:

- The known Gmail connector surface was already unavailable in the local OpenClaw plugin inventory.
- No Gmail connector configuration mutation was required for the successful proof.
- No connector dispatch occurred.
- No Gmail API/provider operation occurred.
- No Gmail-derived content was returned.
- Desktop Codex mutation was recorded as `false`.
- Service restart executed was recorded as `false`.

Connector-negative evidence fields:

- Schema: `fa4-gmail-connector-negative-proof-v2`
- `ok: true`
- Gmail candidate count: `0`
- Gmail connector available: `false`
- Connector dispatch executed: `false`
- Gmail API/provider operation executed: `false`
- Gmail-derived content returned: `false`
- Desktop Codex mutation: `false`
- Service restart executed: `false`
- `productionEvidence: false`
- `credentialAccess: false`
- `gmailMutation: false`

Positive broker proof fields:

- Schema: `fa4-gmail-broker-workflow-evidence-v1`
- Classification: `read-only-live-gmail-broker-workflow`
- Workflow validation succeeded: `true`
- Methods executed in order: `health_check`, `search_threads`
- Search limit: `1`
- Search query: source-bound by the frozen workflow hash to `newer_than:1d`
- Audit match count: `2`
- Underlying audit sequence: `health_check` request/result, then `search_threads` request/result
- No third broker method accepted
- Request/result correlations matched within each method pair
- `productionEvidence: false`
- `credentialAccess: false`
- `gmailMutation: false`
- `rawGmailApiAccess: false`
- `connectorAccess: false`
- `serviceMutation: false`

Item 3 proves:

- the known Codex Apps Gmail connector surface was unavailable to OpenClaw at the tested inventory boundary;
- no connector dispatch or Gmail provider operation occurred in the negative proof;
- the confined Gmail broker remained available.

Item 3 does not prove:

- universal prevention of every conceivable Gmail access path;
- restart persistence;
- reboot persistence;
- containment closure;
- production readiness;
- production credential custody;
- production OpenAI proxy validation.

### Incidental OpenClaw Bookkeeping Migration

During the first local plugin-inventory command in the item-3 proof, OpenClaw reported automatic legacy-state bookkeeping migration:

- update-check state migrated to shared SQLite state;
- legacy update-check source archived to `/Users/agent/.openclaw/update-check.json.migrated`;
- one legacy config-health entry was migrated;
- one conflicting legacy config-health entry remained at `/Users/agent/.openclaw/logs/config-health.json`.

Later inventory output continued to warn that the conflicting legacy config-health entry remained.

This was an incidental OpenClaw CLI state-migration side effect. It was not a Gmail connector change. It did not prove restart or reboot persistence. No Gmail connector/provider operation occurred, no Gmail configuration change was required, no service restart occurred, and desktop Codex was not intentionally modified.

## Source And Evidence Hashes

| Path | SHA-256 |
|---|---|
| `scripts/fa4-gmail-broker-audit-witness.py` | `fd4f1605baefe5dbe47a9c4c1f631ebf122ab7b5da61cf527b371b8b4076d6ca` |
| `scripts/fa4-gmail-broker-workflow-readonly.mjs` | `531150502c8e6eb721e10e6e88ef46366f7cfc30fbee23caad9a9f04fd0a8714` |
| `scripts/run-fa4-gmail-broker-witness.sh` | `0508c22061612058a0f039ab58ac4347ac3563d8386798e09dd5ad3c82a2d319` |
| `audits/F-A4-gmail-connector-negative-proof.json` | `9e93a7a91bd732366129dd21f4f628edf1a73b055682ca81c11ba4a8277117e6` |
| `audits/F-A4-gmail-broker-only-workflow-evidence.json` | `bc3c3d23a9eadd999772ae358fcfd200917071ba9b9ba788279ebf1d85de329c` |

## Canonical Consistency Notes

The canonical documents reviewed agree that:

- locked-sequence items 1 through 3 are complete;
- the Gmail connector/broker mediation tranche is complete only within its stated evidence boundary;
- F-A4 remains open;
- F-A4A / ADR-016 remains active;
- F-A4B remains paused;
- production execution and operator OpenAI cutover dry-run remain unauthorized;
- the next action is independent review of this tranche before the next implementation phase.

No canonical conflict was identified while preparing this bundle. Claude should independently verify this against the cited source paths.

## Unresolved Obligations

Open obligations remain. The Gmail tranche does not close them.

From `docs/AGENT_OS_OBLIGATION_REGISTER.md` and `CONTROL.md`:

- OpenAI key plaintext custody flag remains open until a later authorized cutover removes or verifies absent OpenClaw-readable upstream OpenAI credential sources.
- OpenAI proxy production cutover execution remains open and unauthorized.
- F-A4B Agent Cell strong-containment qualification remains open as a paused hardening lane.
- Gmail recovery passphrase escrow posture remains open under the Gmail recovery runbook.
- OpenClaw security and release monitoring remains open.
- F-A4 DNS, IPv6, alternate-transport, persistence, reboot, rollback, and durable evidence validation remain future F-A4 gates.
- F-A1 through F-A3 require bounded regression on OpenClaw `2026.6.11 (e085fa1)` before F-A4 closure.

## Remaining Roadmap

Preserve canonical order:

1. Independent review of the completed Gmail tranche.
2. Reconcile and approve F-A4 DNS, IPv6, and alternate-transport design.
3. Reapply managed proxy and `pf` containment.
4. Bounded OpenClaw regression for F-A1 through F-A3.
5. F-A4 acceptance, persistence, failure-recovery, reboot, and durable-evidence validation.
6. OpenClaw state snapshot and rollback proof.
7. Qualify the planned OpenClaw upgrade.
8. Re-prove F-A1 through F-A4 after qualification.
9. F-B observability.
10. F-C action governance.
11. F-D dispatch/confirmation split.
12. Supervised capability expansion.

If Claude finds a canonical disagreement about this order, report it rather than choosing a new sequence.

## Item-2 Execution and Governance Postmortem

Item 2 was eventually completed, but the path was too iterative.

What happened:

- The first broker workflow attempts failed around `search_threads`.
- The historical provider reason remained `PRECISE_REASON_UNAVAILABLE`.
- A one-time operator-supervised Gmail read-only OAuth recovery occurred under the `gmailbroker` custody boundary.
- The confined broker workflow succeeded afterward.
- The recovery was prerequisite context, not proof that OAuth was the historical root cause.
- A reusable OAuth recovery script effort grew beyond the milestone and became overengineered.
- Multiple "final correction" cycles were needed for root execution safety, interpreter trust, supplementary groups, run-root layout, audit matching, failure artifacts, provider diagnostics, credential-content access boundaries, process-argument exposure, streaming redaction, and rollback transaction correctness.
- Some synthetic tests validated an approximation rather than the exact live execution path, so live operator attempts found defects late.
- A supervised one-time operator fallback eventually became the safer path than continuing to refine reusable OAuth automation during the milestone.
- Item 3 also encountered wrapper path and cleanup defects before the successful proof, reinforcing that packaging around privileged/runtime boundaries must be validated against the exact invocation path.

Controls that prevented unsafe execution despite pacing failure:

- The operator rejected root execution of agent-writable repository scripts.
- Root-owned copied execution and hash verification were required.
- Agent-owned Node was refused for root execution.
- The witness was ported to a root-trusted system Python interpreter.
- Credential content access was prohibited in diagnostics.
- Raw Gmail, provider, OAuth, account, credential, token, and audit content were not committed.
- The bounded evidence classification remained non-production.
- Canonical documents continued to state F-A4 open and production NO-GO.

Process lesson:

Future milestones should set an explicit correction-cycle limit. After a small number of material privilege or live-path defects, the process should stop implementation iteration and ask for an operator-approved one-time manual or supervised recovery path rather than building broader reusable machinery inside the same milestone.

## Finding Classification Required From Claude

Every finding must be classified as exactly one of:

- `BLOCKING`
- `BOUNDED CORRECTION`
- `FUTURE HARDENING`
- `NO ACTION`

### BLOCKING

A concrete contradiction, exploitable defect, unsupported security claim, broken rollback boundary, or architecture flaw that must be resolved before the next implementation phase.

### BOUNDED CORRECTION

A real but isolated documentation, evidence, implementation, or test defect that can be corrected without reopening accepted architecture.

### FUTURE HARDENING

A legitimate residual risk already outside the completed tranche's stated evidence boundary and not blocking the next approved phase.

### NO ACTION

Already accepted, adequately mitigated, unsupported as a concern, or outside scope.

Claude must not classify a theoretical improvement as blocking without identifying:

- the violated requirement;
- the supporting file/path;
- the concrete failure or attack path;
- why the accepted evidence boundary is insufficient.

## Required Review Questions

1. Do committed items 1 through 3 support their stated conclusions?
2. Is the phrase "known Gmail connector/broker mediation tranche complete within its stated evidence boundary" accurate?
3. Do any canonical documents overstate broker-only Gmail mediation?
4. Is any material Gmail bypass still evidenced in the committed repository?
5. Did item 3 preserve the distinction between OpenClaw and desktop Codex?
6. Are the negative connector proof and positive broker proof logically sufficient for the bounded item-3 claim?
7. Does the OAuth recovery history expose an unresolved credential-custody defect?
8. Are rollback, evidence, and failure-handling controls proportionate to the threat model?
9. Is ADR-016 still internally coherent after these milestones?
10. Is the next roadmap sequence correct?
11. Which findings, if any, must block the next implementation phase?
12. Which concerns belong only in future hardening?
13. What specific governance rules should prevent another open-ended correction loop?
14. Is a maximum correction-cycle rule appropriate, and what should trigger operator fallback?
15. Is there any reason to reopen items 1, 2, or 3?

## Required Claude Output Format

### A. Executive verdict

- overall judgment;
- whether the Gmail tranche is accepted;
- whether the next implementation phase may begin.

### B. Finding table

For each finding:

- ID;
- classification;
- affected requirement;
- source file/path;
- evidence;
- impact;
- exact bounded remedy;
- whether it blocks progress.

### C. Evidence consistency matrix

Rows:

- item 1;
- item 2;
- item 3;
- F-A4 posture;
- production posture;
- next action.

Columns:

- canonical claim;
- implementation evidence;
- test evidence;
- durable audit;
- conclusion.

### D. Architecture review

- accepted controls;
- residual risks;
- concrete contradictions;
- unsupported assumptions.

### E. Process review

- causes of the excessive iteration;
- which reviews were justified;
- which reviews were overengineering;
- recommended correction-cycle and fallback rules.

### F. Final disposition

Exactly one:

- `ACCEPT — proceed`
- `ACCEPT WITH BOUNDED CORRECTIONS`
- `HOLD — blocking defect identified`

Claude must not execute changes or provide implementation drops unless explicitly requested later.

## Manifest Of Included Repository Paths

The bundle relies on these committed source repository paths:

- `CONTROL.md`
- `OPERATING_CONSTITUTION.md`
- `docs/ADR-015_OPENAI_CREDENTIAL_PROXY.md`
- `docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md`
- `docs/F-A4_OPENAI_PROXY_PROGRESS_CHECKPOINT.md`
- `docs/F-A4_OPENAI_PROXY_CUTOVER_PACKAGE.md`
- `docs/AGENT_OS_OBLIGATION_REGISTER.md`
- `docs/AGENT_OS_END_STATE_ARCHITECTURE.md`
- `docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md`
- `docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md`
- `docs/OPENCLAW_BUILD_PLAN.md`
- `audits/F-A4-broker-reliability-validation.md`
- `audits/F-A4-gmail-broker-workflow-validation.md`
- `audits/F-A4-gmail-connector-disablement-validation.md`
- `audits/F-A4-gmail-connector-negative-proof.json`
- `audits/F-A4-gmail-broker-only-workflow-evidence.json`
- `scripts/fa4-gmail-broker-audit-witness.py`
- `scripts/fa4-gmail-broker-workflow-readonly.mjs`
- `scripts/run-fa4-gmail-broker-witness.sh`

No temporary files, raw audit logs, OAuth material, Gmail message content, credentials, tokens, live configuration contents, or external operator scripts are included.

## Bundle Generation Metadata

- Bundle generated from source repository path: `/Users/agent/agent-os`
- Source branch: `main`
- Source HEAD: `a2a45413f24a1e079b9428f22483b875640fa3d1`
- Source `origin/main`: `a2a45413f24a1e079b9428f22483b875640fa3d1`
- Bundle repository path: `/Users/agent/agent-os-bundle`
- Bundle primary artifact: `BUNDLE.md`
- Runtime operations during bundle generation: none.
- Gmail connector calls during bundle generation: none.
- Gmail broker calls during bundle generation: none.
- Gmail API operations during bundle generation: none.
- OAuth operations during bundle generation: none.
- Service restarts during bundle generation: none.
- Production authorization introduced: none.
