# ADR-015 — OpenAI Credential Proxy Cutover Path

**Status:** Approved design; production cutover not executed.

## Decision

Agent OS will replace direct OpenAI static-key use in OpenClaw with a contained OpenAI forwarding proxy.

OpenClaw will receive only a synthetic local proxy token. The real upstream OpenAI credential moves to proxy custody under the `openai-credential-broker` identity during a later authorized cutover.

## Production Topology

- Placement: contained Colima/internal-network components.
- OpenAI proxy: `agent-os-openai-forward-proxy`, identity `openai-credential-broker` (`uid=540`, `gid=740`).
- Future OpenClaw base URL: `http://agent-os-openai-forward-proxy:18187/v1`.
- OpenAI API adapter remains `openai-responses`.
- Proxy upstream is fixed to `https://api.openai.com`.
- Host-only placement remains rejected while `pf` is disabled.

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

## Superseded Path

The file-backed and exec-backed SecretRef OpenAI key paths are superseded for zero-read OpenAI credential custody because OpenClaw eagerly resolves SecretRefs into runtime state.

## Evidence

- Proxy transport/security fixture: `scripts/fa4-openai-proxy-fixture-tests.mjs`.
- Contained-egress fixture: `scripts/fa4-openai-proxy-contained-egress-tests.mjs`.
- Operator inventory: `audits/F-A4-openai-proxy-production-inventory.json`.
- Cutover package manifest: `deploy/openai-proxy/openai-proxy-deployment-manifest.json`.
