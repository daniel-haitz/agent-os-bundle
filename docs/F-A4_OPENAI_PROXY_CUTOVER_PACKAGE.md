# F-A4 OpenAI Proxy Cutover Package

**Status:** Static package and fixture evidence only. Independent review rejected the package as a production transaction implementation. Production execution, operator dry-run, and cutover are not authorized.

Current canonical status:

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY SUBSTRATE PROOF (TEMPORARY FIXTURES): GO`
- `OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: PARTIAL`
- `OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED`
- `F-A4 STATUS: OPEN`

## Purpose

Prepare the controlled replacement of direct OpenAI credential use in OpenClaw with a contained credential-injecting OpenAI forwarding proxy.

## Production Placement

- Status: unresolved and paused.
- Rejected placement: a separate contained OpenClaw model-network component.
- Proxy identity remains `openai-credential-broker` (`uid=540`, `gid=740`) if a proxy path is later authorized.
- Future OpenClaw base URL depends on the selected enforcement architecture.
- Upstream, if a proxy path is authorized: fixed `https://api.openai.com`.
- Host-published ports: none accepted without a separate review.

OpenClaw host-only `baseUrl` placement is not accepted as structural containment while `pf` is disabled. A production egress boundary must be a separately reviewed equivalent that preserves the host Gateway, Gmail broker socket, and host Ollama routes, or governance must explicitly reduce the objective.

The real temporary Colima/internal-network substrate proof proved fixture network behavior, but it did not resolve the production OpenClaw placement decision. The following rejected statement is retained for history only:

- Rejected placement: OpenClaw model-network execution must run inside a contained component on an internal Docker/Colima network, with the OpenAI proxy as a separate dual-homed component.

A host OpenClaw Gateway cannot be structurally denied direct OpenAI egress by changing `baseUrl` alone while `pf` remains disabled.

Read-only reconciliation in `audits/F-A4-openai-proxy-architecture-reconciliation.md` found this rejected placement is not constructible as written on installed OpenClaw `2026.6.11`: model-provider HTTP originates inside the host Gateway process, and the package does not preserve the existing host Gmail broker Unix-socket boundary or host Ollama loopback model routes.

Architecture alternatives review in `audits/F-A4-openai-proxy-architecture-alternatives.md` found no currently viable path that satisfies structural direct OpenAI egress denial while also preserving the host Gateway, Gmail broker socket, host Ollama routes, and `pf`-disabled constraint. The package is paused pending a formal architecture-risk decision.

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
- Rejected single-file storage: `/Users/agent/.openclaw/openai-proxy/local-token`.
- Rejected ownership/mode for shared use: `openclawgw:openclawgw 0600`.
- Reason: a `0600` file owned by `openclawgw` is not normally readable by proxy UID `540`; the substrate proof did not prove this exact production mount/ownership arrangement.
- Bounded alternative to evaluate: one OpenClaw-owned token file and one broker-owned proxy token file with identical generated contents and transactional rotation.
- Rotation: generate new token, update proxy/OpenClaw config transactionally, validate, then retire old token.

The rejected path `/Users/openai-credential-broker/.../local-token/` must not be used for the OpenClaw-readable local token.

## Cutover Driver

`scripts/fa4-openai-proxy-cutover.sh` defaults to dry-run mode.

Dry-run currently validates static package structure and fixture plans:

- deployment manifest;
- topology;
- package files;
- config patch preview;
- a listed 22-phase transaction specification;
- touched-artifact manifest;
- credential migration design;
- auth cleanup plan;
- regression plan;
- generated rollback preview;
- executable transaction fixture suite.

The production flag is present only as a reviewed future entry point and is hard-disabled in the current phase.

## Rollback

Fixture rollback support is in `scripts/fa4-openai-proxy-rollback.mjs` and `scripts/fa4-openai-proxy-transaction-fixtures.mjs`.

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

`scripts/fa4-openai-proxy-transaction-fixtures.mjs` mutates temporary files only. It does not prove production rollback of owner/group, ACL/xattrs, Docker/Colima state, service state, launchd state, source credential custody, or startup ordering.

## Open Blockers

- Production placement decision reopened; contained OpenClaw model-network component is not supported as written.
- Architecture alternatives verdict: no currently viable path under current constraints; formal architecture-risk decision required.
- Local-token custody is unresolved.
- Executable production transaction is not implemented.
- Executable production rollback is not implemented.
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
