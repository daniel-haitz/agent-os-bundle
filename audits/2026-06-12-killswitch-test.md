# Kill-Switch Live Test

**Date:** 2026-06-12  
**Installed version:** OpenClaw 2026.6.5  
**Verdict:** **NO-GO as an in-flight host-process panic button.**

OpenClaw's abort surfaces stop the tracked agent run, but the live test proved that
`sessions.abort` does not terminate an already-running host shell process. The Gateway
reported the run aborted in about one second while the inert counter continued to its
natural completion.

## Stop Mechanisms

### `/stop`

- Type or send `/stop` as a standalone command in the active Telegram/chat session.
- It targets that chat session's current run.
- It clears queued follow-ups, calls the embedded/reply-run abort primitive, records the
  abort, and cascades cancellation to tracked child subagents.
- It is a chat command, not a standalone CLI command.

### `/queue interrupt`

- Send `/queue interrupt` as a standalone command in the target chat session to store
  interrupt mode for that session.
- The next inbound message for that session aborts the active run, waits for run shutdown,
  and starts the newest message.
- There is no `openclaw queue` CLI command in 2026.6.5.
- Source shows it calls the same embedded-run abort primitive used by `/stop`.

### `sessions.abort`

Direct Gateway API:

```bash
openclaw gateway call sessions.abort \
  --params '{"key":"<session-key>","runId":"<run-id>","agentId":"<agent-id>"}'
```

It accepts `{key, runId?}`, `{runId}`, and optional `agentId`. This is the most precise
operator/API surface because it can bind both session and run.

There is no `openclaw sessions abort` subcommand in 2026.6.5.

## Live Test

### Baseline

An isolated test session ran a bounded shell loop that appended a counter and epoch
timestamp to `/tmp/killtest_20260612.log` once per second for 120 iterations.

Proof:

- Tool duration: 122,084 ms
- Final marker: `120 1781301423`
- The baseline confirmed that the command was a real long-running exec.

### Abort run

A second bounded loop wrote to `/tmp/killtest_20260612_run2.log`.

- First marker: `1 1781302403`
- Abort fired: epoch `1781302414`
- `sessions.abort` returned at epoch `1781302415`
- API result: `{"abortedRunId":"killtest-20260612-run2","status":"aborted"}`
- `agent.wait` reported the run ended at `1781302415646`, `stopReason: "rpc"`

The underlying process did not stop:

- At epoch `1781302422`: 20 lines, final marker `20 1781302422`
- At epoch `1781302428`: 25 lines, final marker `25 1781302427`
- Natural completion: `120 1781302524`

The counter continued for roughly 109 seconds after the abort command. Halt latency is
therefore **not applicable: the process was not halted**.

Both `/tmp` marker files were removed after the test, and no test process remains.

## Tested vs. Not Tested

| Scenario | Status | Finding |
| --- | --- | --- |
| Long-running exec | **LIVE TESTED** | `sessions.abort` stopped run tracking/model flow but did not kill the shell process |
| Model generation | **NOT LIVE TESTED** | Docs/source indicate abort signals the active run, but no measured proof in this drop |
| Subagent task | **NOT LIVE TESTED** | `/stop` has a tracked-subagent cascade, but no live proof that a subagent's in-flight host process dies |
| `/stop` independently | **NOT LIVE TESTED** | Source-equivalent abort primitive plus queue clearing/subagent cascade |
| `/queue interrupt` independently | **NOT LIVE TESTED** | Source-equivalent abort primitive, followed by newest-message execution |

Only one inert test workload was used. Additional live runs were not created after the
direct API established that the shared abort primitive does not kill in-flight exec.

## Recommended Daily Command

From the phone, use standalone `/stop` in the affected Telegram chat. It is the fastest
available user-facing command, clears queued work, and cascades to tracked subagents.

Limitation: `/stop` must be treated as **stop the agent run and prevent further steps**,
not as a guaranteed kill of an already-running host process. For exact automation/API
targeting, use `sessions.abort` with both session key and run ID, with the same limitation.

Do not use `/queue interrupt` as the panic button: it is replacement-message behavior and
starts new work after aborting the old run.

## C.5 / C.6 Decision

The receive-vs-interrupt split does **not** collapse. OpenClaw can receive and acknowledge
an abort while an in-flight host process continues. A real C.6 mechanism still needs
process-group ownership and verified TERM/KILL escalation for exec children, plus equivalent
handling for nested/subagent processes.

## Configuration and Drift

No OpenClaw configuration was changed. The tracked drift baseline remains clean at
`b77a0f8` for `openclaw.json` and `exec-approvals.json`.

`openclaw config validate` passed. `openclaw doctor` again hit the existing
`EPERM: chmod ~/.openclaw/state` issue; this was pre-existing and is already flagged in
`CONTROL.md`.
