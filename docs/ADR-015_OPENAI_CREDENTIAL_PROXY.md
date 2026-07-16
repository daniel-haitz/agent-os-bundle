# ADR-015 — OpenAI Credential Proxy Cutover Path

**Status:** Approved design direction; production substrate proof passed; transaction package implemented; cutover not executed.

## Decision

Agent OS will replace direct OpenAI static-key use in OpenClaw with a contained OpenAI forwarding proxy.

OpenClaw will receive only a synthetic local proxy token. The real upstream OpenAI credential moves to proxy custody under the `openai-credential-broker` identity during a later authorized cutover.

## Production Placement

- Placement: contained Colima/internal-network components.
- OpenAI proxy: `agent-os-openai-forward-proxy`, identity `openai-credential-broker` (`uid=540`, `gid=740`).
- Future OpenClaw base URL: `http://agent-os-openai-forward-proxy:18187/v1`.
- OpenAI API adapter remains `openai-responses`.
- Proxy upstream is fixed to `https://api.openai.com`.
- Host-only placement remains rejected while `pf` is disabled.

The real substrate proof resolved the placement decision: OpenClaw model-network execution must run inside a contained component on an internal Docker/Colima network. The OpenAI proxy is a separate contained component dual-homed between the OpenClaw-side internal network and a constrained upstream egress network. A host OpenClaw Gateway may orchestrate, but must not originate direct OpenAI HTTP traffic after F-A4 closure.

Changing `models.providers.openai.baseUrl` alone is not structural containment for a host OpenClaw Gateway while `pf` remains disabled.

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
- OpenClaw direct egress to OpenAI is denied by the contained-network policy after cutover.
- Realtime, image, audio/TTS, file/upload, batch, and assistant/thread endpoints are denied until separately proven.
- The constrained local proxy token is stored at `/Users/agent/.openclaw/openai-proxy/local-token` as `openclawgw:openclawgw 0600` and mounted read-only into contained components.
- The upstream OpenAI key is stored at `/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets/openai-upstream.json` as `openai-credential-broker:openai-credential-broker 0600` and mounted read-only into the proxy only.

## Superseded Path

The file-backed and exec-backed SecretRef OpenAI key paths are superseded for zero-read OpenAI credential custody because OpenClaw eagerly resolves SecretRefs into runtime state.

## Evidence

- Proxy transport/security fixture: `scripts/fa4-openai-proxy-fixture-tests.mjs`.
- Contained-egress fixture: `scripts/fa4-openai-proxy-contained-egress-tests.mjs`.
- Real Colima/internal-network substrate proof: `scripts/fa4-openai-proxy-colima-substrate-proof.mjs` and `audits/F-A4-openai-proxy-colima-substrate-proof.md`.
- Production transaction dry-run and rollback package: `scripts/fa4-openai-proxy-cutover.sh`, `scripts/fa4-openai-proxy-rollback.mjs`, and `scripts/fa4-openai-proxy-transaction-fixtures.mjs`.
- Operator inventory: `audits/F-A4-openai-proxy-production-inventory.json`.
- Cutover package manifest: `deploy/openai-proxy/openai-proxy-deployment-manifest.json`.

The contained-egress fixture is synthetic policy proof. The real Colima/internal-network substrate proof separately validates Docker/Colima networking, container DNS, IPv4/IPv6 denial, direct-IP denial, host-network escape resistance, restart/reconnect behavior, proxy-only upstream access, UID/GID mapping, token mount separation, and teardown.
