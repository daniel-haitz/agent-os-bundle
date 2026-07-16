# F-A4 OpenAI Proxy Architecture Reconciliation

**Date:** 2026-07-16  
**Scope:** read-only reconciliation after independent rejection of `PUBLISHED_REF 0fcde94` as a production transaction implementation.  
**Runtime baseline:** OpenClaw `2026.6.11 (e085fa1)`.

## Decision

`CONTAINED MODEL-NETWORK COMPONENT IS NOT SUPPORTED AND THE PLACEMENT DECISION MUST BE REOPENED`

The rejected package assumed a separate contained OpenClaw model-network component. Installed OpenClaw evidence does not show a supported model-provider worker, model-network sidecar, Unix-socket provider bridge, or provider-transport delegation boundary that can move only model HTTP transport into Docker/Colima while leaving the host Gateway intact.

## OpenClaw Process Model

Read-only source and launchd evidence:

- LaunchDaemon `ai.openclaw.gateway` runs one host process as `openclawgw`: `/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node /Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/index.js gateway --port 18789 --bind loopback`.
- OpenAI Responses transport is constructed in-process:
  - `dist/openai-transport-stream-Dj78Cdnf.js:2468-2476` builds an `OpenAI` SDK client with `apiKey`, `baseURL: model.baseUrl`, `defaultHeaders`, and guarded `fetch`.
  - `dist/openai-transport-stream-Dj78Cdnf.js:2508-2516` resolves `options.apiKey || getEnvApiKey(model.provider)` and constructs that client in the stream function.
  - `dist/openai-responses-shared-C2-Tl1CB.js:325-332` calls `client.responses.create(...).withResponse()` directly.
- Ollama transport is also in-process:
  - `dist/stream-D4CByBVL.js:717-759` builds `/api/chat` from the configured base URL and calls `fetchWithSsrFGuard`.
  - `dist/stream-D4CByBVL.js:999-1003` creates the configured Ollama stream function from model/provider base URL.
- Source search found OpenClaw runtime sidecars for plugins/memory/startup, but no supported model-network sidecar or provider-worker interface for isolating model transport independently from the Gateway process.

Finding: the process that originates model-provider HTTP is the host OpenClaw Gateway process. A separate contained model-network execution component is not constructible with the accepted installed behavior without an OpenClaw architecture change or a different placement strategy.

## Gmail Broker Path

Current Gmail path evidence:

- `src/gmail-broker/gmail-broker.mjs:3-4` identifies runtime user `gmailbroker` and socket `/var/run/agent-os/gmail-broker.sock`.
- `src/gmail-broker/gmail-broker.mjs:35-43` defines the socket path, broker credential paths, and `gmailbroker-clients` group.
- `src/gmail-broker/gmail-broker.mjs:748-755` creates the Unix socket and sets mode `0660`, group `gmailbroker-clients`.
- Live metadata observed by this read-only pass:
  - `/var/run/agent-os` is `gmailbroker:gmailbroker-clients 0750`.
  - `/var/run/agent-os/gmail-broker.sock` is `gmailbroker:gmailbroker-clients 0660`.

Verdict: `INCOMPATIBLE` with the rejected contained model-network component as written.

Reason: moving Gmail reader execution into a container would require either mounting the host Unix socket into the container with correct `gmailbroker-clients` GID semantics or adding a new broker bridge. The package does not prove macOS/Colima Unix-socket bind reliability, UID/GID mapping, or that exposing the broker socket to a container preserves the accepted F-A1 Gmail boundary.

## Ollama Path

Current Ollama path evidence:

- Live process listing shows Ollama served by host user `dannybigdeals` using `/opt/homebrew/opt/ollama/bin/ollama serve`.
- `curl -fsSI http://127.0.0.1:11434/` returned `HTTP/1.1 200 OK`.
- Current route inventory records `heartbeat` and `gmail-reader` as local-only Ollama routes.

Verdict: `INCOMPATIBLE` with the rejected contained model-network component as written.

Reason: a Docker/Colima-internal component with host escape denied cannot reach host loopback `127.0.0.1:11434`. Using `host.docker.internal` or a host gateway would reopen the host escape the egress proof was intended to deny. A narrow Ollama bridge may be possible, but that is a new bounded architecture change and was not implemented or proven by the rejected package.

## Credential Source Inventory

This read-only agent context could not traverse protected OpenClaw state such as agent stores, sessions, `state`, `secrets`, `credentials`, and `credential-backups`; attempts returned permission denied. Therefore this pass cannot independently revalidate the operator-level claim of zero protected evidence gaps.

Current committed operator evidence:

- `audits/F-A4-openai-proxy-production-inventory.json` records one direct-bypass credential source:
  - `/Users/agent/.openclaw/openclaw.json:models.providers.openai.apiKey`
  - classification: `plaintext-or-token`
  - no value or hash included.
- Earlier F-A4 validation evidence records historical plaintext OpenAI findings at:
  - `models.providers.openai.apiKey`
  - `profiles.openai:manual.key`

Conclusion: the only current operator-proven live source in the committed production inventory is the provider `apiKey`, but the package must continue treating auth profiles, generated stores, snapshots, and caches as in-scope cleanup/verification surfaces because this non-root pass could not independently inspect them and installed auth precedence can activate them after config cleanup.

## Auth Precedence

Installed source evidence:

- `dist/model-auth-Bjx4UCgB.js:173-177` gives explicit provider config `auth: "api-key"` plus an explicit provider `apiKey` priority over profile/environment auth.
- `dist/model-auth-Bjx4UCgB.js:518-570` resolves a requested auth profile first when a `profileId` is explicitly selected.
- `dist/model-auth-Bjx4UCgB.js:572-593` evaluates configured auth profile order when `auth.profiles` or `auth.order` exists.
- `dist/model-auth-Bjx4UCgB.js:649-663` returns the explicit provider config key when the `api-key` override and explicit config key are present.
- `dist/model-auth-Bjx4UCgB.js:681-759` falls back through auth-profile order, environment, and custom provider keys when the explicit provider key does not win.

For current `openai/gpt-5.5`, committed operator inventory shows `models.providers.openai.apiKey` plus current base URL `https://api.openai.com/v1`; with explicit `auth: api-key`, that provider key is the current direct-bypass source. If it is removed or changed later, auth profiles and environment can become effective unless cleaned or denied.

## Local Token Reconciliation

Rejected selected path:

- `/Users/agent/.openclaw/openai-proxy/local-token`
- `openclawgw:openclawgw 0600`
- mounted read-only into both contained OpenClaw and proxy components.

Verdict: invalid as a shared single file for `openclawgw` and proxy UID `540`.

Reason: a `0600` file owned by UID `555` is not readable by UID `540` under normal Unix permission semantics. The substrate proof did not prove this exact production ownership arrangement. The bounded alternative to evaluate is two token files with identical generated contents: one OpenClaw-owned source and one broker-owned proxy source, rotated transactionally, with no broad shared directory mount.

## Rollback Reality Check

| Category | Classification | Notes |
|---|---|---|
| file bytes | `FIXTURE-ONLY` | `scripts/fa4-openai-proxy-rollback.mjs` can copy manifest backups in fixtures. |
| owner/group | `ABSENT` | rollback helper does not restore owner/group. |
| mode | `FIXTURE-ONLY` | rollback helper applies `chmod` when manifest includes mode. |
| ACL/xattrs | `ABSENT` | no ACL/xattr capture or restore. |
| auth profile | `FIXTURE-ONLY` | transaction fixtures model auth files; no production store handling. |
| generated stores | `FIXTURE-ONLY` | fixture modeled only. |
| proxy files | `FIXTURE-ONLY` | manifest described; no production install/restore execution. |
| token files | `FIXTURE-ONLY` | local-token model itself is unresolved. |
| Docker networks | `PLANNED` | no production network rollback executor. |
| containers | `PLANNED` | no production container rollback executor. |
| service state | `PLANNED` | no production service-state restore. |
| launchd state | `ABSENT` | no launchd mutation/rollback implementation. |
| Colima state | `PLANNED` | substrate proof handled temporary resources only. |
| startup ordering | `PLANNED` | documented, not implemented. |
| source credential | `PLANNED` | real credential migration not implemented. |
| partially migrated custody | `PLANNED` | synthetic fixtures only. |

## Corrected Status

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY SUBSTRATE PROOF (TEMPORARY FIXTURES): GO`
- `OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: PARTIAL`
- `OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED`
- `F-A4 STATUS: OPEN`

## Approved Next Bounded Action

Reopen the OpenAI proxy placement decision and produce a bounded architecture alternative that preserves the proven host OpenClaw Gateway, host Gmail broker Unix-socket boundary, and host Ollama loopback model routes while still structurally denying direct OpenAI egress from the process that performs OpenAI model transport.
