# F-A0 Platform Hardening Audit

Date: 2026-06-16
Scope: AUDIT ONLY. No config changes, installs, skills, broker work, sandbox enablement, or reader/no-send changes.

Session labels:
- Codex session: commands run from this Codex task in `/Users/agent/agent-os`.
- Plain agent SSH session: attempted only for commands that failed in Codex; SSH authentication was not available from this session.

## Result Summary

| Item | Status | Finding |
| --- | --- | --- |
| OpenClaw version / install / runtime user | PASS | OpenClaw `2026.6.5 (5181e4f)`, user install under `/Users/agent/.local/openclaw`, gateway LaunchAgent running as `agent`. |
| `openclaw security audit --deep` | REMEDIATED / OPEN WARNS | Codex execution failed, but plain agent SSH output was captured separately: 1 critical, 2 warn, 1 info. F-A0 remediation removed the critical; current audit is 0 critical, 2 warn, 2 info. |
| `openclaw secrets audit --check` | PASS | Clean: `plaintext=0, unresolved=0, shadowed=0, legacy=0`. |
| Channels and Telegram allowlist | PASS | Telegram is enabled with pairing DM policy and sender allowlist `telegram:8745949064`; groups disabled. |
| Per-agent tool surfaces | FAIL | Gmail Reader is contractually narrowed, but still has `exec` with `mode=auto` as the same Unix user that owns Gmail credentials. |
| Elevated / privileged tools | PASS | `sandbox explain` reports elevated subsystem enabled, but not allowed by config; no configured `tools.elevated` grant found. |
| Installed skills | PASS | No enabled skills in config; configured skill catalog entries are disabled; no local `SKILL.md` found under `~/.openclaw` at audit depth. |
| Installed hooks | PASS | No OpenClaw hooks configured; only git sample hook files found. |
| Gateway WebSocket auth | PASS | `gateway.auth.mode="token"` with redacted token in sanitized config. |
| Gateway bind / exposure | PASS | Gateway listens on loopback only: `127.0.0.1:18789` and `[::1]:18789`; Tailscale mode off. |
| Browser-control exposure | RESOLVED / PASS | `browser=null`; no agent browser grant found. Native audit's "enabled" wording means subsystem-available, not actually reachable by a configured agent in current evidence. |
| Gmail credential/keyring exposure | FAIL | Current wrapper passes `GOG_KEYRING_PASSWORD` to child env and all credential files are same-UID readable by `agent`; Gmail Reader `exec` can reach the wrapper/keyring path. |
| Places Gmail Reader can see secrets/config | FAIL | Same-UID `exec` can reach wrapper, password file, keyring, gog config, oauth-client metadata, service env files, and OpenClaw config paths unless future broker/sandbox removes that authority. |

## Evidence

### 1. OpenClaw Version, Install Method, Runtime User

Status: PASS

Command, Codex session:

```sh
openclaw --version
which openclaw
ls -l $(which openclaw)
readlink $(which openclaw) || true
id
whoami
```

Output:

```text
OpenClaw 2026.6.5 (5181e4f)
/Users/agent/.local/bin/openclaw
lrwxr-xr-x  1 agent  staff  43 ... /Users/agent/.local/bin/openclaw -> /Users/agent/.local/openclaw/bin/openclaw
/Users/agent/.local/openclaw/bin/openclaw
uid=501(agent) gid=20(staff) groups=20(staff),12(everyone),61(localaccounts),100(_lpoperator),701(com.apple.sharepoint.group.1)
agent
```

Command, Codex session:

```sh
launchctl print gui/$(id -u)/ai.openclaw.gateway 2>&1 | sed -n '1,220p'
```

Output excerpt:

```text
path = /Users/agent/Library/LaunchAgents/ai.openclaw.gateway.plist
state = running
program = /Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
arguments = {
        /Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node
        /Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/index.js
        gateway
        --port
        18789
}
working directory = /Users/agent/.openclaw
umask = 77
```

Command, Codex session:

```sh
lsof -nP -iTCP:18789 -sTCP:LISTEN 2>&1 || true
```

Output:

```text
COMMAND  PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node    1331 agent   18u  IPv4 ...              0t0  TCP 127.0.0.1:18789 (LISTEN)
node    1331 agent   19u  IPv6 ...              0t0  TCP [::1]:18789 (LISTEN)
```

Interpretation: user-space OpenClaw install under `~/.local/openclaw`, launched as the `agent` user's LaunchAgent, with bundled Node.

### 2. OpenClaw Security Audit

Status: REMEDIATED / OPEN WARNS

Command, Codex session:

```sh
openclaw security audit --help
openclaw security audit --deep
```

Output:

```text
Usage: openclaw security audit [options]

run security posture audit

Options:
  --auth <mode>  override auth mode for the emitted plan (token|password|none)
  --deep         include local network/service inspection
  --fix          apply safe config-only fixes after showing the plan
  --json         output JSON
  --password     derive a gateway password hash from OPENCLAW_GATEWAY_PASSWORD
  --token        generate and persist a gateway token (default behavior)
  -h, --help     display help for command

[openclaw] Could not start the CLI.
[openclaw] Reason: EPERM: operation not permitted, chmod '/Users/agent/.openclaw/state'
[openclaw] Debug: set OPENCLAW_DEBUG=1 to include the stack trace.
[openclaw] Try: openclaw doctor
[openclaw] Help: openclaw --help
```

Plain SSH retry command:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null agent@localhost 'openclaw security audit --deep'
```

Output:

```text
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
agent@localhost: Permission denied (publickey,password,keyboard-interactive).
```

Finding from Codex: the audit command exists in this OpenClaw version, but no trustworthy audit output was produced from Codex.

#### Native deep-audit (plain agent SSH, 2026-06-16)

Status: CLOSED / FAIL

Summary recorded from plain agent SSH output: 1 critical, 2 warn, 1 info.

Findings:

- CRITICAL `models.small_params`: `qwen2.5-coder:14b` appears at `agents.defaults.model.fallbacks` while web-capable tools are available and sandbox mode is off. This is a small-model prompt-injection risk. The heartbeat agent's Qwen path is not the issue because heartbeat is separately restricted with web off. This is also not the email-reader path: `gmail-reader` and `email-researcher` use `openai/gpt-5.5`, and `email-researcher` explicitly denies `web_fetch`. The risk is the default fallback/provider path.
- WARN `exec-not-read-only`: independently confirms the Gmail Reader same-UID `exec` finding in this audit. Owned by F-A1/F-A2; no separate F-A0 reader-exec remediation is proposed.
- WARN `trusted_proxies`: benign in this deployment because Gateway is loopback-only and there is no reverse proxy in front of it. Note and ignore unless the Gateway is later exposed through a proxy.
- INFO trust model: OpenClaw reports a personal assistant trust boundary, not a hostile multi-tenant boundary. Platform-level implication: OpenClaw is the runtime/harness, not the Agent OS trust boundary. This validates the reconciled spine. Relevant wording: "one trusted operator boundary per gateway" and "not a hostile multi-tenant security boundary."

#### F-A0 remediation re-audit (Codex unsandboxed local, 2026-06-16)

Plain agent SSH retry from this Codex session failed:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=8 agent@Danny-Mac-Mini.local 'PATH=/Users/agent/.local/bin:$PATH openclaw security audit --deep'
```

Output:

```text
agent@danny-mac-mini.local: Permission denied (publickey,password,keyboard-interactive).
```

Because plain SSH was unavailable from Codex, the re-audit was run as the local `agent` user outside the Codex filesystem sandbox:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw security audit --deep
```

Output:

```text
OpenClaw security audit
Summary: 0 critical · 2 warn · 2 info
Run deeper: openclaw security audit --deep

WARN
gateway.trusted_proxies_missing Reverse proxy headers are not trusted
tools.exec.fs_tools_disabled_but_exec_enabled Filesystem tool policy does not make exec read-only

INFO
summary.attack_surface Attack surface summary
  browser control: enabled
  trust model: personal assistant (one trusted operator boundary), not hostile multi-tenant on one shared gateway
models.small_params Small models require sandboxing and web tools disabled
  Small models (<=300B params) detected:
- ollama/qwen2.5-coder:14b (14B) @ agents.defaults.model.fallbacks (ok; sandbox=off; web=[off])
- ollama/qwen2.5-coder:14b (14B) @ agents.list.heartbeat.model.primary (ok; sandbox=off; web=[off])
No web/browser tools detected for these models.
```

Result: the prior CRITICAL `models.small_params` finding is gone. It is now INFO with `web=[off]` for both Qwen paths.

### 3. OpenClaw Secrets Audit

Status: PASS

Command, Codex session:

```sh
openclaw secrets audit --help
openclaw secrets audit --check
```

Output:

```text
Usage: openclaw secrets audit [options]

scan config for plaintext/unresolved/shadowed secret values

Options:
  --allow-exec  also allow command-backed secret providers
  --check       exit non-zero if issues are found
  --json        output JSON
  -h, --help    display help for command

Secrets audit: clean. plaintext=0, unresolved=0, shadowed=0, legacy=0.
```

### 4. Channels and Telegram Allowlist

Status: PASS

Command, Codex session:

```sh
jq '{channels, gateway, browser, hooks}' /Users/agent/.openclaw/openclaw.sanitized.json
```

Output:

```json
{
  "channels": {
    "telegram": {
      "botToken": "__REDACTED__",
      "dmPolicy": "pairing",
      "enabled": true,
      "groupPolicy": "disabled",
      "name": "LLoyd_entouragebot"
    }
  },
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "__REDACTED__"
    },
    "bind": "loopback",
    "mode": "local",
    "port": 18789,
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    }
  },
  "browser": null,
  "hooks": null
}
```

Command, Codex session:

```sh
jq '{commands, session}' /Users/agent/.openclaw/openclaw.sanitized.json
jq . /Users/agent/.openclaw/devices/telegram-default-allowFrom.json
```

Output:

```json
{
  "commands": {
    "ownerAllowFrom": [
      "telegram:8745949064"
    ]
  },
  "session": {
    "dmScope": "per-channel-peer"
  }
}
{
  "version": 1,
  "allowFrom": [
    "8745949064"
  ]
}
```

Interpretation: Telegram is the only configured channel found in sanitized config. Groups are disabled. The sender allowlist exists and contains numeric Telegram sender ID `8745949064`.

### 5. Per-Agent Tool Surface

Status: FAIL

Command, Codex session:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw agents list --json
```

Output:

```json
[
  {
    "id": "main",
    "workspace": "/Users/agent/.openclaw/workspace",
    "agentDir": "/Users/agent/.openclaw/agents/main/agent",
    "model": "openai/gpt-5.5",
    "bindings": 0,
    "isDefault": true
  },
  {
    "id": "heartbeat",
    "name": "Restricted Heartbeat",
    "workspace": "/Users/agent/.openclaw/workspace",
    "agentDir": "/Users/agent/.openclaw/agents/heartbeat/agent",
    "model": "ollama/qwen2.5-coder:14b",
    "bindings": 0,
    "isDefault": false
  },
  {
    "id": "gmail-reader",
    "name": "Confined Gmail Reader",
    "workspace": "/Users/agent/.openclaw/workspace-gmail-reader",
    "agentDir": "/Users/agent/.openclaw/agents/gmail-reader/agent",
    "model": "openai/gpt-5.5",
    "bindings": 0,
    "isDefault": false
  },
  {
    "id": "email-researcher",
    "name": "Isolated Email Researcher",
    "workspace": "/Users/agent/.openclaw/workspace-email-researcher",
    "agentDir": "/Users/agent/.openclaw/agents/email-researcher/agent",
    "model": "openai/gpt-5.5",
    "bindings": 0,
    "isDefault": false
  }
]
```

Command, Codex session:

```sh
jq '{agents: .agents, tools: .tools}' /Users/agent/.openclaw/openclaw.sanitized.json
```

Output excerpt:

```json
{
  "tools": {
    "alsoAllow": [
      "message"
    ],
    "exec": {
      "security": "allowlist"
    },
    "profile": "coding"
  },
  "agents": {
    "defaults": {
      "model": "ollama/qwen2.5-coder:14b",
      "primary": "openai/gpt-5.5",
      "workspace": "/Users/agent/.openclaw/workspace"
    },
    "list": [
      {
        "id": "main",
        "subagents": {
          "allowAgents": [
            "gmail-reader",
            "email-researcher"
          ],
          "requireAgentId": true
        },
        "tools": {
          "alsoAllow": [
            "sessions_spawn",
            "sessions_yield",
            "subagents",
            "agents_list"
          ],
          "deny": [
            "gateway",
            "cron",
            "sessions_list",
            "sessions_history",
            "sessions_send",
            "session_status"
          ],
          "exec": {
            "security": "allowlist",
            "strictInlineEval": true
          }
        }
      },
      {
        "id": "gmail-reader",
        "tools": {
          "allow": [
            "exec"
          ],
          "deny": [
            "process",
            "read",
            "write",
            "edit",
            "apply_patch",
            "group:sessions",
            "gateway",
            "cron",
            "message"
          ],
          "exec": {
            "mode": "auto",
            "security": "allowlist",
            "strictInlineEval": true
          },
          "profile": "minimal"
        },
        "workspace": "/Users/agent/.openclaw/workspace-gmail-reader"
      },
      {
        "id": "email-researcher",
        "tools": {
          "alsoAllow": [
            "web_search"
          ],
          "deny": [
            "session_status",
            "group:runtime",
            "group:fs",
            "group:messaging",
            "group:sessions",
            "group:agents",
            "web_fetch",
            "x_search",
            "browser",
            "gateway",
            "cron"
          ],
          "profile": "minimal"
        },
        "workspace": "/Users/agent/.openclaw/workspace-email-researcher"
      }
    ]
  }
}
```

Interpretation:
- Main can spawn/yield to the two subagents and has a constrained shell allowlist.
- Gmail Reader denies file tools but allows `exec` with `mode=auto`; because it runs as Unix user `agent`, process-level file authority still reaches same-UID credential material.
- Email Researcher has web search only and denies filesystem/runtime/session/messaging groups in config.

Bounded remediation task: F-A1 must move Gmail operations behind a semantic capability broker; F-A2 must ensure the reader cannot read Gmail credentials or call raw Gmail tooling by same-UID `exec`.

### 6. Elevated / Privileged Tools

Status: PASS

Command, Codex session:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent gmail-reader --json
```

Output excerpt:

```json
{
  "sandbox": {
    "mode": "off",
    "scope": "agent",
    "workspaceAccess": "none",
    "workspaceRoot": "/Users/agent/.openclaw/sandboxes",
    "sessionIsSandboxed": false
  },
  "elevated": {
    "enabled": true,
    "allowedByConfig": false,
    "alwaysAllowedByConfig": false,
    "allowFrom": {},
    "failures": []
  }
}
```

The same elevated status was returned for `main` and `email-researcher`. No explicit `tools.elevated` grant was found in sanitized config.

### 7. Installed Skills

Status: PASS

Command, Codex session:

```sh
jq '{skills: .skills, plugins: .plugins}' /Users/agent/.openclaw/openclaw.sanitized.json
find /Users/agent/.openclaw -maxdepth 4 \( -name 'SKILL.md' -o -name 'skill.json' -o -name 'plugin.json' \) -print | sort
```

Output summary:

```text
Config contains many catalog skill entries, all with "enabled": false.
Enabled plugins in config: codex, ollama, openai.
No SKILL.md, skill.json, or plugin.json files were found under ~/.openclaw at maxdepth 4.
```

Interpretation: no installed/enabled community or local OpenClaw skills were found in the live OpenClaw config. Provider plugins `codex`, `ollama`, and `openai` are enabled.

### 8. Installed Hooks

Status: PASS

Command, Codex session:

```sh
find /Users/agent/.openclaw -maxdepth 4 -type f \( -iname '*hook*' -o -path '*/hooks/*' -o -path '*/plugins/*' \) -print | sort
```

Output:

```text
/Users/agent/.openclaw/.git/hooks/applypatch-msg.sample
/Users/agent/.openclaw/.git/hooks/commit-msg.sample
/Users/agent/.openclaw/.git/hooks/fsmonitor-watchman.sample
/Users/agent/.openclaw/.git/hooks/post-update.sample
/Users/agent/.openclaw/.git/hooks/pre-applypatch.sample
/Users/agent/.openclaw/.git/hooks/pre-commit.sample
/Users/agent/.openclaw/.git/hooks/pre-merge-commit.sample
/Users/agent/.openclaw/.git/hooks/pre-push.sample
/Users/agent/.openclaw/.git/hooks/pre-rebase.sample
/Users/agent/.openclaw/.git/hooks/pre-receive.sample
/Users/agent/.openclaw/.git/hooks/prepare-commit-msg.sample
/Users/agent/.openclaw/.git/hooks/push-to-checkout.sample
/Users/agent/.openclaw/.git/hooks/sendemail-validate.sample
/Users/agent/.openclaw/.git/hooks/update.sample
```

Interpretation: only git sample hooks were found. OpenClaw `hooks` config is `null`.

### 9. Gateway WebSocket Auth

Status: PASS

Evidence from sanitized config:

```json
"gateway": {
  "auth": {
    "mode": "token",
    "token": "__REDACTED__"
  },
  "bind": "loopback",
  "mode": "local",
  "port": 18789
}
```

Interpretation: Gateway auth is enabled in token mode. The token value was redacted by the sanitized config and was not printed.

### 10. Gateway Bind / Exposure

Status: PASS

Evidence:

```json
"gateway": {
  "bind": "loopback",
  "mode": "local",
  "port": 18789,
  "tailscale": {
    "mode": "off",
    "resetOnExit": false
  }
}
```

`lsof` confirmed only loopback listeners:

```text
TCP 127.0.0.1:18789 (LISTEN)
TCP [::1]:18789 (LISTEN)
```

Interpretation: no public internet bind was found; Gateway is local loopback only. Tailscale gateway exposure is off in config.

### 11. Browser-Control Exposure

Status: RESOLVED / PASS

Evidence:

```json
"browser": null
```

Command, Codex session:

```sh
find /Users/agent/.openclaw -maxdepth 4 -type f \( -iname '*browser*' -o -iname '*canvas*' -o -iname '*gateway*' -o -iname '*session*' \) -not -path '*/state/*' -not -path '*/workspaces/*' -print | sort
```

Output:

```text
/Users/agent/.openclaw/agents/gmail-reader/sessions/sessions.json
/Users/agent/.openclaw/agents/heartbeat/sessions/sessions.json
/Users/agent/.openclaw/agents/main/sessions/sessions.json
/Users/agent/.openclaw/gateway-supervisor-restart-handoff.json
/Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
/Users/agent/.openclaw/service-env/ai.openclaw.gateway.env
/Users/agent/.openclaw/tmp/openclaw-501/gateway.cf4b7e92.lock
```

Additional read-only diagnosis, Codex session:

```sh
jq '{browser, tools, agents: .agents}' /Users/agent/.openclaw/openclaw.sanitized.json
rg -n 'browser|web_fetch|web_search|group:web|tools\.byProvider|byProvider|qwen|ollama' /Users/agent/.openclaw/openclaw.sanitized.json /Users/agent/.openclaw/workspace/TOOLS.md /Users/agent/.openclaw/workspace-gmail-reader/TOOLS.md /Users/agent/.openclaw/workspace-email-researcher/TOOLS.md
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent main --json
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent gmail-reader --json
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent email-researcher --json
PATH=/Users/agent/.local/bin:$PATH openclaw sandbox explain --agent heartbeat --json
```

Output summary:

```text
browser=null
No tools.byProvider entry exists in sanitized config.
rg found browser only in deny/context locations:
  email-researcher denies web_fetch and browser
  email-researcher TOOLS.md says not to use browser/web_fetch
Sandbox explain for main, gmail-reader, email-researcher, and heartbeat lists browser in the default deny set.
No explicit agent browser allow/alsoAllow grant was found.
```

Interpretation: no browser-control config, browser-control state file, or agent browser grant was found. The native audit's "browser control: enabled" wording is therefore resolved as subsystem-available-but-ungranted, not actually reachable by a configured agent in the current evidence.

### 12. Gmail Credential / Keyring Exposure Path

Status: FAIL

Commands, Codex session:

```sh
rg -n 'GOG_HOME|GOG_KEYRING|SAFE_|gmail-no-send|enable-commands|wrap-untrusted|no-send' /Users/agent/.openclaw/scripts/gmail-draft-safe.mjs
stat -f '%Sp %Su:%Sg %z %N' /Users/agent/.openclaw/secrets/gog-keyring-password /Users/agent/.openclaw/gmail-draft-gog/config/config.json /Users/agent/.openclaw/gmail-draft-gog/oauth-client.json /Users/agent/.openclaw/gmail-draft-gog/data/credentials.json
find /Users/agent/.openclaw/gmail-draft-gog/data/keyring -maxdepth 1 -type f -print -exec stat -f '%Sp %Su:%Sg %z %N' {} \;
```

Evidence:

```text
Wrapper path: /Users/agent/.openclaw/scripts/gmail-draft-safe.mjs
SAFE_GOG_BIN=/Users/agent/.local/bin/gog-gmail-draft-safe
SAFE_GOG_HOME=/Users/agent/.openclaw/gmail-draft-gog
SAFE_ACCOUNT=daniel.haitz@gmail.com
SAFE_KEYRING_PASSWORD_FILE=/Users/agent/.openclaw/secrets/gog-keyring-password
Wrapper child env includes:
  GOG_HOME=SAFE_GOG_HOME
  GOG_KEYRING_BACKEND=file
  GOG_KEYRING_PASSWORD=<password read from file>
Wrapper exact commands include:
  gmail.drafts.create,gmail.drafts.update,gmail.drafts.list,gmail.drafts.get,gmail.messages.search,gmail.get
Wrapper safe flags include:
  --gmail-no-send --no-input --wrap-untrusted --json --results-only
```

Credential file metadata, contents not printed:

```text
-rw------- agent:staff 15 /Users/agent/.openclaw/secrets/gog-keyring-password
-rw------- agent:staff ... /Users/agent/.openclaw/gmail-draft-gog/config/config.json
-rw------- agent:staff 409 /Users/agent/.openclaw/gmail-draft-gog/oauth-client.json
-rw------- agent:staff 93 /Users/agent/.openclaw/gmail-draft-gog/data/credentials.json
-rw------- agent:staff ... /Users/agent/.openclaw/gmail-draft-gog/data/keyring/_gogcli_key_v1_...
```

Command, Codex session:

```sh
sed -n '1,220p' /Users/agent/.openclaw/workspace-gmail-reader/TOOLS.md
```

Output:

```text
# Gmail Reader Tools

Use only the confined wrapper:

/Users/agent/.openclaw/scripts/gmail-draft-safe.mjs

Its permitted actions are:

- message-search
- message-get
- draft-list
- draft-get
- draft-create
- draft-update

The second argument is the wrapper's base64url JSON payload. There is no send,
forward, delete, auth, configuration, or unrestricted gog command.
```

Interpretation: no-send is currently enforced by cooperative wrapper, compiled safe binary, and policy. It is not structural against the reader process because the reader runs with same-UID process authority and `exec` access.

Bounded remediation task: F-A1 must implement a Gmail capability broker that enforces semantic operations (`read/search/draft-only`) outside reader-controlled process authority. F-A2 must then remove reader access to raw credential files/env and raw Gmail-capable tooling.

### 13. Places Gmail Reader Can See Secrets, Env Vars, Credential Files, or Config

Status: FAIL

Inventory:

| Path / surface | Evidence | Reader exposure |
| --- | --- | --- |
| `/Users/agent/.openclaw/scripts/gmail-draft-safe.mjs` | Wrapper source contains credential paths and creates child env. | Same-UID `exec` can invoke or inspect unless blocked by future containment. |
| `/Users/agent/.openclaw/secrets/gog-keyring-password` | `-rw------- agent:staff`, read by wrapper. | Same Unix user as reader; mode protects other users, not same-UID reader process. |
| `/Users/agent/.openclaw/gmail-draft-gog/data/keyring/*` | `-rw------- agent:staff` file keyring. | Same-UID reachable. |
| `/Users/agent/.openclaw/gmail-draft-gog/config/config.json` | Contains `gmail_no_send: true` and no-send account map. | Same-UID readable; config is not secret but maps the auth chain. |
| `/Users/agent/.openclaw/gmail-draft-gog/oauth-client.json` | `-rw------- agent:staff`; contents not printed. | Same-UID reachable. |
| `/Users/agent/.openclaw/gmail-draft-gog/data/credentials.json` | `-rw------- agent:staff`; contents not printed. | Same-UID reachable. |
| Child process env from wrapper | `GOG_KEYRING_PASSWORD`, `GOG_HOME`, `GOG_KEYRING_BACKEND=file`. | Reader-controlled invocation path can cause credential-bearing child process creation. |
| `/Users/agent/.openclaw/openclaw.sanitized.json` | Shows channel/gateway/agent/tool paths with secrets redacted. | Same-UID readable; not a secret dump but useful map. |
| `/Users/agent/.openclaw/secrets/secrets.json` and `telegram.json` | Configured local secret providers; contents not printed. | Same-UID file authority may reach them unless filesystem policy blocks access. |
| `/Users/agent/.openclaw/service-env/ai.openclaw.gateway.env` | `-rw------- agent:staff`; keys include `PATH`, `HOME`, `OPENCLAW_GATEWAY_PORT`, service metadata. | Same-UID readable; keys printed, values not printed. |

Command, Codex session:

```sh
stat -f '%Sp %Su:%Sg %z %N' /Users/agent/.openclaw/service-env/ai.openclaw.gateway.env /Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
awk -F= 'NF && $1 !~ /^#/ {print $1}' /Users/agent/.openclaw/service-env/ai.openclaw.gateway.env
```

Output:

```text
-rw------- agent:staff 695 /Users/agent/.openclaw/service-env/ai.openclaw.gateway.env
-rwx------ agent:staff 95 /Users/agent/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh
export HOME
export NODE_EXTRA_CA_CERTS
export NODE_USE_SYSTEM_CA
export OPENCLAW_GATEWAY_PORT
export OPENCLAW_LAUNCHD_LABEL
export OPENCLAW_SERVICE_KIND
export OPENCLAW_SERVICE_MARKER
export OPENCLAW_SERVICE_VERSION
export OPENCLAW_SYSTEMD_UNIT
export OPENCLAW_WINDOWS_TASK_NAME
export PATH
export TMPDIR
```

Bounded remediation task: F-A1/F-A2 must treat same-UID file/process authority as the boundary failure. The fix is not more wrapper instructions; it is moving Gmail capability and credentials outside the reader's authority, then validating the reader cannot access the old paths.

## Additional Control Checks

### Config Validation / Doctor

Status: PARTIAL

Command, Codex session:

```sh
openclaw config validate
openclaw doctor
```

Output:

```text
Config valid: ~/.openclaw/openclaw.json

[openclaw] Could not start the CLI.
[openclaw] Reason: EPERM: operation not permitted, chmod '/Users/agent/.openclaw/state'
[openclaw] Debug: set OPENCLAW_DEBUG=1 to include the stack trace.
[openclaw] Try: openclaw doctor
[openclaw] Help: openclaw --help
```

Plain SSH retry for `openclaw doctor` failed with the same SSH authentication issue recorded in section 2.

## F-A0 Remediation (proposed, not applied)

Status: APPLIED for CRITICAL `models.small_params`. No browser subsystem change and no reader/no-send/broker change were applied.

### Applied fix for CRITICAL `models.small_params`

Goal: prevent the small/local Qwen model from receiving web/browser-capable tools when used through fallback/provider paths while sandbox remains off.

Validated path: Step 2A provider-scoped config. `openclaw config patch --stdin --dry-run --json` returned:

```json
{
  "ok": true,
  "operations": 1,
  "configPath": "~/.openclaw/openclaw.json",
  "inputModes": [
    "json"
  ],
  "checks": {
    "schema": true,
    "resolvability": true,
    "resolvabilityComplete": true
  },
  "refsChecked": 0,
  "skippedExecRefs": 0
}
```

Applied config edit:

```json
{
  "tools": {
    "byProvider": {
      "ollama/qwen2.5-coder:14b": {
        "deny": [
          "group:web",
          "browser"
        ]
      }
    }
  }
}
```

`openclaw config validate --json` after apply:

```json
{"valid":true,"path":"/Users/agent/.openclaw/openclaw.json"}
```

Gateway apply step:

`openclaw config patch` reported `Restart the gateway to apply.`, so the Gateway was restarted with the established launchd path:

```sh
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

Post-restart evidence:

```text
launchctl: state = running, pid = 47950, runs = 2
lsof: node 47950 agent TCP 127.0.0.1:18789 (LISTEN)
lsof: node 47950 agent TCP [::1]:18789 (LISTEN)
openclaw config validate --json: {"valid":true,"path":"/Users/agent/.openclaw/openclaw.json"}
```

Tracked redacted diff:

```diff
 "tools": {
   "alsoAllow": [
     "message"
   ],
+  "byProvider": {
+    "ollama/qwen2.5-coder:14b": {
+      "deny": [
+        "group:web",
+        "browser"
+      ]
+    }
+  },
   "exec": {
     "ask": "on-miss",
     "security": "allowlist"
```

Expected effect:
- Blocks web and browser surfaces when the Qwen provider/model is selected through default fallback routing.
- Should not break heartbeat's Qwen use: heartbeat is already configured with a minimal profile and no web tools.
- May affect any future overnight Qwen/Aider-style task that expects Qwen to use web/browser tools. That is desirable by default for this trust model; if an overnight task needs web, it should use a strong-model researcher path or receive a separately reviewed, task-scoped exception.

Role-preservation evidence:

```sh
PATH=/Users/agent/.local/bin:$PATH openclaw config get tools.byProvider --json
```

Output:

```json
{
  "ollama/qwen2.5-coder:14b": {
    "deny": [
      "group:web",
      "browser"
    ]
  }
}
```

Main's local/mechanical path remains intact: sanitized config still has the same `agents.list.main.tools.exec.safeBins` (`cut`, `uniq`, `head`, `tail`, `tr`, `wc`, `grep`) and the same safe-bin profiles. The only provider-scoped denial is `group:web` + `browser`.

Heartbeat's Qwen path remains unchanged: `agents.list.heartbeat.model.primary = ollama/qwen2.5-coder:14b`, `fallbacks=[]`, tools still `profile=minimal`, `alsoAllow=[read,message]`, and deny still includes `group:runtime`, write/edit/apply_patch, sessions, gateway, and cron.

Record: Qwen retains local/mechanical tool surface for token-saving bounded tasks; only untrusted web/browser input surfaces are denied.

### Browser item

Finding: resolved as subsystem-available-but-ungranted. No standalone browser disable/enable change is proposed.

Proposed action:
- Do not change `browser` subsystem config in F-A0 remediation.
- Include `browser` in the Qwen/provider deny above because the critical finding specifically involves small-model access to web/browser-capable surfaces.
- Re-run `openclaw security audit --deep` after the provider deny is applied; only add an explicit global/per-agent browser deny if the native audit still reports actual reachable browser exposure.

### Reader `exec-not-read-only`

No separate F-A0 config remediation proposed.

This remains owned by F-A1/F-A2:
- F-A1: Gmail capability broker enforces semantic Gmail operations (`read/search/draft-only`) outside reader-controlled process authority.
- F-A2: reader credential containment proves the reader cannot read the gog keyring/password/config paths or invoke raw Gmail-capable tooling.

### `trusted_proxies`

No remediation proposed while Gateway remains loopback-only and no reverse proxy is configured.

If Gateway is later put behind a proxy, define the exact trusted proxy list at that time and re-run the audit.

## Gate Outcome

F-A0 audit and remediation are complete for the critical small-model web/browser finding. Current native audit summary is `0 critical · 2 warn · 2 info`.

Remaining warnings are intentionally not remediated in F-A0:
- `tools.exec.fs_tools_disabled_but_exec_enabled`: owned by F-A1/F-A2.
- `gateway.trusted_proxies_missing`: benign while Gateway remains loopback-only and no reverse proxy is configured.

Bounded next tasks:

1. Proceed to F-A1 as a remediation design/build task for the Gmail capability broker; do not treat existing wrapper/no-send layers as structural containment.
2. In F-A2, prove the reader cannot read the Gmail keyring/password/config paths or spawn raw Gmail-capable binaries before claiming reader credential containment.
