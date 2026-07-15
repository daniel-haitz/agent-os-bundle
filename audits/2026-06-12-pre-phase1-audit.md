# Phase 1 Pre-Phase Audit

**Date:** 2026-06-12
**Installed version:** OpenClaw 2026.6.5 (5181e4f)
**Scope:** Read-only audit of the Phase 0 baseline; no live tool run and no OpenClaw mutation.

## Gate

**NO-GO — do not execute the current Phase 1 plan unchanged.**

The native approval engine is a viable Phase 1 foundation, but the installed facts require
four plan corrections before configuration begins:

1. Phase 1.1 must explicitly set restrictive exec policy and `askFallback: deny`; the
   installed default is currently YOLO (`security=full`, `ask=off`, `askFallback=full`),
   not fail-closed.
2. Phase 1.2 must design a custom typed plugin/hook for Notify-tier delivery. OpenClaw
   exposes tool-observation hooks and telemetry, but no declarative native
   "run this reversible action and notify the operator" tier.
3. Phase 1.5 must test the actual interrupt surfaces (`/stop`, `/queue interrupt`, and
   `sessions.abort`). `/approve ... deny`, `/steer`, and goal state are not a combined
   running-task kill switch.
4. Phase 1.6 must enable native loop detection and add controls for the uncovered doctrine
   requirements: a total iteration cap, a true cost circuit breaker, and durable trip state.

After a revised Claude drop incorporates those changes, Phase 1.1 may proceed.

## Central Question

> Can any inbound message, malicious page, replayed event, or misconfiguration cause an
> unintended action or a secret leak under the trust model we are about to configure?

**Current baseline answer: yes.** A message accepted from the paired Telegram owner reaches
an unsandboxed main agent whose effective host exec policy is `full/off/full`. The agent can
also use filesystem and session tools. Phase 1 is therefore required before adding untrusted
content paths, shared senders, browser work, or sensitive secrets.

No malicious-page path exists yet because the browser tool is denied by the current coding
profile. SecretRefs keep configured gateway and Telegram tokens out of model-readable config,
but unrestricted host exec could still read files available to the user account.

## Evidence Read

Installed documentation:

- `docs/tools/exec-approvals.md`
- `docs/tools/exec-approvals-advanced.md`
- `docs/tools/exec.md`
- `docs/tools/permission-modes.md`
- `docs/channels/telegram.md`
- `docs/help/faq-first-run.md`
- `docs/tools/loop-detection.md`
- `docs/concepts/queue.md`
- `docs/concepts/queue-steering.md`
- `docs/tools/steer.md`
- `docs/tools/goal.md`
- `docs/tools/slash-commands.md`
- `docs/automation/hooks.md`
- `docs/plugins/hooks.md`
- `docs/tools/multi-agent-sandbox-tools.md`
- `docs/gateway/sandboxing.md`
- `docs/gateway/protocol.md`

Read-only commands:

- `openclaw --version`
- `openclaw config get agents --json`
- `openclaw config get tools --json`
- `openclaw config get channels.telegram --json`
- `openclaw config get commands --json`
- `openclaw sandbox explain --agent main --json`
- `openclaw approvals get --json`
- `openclaw exec-policy show --json`
- `openclaw cron list --json`
- `openclaw hooks list --json`
- `openclaw doctor`
- `git -C ~/.openclaw status`, `diff`, `log`, and `ls-files`

## 1. Native Approval Engine

### Finding 1.1 — Engine surface: SETTLED

OpenClaw 2026.6.5 supports:

- `exec.security`: `deny`, `allowlist`, or `full`.
- `exec.ask`: `off`, `on-miss`, or `always`.
- `askFallback`: `deny`, `allowlist`, or `full` when an approval prompt cannot be
  delivered or answered.
- `approvals.exec`: optional forwarding of approval prompts to configured chat targets.
- `channels.telegram.execApprovals`: Telegram-native approval client behavior, including
  approver IDs, DM/channel target, and agent/session filters.

The host exec gate is the effective intersection of requested `tools.exec` policy and the
host-local `~/.openclaw/exec-approvals.json`. Chat approval settings route and render
decisions; they are not the execution gate.

Tool policy is evaluated before the model call. A denied tool is removed from the model's
available schema and cannot be restored by sandbox or elevated settings.

### Finding 1.2 — Current main-agent posture: SETTLED, HIGH RISK

Current effective state:

| Control | Effective value |
|---|---|
| Tool profile | `coding`, plus `message` |
| Sandbox | `off` |
| Exec host | `auto` |
| Exec security | `full` |
| Exec ask | `off` |
| Ask fallback | `full` |
| Host approvals file | absent |
| `approvals.exec` | absent |
| `channels.telegram.execApprovals` | absent; native auto-resolution may use owner IDs once approvals exist |
| Elevated | unavailable to the current sender/config, but not needed for unsandboxed full exec |

`openclaw sandbox explain` shows `exec`, `process`, read/write/edit/apply-patch, and
session tools available. It shows browser, cron, and gateway denied by the current profile.

The current posture is OpenClaw's documented default host behavior, described by its docs
as YOLO. It is not the strict baseline described in the build plan.

### Finding 1.3 — Telegram approval roles: SETTLED

Normal Telegram access and approval authority are separate:

- Telegram is enabled with `dmPolicy: pairing` and groups disabled.
- The command owner is `telegram:8745949064`.
- There are no pending Telegram pairing requests.
- `channels.telegram.allowFrom`/pairing controls normal inbound access.
- Exec approvers resolve from explicit numeric approvers or, when safely available,
  `commands.ownerAllowFrom`.
- Pending exec approvals expire after 30 minutes by default.

## 2. Fail-Closed and Approval Binding

### Finding 2.1 — Ask fallback default: SETTLED, PLAN CLAIM MUST CHANGE

The general docs say that a request which must prompt and has no reachable UI resolves
through `askFallback`, and their restrictive example uses `deny`.

However, the installed effective default on this machine and version is:

```text
security=full ask=off askFallback=full
```

The installed runtime source also resolves an absent approval-file fallback to `full`.
Therefore the plan must not claim that the unconfigured product is fail-closed. Phase 1.1
must explicitly configure `askFallback: deny` in the enforceable host approval policy,
along with restrictive requested exec policy.

Once explicitly configured to `deny`, an unavailable approval client blocks the command.

### Finding 2.2 — Approval context and TOCTOU binding: PARTLY SETTLED

Installed docs explicitly guarantee for approved **node-host** runs:

- canonical cwd;
- exact argv;
- bound environment when present;
- pinned executable path when applicable;
- best-effort binding of one concrete script/interpreter file operand;
- denial if that bound file changes after approval and before execution;
- refusal to mint an approval-backed run when exactly one bindable file cannot be
  identified.

This is not a complete semantic model of every loader path. Inline interpreter evaluation
needs `strictInlineEval: true` for stronger coverage.

**OPEN — owner Phase 1.5:** the installed docs do not state the same canonical
cwd/argv/env/file-binding guarantee as explicitly for gateway-host execution. Confirm the
chosen Phase 1 execution target hands-on.

Test design for Phase 1.5, not executed here:

1. Use a disposable workspace and harmless script that writes only to a temporary marker.
2. Set the test agent to `ask: always`, `askFallback: deny`, and the intended host.
3. Request the script and wait for an approval ID without approving it.
4. Change the script contents, then approve the original ID.
5. Require a denial and prove the marker was not written.
6. Repeat with changed argv, cwd, and a bound environment value.
7. Repeat on every intended host type; verify inline eval is approval-only.

## 3. Three `[VERIFY]` Items

### 3a. Notify-Tier Mechanism: SETTLED — CUSTOM BUILD REQUIRED

There is no declarative native Notify tier equivalent to:

> execute a reversible side effect without approval, then send an operator notification.

Available native surfaces are components, not a complete policy:

- `after_tool_call` is a typed plugin observation hook.
- internal hooks do not expose tool execution events.
- diagnostic events/OTel are telemetry, not a policy or operator-notification route.
- system events inject text into an agent session/heartbeat; they are not direct operator
  notifications.
- exec lifecycle messages exist for approved asynchronous exec runs, not as a configurable
  notification policy for arbitrary reversible tools.

**Direction change:** Phase 1.2 must include a custom typed plugin/hook that classifies the
configured Notify-tier tools/actions and emits a sanitized Telegram/operator notification
after execution. It must not include secrets or unrestricted tool output. Delivery failure
semantics and audit correlation must be specified before implementation.

### 3b. Kill-Switch Semantics: SETTLED FOR DOCS; HANDS-ON TEST OPEN

The proposed combination does not collapse the old receive/record and interruption split:

- `/approve <id> deny` prevents that pending command from running. It does not abort other
  work already running.
- `/steer` injects guidance at the next supported runtime/model boundary. It explicitly
  does not interrupt an in-flight tool call.
- Goal commands alter durable objective state. Goal pause/block/complete is not a run
  cancellation mechanism.
- `/stop` aborts the current run.
- `/queue interrupt` aborts the active run, then starts the newest message.
- Gateway `sessions.abort`/`chat.abort` are explicit active-run abort APIs.
- Task cancellation kills child sessions for ACP/subagent tasks, but CLI-tracked task
  cancellation may only record cancellation because no child runtime handle exists.

**OPEN — owner Phase 1.5:** hands-on test `/stop`, `/queue interrupt`, and `sessions.abort`
during (a) model generation, (b) a long-running exec, and (c) delegated/subagent work.
Measure whether the child OS process is terminated and whether any already-issued side
effect completes before cancellation. Do not represent `/steer`, goal status, or approval
denial as a hard interrupt.

### 3c. Loop-Prevention Depth: SETTLED — PARTIAL NATIVE COVERAGE

Current config has no `tools.loopDetection` block:

- rolling-history detectors are disabled by default;
- the post-compaction guard remains enabled while the master flag is unset;
- no rolling detector protects normal current runs.

Doctrine mapping:

| Control | Native coverage | Finding |
|---|---|---|
| Iteration cap | No general total tool/turn cap | **GAP** |
| Hash detector | Same tool+params, identical outcome hashes, ping-pong, and post-compaction `(tool,args,result)` hashes | **NATIVE** |
| No-progress oracle | Repeated identical outcomes, known polling without state change, unknown-tool retry, ping-pong | **NATIVE HEURISTIC**, not semantic proof |
| Cost circuit breaker | `globalCircuitBreakerThreshold` counts no-progress calls; it is not monetary/token cost. Goal token budgets are explicitly not billing caps | **GAP** |
| Persistent state on trip | Loop reason is logged/recorded for the run, but no documented durable trip latch blocks later runs until operator reset | **GAP** |
| Stuck detection | Warning, suppression, critical blocking, unknown-tool, polling, ping-pong, and compaction-loop abort | **NATIVE** |

**Direction change:** Phase 1.6 must explicitly enable rolling loop detection and add a
custom iteration/cost budget plus durable tripped-state handling. Native detectors should
remain the first line for repetitive/no-progress patterns.

## 4. Config Self-Modification Defense

### Finding 4.1 — Per-agent hard deny: SETTLED

`agents.list[].tools.deny` can further restrict an agent after global/profile policy.
Earlier denied tools cannot be granted back by later policy levels. Exact tool IDs can
hard-block `gateway`, `cron`, and individual `sessions_*` tools. Tool-group shorthands can
cover broader groups, but the Phase 1 design should list exact session tools where least
privilege matters.

The current main agent already has `gateway` and `cron` denied by the effective coding
profile, but session tools remain available. Phase 1 must make the intended restrictions
explicit rather than depend on profile contents.

### Finding 4.2 — Config drift baseline: SETTLED

- `~/.openclaw` HEAD is `e59160b baseline`.
- The only tracked file is `openclaw.json`.
- Working-tree and staged diffs for `openclaw.json` are clean.
- `git status` lists runtime/state directories and backups as untracked. They are not
  configuration drift and must not be added to this repository.

No tracked config drift exists.

## 5. Inbound Threat Pass

### Telegram messages to `@LLoyd_entouragebot`: SETTLED, CURRENTLY HIGH RISK

- Direct messages require pairing; groups are disabled.
- The paired owner can submit natural-language prompts and authorized slash commands.
- With sandbox off and exec `full/off`, a crafted or mistaken accepted prompt can cause
  unapproved host execution, filesystem writes, process activity, outbound messages, or
  session manipulation.
- Browser, cron, gateway, and other channel tools are currently removed by policy, which
  narrows but does not eliminate host risk.
- Because this is a personal-assistant trust model, pairing authenticates the sender; it
  does not make prompt content safe. Forwarded malicious instructions or prompt injection
  supplied by the owner remain actionable content.

### Approval replies: SETTLED, LOW CURRENT EXPOSURE / FUTURE HIGH AUTHORITY

- No exec approvals are currently generated because exec is `full/off`.
- There is no explicit forwarding config and no pending pairing request.
- Once Phase 1 enables approvals, only authorized numeric approvers should resolve them.
- Approval IDs expire, and a denial prevents the pending command from running.
- Replayed or stale approval IDs should fail after resolution/expiry, but live replay and
  wrong-sender negative tests belong in Phase 1.3.
- Approval replies are not a kill switch for unrelated or already-running actions.

### Heartbeat turns: SETTLED, CONTROLLED PROMPT BUT OVER-PRIVILEGED AGENT

- Runs every 30 minutes in an isolated, light-context session on local Qwen with a
  180-second timeout.
- `HEARTBEAT.md` currently says to reply exactly `HEARTBEAT_OK` and not call tools.
- There are no due tasks or external event text observed in this audit.
- The instruction is behavioral, not a mechanical tool restriction. If the heartbeat file,
  injected system events, workspace instructions, or model behavior changes, the heartbeat
  agent inherits the current permissive tool posture and could execute host actions.
- Phase 1 must give heartbeat a mechanically restricted tool set, not rely on prompt text.

### Cron: SETTLED

- `openclaw cron list --json` reports zero jobs.
- There is currently no cron-triggered inbound execution path.
- Future cron jobs are headless. Their approval/fallback and tool policy must be designed
  explicitly because they cannot wait indefinitely for interactive approval.

### Malicious pages and other channels: SETTLED FOR CURRENT BASELINE

- Telegram is the only enabled external messaging channel in the inspected config.
- Group Telegram input is disabled.
- Browser is denied by effective tool policy, so no malicious-page ingestion path is
  currently active.
- No network webhook or additional inbound integration was identified in the scoped Phase 0
  configuration.

## Doctor and Residual Operational Notes

`openclaw doctor` completed with no channel security warning, missing skill requirement, or
plugin error. It reported 27 orphan transcript files and offered a mutating archive fix;
this audit did not run that fix.

This doctor result does not make the current execution policy safe. The effective-policy
inspection is authoritative for this gate.

## Entry Conditions for the Next Claude Drop

The Phase 1.1 drop must:

1. Treat `full/off/full`, sandbox off, and unrestricted heartbeat/session tools as the
   explicit starting risk.
2. Configure both requested exec policy and host-local approval policy, with
   `askFallback: deny`; verify the effective merge after configuration.
3. Preserve Telegram pairing and require explicit numeric approval authority.
4. Add the Notify-tier custom plugin/hook design before Phase 1.2 implementation.
5. Replace the kill-switch claim with `/stop`, `/queue interrupt`, and `sessions.abort`
   tests in Phase 1.5.
6. Enable native rolling loop detection and define custom iteration, cost, and persistent
   trip controls for Phase 1.6.
7. Explicitly deny config/self-modification tools per agent, including required
   `sessions_*` IDs, rather than relying on a profile.
8. Mechanically restrict heartbeat tools.

**Audit conclusion:** OpenClaw's native policy and approval primitives are suitable, but the
existing plan overstates default fail-closed behavior and native coverage for Notify,
interruption, and loop prevention. Revise the plan/drop first; then proceed to Phase 1.1.
