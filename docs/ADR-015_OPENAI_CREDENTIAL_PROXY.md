# ADR-015 — OpenAI Credential Proxy Cutover Path

**Status:** Approved design direction; proxy/static fixture proof passed; no viable production enforcement path under current constraints; cutover not executed.

## Decision

Agent OS will replace direct OpenAI static-key use in OpenClaw with a credential-injecting OpenAI forwarding proxy only after the enforcement architecture is explicitly selected.

OpenClaw will receive only a synthetic local proxy token. The real upstream OpenAI credential moves to proxy custody under the `openai-credential-broker` identity during a later authorized cutover.

## Production Placement Status

- Placement: unresolved. The previously proposed contained model-network component is rejected as written.
- OpenAI proxy identity remains `openai-credential-broker` (`uid=540`, `gid=740`) if a proxy path is later authorized.
- Future OpenClaw base URL depends on the selected enforcement architecture.
- OpenAI API adapter remains `openai-responses`.
- Proxy upstream is fixed to `https://api.openai.com`.
- Host-only `baseUrl` placement remains rejected as structural containment while `pf` is disabled.

The temporary Colima substrate proof proved fixture network behavior only. It did not prove a production OpenClaw placement. Independent review of `PUBLISHED_REF 0fcde94` rejected the claimed contained OpenClaw model-network component as a production transaction implementation.

Read-only reconciliation in `audits/F-A4-openai-proxy-architecture-reconciliation.md` found:

- Installed OpenClaw `2026.6.11` originates model-provider HTTP inside the host Gateway process.
- No supported model-network worker/sidecar or provider transport bridge was found.
- The rejected placement does not preserve the existing host Gmail broker Unix-socket boundary as written.
- The rejected placement does not preserve host Ollama loopback routes for `heartbeat` and `gmail-reader` as written.
- The production placement decision must be reopened.

Changing `models.providers.openai.baseUrl` alone is not structural containment for a host OpenClaw Gateway while `pf` remains disabled.

Read-only alternatives review in `audits/F-A4-openai-proxy-architecture-alternatives.md` found:

- Full Gateway containment could provide structural egress, but it replatforms the host Gateway and requires unproven Gmail/Ollama bridges.
- An OpenClaw provider bridge can preserve real-key non-readability and normal authenticated-route control, but it does not structurally deny direct OpenAI networking from a host Gateway.
- Host egress gateways and proxy environment variables are cooperative only.
- No currently viable candidate meets the full F-A4 OpenAI objective while preserving the host Gateway, Gmail broker socket, host Ollama routes, and `pf`-disabled constraint.
- Continuing requires a formal architecture-risk decision.

## Scope

OpenAI routes requiring cutover:

- `main`
- `research-handoff-gate`
- `email-researcher`

Local-only routes remain unchanged:

- `heartbeat`
- `gmail-reader`

## Security Requirements

- The real OpenAI key is never printed, passed on a command line, committed, or written to broad evidence.
- The proxy strips caller credential headers and injects exactly one upstream `Authorization` header.
- OpenClaw direct egress to OpenAI must be structurally denied by the selected enforcement architecture before cutover can be approved.
- Realtime, image, audio/TTS, file/upload, batch, and assistant/thread endpoints are denied until separately proven.
- The previous single-file local token path `/Users/agent/.openclaw/openai-proxy/local-token` as `openclawgw:openclawgw 0600` is not accepted for shared use by both `openclawgw` and proxy UID `540`; a two-file transactional rotation model must be evaluated.
- The upstream OpenAI key is stored at `/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets/openai-upstream.json` as `openai-credential-broker:openai-credential-broker 0600` and mounted read-only into the proxy only.

## Superseded Path

The file-backed and exec-backed SecretRef OpenAI key paths are superseded for zero-read OpenAI credential custody because OpenClaw eagerly resolves SecretRefs into runtime state.

## Evidence

- Proxy transport/security fixture: `scripts/fa4-openai-proxy-fixture-tests.mjs`.
- Contained-egress fixture: `scripts/fa4-openai-proxy-contained-egress-tests.mjs`.
- Real Colima/internal-network substrate proof: `scripts/fa4-openai-proxy-colima-substrate-proof.mjs` and `audits/F-A4-openai-proxy-colima-substrate-proof.md`.
- Static transaction specification and fixture rollback package: `scripts/fa4-openai-proxy-cutover.sh`, `scripts/fa4-openai-proxy-rollback.mjs`, and `scripts/fa4-openai-proxy-transaction-fixtures.mjs`.
- Operator inventory: `audits/F-A4-openai-proxy-production-inventory.json`.
- Cutover package manifest: `deploy/openai-proxy/openai-proxy-deployment-manifest.json`.

The contained-egress fixture is synthetic policy proof. The temporary Colima/internal-network substrate proof separately validates Docker/Colima fixture networking, container DNS, IPv4/IPv6 denial, direct-IP denial, host-network escape resistance, restart/reconnect behavior, proxy-only upstream access, UID/GID mapping, token mount separation, and teardown for temporary resources only.
