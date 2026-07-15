# Gmail Connector Discovery

**Date:** 2026-06-12  
**Installed OpenClaw:** 2026.6.5  
**Verdict:** **NO-GO for the stock setup path.**

**Plain-English answer:** We can authorize Gmail so Google permits reading but
not sending, and we can route incoming mail to a dedicated reader agent.
However, OpenClaw 2026.6.5's stock Gmail setup persists hook authentication
secrets in plaintext in `openclaw.json`. Do not grant Gmail OAuth until that
secret-storage gap and the default main-agent/delivery behavior are remediated.

## 1. Connect mechanism — SETTLED

Gmail is not an OpenClaw chat channel or a Gmail tool plugin. It is a built-in
Gmail Pub/Sub webhook integration:

```text
Gmail API watch -> Google Pub/Sub -> gog gmail watch serve/pull
-> OpenClaw /hooks/gmail -> agent turn
```

The installed command is:

```bash
openclaw webhooks gmail setup --account <email>
```

That command requires `gcloud`, `gog` (`gogcli`), and normally Tailscale. It
creates/enables Google APIs and Pub/Sub resources, starts the Gmail watch,
enables OpenClaw hooks and the Gmail preset, writes `hooks.gmail`, and configures
the push endpoint. It is mutating and was not run.

Current machine discovery:

- `gog`: not installed
- `gcloud`: not installed
- `tailscale`: installed
- `hooks`: not configured

The operator must authorize `gog` separately before OpenClaw can start the
watch. The OpenClaw setup command does not provide a Gmail OAuth-scope flag.

## 2. OAuth scope — SETTLED

`gog auth add` supports both:

```bash
gog auth add <email> --services gmail --readonly
gog auth add <email> --services gmail --gmail-scope readonly
```

Either selects exactly:

```text
https://www.googleapis.com/auth/gmail.readonly
```

plus OIDC identity scopes (`openid`, `email`, and `userinfo.email`). The default
Gmail authorization is not read-only: it requests `gmail.modify` plus Gmail
settings scopes. Therefore the future operator OAuth command must explicitly
select Gmail only and `--gmail-scope readonly` (or `--readonly`).

`gmail.readonly` is provider-enforced: Gmail send, modify, draft-write, label
mutation, and settings operations are outside the token's authority.

For a real Gmail-draft workflow, `gmail.compose` is the narrower applicable
scope: it permits creating and managing drafts, but it also permits sending
mail, including sending those drafts. Therefore `gmail.compose` can support
"agent creates draft, operator sends," but never-send becomes a software
guarantee rather than a provider-enforced boundary. The connector must make
`users.drafts.send` and `users.messages.send` unreachable.

The current `gog` CLI exposes only `full|readonly` through
`--gmail-scope`. Option B would therefore need readonly plus an explicit
additional compose scope, rather than an unsupported
`--gmail-scope compose` value:

```bash
gog auth add <email> \
  --services gmail \
  --gmail-scope readonly \
  --extra-scopes https://www.googleapis.com/auth/gmail.compose
```

## 3. Untrusted data surface — SETTLED

The watcher sends these message fields to OpenClaw:

- message ID and thread ID
- sender and recipient
- subject and date
- snippet
- labels
- optional first `text/plain` body, truncated to `maxBytes`

The installed OpenClaw setup defaults `includeBody` to `true` and `maxBytes` to
20,000. The built-in Gmail mapping renders sender, subject, snippet, and body
into the agent prompt.

Attachments and attachment bytes are not present in the watch payload. Reading
them would require a separate Gmail fetch/attachment command and is outside
this connector-discovery drop.

Gmail hook sessions receive OpenClaw's external-untrusted-content wrapping and
special-token sanitization by default. `hooks.gmail.allowUnsafeExternalContent`
must remain unset/false. This prompt wrapper is defense-in-depth, not a
structural permission boundary.

## 4. Send-disable — SETTLED WITH CONSTRAINTS

The strongest connector-level send denial is the `gmail.readonly` OAuth grant:
it cannot send through Google's API, but it also cannot create Gmail drafts.

With `gmail.compose`, Gmail drafts can be created, but the same scope authorizes
both `users.drafts.send` and `users.messages.send`. Under that option, no-send
must be enforced in software and audited at every executable surface.

`gog` also has `--gmail-no-send`, config `gmail_no_send`, exact command
allowlists, and baked read-only safety-profile binaries. These are useful
additional controls, but the OpenClaw watcher invocation does not add
`--gmail-no-send`. For this integration the read-only OAuth scope is the
provider-enforced wall.

The Gmail hook only receives inbound events; it does not expose a Gmail send
method to the agent. Future on-demand Gmail access must use a restricted reader
surface, not a general `gog` binary reachable through unrestricted exec.

One separate default is unsafe for the planned read-and-report phase:
OpenClaw resolves an omitted hook `deliver` value as `true`. The stock Gmail
preset omits `deliver`, so the build must override the mapping with
`deliver: false`.

### Option B send-path audit — SETTLED WITH CONSTRAINTS

The current `gog` source contains three direct Gmail API send call sites:

- `internal/cmd/gmail_drafts.go`: `GmailDraftsSendCmd` calls
  `svc.Users.Drafts.Send`. Reachable through `gog gmail drafts send`.
- `internal/cmd/gmail_send.go`: `sendGmailBatches` calls
  `svc.Users.Messages.Send`. Reachable through `gog gmail send`; the
  `gmail autoreply` command also reaches this helper.
- `internal/cmd/gmail_forward.go`: `GmailForwardCmd` calls
  `svc.Users.Messages.Send`. Reachable through `gog gmail forward`.

`gog` has a software guard covering the send command paths `gmail.send`,
`gmail.autoreply`, `gmail.forward`, and `gmail.drafts.send` through the
`--gmail-no-send` flag, global `gmail_no_send` config, or per-account no-send
config. Draft create and update are not classified as sends.

The installed OpenClaw Gmail webhook invokes only:

- `gog gmail watch start`
- `gog gmail watch serve`

Those watcher paths fetch Gmail changes and POST inbound events to
`/hooks/gmail`; they do not call any Gmail send API. Therefore the direct
inbound-webhook-only process is not connected to the three send call sites.

This is auditably no-send only while the reader agent cannot execute the general
`gog` CLI or another Gmail-capable tool. Granting `gmail.compose` to a credential
available to unrestricted `gog` remains send-capable despite the webhook path
itself being inbound-only. A future compose build must combine dedicated reader
confinement with `gmail_no_send` defense-in-depth and expose only a narrow
draft-create/update wrapper, never the general `gog` command surface.

Audit-version caveat: `gog` is not installed on this machine yet. The `gog`
findings above are from the current upstream source, while the webhook
reachability findings are from installed OpenClaw 2026.6.5. The exact installed
`gog` version must be pinned and rescanned before Option B is activated.

## 5. Credential storage — OPEN / BLOCKER

Gmail OAuth credentials do stay outside `openclaw.json`:

- OAuth client JSON is stored in the gog config directory.
- Refresh tokens are stored by gog's secret store.
- On macOS the default secret-store backend is Keychain.

This is not OpenClaw SecretRef; it is an external Keychain-backed credential
store, which is acceptable for the OAuth refresh token.

The blocker is OpenClaw hook authentication:

- `openclaw webhooks gmail setup` generates `hooks.token` and
  `hooks.gmail.pushToken`.
- The setup source writes both values directly into `openclaw.json`.
- OpenClaw's SecretRef support matrix explicitly lists both paths as
  unsupported because they are runtime-minted/session-bearing credentials.
- Both schema fields are strings, not SecretRef objects.

Therefore the stock setup violates the existing no-plaintext-secret-at-rest
rule and would put secrets into the git-baselined config. This must be solved
by an OpenClaw version/code change or a reviewed alternative hook-auth design
before OAuth or connector activation.

## 6. Reader-agent confinement — SETTLED WITH REQUIRED OVERRIDE

The stock Gmail preset has no `agentId`, so it falls back to the default agent,
currently `main`.

Hook mappings support:

- explicit `agentId`
- `hooks.allowedAgentIds`
- per-message or static session keys
- `deliver: false`

Custom mappings are evaluated before preset mappings, and the first matching
mapping wins. The build can therefore override `/hooks/gmail` with an explicit
dedicated reader agent and restrict `hooks.allowedAgentIds` to that reader.
The reader must hold no secrets and have no host-action, session, gateway,
message-send, or general exec capability.

The current `heartbeat` agent definition demonstrates the multi-agent pattern,
but a separate email reader has not been created in this drop.

## Build entry conditions

Do not perform Gmail OAuth until a reviewed build drop provides all of:

1. Choose explicitly between structurally no-send `gmail.readonly`, or
   `gmail.compose` plus reviewed software controls for real Gmail drafts.
2. No plaintext `hooks.token` or `hooks.gmail.pushToken` in tracked config.
3. A dedicated restricted reader agent.
4. An explicit Gmail mapping to that reader with `deliver: false`.
5. `hooks.allowedAgentIds` restricted to the reader.
6. External-content safety wrapping left enabled.

No OAuth grant, dependency installation, connector activation, config write,
email read, or email send occurred during this discovery.

## Sources inspected

- Installed OpenClaw CLI help, configuration schema, docs, and compiled source
  for `webhooks gmail`, Gmail watcher setup, hook mapping, external-content
  wrapping, routing, and SecretRef support.
- Official gogcli source:
  - <https://github.com/openclaw/gogcli/blob/main/internal/googleauth/service.go>
  - <https://github.com/openclaw/gogcli/blob/main/internal/cmd/auth_add.go>
  - <https://github.com/openclaw/gogcli/blob/main/internal/cmd/gmail_no_send.go>
  - <https://github.com/openclaw/gogcli/blob/main/internal/secrets/store.go>
  - <https://github.com/openclaw/gogcli/blob/main/docs/watch.md>
