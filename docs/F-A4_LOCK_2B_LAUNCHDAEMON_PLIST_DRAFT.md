# F-A4-LOCK-2B LaunchDaemon Plist Draft

Date: 2026-06-20
Purpose: draft-only artifact for operator review before Phase 3.4 of the F-A4
gateway re-home cutover.

No plist was installed. No launchd service, live LaunchAgent, OpenClaw config, or
service env file was modified.

## Source Read

Live LaunchAgent:

- Path: `/Users/agent/Library/LaunchAgents/ai.openclaw.gateway.plist`
- Label: `ai.openclaw.gateway`
- Comment: `OpenClaw Gateway (v2026.6.5)`
- RunAtLoad: `true`
- KeepAlive: `true`
- ExitTimeOut: `20`
- ProcessType: `Interactive`
- ThrottleInterval: `10`
- Umask: `63`
- WorkingDirectory: `/Users/agent/.openclaw`
- StandardOutPath: `/Users/agent/Library/Logs/openclaw/gateway.log`
- StandardErrorPath: `/dev/null`

Live ProgramArguments:

```text
/Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
/Users/agent/.openclaw/service-env/ai.openclaw.gateway.env
/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node
/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/index.js
gateway
--port
18789
```

Live service env:

```text
HOME=/Users/agent
NODE_EXTRA_CA_CERTS=/etc/ssl/cert.pem
NODE_USE_SYSTEM_CA=1
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_LAUNCHD_LABEL=ai.openclaw.gateway
OPENCLAW_SERVICE_KIND=gateway
OPENCLAW_SERVICE_MARKER=openclaw
OPENCLAW_SERVICE_VERSION=2026.6.5
OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service
OPENCLAW_WINDOWS_TASK_NAME=OpenClaw Gateway
PATH=/Users/agent/.local/openclaw/tools/node-v22.22.0/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
TMPDIR=/Users/agent/.openclaw/tmp
```

Live config currently has `gateway.bind="loopback"` and `gateway.port=18789`.
The live LaunchAgent does not pass `--bind loopback` in ProgramArguments; the draft
adds it explicitly as an intentional hardening/no-ambiguity delta.

## Draft Decisions

### HOME

Recommendation: keep `HOME=/Users/agent` for the cutover.

Reason: this is the minimal behavioral change. The live config and workspaces are
already rooted under `/Users/agent/.openclaw`, and the cutover runbook makes that tree
reachable to `openclawgw` with narrow traversal ACLs plus service-owned runtime dirs.
Using `/var/empty` would require proving every HOME-relative OpenClaw cache/state path
is overridden. Using a new service home would become a state relocation, which is not
the selected strategy.

Tradeoff: `HOME` will still name the `agent` home even though the process runs as
`openclawgw`. The trust boundary is maintained by ownership/mode: `.openclaw` is
`root:openclawgw 0550`, root-owned policy/config is read-only, and mutable runtime
dirs are `openclawgw`-owned.

### Env Wrapper

Recommendation: do not use the old env-wrapper in the LaunchDaemon. Inline the env
with `EnvironmentVariables` and call Node directly.

Reason: the wrapper is another executable file that must be locked and reasoned about.
Inlining the exact current env plus explicit config/state paths reduces moving parts
for the daemon. The wrapper may remain in `service-env/` as a root-owned readable
artifact, but this draft does not depend on executing it.

### GroupName

The draft includes `GroupName=openclawgw`. `UserName=openclawgw` is the load-bearing
field; `GroupName` makes the primary group explicit and matches the ownership plan.

## Draft Plist

Install target, if accepted by the operator:
`/Library/LaunchDaemons/ai.openclaw.gateway.plist`

Expected installed ownership/mode:
`root:wheel 0644`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>ai.openclaw.gateway</string>

    <key>Comment</key>
    <string>OpenClaw Gateway (v2026.6.5) - service-user LaunchDaemon draft</string>

    <key>UserName</key>
    <string>openclawgw</string>

    <key>GroupName</key>
    <string>openclawgw</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>ExitTimeOut</key>
    <integer>20</integer>

    <key>ThrottleInterval</key>
    <integer>10</integer>

    <key>Umask</key>
    <integer>63</integer>

    <key>WorkingDirectory</key>
    <string>/Users/agent/.openclaw</string>

    <key>EnvironmentVariables</key>
    <dict>
      <key>HOME</key>
      <string>/Users/agent</string>

      <key>NODE_EXTRA_CA_CERTS</key>
      <string>/etc/ssl/cert.pem</string>

      <key>NODE_USE_SYSTEM_CA</key>
      <string>1</string>

      <key>OPENCLAW_CONFIG_PATH</key>
      <string>/Users/agent/.openclaw/openclaw.json</string>

      <key>OPENCLAW_GATEWAY_PORT</key>
      <string>18789</string>

      <key>OPENCLAW_LAUNCHD_LABEL</key>
      <string>ai.openclaw.gateway</string>

      <key>OPENCLAW_SERVICE_KIND</key>
      <string>gateway</string>

      <key>OPENCLAW_SERVICE_MARKER</key>
      <string>openclaw</string>

      <key>OPENCLAW_SERVICE_VERSION</key>
      <string>2026.6.5</string>

      <key>OPENCLAW_STATE_DIR</key>
      <string>/Users/agent/.openclaw/state</string>

      <key>OPENCLAW_SYSTEMD_UNIT</key>
      <string>openclaw-gateway.service</string>

      <key>OPENCLAW_WINDOWS_TASK_NAME</key>
      <string>OpenClaw Gateway</string>

      <key>PATH</key>
      <string>/Users/agent/.local/openclaw/tools/node-v22.22.0/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>

      <key>TMPDIR</key>
      <string>/Users/agent/.openclaw/tmp</string>
    </dict>

    <key>ProgramArguments</key>
    <array>
      <string>/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node</string>
      <string>/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/index.js</string>
      <string>gateway</string>
      <string>--port</string>
      <string>18789</string>
      <string>--bind</string>
      <string>loopback</string>
    </array>

    <key>StandardInPath</key>
    <string>/dev/null</string>

    <key>StandardOutPath</key>
    <string>/Users/agent/.openclaw/logs/gateway.log</string>

    <key>StandardErrorPath</key>
    <string>/Users/agent/.openclaw/logs/gateway.err.log</string>
  </dict>
</plist>
```

## Discrepancies From Assumed Facts

- The live LaunchAgent does not pass `--bind loopback`; it only passes
  `gateway --port 18789`. The live config contains `gateway.bind="loopback"`. This draft
  makes `--bind loopback` explicit so daemon behavior does not depend on HOME/config
  resolution ordering.
- The live LaunchAgent writes stdout to `/Users/agent/Library/Logs/openclaw/gateway.log`
  and stderr to `/dev/null`. This draft moves logs to
  `/Users/agent/.openclaw/logs/`, which the cutover plan makes `openclawgw`-writable.
- The live LaunchAgent uses the env-wrapper script. This draft inlines env and calls Node
  directly.
- The live `service-env` does not set `OPENCLAW_CONFIG_PATH` or `OPENCLAW_STATE_DIR`.
  This draft sets both explicitly to avoid resolving config/state relative to
  `openclawgw`'s `/var/empty` home.

No discrepancy found for version, node path, dist path, port, label, or working
directory.

## Operator Install Steps

Do this only during Phase 3.4 of the cutover runbook, after Phase 3.3 permissions
checks pass.

1. Create `/Library/LaunchDaemons/ai.openclaw.gateway.plist` with the reviewed content
   above.
2. Set required ownership/mode:

   ```sh
   sudo chown root:wheel /Library/LaunchDaemons/ai.openclaw.gateway.plist
   sudo chmod 0644 /Library/LaunchDaemons/ai.openclaw.gateway.plist
   ```

3. Continue with the runbook's Phase 3.5 and 3.6:

   ```sh
   sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
   sudo launchctl kickstart -k system/ai.openclaw.gateway
   ```

Do not bootstrap this plist while the old LaunchAgent is still active.

## Pre-Install Checklist

Before installing the plist, verify the Phase 3.3 proofs:

- `openclawgw` can traverse `/Users/agent`, `/Users/agent/.local`, and
  `/Users/agent/.openclaw`.
- `openclawgw` can read `/Users/agent/.openclaw/openclaw.json`.
- `openclawgw` cannot write `/Users/agent/.openclaw/openclaw.json`.
- `agent` cannot rename/replace `/Users/agent/.openclaw/openclaw.json`.
- `openclawgw` can write `/Users/agent/.openclaw/state`.
- `openclawgw` can execute
  `/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node`.
- `openclawgw` can read
  `/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/index.js`.
- `/Users/agent/.openclaw/logs` exists and is writable by `openclawgw`.
- `/Users/agent/.openclaw/tmp` exists and is writable by `openclawgw`.
- The operator has accepted the `HOME=/Users/agent` minimal-change decision.
- The operator has accepted the env-wrapper removal / inline environment decision.

After bootstrap, check:

- `launchctl print system/ai.openclaw.gateway` shows the job running.
- `ps -axo user,pid,command | grep -i 'openclaw.*gateway' | grep -v grep` shows
  `openclawgw` as the process user.
- `/Users/agent/.openclaw/logs/gateway.log` has clean startup lines and no
  `EACCES`, `EPERM`, `openclaw.json`, or Keychain/login-session errors.

## Non-Actions

This draft did not install the plist, touch `/Library/LaunchDaemons`, stop/start
launchd, edit the live LaunchAgent, edit `openclaw.json`, or modify the service-env
files.
