# F-A4-LOCK-PHASE5 Egress Wall Draft

Date: 2026-06-20
Purpose: draft-only artifacts for the operator-owned F-A4 egress wall. Codex did
not install a proxy, create users, modify OpenClaw config, touch launchd, or load pf.

## Draft Artifacts

Files drafted under `drafts/fa4-phase5/`:

- `agent-os-egress-proxy.mjs` - hardened Node HTTP CONNECT proxy.
- `allowlist.txt` - FA4_2-corrected exact hostname allowlist.
- `ai.agent-os-egress-proxy.plist` - root LaunchDaemon draft for the proxy.
- `agent-os-egress.anchor` - pf anchor draft.
- `pf.conf.fragment` - `/etc/pf.conf` fragment required to make the anchor active.
- `ai.agent-os-egress-pf.plist` - root LaunchDaemon draft that reloads `/etc/pf.conf`
  for persistence after the operator adds the fragment.
- `phase5-proof-commands.sh` - reviewed command set for leak tests and lock checks.

Validation run by Codex:

- `node --check drafts/fa4-phase5/agent-os-egress-proxy.mjs` passed.
- `plutil -lint` on both plist drafts passed.
- `sh -n drafts/fa4-phase5/phase5-proof-commands.sh` passed.
- `openclaw proxy validate --help` confirms this installed version supports
  `--proxy-url`, `--allowed-url`, and `--denied-url`.

Not run by Codex:

- No `pfctl` command was run.
- No proxy process was started.
- No launchd command was run.
- No file under `/Library`, `/etc`, `/Users/agent/.openclaw`, or live launchd paths
  was modified.

## Proxy Design

The proxy is a small Node CONNECT proxy using only built-in Node modules.

Security behavior:

- Binds to `127.0.0.1:13128` by default.
- Accepts only HTTP `CONNECT`.
- Exact-host allowlist only; no suffix/wildcard matching.
- Allows CONNECT only to port `443`.
- Rejects IP-literal targets.
- Resolves DNS proxy-side by calling `net.connect({ host, port })`.
- Denies by default.
- Logs every allow/deny/malformed request as JSONL.
- Reads allowlist from a root-owned file and refuses group/world-writable allowlists.
- Reloads allowlist on `SIGHUP`; there is no network reconfiguration endpoint.

Draft install paths:

- Source:
  `/Library/Application Support/agent-os-egress-proxy/agent-os-egress-proxy.mjs`
- Allowlist:
  `/Library/Application Support/agent-os-egress-proxy/allowlist.txt`
- Audit log:
  `/Library/Logs/agent-os-egress-proxy/proxy.jsonl`
- LaunchDaemon:
  `/Library/LaunchDaemons/ai.agent-os-egress-proxy.plist`

Recommended ownership/mode:

```sh
sudo mkdir -p "/Library/Application Support/agent-os-egress-proxy"
sudo mkdir -p /Library/Logs/agent-os-egress-proxy
sudo chown root:egressproxy "/Library/Application Support/agent-os-egress-proxy"
sudo chmod 0750 "/Library/Application Support/agent-os-egress-proxy"
sudo chown root:egressproxy "/Library/Application Support/agent-os-egress-proxy/agent-os-egress-proxy.mjs"
sudo chmod 0440 "/Library/Application Support/agent-os-egress-proxy/agent-os-egress-proxy.mjs"
sudo chown root:egressproxy "/Library/Application Support/agent-os-egress-proxy/allowlist.txt"
sudo chmod 0440 "/Library/Application Support/agent-os-egress-proxy/allowlist.txt"
sudo chown egressproxy:egressproxy /Library/Logs/agent-os-egress-proxy
sudo chmod 0750 /Library/Logs/agent-os-egress-proxy
sudo chown root:wheel /Library/LaunchDaemons/ai.agent-os-egress-proxy.plist
sudo chmod 0644 /Library/LaunchDaemons/ai.agent-os-egress-proxy.plist
```

The `egressproxy` role user is operator-created by hand. It must be non-admin and
non-login. It does not need access to OpenClaw state or the Gmail broker.

## Allowlist

Draft allowlist:

```text
chatgpt.com
search.parallel.ai
html.duckduckgo.com
api.telegram.org
```

Notes:

- `chatgpt.com`, `search.parallel.ai`, and `html.duckduckgo.com` came from FA4_2 live
  proxy capture.
- `api.telegram.org` is the Telegram control plane.
- Broker Google hosts are separate because the broker is a different process/user.
- `example.com` is intentionally not in the allowlist. Use
  `openclaw proxy validate --allowed-url https://chatgpt.com/ --denied-url https://example.com/`
  instead of the default validator target.

## Proxy LaunchDaemon Draft

Draft file: `drafts/fa4-phase5/ai.agent-os-egress-proxy.plist`.

The plist runs as `egressproxy`, not `openclawgw`, and points Node at the installed
source path. It writes launchd stdout/stderr under `/Library/Logs/agent-os-egress-proxy/`.
The operator must install it as `root:wheel 0644`.

Bootstrap commands, only after the role user and files are installed:

```sh
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.agent-os-egress-proxy.plist
sudo launchctl kickstart -k system/ai.agent-os-egress-proxy
sudo launchctl print system/ai.agent-os-egress-proxy
lsof -nP -iTCP:13128 -sTCP:LISTEN
```

Sanity tests before touching OpenClaw config:

```sh
curl -I --max-time 10 -x http://127.0.0.1:13128 https://chatgpt.com/
curl -I --max-time 10 -x http://127.0.0.1:13128 https://example.com/ && echo "BAD" || echo "denied good"
sudo tail -20 /Library/Logs/agent-os-egress-proxy/proxy.jsonl
```

## pf Backstop Draft

Draft anchor: `drafts/fa4-phase5/agent-os-egress.anchor`.

Rules:

```pf
pass quick on lo0 all
pass out quick proto tcp from any to 127.0.0.1 port 13128 user openclawgw
block drop out quick proto { tcp udp } from any to any user openclawgw
```

Rationale:

- Loopback remains intact for the gateway control plane, proxy port, Ollama, and other
  local IPC-adjacent use.
- `openclawgw` may connect to the proxy port only.
- `openclawgw` gets no direct DNS, because CONNECT carries the hostname and the proxy
  resolves it.
- Other users/processes are not restricted by this anchor.

Critical pf persistence note:

Loading an anchor by name is not enough unless the main ruleset references it. The
operator must add the reviewed `pf.conf.fragment` lines to `/etc/pf.conf`:

```pf
anchor "agent-os/egress"
load anchor "agent-os/egress" from "/Library/Application Support/agent-os-egress-proxy/agent-os-egress.anchor"
```

Then dry-run the full ruleset:

```sh
sudo pfctl -nf "/Library/Application Support/agent-os-egress-proxy/agent-os-egress.anchor"
sudo pfctl -nf /etc/pf.conf
```

Only after that succeeds, capture state and load:

```sh
sudo pfctl -sa > /Users/dannybigdeals/pf-state-before.txt 2>&1
sudo pfctl -f /etc/pf.conf
```

The `ai.agent-os-egress-pf.plist` draft reloads `/etc/pf.conf` at boot. It assumes
the operator has already added the anchor/load lines to `/etc/pf.conf`. Install it as
`root:wheel 0644`.

## Gateway Config Change For Operator

After the proxy sanity tests pass and before pf is loaded, edit root-owned
`/Users/agent/.openclaw/openclaw.json` as root:

```json
"proxy": {
  "enabled": true,
  "proxyUrl": "http://127.0.0.1:13128",
  "loopbackMode": "gateway-only"
}
```

Then restart the gateway daemon and prove forced researcher web_search works through
the proxy log. Do not proceed to pf until the managed proxy path works.

## Proof Commands

Draft command file: `drafts/fa4-phase5/phase5-proof-commands.sh`.

It is intentionally written as a command set for the operator to run/review by hand,
not as an unattended automation script. It covers:

- proxy allow/deny sanity;
- pf dry-run command;
- non-`openclawgw` connectivity check;
- direct egress denial as `openclawgw`;
- DNS-denial as `openclawgw`;
- lock confirmation for `openclaw.json`, allowlist, and pf anchor;
- native `openclaw proxy validate` using explicit allowed/denied URLs.

## Acceptance Criteria

F-A4 Phase 5 accepts only when all are true:

- Forced researcher web_search succeeds and proxy log shows allowed CONNECTs to
  `chatgpt.com` and `search.parallel.ai` as needed.
- Direct `curl` as `openclawgw` to both `example.com` and `chatgpt.com` fails without
  using the proxy.
- Direct DNS as `openclawgw` fails.
- `openclawgw` cannot edit `openclaw.json`, the allowlist, or the pf anchor.
- `openclaw proxy validate --proxy-url http://127.0.0.1:13128 --allowed-url https://chatgpt.com/ --denied-url https://example.com/` passes.
- F-A1 broker read, F-A3 gate, Telegram, and broker Google egress still work.

## Recovery Notes

If pf causes unexpected connectivity loss, recover from local console or an existing
admin session:

```sh
sudo pfctl -d
```

If the bad anchor has been added to `/etc/pf.conf`, comment out the
`agent-os/egress` fragment before reloading `/etc/pf.conf`; otherwise reloading the
same file will reload the bad anchor. Then inspect
`/Users/dannybigdeals/pf-state-before.txt`, the pf anchor, and the `/etc/pf.conf`
fragment before retrying. Disabling pf removes the backstop until it is reloaded; the
managed proxy may still be active.
