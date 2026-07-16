# ADR-016 — F-A4 OpenAI Reduced Objective Risk Acceptance

**Status:** Accepted architecture-risk decision.  
**Date:** 2026-07-16.  
**Applies to:** F-A4 OpenAI credential custody and provider routing on OpenClaw `2026.6.11 (e085fa1)`.

## Decision

Agent OS accepts a formally reduced F-A4 OpenAI security objective for the current platform release.

The host OpenClaw Gateway remains in place. Gmail broker Unix-socket access, host Ollama routes, Telegram, research/web capability, current launchd/tamper controls, and disabled `pf` are preserved.

The OpenAI static-key remediation path proceeds with a credential-injecting forwarding proxy and deterministic removal of alternate authenticated OpenAI credential sources. It does not claim structural denial of every possible direct OpenAI network connection from a fully compromised host Gateway process.

## Prior Objective

The prior objective required all of the following:

- the real OpenAI key is outside OpenClaw-readable state;
- normal OpenAI provider traffic routes through a credential-injecting proxy;
- alternate authenticated direct OpenAI credential sources are removed or denied;
- direct OpenAI egress from the process that originates model transport is structurally denied;
- a fully compromised Gateway process cannot bypass the proxy with direct OpenAI networking;
- Gmail broker, host Ollama, Telegram, research/web, and launchd/tamper controls remain intact;
- `pf` remains disabled.

## Why The Prior Objective Is Not Achievable Now

`audits/F-A4-openai-proxy-architecture-reconciliation.md` and `audits/F-A4-openai-proxy-architecture-alternatives.md` found:

- installed OpenClaw `2026.6.11` originates OpenAI Responses transport inside the host Gateway process;
- installed OpenClaw has no supported model-network worker/sidecar boundary for moving only model provider traffic into containment;
- full Gateway containerization would replatform the host Gateway and introduces unproven Gmail broker and host Ollama bridge problems;
- a host `baseUrl`/HTTP-proxy configuration is cooperative, not a network sandbox;
- macOS host-process egress controls that could enforce the stronger guarantee require a different platform/control decision outside the current constraints;
- `pf` remains disabled by authority.

Therefore the stronger structural-egress objective cannot be met while preserving the required host Gateway, Gmail, Ollama, Telegram, research/web, launchd/tamper, and `pf`-disabled constraints.

## Alternatives Considered

| Alternative | Result |
|---|---|
| Full Gateway containment | Stronger egress control possible, but not selected because it replatforms the host Gateway and leaves Gmail/Ollama bridges unproven. |
| OpenClaw provider-bridge patch | Can improve key custody and normal route control, but does not by itself structurally deny host Gateway networking and creates an upgrade burden. |
| macOS host egress control | No accepted built-in per-destination/per-process control is available under the current constraints; Network Extension or `pf` would require a separate decision. |
| Host egress gateway or proxy environment | Cooperative only; direct sockets, SDKs, child processes, and environment changes can bypass it. |
| Reduced objective with credential-injecting proxy | Selected for current platform release with explicit residual-risk acceptance. |

## Revised Objective

The revised F-A4 OpenAI objective is:

1. The real upstream OpenAI credential is not readable by OpenClaw, agents, tools, provider configuration, auth profiles, generated stores, environment, logs, evidence, snapshots, backups, or normal runtime artifacts.
2. Normal OpenAI provider traffic routes through the credential-injecting proxy.
3. All alternate authenticated direct OpenAI credential sources are removed, neutralized, or verified absent.
4. The proxy strips caller credentials and injects the broker-owned upstream credential.
5. Gmail broker, Ollama, Telegram, research/web, and existing host functionality remain intact.
6. The system does not claim structural denial of every possible direct OpenAI network connection from a fully compromised host Gateway process.
7. The residual compromised-Gateway direct-network risk is explicitly accepted for the current platform release.

## Threat Coverage Matrix

| Threat | Revised objective result |
|---|---|
| OpenAI key readable from OpenClaw config | Mitigated; must be absent after cutover. |
| OpenAI key readable from auth profiles | Mitigated; must be absent after cutover. |
| OpenAI key readable from generated stores, snapshots, caches, backups, logs, evidence, or environment | Mitigated; residue scan is a closure gate. |
| Normal OpenAI provider request bypasses proxy | Mitigated through `baseUrl` and auth-precedence cleanup; must be functionally proven. |
| Caller supplies its own credential headers to proxy | Mitigated; proxy must strip caller credential headers and inject one broker-owned upstream credential. |
| Gmail broker disrupted | Mitigated by preserving host Gateway and existing socket boundary; regression required. |
| Host Ollama routes disrupted | Mitigated by preserving host Gateway and host loopback routes; regression required. |
| Telegram or research/web disrupted | Mitigated by preserving host Gateway; regression required. |
| Fully compromised host Gateway opens unauthenticated direct network connection to OpenAI | Accepted residual risk. |
| Fully compromised host Gateway uses a missed real OpenAI credential source | Not accepted; credential-source cleanup and residue scan must prevent this. |
| Future platform supports stronger process egress control | Future hardening trigger. |

## Revised Closure Criteria

F-A4 OpenAI closure may be considered only after all of these pass:

- upstream OpenAI key is in broker/proxy custody only;
- zero OpenClaw-readable upstream OpenAI credential;
- normal provider route through proxy;
- deterministic auth-precedence cleanup;
- no OpenAI key in provider config;
- no OpenAI key in auth profiles;
- no OpenAI key in environment or launchd;
- no key residue in generated stores, snapshots, backups, caches, logs, or evidence;
- constrained local proxy capability;
- proxy request, path, method, header, timeout, and body enforcement;
- Gmail broker regression;
- Telegram regression;
- Ollama regression;
- research/web regression;
- restart validation;
- reboot validation;
- executable rollback and recovery;
- residual-risk acceptance recorded in this ADR and cited by closure evidence.

Closure must not claim structural denial of every possible direct OpenAI network connection from a fully compromised host Gateway process.

## Local Proxy Authentication Recommendation

Use authenticated loopback with two identity-owned token files:

- an OpenClaw-readable local token file owned by the OpenClaw runtime identity;
- a proxy-readable local token file owned by the broker/proxy identity;
- identical generated token contents, minimum 256 bits entropy;
- no token in environment, argv, logs, repository, image layers, or broad evidence;
- transactional rotation writes both files, validates proxy and OpenClaw route behavior, then retires prior token material;
- rollback restores prior token files and metadata or removes newly created token files.

Unix-domain socket peer credentials remain attractive for a future IPC provider bridge, but the current revised objective preserves the existing host OpenClaw transport and uses the installed supported `baseUrl` path. The two-file token model is the simplest bounded mechanism for the host-based proxy placement.

## Future Hardening Trigger

Move this former requirement to future hardening:

> structural denial of every possible direct OpenAI network connection from a fully compromised host Gateway process.

Revisit the stronger objective if any of these become available or authorized:

- full Gateway replatforming with proven Gmail/Ollama/Telegram/research regressions;
- a supported OpenClaw provider transport boundary or upstream provider-bridge feature;
- an accepted macOS process egress control such as a signed content filter;
- explicit authorization to use `pf` or another host enforcement mechanism.

## Review And Expiration

This risk acceptance must be reviewed:

- before F-A4 closure;
- before any OpenClaw upgrade qualification;
- before enabling new OpenAI endpoint classes such as realtime, image, audio/TTS, files/uploads, batches, or assistants/threads;
- after any incident suggesting OpenClaw-readable credential residue or direct authenticated OpenAI bypass;
- no later than the next OpenClaw production baseline change.

## Owner Approval Requirement

This decision requires owner/operator approval because it explicitly accepts residual compromised-Gateway direct-network risk. The decision is not transferable to other providers, endpoints, or future platform releases without review.

## Next Bounded Action

Implement the revised-objective proxy transaction and executable rollback package, with production execution still disabled.
