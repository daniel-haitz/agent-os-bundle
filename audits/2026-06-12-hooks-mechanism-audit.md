# Hooks Mechanism Audit — Notify Tier

**Date:** 2026-06-12  
**Installed version:** OpenClaw 2026.6.5  
**Result:** **GO, with mandatory design constraints.**

The installed typed plugin-hook surface is sufficient to build Notify safely, but a
naive hook is not sufficient. The build must never forward hook arguments, results,
errors, session keys, or call IDs. It must construct a fixed, allowlisted notification
from non-sensitive metadata and use a persistent local outbox with retries and a visible
terminal-failure state. Native `after_tool_call` execution is fire-and-forget and only
logs delivery failures, so it does not itself provide a non-silent notification guarantee.

**Central finding:** Yes, a hook can notify without forwarding secret material and
without silently losing failures, but only if the plugin deliberately excludes sensitive
event fields and adds durable delivery tracking. The native hook plus one direct Telegram
send does not meet the second requirement by itself.

## 1. What `after_tool_call` Can See — SETTLED

The correct surface is the typed plugin lifecycle hook registered with
`api.on("after_tool_call", ...)`, not an internal `HOOK.md` automation event.

The installed type declares these event fields:

- `toolName`
- `params`
- `runId`
- `toolCallId`
- `result`
- `error`
- `durationMs`

The hook context also includes `agentId`, `sessionKey`, `sessionId`, `runId`, and
`toolCallId`. Runtime source confirms that the hook receives the adjusted tool arguments
and the sanitized tool result after execution.

`sanitized` does not mean secret-redacted. The result remains the model-visible tool
result and can include file contents, command output, environment values, or other secret
material. Arguments can likewise contain secrets, message bodies, paths, URLs, or inline
code. Error strings can echo arguments, paths, or returned data.

Safe notification fields:

- A plugin-owned fixed action label or classification
- A normalized tool name, only when the classification policy permits it
- Success/failure as a boolean
- A coarse duration bucket, if useful
- A plugin-generated notification ID with no relationship to session or tool-call IDs

Must never be forwarded:

- `params`
- `result`
- `error`
- `sessionKey` / `sessionId`
- `runId` / `toolCallId`
- Raw paths, commands, message bodies, URLs, headers, environment values, or file content

The hook may inspect the minimum fields needed to classify an action, but the outbound
message must be generated from a separate allowlisted structure rather than by redacting
or serializing the event.

Evidence:

- `dist/plugin-sdk/hook-types-DgRt3F-m.d.ts:624`
- `dist/selection-But6hGR0.js:2554`
- `dist/selection-But6hGR0.js:2860`
- `docs/plugins/hooks.md` — `after_tool_call` observes results, errors, and duration

## 2. Notification Path and Failure Behavior — SETTLED

### Installed outbound path

A trusted native plugin can load the Telegram outbound adapter directly:

```text
api.runtime.channel.outbound.loadAdapter("telegram")
```

It can then call the adapter's `sendText({ cfg, to, text, accountId?, threadId? })`.
The bundled `device-pair` plugin uses this exact path. This is preferable to invoking the
agent `message` tool or launching another agent turn.

The target must be an explicit owner Telegram ID from plugin configuration, not a value
taken from tool arguments or an untrusted inbound event. Plugin configuration belongs
under `plugins.entries.<id>.config`; credentials remain in the existing Telegram channel
SecretRef and are not copied into plugin config.

### Failure behavior

`after_tool_call` is a void hook. Hook handlers run in parallel, and the tool completion
path calls the hook runner without awaiting it. Handler errors and timeouts are caught and
logged. The original tool action has already completed and is not rolled back or marked
failed because notification delivery failed.

Therefore, network failure, Telegram failure, adapter absence, plugin timeout, gateway
shutdown, or process crash can leave the operator unnotified while the original action
still succeeds. A direct send can throw or return a delivery result, but native hook
orchestration provides no durable retry or operator-visible failure guarantee.

Required build behavior:

1. Persist a minimal, secret-free notification record before attempting delivery.
2. Retry with bounded backoff and idempotency/deduplication.
3. Mark delivery success only after the adapter returns success.
4. Preserve a terminal failure record and expose it through doctor/status or another
   independently inspectable local signal.
5. Drain pending records on gateway/plugin startup.

This makes delivery failure non-silent in durable state even when Telegram is unavailable.
The action itself remains non-blocking; Notify is observation, not approval.

### Loop risk

Direct adapter delivery is outbound channel I/O, not an agent tool call, so it does not
re-enter `after_tool_call`. It may participate in outbound message lifecycle hooks, but
that does not create an `after_tool_call` loop.

Using the agent `message` tool, a gateway-triggered agent run, or a subagent to send the
notification would create avoidable recursion risk and is rejected for the Notify design.
The plugin should also ignore the `message` tool explicitly as defense in depth.

Evidence:

- `dist/plugin-sdk/types-Dk6viGJ9.d.ts:6228` — outbound adapter loader
- `dist/extensions/device-pair/index.js:552` — bundled direct Telegram send
- `dist/hook-runner-global-Ck8dmI0_.js:352` — void hooks run in parallel
- `dist/hook-runner-global-Ck8dmI0_.js:746` — `after_tool_call` is fire-and-forget
- `dist/selection-But6hGR0.js:2873` — caller does not await; failure is logged

## 3. Registration, Scope, and Scheduling — SETTLED

Notify should be a normal non-channel OpenClaw plugin created with `definePluginEntry`.
It is installed with `openclaw plugins install <local-path-or-pinned-package>`, enabled as
needed, and configured under:

```text
plugins.entries.<plugin-id>.config
```

The runtime handler is registered with:

```text
api.on("after_tool_call", handler, { priority?, timeoutMs? })
```

Registration options provide priority and timeout only. There is no declarative tool-name,
action-class, or agent filter on `api.on`.

Scoping must therefore be internal and fail closed:

- Return immediately unless `ctx.agentId === "main"`.
- Return unless the tool/action matches an explicit Notify classification table.
- Do not run for the dedicated `heartbeat` agent.
- Default unknown tools and unknown argument shapes to no notification until classified.
- Keep classification and outbound rendering separate so inspected arguments cannot leak
  into the notification.

The handler is asynchronous relative to the agent/tool path. Multiple void-hook handlers
run in parallel; OpenClaw waits inside the hook runner for each handler or timeout, but the
tool completion caller does not await that runner. Notify cannot block or undo the action.

Evidence:

- `docs/tools/plugin.md:50` — plugin install paths
- `docs/tools/plugin.md:71` — plugin config path
- `docs/tools/plugin.md:225` — typed hooks use `api.on`
- `dist/plugin-sdk/types-Dk6viGJ9.d.ts:8601` — only priority/timeout registration options

## 4. Safe-List Drift Detection

**SETTLED.** `~/.openclaw/exec-approvals.json` was inspected directly and scanned for the
repo's secret patterns. It contains policy fields and four Git allowlist patterns only;
the socket object is empty. No token, credential, private key, API key, or secret-shaped
assignment was found. The file remains mode `0600`.

It is now tracked alongside `openclaw.json` in the separate `~/.openclaw` repository.
Baseline commit:

```text
b77a0f8 baseline: track exec-approvals.json (safe-list under drift detection)
```

Tracked drift for both files is clean. The state directory still contains intentionally
untracked operational data and secrets; those were not added.

## Build Entry Conditions for DROP 1.2b-build

- Use a typed native plugin and `api.on("after_tool_call")`.
- Filter to `agentId === "main"` and an explicit Notify action table.
- Emit only fixed allowlisted metadata; never forward event arguments, results, errors,
  session identifiers, commands, paths, or message content.
- Deliver through `api.runtime.channel.outbound.loadAdapter("telegram").sendText`.
- Use an explicit configured owner target.
- Add a durable secret-free outbox, retry/deduplication, startup drain, and visible terminal
  failure state.
- Do not use the agent `message` tool, a subagent, or an agent turn for delivery.
- Test success, Telegram outage, restart with pending delivery, duplicate events, malformed
  arguments, secret-bearing arguments/results, heartbeat exclusion, and loop resistance.
