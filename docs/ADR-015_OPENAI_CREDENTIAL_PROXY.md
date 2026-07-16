# ADR-015 — OpenAI Credential Proxy Cutover Path

**Status:** Approved design direction under formally reduced F-A4 objective; cutover not executed.

## Decision

Agent OS will replace direct OpenAI static-key use in OpenClaw with a credential-injecting OpenAI forwarding proxy under the reduced objective accepted in `docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md`.

OpenClaw will receive only a synthetic local proxy token. The real upstream OpenAI credential moves to proxy custody under the `openai-credential-broker` identity during a later authorized cutover.

## Production Placement Status

- Placement: host OpenClaw Gateway preserved; credential-injecting proxy path proceeds under the reduced objective.
- OpenAI proxy identity remains `openai-credential-broker` (`uid=540`, `gid=740`).
- Future OpenClaw base URL points to the reviewed local proxy endpoint selected by the revised-objective transaction package.
- OpenAI API adapter remains `openai-responses`.
- Proxy upstream is fixed to `https://api.openai.com`.
- Host `baseUrl` routing is not a network sandbox and must not be described as structural egress denial.

The temporary Colima substrate proof proved fixture network behavior only. It did not prove a production OpenClaw placement. Independent review of `PUBLISHED_REF 0fcde94` rejected the claimed contained OpenClaw model-network component as a production transaction implementation.

Read-only reconciliation in `audits/F-A4-openai-proxy-architecture-reconciliation.md` found:

- Installed OpenClaw `2026.6.11` originates model-provider HTTP inside the host Gateway process.
- No supported model-network worker/sidecar or provider transport bridge was found.
- The rejected placement does not preserve the existing host Gmail broker Unix-socket boundary as written.
- The rejected placement does not preserve host Ollama loopback routes for `heartbeat` and `gmail-reader` as written.
- The production placement decision was reopened, and ADR-016 now accepts the reduced host-Gateway objective for the current platform release.

Changing `models.providers.openai.baseUrl` alone is not structural containment for a host OpenClaw Gateway while `pf` remains disabled.

Read-only alternatives review in `audits/F-A4-openai-proxy-architecture-alternatives.md` found:

- Full Gateway containment could provide structural egress, but it replatforms the host Gateway and requires unproven Gmail/Ollama bridges.
- An OpenClaw provider bridge can preserve real-key non-readability and normal authenticated-route control, but it does not structurally deny direct OpenAI networking from a host Gateway.
- Host egress gateways and proxy environment variables are cooperative only.
- No currently viable candidate meets the former full structural-egress objective while preserving the host Gateway, Gmail broker socket, host Ollama routes, and `pf`-disabled constraint.

ADR-016 records the owner/operator decision to accept the reduced objective for the current platform release.

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
- Normal OpenAI provider traffic must route through the proxy.
- All alternate authenticated direct OpenAI credential sources must be removed, neutralized, or verified absent.
- Closure must not claim structural denial of every possible direct OpenAI network connection from a fully compromised host Gateway process.
- Realtime, image, audio/TTS, file/upload, batch, and assistant/thread endpoints are denied until separately proven.
- Local proxy authentication uses the ADR-016 recommendation: two identity-owned token files with identical generated contents, transactional rotation, no token in environment/argv/logs/repository/image layers/broad evidence, and executable rollback.
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
