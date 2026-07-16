# F-A4 OpenAI Proxy Cutover Package

**Status:** Production transaction package implemented for dry-run/review. Production execution and cutover are not authorized.

Current canonical status:

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY PRODUCTION SUBSTRATE PROOF: GO`
- `OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: GO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `F-A4 STATUS: OPEN`

## Purpose

Prepare the controlled replacement of direct OpenAI credential use in OpenClaw with a contained credential-injecting OpenAI forwarding proxy.

## Production Placement

- Colima profile: `agent-os`.
- Network: `agent-os-openai-egress`.
- Proxy service: `agent-os-openai-forward-proxy`.
- Proxy identity: `openai-credential-broker` (`uid=540`, `gid=740`).
- Future OpenClaw base URL: `http://agent-os-openai-forward-proxy:18187/v1`.
- Upstream: fixed `https://api.openai.com`.
- Host-published ports: none in the target design.

OpenClaw host-only placement is not accepted while `pf` is disabled. The production egress boundary must be the contained network or a separately reviewed equivalent.

The real Colima/internal-network substrate proof resolved the placement decision:

- OpenClaw model-network execution must run inside a contained component on an internal Docker/Colima network.
- The OpenAI proxy is a separate contained component dual-homed between the OpenClaw-side internal network and a constrained upstream egress network.
- A host OpenClaw Gateway may orchestrate, but must not originate direct OpenAI HTTP traffic after F-A4 closure.

A host OpenClaw Gateway cannot be structurally denied direct OpenAI egress by changing `baseUrl` alone while `pf` remains disabled.

## Credential Migration

The existing OpenAI provider key currently lives at:

`/Users/agent/.openclaw/openclaw.json:models.providers.openai.apiKey`

During a later authorized cutover only:

1. Capture rollback evidence.
2. Read the existing key inside the operator-owned script process only.
3. Write it to broker custody at the manifest-defined path with owner `openai-credential-broker:openai-credential-broker` and mode `0600`.
4. Validate proxy health and route behavior.
5. Patch OpenClaw to use the contained proxy and synthetic local token.
6. Remove or neutralize the original direct provider key only after validation passes.

The key must never be printed, passed on a command line, written to the repository, or placed in broad evidence.

## Local Token

The local proxy token is a constrained local capability token, not an upstream OpenAI credential.

- Minimum entropy: 256 bits.
- OpenClaw visibility: allowed.
- OpenAI usability: none.
- Storage: `/Users/agent/.openclaw/openai-proxy/local-token`.
- Ownership/mode: `openclawgw:openclawgw 0600`.
- Runtime use: mounted read-only into the contained OpenClaw model-network component and the OpenAI proxy component.
- Rotation: generate new token, update proxy/OpenClaw config transactionally, validate, then retire old token.

The rejected path `/Users/openai-credential-broker/.../local-token/` must not be used for the OpenClaw-readable local token.

## Cutover Driver

`scripts/fa4-openai-proxy-cutover.sh` defaults to dry-run mode.

Dry-run implements and validates:

- deployment manifest;
- topology;
- package files;
- config patch preview;
- 22 transaction phases;
- touched-artifact manifest;
- credential migration design;
- auth cleanup plan;
- regression plan;
- generated rollback script;
- executable transaction fixture suite.

The production flag is present only as a reviewed future entry point and is hard-disabled in the current phase.

## Rollback

Executable rollback support is in `scripts/fa4-openai-proxy-rollback.mjs` and `scripts/fa4-openai-proxy-transaction-fixtures.mjs`.

Historical rollback scenario fixtures are in `scripts/fa4-openai-proxy-rollback-fixtures.mjs`.

Rollback scenarios include:

- proxy failure before config cutover;
- proxy failure after config cutover;
- gateway restart failure;
- model invocation failure;
- egress wall failure;
- auth cleanup overreach;
- reboot persistence failure.

Temporary restoration of the old direct OpenAI route after cutover requires explicit operator approval and evidence.

`scripts/fa4-openai-proxy-transaction-fixtures.mjs` mutates temporary files only and verifies rollback for failures before credential migration, after credential migration, after config patch, proxy start failure, contained OpenClaw failure, gateway restart failure, route-test failure, Gmail/Telegram/Ollama regression failure, source-key removal failure, cold-start failure, and reboot failure.

## Open Blockers

- Actual upstream-key custody path not installed.
- Actual production proxy is not installed.
- Production OpenClaw routing is not changed.
- Live credential migration is not executed.
- Gmail, Telegram, and Ollama regression must be run during later cutover readiness.
- Cold-start and reboot not proved.
- Real production cutover not authorized.

## Production Artifact Paths

| Artifact | Path | Owner | Group | Mode | Rollback |
|---|---|---|---|---:|---|
| local proxy token | `/Users/agent/.openclaw/openai-proxy/local-token` | `openclawgw` | `openclawgw` | `0600` | remove if absent-before; restore backup if existing-before |
| upstream OpenAI credential | `/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets/openai-upstream.json` | `openai-credential-broker` | `openai-credential-broker` | `0600` | remove if absent-before; restore backup if existing-before |
| proxy code | `/Users/openai-credential-broker/agent-os-openai-credential-broker/bin/openai-forward-proxy.mjs` | `root` | `openai-credential-broker` | `0550` | remove if absent-before; restore backup if existing-before |
| proxy runtime | `/Users/openai-credential-broker/agent-os-openai-credential-broker/runtime/node` | `root` | `openai-credential-broker` | `0550` | remove if absent-before; restore backup if existing-before |
| container manifest | `/Users/openai-credential-broker/agent-os-openai-credential-broker/manifests/docker-compose.openai-proxy.yml` | `root` | `openai-credential-broker` | `0440` | remove if absent-before; restore backup if existing-before |
| OpenClaw config | `/Users/agent/.openclaw/openclaw.json` | `root` | `openclawgw` | `0440` | restore exact bytes and metadata; temporary direct-route restoration requires explicit operator approval |
| evidence | `/private/tmp/agent-os-openai-proxy-cutover-<timestamp>-<pid>` | operator | operator | `0700` | preserve evidence |

## Closure Evidence Checklist

- Proxy artifact hashes match manifest.
- Upstream credential is in broker custody only.
- Synthetic token is active and not logged.
- `main`, `research-handoff-gate`, and `email-researcher` route through proxy.
- `heartbeat` and `gmail-reader` remain local-only.
- Direct OpenAI egress from OpenClaw is denied.
- Arbitrary proxy egress is denied.
- Residue scan finds no real OpenAI credential in OpenClaw-readable files, env, children, logs, generated stores, or snapshots.
- Cold-start and reboot validation pass.
