# Agent OS Change Control Standard

**Status:** Approved governance standard. Effective upon approval and commit to the canonical repository.

## Purpose

Prevent divergence between:

- live runtime state;
- `CONTROL.md`;
- architecture decisions;
- operational runbooks;
- evidence artifacts.

This standard applies to runtime, security, architecture, documentation, and capability changes that can affect Agent OS authority, trust boundaries, phase status, or operational obligations.

Documentation does not create runtime authority. It records verified state, approved architecture, required gates, and evidence locations.

## Required Change Lifecycle

All runtime, security, architecture, documentation, or capability changes follow:

```text
Observe
→ Document
→ Propose
→ Approve
→ Change
→ Validate
→ Reconcile
→ Commit
```

Meaning:

- **Observe:** inspect relevant live state, repository state, evidence, and prior decisions before mutation.
- **Document:** record verified facts, drift, uncertainty, and affected boundaries.
- **Propose:** state the smallest bounded change, expected effect, rollback, and validation plan.
- **Approve:** obtain explicit approval for the proposed scope.
- **Change:** mutate only approved files, services, policies, credentials, or runtime state.
- **Validate:** prove positive path, negative path, persistence, and evidence proportional to risk.
- **Reconcile:** update `CONTROL.md`, architecture decisions, runbooks, and evidence indexes to match validated reality.
- **Commit:** commit only the reviewed scope with a truthful message and clean status.

Skipping reconciliation is a failed change, even when the runtime behavior works.

## Changes Requiring Reconciliation

The following require documentation and evidence reconciliation before closure:

- OpenClaw version changes;
- model assignments;
- agent configuration;
- connectors;
- MCP servers;
- plugins;
- credentials;
- permissions;
- launchd services;
- sockets;
- proxy/firewall changes;
- security boundary changes;
- approval policy changes;
- broker capability changes;
- runtime identity or ownership changes;
- evidence, logging, audit, or retention changes;
- phase status changes;
- rollback or recovery procedure changes.

## Documentation Migration Rule

No security-relevant item may disappear during refactoring.

Every removed item must be classified as one of:

- **Closed** — with evidence reference.
- **Moved** — with destination reference.
- **Retired** — with approval rationale.
- **Superseded** — with ADR reference.

No silent deletion is allowed.

Security-critical obligations are tracked in `docs/AGENT_OS_OBLIGATION_REGISTER.md`. Refactors must preserve, close, move, retire, or supersede every listed obligation.

If a document is compressed, split, renamed, or converted into an index, every active obligation, open blocker, phase gate, credential boundary, connector risk, approval rule, and runtime baseline must remain discoverable from canonical documents.

## State Migration Rule

When canonical documentation is rewritten, compressed, or reorganized:

- Existing obligations must be migrated explicitly.
- Existing evidence references must be preserved or replaced.
- Existing blockers must remain visible until closed or retired.
- A documentation refactor is treated as a change event, not a formatting event.

A shorter document is not considered equivalent unless all active obligations, decisions, evidence references, and unresolved risks remain traceable.

## `CONTROL.md` Compression Rule

`CONTROL.md` may remain concise.

However, when content moves out of `CONTROL.md`:

- the destination document must be recorded;
- status must remain visible;
- open security obligations cannot disappear;
- phase closure limits must remain visible or directly referenced;
- unresolved blockers must retain owner, status, and next validation gate.

`CONTROL.md` should point to detailed runbooks and ADRs; it must not hide active obligations inside historical notes.

## Evidence Traceability

Phase closures require:

- evidence location;
- commit reference;
- validation date;
- runtime baseline.

Closed status without evidence linkage is provisional.

A phase may remain summarized in `CONTROL.md`, but every closed phase must have a discoverable evidence pointer.

Evidence may live in audit files, runbooks, sanitized logs, operator records, or committed validation summaries. The location must be recorded in canonical documentation.

Evidence must distinguish:

- live runtime proof;
- historical proof;
- inferred status;
- proposed future validation.

## Phase Completion Pattern

Every phase closure or closure-ready claim must have:

- architecture decision or explicit inheritance from an existing decision;
- implementation path;
- validation script or exact validation command block;
- evidence artifact;
- `CONTROL.md` status update;
- publication checkpoint.

Partial validation may be recorded, but it must not be described as closure.

## Operator Action Pattern

Privileged operator actions must be repeatable and reviewable. They require:

- idempotent script or exact guarded command block;
- preflight checks;
- evidence output location;
- rollback guidance or rollback script proportional to risk;
- post-change validation output.

Operator actions must not rely on undocumented manual repairs when the same step is expected to recur.

## Evidence Record Pattern

Evidence for phase gates and runtime changes must include:

- exact command;
- timestamp;
- identity used;
- result or exit status;
- interpretation;
- closure impact.

## Runtime Authority Rule

For live system state:

```text
Runtime evidence > canonical documentation > historical artifacts > session summaries.
```

Documentation records validated reality but cannot override live runtime evidence.

## Wrap-Up And Publish Requirements

Wrap-up validation should eventually detect:

- broken document references;
- runtime version drift;
- stale paths;
- missing canonical documents;
- disappearance of security-critical gates;
- missing evidence locations for closed phases;
- removed obligations without Closed/Moved/Retired/Superseded classification.

This document defines the requirement only. It does not implement scripts.

## Non-Goals

This standard does not authorize runtime mutation, credential access, connector changes, service restarts, or security-control changes.

It also does not require `CONTROL.md` to carry every detail. It requires that details remain traceable, current, and canonically referenced.
