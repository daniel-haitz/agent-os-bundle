# F-A4 OpenAI Proxy Architecture Alternatives

**Date:** 2026-07-16  
**Scope:** read-only architecture decision after the contained model-network component was rejected.  
**Runtime baseline:** OpenClaw `2026.6.11 (e085fa1)`.

## Verdict

`NO CURRENTLY VIABLE PATH — F-A4 MUST PAUSE PENDING A DIFFERENT PLATFORM OR CONTROL`

**Superseding decision:** `docs/ADR-016_F-A4_OPENAI_REDUCED_OBJECTIVE_RISK_ACCEPTANCE.md` accepts Candidate E for the current platform release. This audit remains the source evidence for why the former stronger structural-egress objective was moved to future hardening.

Under current canonical constraints, no reviewed candidate both preserves the functioning host OpenClaw Gateway, Gmail broker Unix-socket boundary, host Ollama routes, Telegram/research/web behavior, and `pf`-disabled rule while also structurally denying direct OpenAI egress from the process that originates OpenAI model transport.

The closest implementable path is a provider-bridge/proxy that keeps the real OpenAI key outside OpenClaw and removes normal authenticated direct routes. That is useful, but it does not structurally prevent a host Gateway with general network capability from opening a direct connection to OpenAI if the Gateway process is compromised.

## Mandatory Security Guarantees

Current F-A4 authority requires:

1. Credential non-readability: the real OpenAI key is not readable by OpenClaw files, runtime state, generated stores, environment, tools, or agent-readable artifacts.
2. Authenticated direct-route denial: OpenClaw has no usable real OpenAI credential in provider config, auth profiles, environment, generated stores, snapshots, fallback providers, or runtime caches.
3. Normal OpenAI provider transport uses a credential-injecting proxy, and the proxy strips caller credentials before injecting the broker-owned upstream credential.
4. Gmail broker Unix-socket access and host Ollama routes for `heartbeat` and `gmail-reader` remain functional.
5. `pf` remains disabled.
6. Production cutover, operator dry-run, and live credential migration remain unauthorized.

The unresolved guarantee is stronger:

- all direct network-route denial from the host Gateway process to OpenAI hostname/IP/IPv6 routes; and
- resistance to a fully compromised Gateway process using general network primitives, web/research tools, shell-capable tools, or child processes to bypass the normal provider path.

Those stronger guarantees remain mandatory for structural F-A4 egress containment unless governance explicitly reduces the objective.

## Installed Runtime Evidence

- LaunchDaemon `ai.openclaw.gateway` runs on the host as `openclawgw` with `/Users/agent/.local/openclaw/tools/node-v22.22.0/bin/node /Users/agent/.local/openclaw/tools/node-v22.22.0/lib/node_modules/openclaw/dist/index.js gateway --port 18789 --bind loopback`.
- OpenAI Responses transport is built in-process:
  - `dist/openai-transport-stream-Dj78Cdnf.js:2468-2476` constructs `new OpenAI({ apiKey, baseURL: model.baseUrl, fetch: buildGuardedModelFetch(model) })`.
  - `dist/openai-transport-stream-Dj78Cdnf.js:2508-2516` resolves the API key and creates the client inside the transport stream function.
  - `dist/openai-responses-shared-C2-Tl1CB.js:325-332` invokes `client.responses.create(...).withResponse()`.
- Ollama transport is also in-process:
  - `dist/stream-D4CByBVL.js:717-759` posts to the resolved Ollama chat URL with `fetchWithSsrFGuard`.
  - `dist/stream-D4CByBVL.js:999-1003` creates the configured Ollama stream function from model/provider base URL.
- Auth precedence is source-backed:
  - `dist/model-auth-Bjx4UCgB.js:173-177` lets explicit provider `auth: "api-key"` plus explicit `apiKey` outrank profile/environment auth.
  - `dist/model-auth-Bjx4UCgB.js:518-570` honors explicitly selected profiles.
  - `dist/model-auth-Bjx4UCgB.js:572-759` falls back through configured profile order, environment, and configured provider keys.
- Gmail broker socket is host-local:
  - `/var/run/agent-os` is `gmailbroker:gmailbroker-clients 0750`.
  - `/var/run/agent-os/gmail-broker.sock` is `gmailbroker:gmailbroker-clients 0660`.
- Ollama is host-local at `http://127.0.0.1:11434/` and returned `HTTP/1.1 200 OK`.
- Colima was observed stopped during this read-only pass; no container substrate was started.
- macOS Application Firewall tooling shown by `/usr/libexec/ApplicationFirewall/socketfilterfw --help` is app allow/block oriented and not a per-destination outbound OpenAI egress control. `sandbox-exec` exists, but no accepted profile or supported OpenClaw launch wrapper currently provides the required destination-selective network policy while preserving Telegram/web/Gmail/Ollama behavior.

## Candidate A — Containerize the Full Gateway

Classification: `SUPPORTED WITH BOUNDED CHANGES` as a replatforming project, but not viable under the current preservation constraint.

Running the actual OpenClaw Gateway inside Docker/Colima would make contained-network egress controls meaningful because the process that originates OpenAI transport would no longer retain unrestricted host networking. It would require moving the real Gateway command, config/state, workspaces, Telegram runtime, local tools, browser/research behavior, and supervision model into the contained placement.

Required unresolved paths:

- Gateway to Gmail broker: either bind-mount `/var/run/agent-os/gmail-broker.sock` into the container with exact `gmailbroker-clients` GID semantics, or add a new broker bridge. Neither is proven, and both affect the accepted F-A1 socket boundary.
- `heartbeat`/`gmail-reader` to Ollama: host loopback `127.0.0.1:11434` is not reachable from a host-escape-denied container. `host.docker.internal` or a host gateway bridge reopens host reachability. A narrow Ollama bridge would be a new component.
- Launchd/tamper boundary: the current root-owned host LaunchDaemon and `/Users/agent/.openclaw` custody model would need a container-equivalent custody and upgrade/rollback model.
- Telegram/research/web/local tools: all host and network paths would need separate regression evidence.

Candidate A can potentially provide all-direct OpenAI network-route denial, but it does not preserve the functioning host Gateway as required. It is a different platform placement, not a bounded continuation of the current package.

## Candidate B — OpenClaw Provider-Bridge Patch

Classification: useful for key custody and normal authenticated route control, insufficient for structural egress alone.

Patch points are concrete:

- Replace or wrap `createOpenAIResponsesClient` at `dist/openai-transport-stream-Dj78Cdnf.js:2468-2476`.
- Ensure `createOpenAIResponsesTransportStreamFn` at `dist/openai-transport-stream-Dj78Cdnf.js:2478-2516` cannot fall back to `getEnvApiKey(model.provider)`.
- Keep Responses calls at `dist/openai-responses-shared-C2-Tl1CB.js:325-332` on a fixed IPC-backed client path.
- Deny or scrub auth precedence paths in `dist/model-auth-Bjx4UCgB.js:518-765` so profile/env/generated stores cannot restore a real key.

Possible IPCs:

- Unix-domain socket with peer credentials;
- authenticated loopback service;
- fixed root-controlled local broker binary.

Guarantees:

| Guarantee | Result |
|---|---|
| Key non-readability | Achievable if the real key stays only in broker/proxy custody. |
| Authenticated direct-route denial for normal provider transport | Achievable if all auth/profile/env/generated stores are cleaned or ignored. |
| All direct OpenAI connectivity denial | Not achieved. The host Gateway keeps general networking. |
| Fully compromised Gateway resistance | Not achieved. A compromised Gateway can use other network primitives unless another enforcement control exists. |

This candidate requires a maintained OpenClaw fork or local patch with integrity verification. Upgrades can overwrite it. It should not be described as structural egress containment without a separate host egress control.

## Candidate C — Host Process Sandbox / Egress Control

Classification: no supported current control found that satisfies the full policy while preserving current behavior.

Reviewed mechanisms:

| Mechanism | Finding |
|---|---|
| macOS Application Firewall | Inbound/application allow/block oriented; not a destination-selective outbound OpenAI denial control. |
| `sandbox-exec` / Seatbelt profiles | Present on host, but no accepted OpenClaw profile exists. A profile broad enough for Telegram, web/research, local sockets, and Ollama would still need precise outbound destination control; a profile strict enough for OpenAI denial risks breaking required runtime behavior and is not currently supported by the build. |
| Network Extension / content filter | Potentially capable, but requires a new signed privileged host component and operational approval outside the current package. It is not an existing Agent OS foundation and would need independent proof. |
| User/UID-specific firewall outside `pf` | No accepted built-in mechanism was found that provides per-UID OpenAI hostname/IP/IPv6 denial while preserving required local and web paths. |
| Launchd wrappers and proxy environment | Cooperative only; direct sockets, SDKs, child processes, or altered environment can bypass. |

Candidate C remains possible only if governance authorizes a new host enforcement component, such as a signed Network Extension/content filter, or reopens the `pf` prohibition. Neither is available under current constraints.

## Candidate D — Narrow Host Egress Gateway

Classification: `COOPERATIVE ONLY`.

Keeping the Gateway on the host while setting provider `baseUrl` or process proxy environment to a local egress gateway preserves Gmail, Ollama, Telegram, and local tooling paths. It does not force all outbound traffic through that gateway:

- Node `fetch`, OpenAI SDK calls, child processes, shell tools, and plugins can create direct sockets unless the host enforces a network rule outside the process.
- Proxy environment variables are mutable/cooperative and can be ignored.
- DNS and direct-IP bypass remain possible.

Candidate D is acceptable only for a reduced objective where normal provider traffic is routed through the proxy and real-key custody is removed from OpenClaw. It is not structural direct-route denial.

## Candidate E — Reduced Security Objective

Classification: technically achievable, but requires explicit architecture-risk acceptance.

Reduced objective:

- The real OpenAI key is isolated in proxy custody and never stored in OpenClaw-readable state.
- OpenClaw receives only a constrained synthetic local token.
- Normal `openai/gpt-5.5` Responses transport uses the proxy.
- Existing provider keys, auth profiles, environment credentials, generated stores, and direct authenticated fallbacks are removed or neutralized.

Remaining risk:

- The host Gateway still has general network capability.
- A fully compromised Gateway could attempt unauthenticated direct OpenAI connections, use other network paths, or exploit any missed authenticated source.
- This does not structurally deny all direct OpenAI network routes.

Accepting this model would explicitly weaken the currently stated structural egress objective. It must be recorded as an architecture-risk decision, not treated as F-A4 containment completion.

## Gmail And Ollama Preservation Paths

| Candidate | Gateway to Gmail broker | `gmail-reader` to Gmail broker | `heartbeat` to Ollama | `gmail-reader` to Ollama | Telegram/web/research | OpenAI proxy path |
|---|---|---|---|---|---|---|
| A Full Gateway container | Requires socket bind/bridge; unproven GID and boundary impact | Same contained path; unproven | Requires host Ollama bridge; host loopback unavailable | Same | Must be revalidated in container | Structurally enforceable in contained network if all Gateway traffic moves |
| B Provider bridge | Existing host socket unchanged | Existing host socket unchanged | Existing host `127.0.0.1:11434` unchanged | Existing host `127.0.0.1:11434` unchanged | Existing host paths unchanged | Normal OpenAI provider path goes IPC/proxy; no structural network denial |
| C Host egress control | Existing host socket unchanged if policy permits local Unix sockets | Existing host socket unchanged | Existing host loopback unchanged if policy permits | Existing host loopback unchanged if policy permits | Must be encoded in host filter | Could be structural only with a proven destination filter |
| D Host egress gateway | Existing host socket unchanged | Existing host socket unchanged | Existing host loopback unchanged | Existing host loopback unchanged | Existing host paths unchanged | Cooperative proxy/baseUrl path only |
| E Reduced objective | Existing host socket unchanged | Existing host socket unchanged | Existing host loopback unchanged | Existing host loopback unchanged | Existing host paths unchanged | Cooperative/provider-bridge path with real-key custody removed |

## Auth And Credential Sources

The current operator-proven live direct-bypass source remains:

- `/Users/agent/.openclaw/openclaw.json:models.providers.openai.apiKey`

The package must still account for:

- auth profiles and manually selected profile IDs;
- environment variables including provider-specific keys;
- generated model stores;
- runtime snapshots/caches;
- backups and temporary files;
- prior SecretRef plans and superseded resolver artifacts;
- fallback providers and aliases.

Installed precedence means removing the explicit provider key can cause profile or environment credentials to become effective unless the cutover explicitly cleans or denies them. No candidate can claim authenticated direct-route denial without a deterministic cleanup and verification pass across all these surfaces.

## Local Token Options

| Option | Assessment |
|---|---|
| Two identical `0600` token files, one per identity | Best fit for a host/proxy or container split if static bearer tokens are used. Avoids impossible shared-owner semantics. Requires transactional rotation and equality verification without logging values. |
| Group-readable shared token with narrow group | Possible but increases blast radius and group-management burden. It should not be selected unless two-file rotation is rejected for a concrete reason. |
| Proxy-generated challenge/response or short-lived token | Stronger than static token, but adds protocol complexity and state synchronization. Useful if a long-lived synthetic token is considered too exposed. |
| Unix-socket peer credentials with no static token | Preferred if a provider bridge or local IPC is selected and both peers are on the same host/namespace. It avoids static token storage but does not solve structural egress by itself. |
| Other mechanism | Requires source-backed proof before selection. |

Because no production placement is selected, there is no final local-token selection. If governance chooses Candidate B, Unix-socket peer credentials should be evaluated first. If it chooses a loopback HTTP proxy, use two separate token files rather than one shared `0600` file.

## Decision Matrix

| Candidate | Preserves host Gateway | Preserves Gmail | Preserves Ollama | Real key unreadable by OpenClaw | Blocks authenticated direct OpenAI bypass | Blocks all direct OpenAI connectivity | Protects against compromised Gateway | Requires OpenClaw fork | Requires signed macOS component | Upgrade burden | Complexity | Reversible | Evidence needed | Recommendation |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---|
| A Full Gateway container | No | Unproven | Unproven | Yes | Yes | Yes | Stronger, if all Gateway traffic moves | No | No | High | High | Medium | Full Gateway container proof, Gmail socket bridge, Ollama bridge, Telegram/web regressions | Not viable under current preservation constraint |
| B Provider bridge patch | Yes | Yes | Yes | Yes | Yes for normal provider path | No | No | Yes | No | High | Medium | Medium | Patch integrity, auth cleanup, IPC proof, separate enforcement/risk decision | Viable only for reduced/partial objective or with separate enforcement |
| C Host process egress control | Yes | Potentially | Potentially | Yes | Yes | Potentially | Potentially | No | Likely for Network Extension | High | High | Medium | Supported host filter proof covering DNS/IP/IPv6 and regressions | No current accepted control |
| D Host egress gateway | Yes | Yes | Yes | Yes | Cooperative | No | No | No | No | Low | Medium | High | Bypass analysis and risk acceptance | Cooperative only |
| E Reduced objective | Yes | Yes | Yes | Yes | Yes if cleanup complete | No | No | No | No | Low-Medium | Medium | High | Formal risk acceptance, cleanup proof | Requires explicit objective reduction |

## Risks And Tradeoffs

- Full containment is strongest but replatforms the Gateway and threatens existing Gmail/Ollama boundaries.
- Provider bridge preserves current behavior but creates fork/upgrade burden and does not block a compromised Gateway from direct networking.
- Host egress enforcement could solve the core issue only with a real supported control not currently approved.
- Reduced objective is practical but conflicts with structural egress containment unless explicitly accepted.

## Evidence Gaps

- No supported OpenClaw provider-worker/sidecar boundary for `2026.6.11`.
- No proven safe Gmail Unix-socket bridge into Colima.
- No proven narrow Ollama bridge that avoids broad host escape.
- No accepted macOS per-process OpenAI egress control while `pf` remains disabled.
- No executable production rollback for owner/group, ACL/xattrs, service state, Docker/Colima state, launchd state, or credential custody.
- No formal risk acceptance for reducing F-A4 to credential non-readability plus cooperative/authenticated-route denial.

## Approved Next Bounded Action

Superseded by ADR-016. The option chosen after this audit was the formally reduced objective.

Prepare a formal F-A4 architecture-risk decision package that chooses exactly one of:

1. authorize a different enforcement platform/control, such as full Gateway replatforming, `pf`, or a signed Network Extension/content filter;
2. authorize a maintained OpenClaw provider-bridge patch plus an explicitly separate enforcement control; or
3. formally reduce the F-A4 OpenAI objective to credential non-readability plus authenticated direct-route cleanup, with the remaining compromised-Gateway direct-network risk accepted.

No implementation, operator dry-run, production cutover, credential migration, or runtime change is authorized by this decision.
