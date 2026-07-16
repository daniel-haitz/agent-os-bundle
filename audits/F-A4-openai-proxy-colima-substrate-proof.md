# F-A4 OpenAI Proxy Colima Substrate Proof

## Result

`OPENAI PROXY PRODUCTION SUBSTRATE PROOF: GO`

Evidence directory:

`/Users/agent/fa4-openai-proxy-substrate-20260716T193354Z-f04c42`

Raw evidence file:

`/Users/agent/fa4-openai-proxy-substrate-20260716T193354Z-f04c42/substrate-proof.json`

## Scope

This proof used temporary Docker/Colima fixture resources only.

It did not modify:

- live OpenClaw configuration;
- live OpenClaw credentials;
- auth profiles;
- generated stores;
- launchd services;
- `pf`;
- production proxy policy;
- production containers or networks;
- Gmail broker;
- Telegram configuration;
- Ollama configuration.

No production cutover, credential migration, or production proxy installation was performed.

## Initial Substrate State

- Colima was initially stopped before this task and was started using the existing profile without configuration flags.
- Colima runtime during proof: Docker on macOS Virtualization Framework, `aarch64`, `virtiofs`.
- Docker client context: `colima`.
- Docker server: `29.5.2`.
- Proof image: local `openclaw-sandbox:bookworm-slim`.
- Existing containers before proof were OpenClaw sandbox containers on Docker network `none`; they were not modified.
- Existing Docker networks before proof: `bridge`, `host`, `none`.
- Existing Docker volumes before proof: none.

## Temporary Topology

Unique proof label:

`ai.agent-os.proof=openai-proxy-substrate-20260716T193354Z-f04c42`

Temporary internal networks:

- `aos-oc-20260716T193354Z-f04c42`: OpenClaw-side fixture to proxy only.
- `aos-up-20260716T193354Z-f04c42`: proxy to approved synthetic upstream only.
- `aos-deny-20260716T193354Z-f04c42`: negative-control forbidden destination network.

Temporary containers:

- `aos-openclaw-20260716T193354Z-f04c42`: OpenClaw-side fixture.
- `aos-proxy-20260716T193354Z-f04c42`: forwarding-proxy fixture, dual-homed between OpenClaw and upstream networks.
- `aos-upstream-20260716T193354Z-f04c42`: approved synthetic TLS upstream.
- `aos-forbidden-20260716T193354Z-f04c42`: arbitrary forbidden destination.
- `aos-unrelated-20260716T193354Z-f04c42`: unrelated container for token-access denial.

No host-network mode and no host-published ports were used.

## Production Placement Decision

OpenClaw model-network execution must run inside a contained component on an internal Docker/Colima network.

The OpenAI proxy is a separate contained component dual-homed between:

- an OpenClaw-side internal network; and
- a constrained upstream egress network.

The host OpenClaw Gateway may orchestrate, but it must not originate direct OpenAI HTTP traffic after F-A4 closure.

Changing `models.providers.openai.baseUrl` on a host Gateway is not sufficient containment while `pf` remains disabled.

## Allow Results

All required allow checks passed:

- OpenClaw-side fixture reached the forwarding proxy.
- Proxy reached the approved synthetic upstream.
- `POST /v1/responses` succeeded.
- Streaming response handling worked.
- Tool-shaped Responses request worked.
- Synthetic local token was accepted.
- Caller token was stripped upstream.
- Synthetic upstream token was injected only at the proxy-to-upstream hop.
- Container DNS resolved approved service names.
- Proxy restart preserved intended policy.
- OpenClaw-side fixture restart preserved intended policy.
- Network reconnect preserved intended policy.

## Deny Results

All required deny checks passed from the OpenClaw-side fixture:

- direct `api.openai.com` hostname;
- direct OpenAI IP;
- arbitrary external IPv4;
- arbitrary external IPv6;
- alternate DNS resolver bypass;
- `HTTP_PROXY`, `HTTPS_PROXY`, and `ALL_PROXY` bypasses;
- direct synthetic upstream access;
- direct forbidden destination access;
- `host.docker.internal` escape;
- host gateway escape;
- published host-port bypass;
- restart/reconnect bypass.

All required deny checks passed from the proxy fixture:

- `example.com`;
- arbitrary external hostname;
- arbitrary IPv4;
- arbitrary IPv6;
- forbidden destination container;
- alternate upstream port;
- caller-controlled `Host`;
- absolute URL;
- `CONNECT`;
- redirect to another host;
- unsupported endpoint.

## DNS, TLS, IPv4, And IPv6 Findings

- Docker embedded DNS resolved service aliases on attached internal networks.
- Custom DNS bypass was denied in the OpenClaw-side fixture because the internal network had no external route.
- Synthetic TLS used fixture hostname `api.openai.test` and a fixture CA; the proxy required certificate validation for that hostname.
- Arbitrary TLS destination by allowed IP was not accepted because the proxy's upstream hostname was fixed.
- Redirects to another host were rejected.
- IPv4 and IPv6 arbitrary external attempts failed from both OpenClaw-side and proxy fixtures.
- Production must enforce fixed upstream host/SNI/TLS policy rather than static CDN IP lists, because `api.openai.com` CDN IPs can drift.

## UID/GID And Mount Findings

- OpenClaw-side fixture ran as UID/GID `555:555`.
- Proxy fixture ran as UID/GID `540:740`.
- Proxy code was mounted read-only.
- Synthetic upstream credential was mounted only into the proxy fixture.
- Synthetic local token was mounted read-only into the OpenClaw-side fixture and proxy fixture.
- OpenClaw-side fixture could not read the upstream credential.
- Proxy fixture could read the upstream credential.
- Proxy fixture could read the local token.
- Unrelated fixture container could read neither token.
- Tokens did not appear in proxy logs or container inspect environment.

## Local Token Custody Decision

Do not place the OpenClaw-readable local token under:

`/Users/openai-credential-broker/.../local-token/`

That path remains rejected unless parent traversal and custody are separately proved.

The proof supports a separate OpenClaw-owned local-token source mounted read-only into both:

- the OpenClaw-side contained component; and
- the OpenAI proxy contained component.

The local token remains a constrained local proxy capability, not the upstream OpenAI credential.

## Production Network Path Matrix

| Source | Destination | Protocol/Port | Placement | Required | Enforcement point |
|---|---|---:|---|---|---|
| OpenClaw model-network component | OpenAI proxy | HTTP 18187 | contained | yes | internal Docker network membership |
| OpenClaw model-network component | `api.openai.com` | HTTPS 443 | contained | no | no external route from internal network |
| OpenAI proxy | `api.openai.com` | HTTPS 443 | contained upstream egress component | yes | upstream allowlist network/gateway required before production |
| Gmail broker | Google APIs | HTTPS 443 | host broker | yes | unchanged; not routed through OpenAI proxy |
| Telegram | Telegram API | HTTPS 443 | existing host/OpenClaw path | yes | unchanged; must be regression-tested before cutover |
| local agents | Ollama `127.0.0.1:11434` | HTTP 11434 | host loopback | yes | unchanged local route |

## Teardown And Zero-Mutation Proof

- Temporary containers removed: PASS.
- Temporary networks removed: PASS.
- No temporary Docker volumes were created.
- Live OpenClaw config/path metadata and readable hashes matched before/after.
- LaunchDaemon plist hashes matched before/after.
- Production proxy custody path remained absent.
- `pf` was not changed by this proof.

## Remaining Blockers At Time Of Substrate Proof

- Production transaction is not implemented.
- Executable credential migration is not implemented.
- Executable rollback is not implemented.
- Actual production proxy is not installed.
- Actual production upstream credential custody is not installed.
- Production OpenClaw routing is not changed.
- Gmail, Telegram, and Ollama regression must be run during later cutover readiness.
- Cold-start and reboot validation remain open.

The first three blockers above were later superseded by `audits/F-A4-openai-proxy-transaction-package-validation.md`, which records the dry-run transaction and executable rollback package as implemented. Production cutover, live credential migration, production proxy installation, live routing changes, cold-start, reboot, and live regressions remain open.

## Final Status

- `OPENAI PROXY PACKAGE STATIC READINESS: GO`
- `OPENAI PROXY SYNTHETIC PROOF: GO`
- `OPENAI PROXY PRODUCTION SUBSTRATE PROOF: GO`
- `OPENAI PROXY PRODUCTION TRANSACTION IMPLEMENTED: SUPERSEDED BY audits/F-A4-openai-proxy-transaction-package-validation.md`
- `OPENAI PROXY PRODUCTION CUTOVER EXECUTED: NO`
- `F-A4 STATUS: OPEN`
