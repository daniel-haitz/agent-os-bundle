# Gateway Panic-Button Live Test

**Date:** 2026-06-12  
**Installed version:** OpenClaw 2026.6.5  
**Verdict:** **GO WITH A CLIENT-RETRY CONSTRAINT.**

`launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway` killed the
gateway-owned in-flight shell and launchd immediately replaced the gateway.
However, the `openclaw agent` CLI used to originate this test automatically
fell back to an embedded agent after the Gateway WebSocket closed and replayed
the prompt. The gateway kill is therefore a verified process-tree kill, but a
panic procedure must also stop or disable any initiating client that can retry
work outside the gateway.

## Recovery Baseline

- LaunchAgent: `ai.openclaw.gateway`
- `KeepAlive`: `true`
- `RunAtLoad`: `true`
- Initial gateway PID: `57469`
- Initial launchd run count: `29`
- Gateway process owner: `agent`, UID `501`

The service was loaded and listening on loopback before the test.

## Live Test

One bounded shell loop appended a counter and epoch timestamp to
`/tmp/panictest_20260612.log` once per second, with a 120-iteration limit.

Before the panic command:

- Counter marker: `11 1781308918`
- Gateway PID: `57469`

After:

```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

the original sequence ended at:

- Final original marker: `18 1781308925`
- New gateway start timestamp: approximately `1781308929`
- New gateway PID: `65509`
- New launchd run count: `30`
- First recovery poll: already `state = running`

The original gateway-owned counter did not produce marker `19`. This proves the
gateway restart terminated that in-flight child process. Launchd replaced the
gateway by the first poll, effectively within one polling interval.

The gateway health RPC subsequently returned `ok: true`; Telegram was enabled,
running, connected, and had no restart pending. The system was not left in
bootout limbo.

## Embedded-Fallback Constraint

The originating `openclaw agent` process reported:

```text
EMBEDDED FALLBACK: Gateway agent failed; running embedded agent:
gateway closed (1012): service restart
```

It then started the same bounded prompt again outside the newly restarted
gateway, producing a fresh sequence beginning at counter `1`. That fallback
was stopped with Ctrl-C; its marker remained unchanged across a five-second
check.

This was a client-side replay, not survival of the original gateway child.
For Telegram-originated work there is no attached `openclaw agent` CLI fallback,
but any CLI, supervisor, or other caller with retry/fallback behavior must be
stopped as part of an emergency response.

## Verified Panic Sequence

For normal Telegram-originated work:

```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

For work originated by an attached CLI or automation:

1. Stop the initiating CLI, supervisor, or retry source.
2. Run the launchd kickstart command above.
3. Confirm `launchctl print gui/$(id -u)/ai.openclaw.gateway` shows a new PID.
4. Confirm `openclaw gateway call health --json` returns `ok: true`.

Do not use `openclaw gateway stop` or `openclaw gateway restart` on this Mac;
those paths can boot out the LaunchAgent instead of preserving launchd
registration. Standalone Telegram `/stop` remains a reasoning/run-state halt,
not a guaranteed kill of an in-flight host process.

## EPERM Diagnosis

The recurring error is:

```text
EPERM: operation not permitted, chmod '/Users/agent/.openclaw/state'
```

There is no ownership or permission mismatch:

- `~/.openclaw`: owner `agent:staff`, UID/GID `501:20`, mode `0700`
- `~/.openclaw/state`: owner `agent:staff`, UID/GID `501:20`, mode `0700`
- Gateway runtime: user `agent`, UID `501`
- State database and sidecars: owner `agent:staff`, mode `0600`

OpenClaw 2026.6.5 calls `ensureOpenClawStatePermissions()` during CLI bootstrap.
For the default database it unconditionally runs:

```js
chmodSync(dir, 0o700)
```

even when the directory is already `0700`. The managed repo-only filesystem
sandbox rejects that metadata write outside its writable roots. The same
read-only `openclaw status --json` command succeeds when run outside that
sandbox, proving this is execution-context policy, not Unix ownership drift.

### Recommended fix

Do not run `chown`, `chmod`, or `doctor --fix`; ownership and modes are already
correct, and those commands do not address this failure.

The durable fix is to upgrade to an OpenClaw release that avoids unconditional
chmod, or patch `ensureOpenClawStatePermissions()` so it only calls `chmodSync`
when the observed mode differs from `0700` and treats `EPERM` as acceptable
only after re-stat confirms the correct owner and mode. Until then, run affected
OpenClaw CLI commands outside the repo-only managed sandbox. A future apply
drop should implement or consume that code fix, not alter state-directory
permissions.

## Cleanup and Drift

- The fallback process was stopped.
- `/tmp/panictest_20260612.log` and the temporary status capture were removed.
- No OpenClaw configuration changed.
- Tracked `openclaw.json` and `exec-approvals.json` remain clean at baseline
  `b77a0f8`.

