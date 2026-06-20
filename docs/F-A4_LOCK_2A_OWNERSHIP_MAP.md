# F-A4-LOCK-2A Ownership Map

Date: 2026-06-20

Scope: read-mostly analysis for Strategy B, "own, do not move". No users,
ownership, daemons, proxy, pf, broker, or OpenClaw config were changed.

## Headline Finding

The configured OpenClaw agents on this machine are native embedded runs inside
the gateway runtime, not separate OS users. Source evidence:

- `attempt-execution-CgTGShuY.js` dispatches normal configured agents through
  `runEmbeddedAgent(...)`.
- `runs-DNgzt7ZR.d.ts` describes "Shared process state for embedded-agent runs"
  and "active embedded runs".
- `docs/tools/subagents.md` distinguishes native sub-agents from `runtime:"acp"`;
  native sub-agents are OpenClaw config agents, while ACP is the external harness
  path.
- `acp-spawn-DDo_MPoU.js` explicitly says ACP sessions run on the host and are
  separate from `runtime:"subagent"`; it rejects configured OpenClaw agents as ACP
  targets unless they are configured as ACP runtimes.

Therefore Model 1 as originally imagined, "gateway=openclawgw but agents=agent",
is not mechanically available in the current OpenClaw native-agent design.
If the gateway runs as `openclawgw`, native agents run under the same effective
UID. Any ownership plan where `openclawgw` owns writable egress config recreates
the original trust-boundary hole under a new username.

Cutover design must be adjusted:

- Gateway process may run as `openclawgw`.
- Native agents will also execute in that process/UID.
- Egress-sensitive configuration must be owned by root or a third operator-owned
  account, not by `openclawgw`, and must be read-only to `openclawgw`.
- The pf/proxy policy remains root/operator-owned.

## Consumer Inventory

Current live state:

- Gateway is a user LaunchAgent in `gui/501`, running as `agent`.
- `~/.openclaw` is `agent:staff`.
- Most runtime dirs/files are `0700`/`0600`.
- Current `.openclaw` drift repo tracks only a narrow allowlist; live
  `openclaw.json`, service env, state, secrets, sessions, logs, identity, npm,
  memory, devices, credentials, tmp, sandboxes are ignored runtime state.

### Path Consumers

| Path | Gateway touches | Native agents touch | Egress-sensitive | Notes |
| --- | --- | --- | --- | --- |
| `openclaw.json` | read at startup/runtime; CLI may update outside service | policy/config read through gateway runtime | yes | Current live file ignored by git, `0600 agent`. Must not be writable by contained UID. |
| `proxy.*` keys | read by gateway before managed proxy install | affects all native agent egress | yes | Must be root/operator-controlled. |
| `service-env/` | launchd wrapper reads; gateway env source | inherited by embedded runtime and child exec tools | yes | Contains `HOME`, `PATH`, `TMPDIR`, service port. Must not be writable by contained UID. |
| `state/openclaw.sqlite*` | read/write | read/write via in-process sessions/state | no direct egress, operationally critical | FA4_2 and prior CLI checks observed OpenClaw chmod/write behavior around `state/`; service UID needs write. |
| `secrets/secrets.json` | reads SecretRefs, gateway token | in-process runtime can resolve through gateway | sensitive but not egress config | Service needs read; agent should not write. |
| `secrets/telegram.json` | Telegram channel token read | channel runtime in gateway reads | sensitive but not egress config | Service needs read; agent should not write. |
| `identity/device-auth.json` | gateway identity/auth writes | in-process runtime observes via gateway | sensitive runtime state | Service needs read/write. |
| `logs/` | writes config/gate logs | gate script writes logs when executed | audit/log state | Service needs write; agent observer may need read. |
| `tmp/` | locks, node cache, hook relay dirs | child exec/tools use inherited `TMPDIR` | operational | Service needs write. Path currently includes UID-specific `openclaw-501` dirs. |
| `npm/` | plugin install/cache load | plugins/codex harness use | supply-chain sensitive | Service needs read/write for plugin lifecycle; agent should not write if runtime is locked. |
| `plugin-skills/` | plugin skill load | prompt/runtime reads | policy/prompt sensitive | Service needs read; writes only by operator/plugin install. |
| `devices/` | pairing/device state write | control-plane reads through gateway | sensitive runtime state | Service needs read/write. |
| `credentials/` | pairing/allowFrom state | channel auth support | sensitive runtime state | Service needs read/write. |
| `memory/` | memory DB read/write | in-process agents use memory tools/context | data-sensitive | Service needs read/write if memory stays enabled. |
| `scripts/` | not core gateway, but tools invoke | agent exec tools run broker/gate wrappers | policy-sensitive | Scripts should be immutable to contained UID; executable/readable by service. |
| `exec-approvals.json` | approval policy read/write by CLI/runtime | affects exec tool decisions | policy-sensitive | Should be operator/root-controlled or at least not writable by contained UID. |
| `workspace*` | reads bootstrap files; may write injected runtime files | prompt files read; some `.openclaw` workspace state written | prompt/policy sensitive | AGENTS/TOOLS/SOUL/etc should be immutable; per-run workspace scratch needs separate write area if required. |
| `agents/*/sessions/` | transcript/session write | native agents write through gateway runtime | runtime state | Service needs write; agent observer may need read. |
| `.git` + tracked worktree | agent currently commits drift | gateway does not need git | drift integrity | Do not let service UID and agent both write one repo. |
| `/Users/agent/.local/openclaw` | launchd executes Node/OpenClaw | child exec inherits PATH | runtime binary trust | Current path is `agent:staff` readable/executable. Should become root/service read-only for service. |
| `/var/run/agent-os/gmail-broker.sock` | not gateway core; gmail-reader tool connects via script | gmail-reader broker client connects | F-A1/F-A2 dependency | Access is `gmailbroker:gmailbroker-clients` `0660`; `openclawgw` must be in that group if gateway UID runs broker client. |

## Read/Write/Exec Matrix

Proposed groups:

- `openclawgw`: service user primary group.
- `openclaw-observers`: optional read-only group containing `agent` for drift
  observation. This group must not grant writes to egress-sensitive files.
- `gmailbroker-clients`: existing broker socket access group; add `openclawgw`
  only after pre-move broker proof.

| Path | Gateway needs | Agent/Codex observer needs | Egress-sensitive | Proposed owner | Proposed group | Proposed mode |
| --- | --- | --- | --- | --- | --- | --- |
| `~/.openclaw` | traverse | read/traverse for observation | boundary root | `root` | `openclawgw` plus ACL/read group as needed | `0750` plus explicit ACLs, or `0755` if no secrets exposed by mode below |
| `openclaw.json` | read | read only | yes | `root` | `openclawgw` | `0440` |
| `service-env/` | traverse/read wrapper/env | no write; maybe read for audit | yes | `root` | `openclawgw` | dir `0550`, files `0440`, wrapper `0550` |
| durable proxy env file | read | no access or read only | yes | `root` | `openclawgw` | `0440` |
| `exec-approvals.json` | read | read for audit | policy-sensitive | `root` | `openclawgw` | `0440` |
| `scripts/*.mjs`, `scripts/*.sh` used by tools | execute/read | read for audit | policy-sensitive | `root` | `openclawgw` | executables `0550`, non-exec `0440` |
| `policies/` | read | read for audit | policy-sensitive | `root` | `openclawgw` | dir `0550`, files `0440` |
| `doctrine/`, tracked `AGENTS.md`/`TOOLS.md`/prompt policy files | read | read for audit | prompt/policy-sensitive | `root` | `openclawgw` | dirs `0550`, files `0440` |
| `secrets/` | read | no access | secret | `openclawgw` or `root` | `openclawgw` | dir `0500`/`0550`, files `0400`/`0440` |
| `state/` | read/write/chmod | no write; optional no read | runtime | `openclawgw` | `openclawgw` | dir `0700`, sqlite `0600` |
| `agents/*/sessions/` | read/write | optional read-only export, not direct write | runtime/data | `openclawgw` | `openclawgw` | dirs `0700`, files `0600` |
| `logs/` | write | read for audit if needed | audit | `openclawgw` | `openclaw-observers` | dir `0750`, files `0640` |
| `tmp/` | read/write | none | runtime | `openclawgw` | `openclawgw` | `0700` |
| `npm/`, `plugin-skills/` | read/write during plugin lifecycle | no write | supply-chain | `openclawgw` for runtime cache; root for pinned plugins where possible | `openclawgw` | `0700`; root-owned plugin pins if locked |
| `devices/`, `credentials/`, `identity/`, `memory/` | read/write | no write | sensitive runtime | `openclawgw` | `openclawgw` | dirs `0700`, files `0600` |
| `workspace*/.openclaw`, sandbox scratch | read/write if runtime creates files | no write | runtime | `openclawgw` | `openclawgw` | `0700` |
| tracked workspace policy files | read | read for audit | prompt/policy | `root` | `openclawgw` | `0440` |
| `.git` drift repo | no runtime need | write commits as observer workflow | drift | `agent` or separate observer repo owner | `staff` | keep outside service-owned runtime writes |
| `/Users/agent/.local/openclaw/tools/...` | execute/read | maybe execute CLI | runtime binary | root or service-readable immutable owner | `openclawgw`/`staff` | dirs `0555`, files `0555` for runtime binary path |

Important correction to Strategy B: do not make `openclawgw` owner-writable on
egress-sensitive files if native agents run as `openclawgw`. Use root-owned,
service-readable files for the enforcement configuration.

## Model Recommendation

Model 1, "gateway only moves while native agents stay `agent`", is not feasible
with current OpenClaw native agents. Native configured agents are embedded runs
inside the gateway process. They do not get a separate Unix UID.

Model 2, "gateway + native agents move to `openclawgw`", is what will actually
happen if the LaunchDaemon runs the gateway as `openclawgw`. This is acceptable
only if `openclawgw` does not own writable egress configuration. The containment
boundary for agents remains:

- OpenClaw tool policy and typed handoff.
- Managed proxy capture for normal runtime HTTP/WebSocket.
- Root-owned proxy config and pf backstop outside `openclawgw`.
- Root-owned immutable scripts/policy where tool execution could otherwise edit
  its own controls.

Thus the recommended model is "Model 2 runtime identity, root-owned controls":

- Gateway/native agents run as `openclawgw`.
- `agent` becomes a Codex/operator observer and repo maintainer, not the OpenClaw
  runtime owner.
- Root/operator owns egress config, service env, LaunchDaemon, pf, and proxy policy.
- `openclawgw` owns mutable runtime state only.

## Git Drift Repo Split

Current tracked baseline in `~/.openclaw`:

- `.gitignore`
- `ITERATION_LOG.md`
- `exec-approvals.json`
- `openclaw.sanitized.json`
- `policies/gmail-draft-safe.yaml`
- `scripts/*.mjs` and helper scripts
- `doctrine/main-AGENTS.md`
- tracked workspace `AGENTS.md` / `TOOLS.md` files
- `workspace-research-handoff-gate/logs/.gitkeep`

Current ignored runtime state includes:

- live `openclaw.json` and backups
- `service-env/`
- `state/`
- `secrets/`
- `agents/`
- `logs/`
- `tmp/`
- `npm/`
- `memory/`
- `identity/`
- `devices/`
- `credentials/`
- `sandboxes/`
- `plugin-skills/`
- `update-check.json`
- generated workspace bootstrap/identity files

Recommended split:

1. Runtime state stays at `/Users/agent/.openclaw` per Strategy B, but ownership
   is divided:
   - mutable runtime state: `openclawgw:openclawgw`;
   - egress/policy baseline files: `root:openclawgw` read-only to service;
   - observer snapshots/reports: `agent` in the `agent-os` repo, not direct commits
     from service-owned runtime churn.
2. Stop treating the live `.openclaw` tree as a normal writable Git worktree if
   service-owned runtime state lives inside it. Mixed UID writes will make drift
   commits brittle.
3. Keep authoritative planning state in `agent-os/CONTROL.md`.
4. Generate a sanitized drift snapshot from root/service-owned files into an
   agent-writable report location, or let operator run a root-owned snapshot job
   that writes a read-only artifact for `agent`.
5. If the `.openclaw` Git repo remains, keep `.git` owned by `agent` and do not
   let `openclawgw` write tracked files. Root-owned tracked files can still be
   read by `agent`, but committing changes requires operator-mediated staging or
   an exported sanitized copy.

Concrete future `.gitignore` posture:

- Continue ignoring runtime churn (`state/`, `agents/`, `logs/`, `tmp/`, `npm/`,
  `identity/`, `memory/`, `devices/`, `credentials/`, `secrets/`, `service-env/`).
- Do not track live secret/config files directly.
- Track generated sanitized snapshots in `agent-os` or a dedicated export dir
  rather than committing from the service-owned runtime tree.

## Cutover Prerequisites for 2B

Operator/root actions to prepare, not executed in this drop:

1. Create service user `openclawgw`, non-admin, no interactive login.
2. Add `openclawgw` to `gmailbroker-clients` only after confirming the broker
   pre-move proof is complete.
3. Create root-owned LaunchDaemon in `/Library/LaunchDaemons` running as
   `openclawgw`.
4. Do not use an agent-writable LaunchAgent or service env.
5. Make root-owned, service-readable egress controls:
   - `proxy.enabled=true` config source;
   - `proxy.proxyUrl` or durable `OPENCLAW_PROXY_URL`;
   - LaunchDaemon env/plist;
   - proxy policy and pf rules.
6. Make mutable runtime dirs `openclawgw` writable:
   - `state/`, `agents/`, `logs/`, `tmp/`, `npm/`, `plugin-skills/` if dynamic,
     `devices/`, `credentials/`, `identity/`, `memory/`, `sandboxes/`,
     `workspace*/.openclaw`, workspace attestations.
7. Make policy/script/prompt files read-only to `openclawgw`:
   - `openclaw.json`, `service-env/`, `exec-approvals.json`, `scripts/`,
     `policies/`, tracked `AGENTS.md`/`TOOLS.md`/doctrine.
8. Re-home or pin the Node/OpenClaw runtime path so the daemon is not executing
   mutable `agent`-owned binaries.
9. Decide the drift export mechanism before the cutover so `agent` can observe
   but not mutate service controls.
10. Validate with a staging read-only path check before launch:
    - every LaunchDaemon path exists;
    - `openclawgw` can read config/scripts/secrets and write runtime dirs;
    - `agent` cannot write egress config/service env/proxy URL.

## Operator-Only Checks Still Needed

- Confirm DROP F-A4-LOCK-1 result: broker accepts a non-agent UID in
  `gmailbroker-clients` and has no hidden peer-UID check.
- Use `sudo -u openclawgw` after user creation to run read/write probes against
  the planned paths before launch.
- Verify OpenClaw can start with a root-owned read-only `openclaw.json`; if it
  attempts to rewrite config on startup, move mutable config outputs elsewhere
  or split immutable proxy config into root-owned service env plus service-owned
  non-security config.
- Check whether any plugin install/update path expects to write into tracked
  `scripts/` or policy files.
- Verify the root-owned pf/proxy backstop with `pfctl -nf` before enabling.

## Bottom Line

Strategy B's "paths do not move" part is viable, but "service user owns the tree"
is too broad. Because native agents are in-process under the gateway UID, the
service UID is also the contained-agent UID. The cutover must make
`openclawgw` the owner of mutable runtime state only, while root/operator owns
egress controls and other policy files read-only to the service.
