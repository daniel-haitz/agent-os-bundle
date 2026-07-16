# F-A4 OpenAI Proxy Cutover Package

**Status:** Static package plus real substrate proof complete. Production transaction and cutover are not implemented or authorized.

Current canonical status:

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY PRODUCTION SUBSTRATE PROOF: GO`
- `OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: NO`
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
- Storage: manifest-defined local-token path.
- Rotation: generate new token, update proxy/OpenClaw config transactionally, validate, then retire old token.

## Cutover Driver

`scripts/fa4-openai-proxy-cutover.sh` defaults to dry-run mode.

Dry-run validates:

- deployment manifest;
- topology;
- package files;
- config patch preview;
- cutover phases;
- credential migration design.

The production flag is present only as a reviewed future entry point and is not authorized in the current phase. The script is currently a static package validator, not an implementation of the nineteen production cutover phases.

## Rollback

Rollback scenario fixtures are in `scripts/fa4-openai-proxy-rollback-fixtures.mjs`.

Rollback scenarios include:

- proxy failure before config cutover;
- proxy failure after config cutover;
- gateway restart failure;
- model invocation failure;
- egress wall failure;
- auth cleanup overreach;
- reboot persistence failure.

Temporary restoration of the old direct OpenAI route after cutover requires explicit operator approval and evidence.

These fixtures are not executable production rollback proof. Executable migration and rollback remain open blockers.

## Open Blockers

- Production transaction is not implemented.
- Executable credential migration is not implemented.
- Executable rollback is not implemented.
- Actual upstream-key custody path not installed.
- Actual production proxy is not installed.
- Production OpenClaw routing is not changed.
- Gmail, Telegram, and Ollama regression must be run during later cutover readiness.
- Cold-start and reboot not proved.
- Real production cutover not authorized.

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
