# F-A4-LOCK-2B-0READ Credential Custody Pass

Date: 2026-06-20
OpenClaw version checked: `OpenClaw 2026.6.5 (5181e4f)`

## Scope

Read-only source/config pass for the gateway re-home credential question: will moving
the gateway from `agent` to a non-login role account make any gateway-critical secret
unreachable because it is bound to the `agent` login session or macOS Keychain?

No users, ownership, gateway service, proxy, pf, broker process, or live config were
changed.

## Headline Verdict

The re-home is credential-safe enough to proceed to the operator Phase 0 staging probe.
On this install, the gateway-critical secrets are file/SQLite based under
`/Users/agent/.openclaw` and are portable by ownership/mode transfer. I found no active
gateway auth path that requires the macOS login Keychain.

Important caveat: OpenClaw does include optional/legacy macOS Keychain discovery for
external CLI auth profiles. The runtime paths checked for gateway/agent execution set
`allowKeychainPrompt: false`, and the doctor path treats legacy Keychain-only OAuth
profiles as something to repair/migrate for headless operation. Phase 0 should still
exercise the actual auth/search path as `gwtest`, because only that proves the current
profile data is not a legacy Keychain-only edge case.

## Keychain Findings

Search scope: installed OpenClaw package under
`/Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw`, excluding
dependency noise.

Hits found:

- `dist/store-CInQELlL.js` can read Codex CLI credentials from macOS Keychain service
  `Codex Auth`, and Claude CLI credentials from `Claude Code-credentials`.
- Those readers return no Keychain credential when `allowKeychainPrompt === false`.
- `dist/doctor-auth-oauth-sidecar-CyX8yj1m.js` has a legacy OpenClaw OAuth Keychain
  repair/migration path for service `OpenClaw Auth Profile Secrets`.
- Runtime/gateway/agent paths checked use `allowKeychainPrompt: false`, including
  embedded agent model/auth bootstrap and secrets-runtime auth-store loading.

Active gateway auth path:

- `openclaw.json` has `gateway.auth.mode="token"` and the token is a `SecretRef`:
  `source=file`, `provider=local`, `id=/gatewayToken`.
- `secrets.providers.local.path` is
  `/Users/agent/.openclaw/secrets/secrets.json`.
- Gateway startup prepares and activates runtime secrets from configured SecretRefs;
  file providers are resolved by secure file reads and JSON Pointer lookup.

Verdict: no active gateway auth path found that reads/writes secrets through macOS
Keychain. Keychain code exists for external CLI credential discovery and legacy repair,
but the runtime paths relevant to this cutover are headless/file-store paths.

## Per-Secret Storage Table

| Secret / credential | Storage mechanism | Path / selector | Portable to `openclawgw`? | Notes |
| --- | --- | --- | --- | --- |
| Gateway auth token | OpenClaw file `SecretRef` provider `local` | `/Users/agent/.openclaw/secrets/secrets.json`, JSON pointer `/gatewayToken` | Yes | Current mode `0600 agent:staff`; needs service-readable custody after cutover. |
| Telegram bot token | OpenClaw file `SecretRef` provider `telegram` | `/Users/agent/.openclaw/secrets/telegram.json`, JSON pointer `/botToken` | Yes | Current mode `0600 agent:staff`; no Keychain dependency found. |
| Device auth / identity | File state | `/Users/agent/.openclaw/identity/device-auth.json`, `/Users/agent/.openclaw/identity/device.json` | Yes | Current dir/file modes are private to `agent`; service user needs the same custody. |
| Telegram pairing / allowlist state | File state | `/Users/agent/.openclaw/credentials/telegram-pairing.json`, `/Users/agent/.openclaw/credentials/telegram-default-allowFrom.json` | Yes | Runtime state; should be service-owned read/write. |
| Agent auth profile stores | SQLite/file runtime stores | `/Users/agent/.openclaw/agents/<agent>/agent/openclaw-agent.sqlite*` | Yes | Current stores are `0600 agent:staff`; runtime code loads auth stores with Keychain prompts disabled. |
| Model provider API keys | Config/auth-profile based if present | Live config only declares local Ollama at `http://127.0.0.1:11434`; no OpenAI/Brave/Tavily key found in `openclaw.json` | Yes / not present in config | Any non-local provider creds would need to be in the auth-profile/file-secret custody set, not agent Keychain. |
| Native web_search / Codex Responses auth | OpenClaw/Codex auth profile/runtime state, not live `openclaw.json` plaintext | Agent auth-profile stores under `/Users/agent/.openclaw/agents/...` and any runtime auth profile state | Likely yes; Phase 0 should prove | Source shows native Codex/OpenAI auth bootstrap loads auth profiles with `allowKeychainPrompt:false`. |
| Gmail / Google OAuth | Broker-owned, outside gateway | Broker tree under `/Users/gmailbroker/...` | Separate custody | Codex cannot read broker source due permissions; operational precedent is strong because broker already runs as role account `gmailbroker`. |

Current relevant modes observed:

- `/Users/agent/.openclaw` is `0700 agent:staff`.
- `secrets/`, `identity/`, `credentials/`, `service-env/`, `tmp/` are `0700 agent:staff`.
- `openclaw.json`, `secrets/*.json`, `identity/device-auth.json`, service env, and
  agent SQLite auth stores are `0600 agent:staff` (env wrapper is `0700` executable).

These modes are compatible with secure custody, but they must be deliberately moved or
re-permissioned for the service account. A non-login `openclawgw` with default home
`/var/empty` will not see these files unless the LaunchDaemon explicitly points it at
the retained `/Users/agent/.openclaw` tree and the ownership plan grants access.

## Broker Role-Account Precedent

Codex could not read `/Users/gmailbroker/agent-os-gmail-broker`:

`find: /Users/gmailbroker/agent-os-gmail-broker: Permission denied`

That is expected and is not a blocker for this read pass. The operational fact still
matters: Gmail works today with the broker running as the role account `gmailbroker`.
If Google/Gmail OAuth depended on the `agent` login Keychain, the current broker design
would already fail. Therefore the broker is strong precedent that the Gmail credential
path is file/keyring custody under the broker user, not `agent` Keychain custody.

Operator-only confirmation, if desired before cutover: read the broker source and
credential paths as `dannybigdeals`/root and confirm the gog file-keyring custody, but
do not change broker files or process state.

## `agent` HOME / Path Dependencies

Credential-safe does not mean path-free. The current service setup is intentionally tied
to `/Users/agent`:

- `service-env/ai.openclaw.gateway.env` exports `HOME=/Users/agent`.
- It sets `PATH=/Users/agent/.local/openclaw/tools/node-v22.22.0/bin:...`.
- It sets `TMPDIR=/Users/agent/.openclaw/tmp`.
- Live config hardcodes workspaces under `/Users/agent/.openclaw/workspace*`.
- Live config hardcodes secret provider paths:
  `/Users/agent/.openclaw/secrets/secrets.json` and
  `/Users/agent/.openclaw/secrets/telegram.json`.
- `exec-approvals.json` and local scripts contain absolute paths under
  `/Users/agent/.openclaw/scripts/...`.

Cutover implications:

- The LaunchDaemon should not rely on `openclawgw`'s default `HOME`; it should set the
  intended OpenClaw config/state/home paths explicitly.
- The OpenClaw node/runtime path under `/Users/agent/.local/openclaw/...` must be
  executable/readable by `openclawgw`, or moved to a root/service-readable runtime path.
- Runtime dirs that hold state, auth stores, sessions, memory, identity, credentials,
  tmp, logs, and workspaces must be writable by `openclawgw`.
- Root-owned policy/config files must remain readable but not writable by `openclawgw`
  where they are part of the F-A4 lock.
- No live config reference to `$HOME/.ssh`, `~/Library/Keychains`, or an `agent`
  login-session-only credential was found in this pass.

## Phase 0 Recommendation

Proceed with operator Phase 0 staging as a low-risk confirmation, not as a skipped
check. The specific things Phase 0 should prove are:

1. A non-login role user can start a staging gateway with root-owned read-only config
   and writable staging state.
2. The same user can load file SecretRefs and auth profile stores after ownership/mode
   is modeled correctly.
3. A forced path that exercises native Codex/web_search auth does not hit a legacy
   Keychain-only profile.
4. Broker read-only access still works by `gmailbroker-clients` group membership.

If Phase 0 surfaces a Keychain-only auth profile warning or an auth failure that mentions
Keychain/login-session access, run the OpenClaw doctor/migration path as the operator
before the live cutover. Do not fix it by granting the service account interactive login
or broad access to `agent`'s login Keychain.

## Clean-State Note

Pre-report checks showed both repos clean. This report is the only intended write for
the drop.
