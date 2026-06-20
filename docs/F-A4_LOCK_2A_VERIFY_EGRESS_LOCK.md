# F-A4-LOCK-2A-VERIFY Egress Lock Verification

Date: 2026-06-20

Scope: source-trace verification only. No live OpenClaw config, gateway,
broker, proxy, pf, user, ownership, daemon, or environment state was changed.
No staging gateway was started by Codex because the empirical root-owned config
test is operator-by-hand.

## Executive Verdict

The surviving lock is root/operator-owned config plus root/operator-owned pf.

Source shows normal gateway startup does not rewrite `openclaw.json`; it reads
and validates the config, applies some runtime-only changes in memory, and
writes mutable sibling state such as health/audit/runtime files. Therefore a
root-owned, service-readable `openclaw.json` is the clean configuration lock
candidate.

However, the managed proxy is still a process-level guardrail. Because native
agents are in-process under the gateway UID after re-home, pf is mandatory as
the OS-level backstop against raw-socket or unsupported transport bypass. It is
not merely additive for the F-A4 trust boundary.

## Q1 - Does Gateway Rewrite `openclaw.json` on Startup?

Verdict: source evidence says **SIBLINGS-ONLY for normal startup**. The gateway
must be able to write state/log/runtime siblings, but normal startup does not
require `openclaw.json` to be writable.

Evidence:

- `server-startup-config-6Ye8RlN1.js` loads startup config through
  `readConfigFileSnapshotWithPluginMetadata(...)`, then sets
  `const wroteConfig = false`.
- The same startup loader calls `applyPluginAutoEnable(...)` and explicitly logs
  that plugins were auto-enabled "for this runtime without writing config".
- `server.impl-Btmg89EG.js` only re-reads a final config snapshot if
  `startupConfigLoad.wroteConfig || authBootstrap.persistedGeneratedToken`.
  With default startup auth persistence false, that path does not fire for
  ordinary startup.
- The docs say startup and hot reload fail closed or skip invalid configs;
  repair is owned by `openclaw doctor --fix`.

Important distinction:

- Explicit writer paths still exist. `setupCommand(...)`, `config.apply`,
  `config.patch`, `openclaw config set`, onboarding/setup, and doctor repair
  can rewrite config.
- The core write path `writeConfigFileLocal(...)` writes through atomic replace,
  chmods mode `0600`, maintains backups, and writes rejected payload siblings.
- `recoverConfigFromJsonRootSuffixWithDeps(...)` and doctor repair can write
  repaired config back to the config path.

Implication:

- 2B should not run setup/doctor/config mutation as the runtime service user
  against the locked production config.
- Normal gateway startup should tolerate `openclaw.json` as root-owned
  read-only to the service user, but this still needs the operator staging proof
  requested by the drop.

Operator empirical test status:

- Not run by Codex. The requested staging test requires root-owned staging
  ownership and running a staging gateway under operator-controlled conditions.

## Q2 - Proxy URL Precedence

Verdict: **config wins over env**.

Runtime lifecycle source:

```js
function resolveProxyUrl(config) {
  const candidate = config?.proxyUrl?.trim() || process.env["OPENCLAW_PROXY_URL"]?.trim();
  if (!candidate) throw new Error("proxy: enabled but no HTTP proxy URL is configured; set proxy.proxyUrl or OPENCLAW_PROXY_URL to an http:// or https:// forward proxy.");
  if (!isSupportedProxyUrl(candidate)) throw new Error("proxy: enabled but proxy URL is invalid; set proxy.proxyUrl or OPENCLAW_PROXY_URL to an http:// or https:// forward proxy.");
  return candidate;
}
```

Validation source says the same thing:

```js
/** Resolves validation config precedence: explicit override, config, then env. */
function resolveProxyValidationConfig(options) {
  const overrideUrl = normalizeProxyUrl(options.proxyUrlOverride);
  ...
  const configUrl = normalizeProxyUrl(options.config?.proxyUrl);
  ...
  const envUrl = normalizeProxyUrl(options.env?.OPENCLAW_PROXY_URL);
  ...
}
```

The docs also state: "`proxy.proxyUrl` takes precedence over
`OPENCLAW_PROXY_URL`."

Implication:

- A root-owned `OPENCLAW_PROXY_URL` env file alone is not a lock if the runtime
  can write `openclaw.json`, because writable config can override the env URL.
- The proxy URL lock must be in root-owned config, or pf must force egress to
  the operator proxy regardless of runtime config.

## Q3 - Can `proxy.enabled` Be Forced Outside Writable Config?

Verdict: **No source-supported env pin was found for managed `proxy.enabled`.**

Evidence:

- Managed proxy activation calls `startProxy(config?.proxy)`.
- `startProxy(config)` immediately returns if `config?.enabled !== true`.
- `OPENCLAW_PROXY_URL` supplies only the URL fallback after config has enabled
  the managed proxy.
- Source and docs searches found no `OPENCLAW_PROXY_ENABLED` equivalent for the
  managed proxy. The only similar env is `OPENCLAW_DEBUG_PROXY_ENABLED`, which
  belongs to the debug/capture proxy, not the managed egress proxy.
- Validation explicitly rejects env URL use unless `proxy.enabled` is true:
  `proxy validation requires proxy.enabled to be true for OPENCLAW_PROXY_URL`.

Implication:

- If `openclaw.json` is writable by the runtime, the runtime can set
  `proxy.enabled=false`, and the managed proxy fails open to direct network.
- Therefore `proxy.enabled` must be pinned in a root/operator-owned config
  source, or pf must be primary.

## Q4 - Surviving Enforcement Design

Branch: **Q1 source says SIBLINGS-ONLY, so root-owned config is viable.**

The clean 2B design should be:

- `openclaw.json`: `root:openclawgw`, mode `0440`.
- Config contains:
  - `proxy.enabled: true`
  - `proxy.proxyUrl: http://127.0.0.1:<operator-proxy-port>`
  - `proxy.loopbackMode` explicitly chosen, likely `gateway-only` unless the
    operator wants loopback proxied or blocked.
- The LaunchDaemon plist and any durable env file are root-owned and not
  writable by `openclawgw`.
- `openclawgw` owns mutable runtime siblings only: `state/`, `logs/`, `tmp/`,
  `agents/*/sessions/`, caches, identity/device state as required.
- Setup/doctor/config mutation commands must be operator-run only, not exposed
  to the service runtime as a normal write path.
- pf is mandatory for F-A4 hostile-agent containment:
  - root-owned pf rule forces outbound traffic from UID `openclawgw` to the
    operator proxy port, and drops non-proxy outbound traffic;
  - loopback traffic needed for Gateway control-plane and local IPC remains
    allowed according to the final pf design;
  - the operator proxy performs hostname allowlisting and audit logging.

Why pf is mandatory, even in the root-owned-config branch:

- OpenClaw's network-proxy docs call the managed proxy a "process-level
  guardrail for normal HTTP and WebSocket egress", not an OS-level network
  sandbox.
- The same docs say it routes ordinary `fetch`, Node HTTP/HTTPS, WebSocket, and
  common clients through Proxyline, but this does not certify every possible raw
  socket/custom transport.
- After re-home, native agents and gateway share UID/process trust. The only
  enforcement point the in-process runtime cannot rewrite is root/operator-owned
  OS policy plus the external proxy.

If the operator staging run contradicts source and proves normal startup needs
`openclaw.json` writable, then the design flips:

- Config/env cannot be trusted as the primary lock.
- pf becomes the primary enforcement point.
- Config proxy settings become advisory/operational convenience only.

## 2B Concrete Inputs

Use these inputs if the operator staging run confirms startup works with a
read-only config:

| Path / control | Owner | Group | Mode | Notes |
| --- | --- | --- | --- | --- |
| `~/.openclaw/openclaw.json` | `root` | `openclawgw` | `0440` | Holds `proxy.enabled=true` and `proxy.proxyUrl`; not writable by runtime UID. |
| LaunchDaemon plist | `root` | `wheel` | `0644` | Runs gateway as `openclawgw`; not writable by `agent` or `openclawgw`. |
| durable service env, if used | `root` | `openclawgw` | `0440` | May hold non-overriding env; cannot lock URL if config writable. |
| mutable runtime dirs | `openclawgw` | `openclawgw` | dirs `0700`, files `0600` | `state/`, `logs/`, `tmp/`, sessions, caches, device/identity as needed. |
| operator proxy config | `root` or operator admin | root/operator group | not writable by `openclawgw` | Contains hostname allowlist and logging policy. |
| pf rules | `root` | `wheel` | system policy | Mandatory OS backstop for UID `openclawgw`. |

Minimum config lock content:

```json
{
  "proxy": {
    "enabled": true,
    "proxyUrl": "http://127.0.0.1:<operator-proxy-port>",
    "loopbackMode": "gateway-only"
  }
}
```

Do not rely on:

- `OPENCLAW_PROXY_URL` alone;
- an `openclawgw`-writable `openclaw.json`;
- managed proxy without pf for hostile-agent containment.

## Staging Work Not Performed

No staging gateway was started. No throwaway config tree was created. No temp
files were left by this drop.

Recommended operator staging command shape, to be adapted by the operator:

- create a throwaway state tree;
- place a minimal valid config at `OPENCLAW_CONFIG_PATH`;
- make that staging config root-owned `0440` and group-readable by the test
  service user;
- run a loopback, non-default-port gateway with `OPENCLAW_STATE_DIR` pointing at
  the writable staging state dir;
- confirm it starts without attempting to rewrite the config path;
- confirm mutable siblings are written under the staging state dir only;
- stop the staging gateway and remove the throwaway tree.

## Bottom Line

Source supports locking managed proxy config in root-owned read-only
`openclaw.json`. But because `proxy.enabled` is config-only and config URL beats
env URL, any writable config defeats the managed proxy. And because the managed
proxy is process-level rather than OS-level containment, pf remains mandatory for
F-A4 once native agents and gateway share the same runtime UID.
