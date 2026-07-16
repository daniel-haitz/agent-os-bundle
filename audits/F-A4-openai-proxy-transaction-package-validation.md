# F-A4 OpenAI Proxy Transaction Package Validation

## Result

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY SUBSTRATE PROOF (TEMPORARY FIXTURES): GO`
- `OPENAI PROXY PRODUCTION TRANSACTION SPECIFICATION: PARTIAL`
- `OPENAI PROXY PRODUCTION TRANSACTION EXECUTABLE: NO-GO`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `OPENAI PROXY OPERATOR DRY-RUN: NOT AUTHORIZED`
- `F-A4 STATUS: OPEN`

This supersedes the earlier `OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: GO` wording. Independent review of `PUBLISHED_REF 0fcde94` rejected the package as a production transaction implementation. See `audits/F-A4-openai-proxy-architecture-reconciliation.md`.

## Scope

This validation covers the static transaction specification and fixture rollback package only.

It did not:

- perform production cutover;
- move the real OpenAI credential;
- change live OpenClaw configuration;
- change auth profiles or generated stores;
- change launchd services;
- create production containers or networks;
- change `pf`;
- change Gmail broker, Telegram, or Ollama configuration.

## Static Package

- Transaction driver: `scripts/fa4-openai-proxy-cutover.sh`.
- Rollback fixture helper: `scripts/fa4-openai-proxy-rollback.mjs`.
- Transaction fixture suite: `scripts/fa4-openai-proxy-transaction-fixtures.mjs`.
- Deployment manifest: `deploy/openai-proxy/openai-proxy-deployment-manifest.json`.

Production mode remains hard-disabled. Operator dry-run and production cutover are not authorized.

## Production Artifact Paths

| Artifact | Path | Owner | Group | Mode |
|---|---|---|---|---:|
| local proxy token | `/Users/agent/.openclaw/openai-proxy/local-token` | `openclawgw` | `openclawgw` | `0600` |
| upstream OpenAI credential | `/Users/openai-credential-broker/agent-os-openai-credential-broker/secrets/openai-upstream.json` | `openai-credential-broker` | `openai-credential-broker` | `0600` |
| proxy code | `/Users/openai-credential-broker/agent-os-openai-credential-broker/bin/openai-forward-proxy.mjs` | `root` | `openai-credential-broker` | `0550` |
| proxy runtime | `/Users/openai-credential-broker/agent-os-openai-credential-broker/runtime/node` | `root` | `openai-credential-broker` | `0550` |
| container manifest | `/Users/openai-credential-broker/agent-os-openai-credential-broker/manifests/docker-compose.openai-proxy.yml` | `root` | `openai-credential-broker` | `0440` |
| OpenClaw config | `/Users/agent/.openclaw/openclaw.json` | `root` | `openclawgw` | `0440` |
| evidence directory | `/private/tmp/agent-os-openai-proxy-cutover-<timestamp>-<pid>` | operator | operator | `0700` |

## Transaction Phases

The dry-run transaction lists 22 phases, but does not implement a production-executable cutover:

1. preflight
2. evidence capture
3. current-state verification
4. Colima substrate verification
5. production network staging
6. contained OpenClaw component staging
7. proxy component staging
8. proxy code/runtime integrity verification
9. local-token generation and staging
10. upstream-key migration staging
11. proxy health validation
12. contained OpenClaw-to-proxy validation
13. direct-egress denial validation
14. OpenClaw config/auth patch staging
15. gateway restart plan
16. functional route validation
17. Gmail/Telegram/Ollama regression plan
18. source-key removal gate
19. residue scan
20. cold-start handoff
21. reboot handoff
22. closure evidence

## Fixture Results

- Credential migration fixture: PASS.
- Residue-scan fixture: PASS.
- Fixture rollback stages: PASS.
- Evidence non-disclosure fixture: PASS.
- Transaction fixture total: `19/19 PASS`.
- Historical rollback scenario fixture: `7/7 PASS`.
- Proxy fixture: `39/39 PASS`.
- Synthetic contained-egress fixture: `23/23 PASS`.

## Rollback Coverage

Executable rollback fixture stages cover:

- failure before credential migration;
- failure after credential migration but before config patch;
- failure after config patch;
- proxy start failure;
- contained OpenClaw failure;
- gateway restart failure;
- route-test failure;
- Gmail/Telegram/Ollama regression failure;
- source-key removal failure;
- cold-start failure;
- reboot failure.

Temporary restoration of the old direct OpenAI route after cutover requires explicit operator approval and evidence.

## Remaining Blockers

- Production cutover is not executed.
- Live OpenAI credential migration is not executed.
- Production proxy and contained OpenClaw components are not installed.
- Live OpenClaw routing is not changed.
- Gmail, Telegram, Ollama, cold-start, and reboot validations remain future gates.

## Next Action

Independent adversarial review of the completed production transaction and executable rollback package.
