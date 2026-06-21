# AGENT OS — STATE BUNDLE FOR CLAUDE
_Generated: 2026-06-21T23:47:09Z · commit: 0b973f6_

This is a sanitized snapshot for Claude.ai review. Secrets are excluded by .gitignore + scan.

---
## CONTROL.md (current state)
```markdown
# CONTROL.md — Single Source of Truth

## Canonical references — read before building
Read these at the start of any build session. Architecture and phase ordering defer to these over anything below in this file or the plan.
- docs/AGENT_OS_END_STATE_ARCHITECTURE.md — what we're building (personal life-ops agent), the four foundations, dispatch/confirm split, deny-by-default policy. The spine; phase order follows this.
- docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md — how OpenClaw 2026.6.5 actually enforces runtime, exec, sandbox, egress, auth, and observability. Resolve its §9 VERIFY items before any foundation build drop.
- docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md — prompt-injection patterns; run the §6 checklist before any new capability.
- docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md — per-domain research + per-phase pre-build checklists.

## Access / connection (operator reference)
- Confined build user: `ssh agent@Danny-Mac-Mini.local` (or `@100.96.231.45`). Repo `~/agent-os`; built system `~/.openclaw`.
- Admin user (installs/privileged ops, owns `/opt/homebrew`): `ssh dannybigdeals@Danny-Mac-Mini.local` (or `@100.96.231.45`).
- Boundary (verified 2026-06-15): agent CANNOT escalate to dannybigdeals. Privileged actions = operator-by-hand in a dannybigdeals session, not an agent/Codex action.
- Pull file to MacBook: `scp agent@Danny-Mac-Mini.local:~/agent-os/[file] ~/Downloads/`
- Credentials/keys live in operator's keychain/password manager — NOT in this doc.

## System state (where the built system actually is)
The PLAN lives here (agent-os, pushed to origin). The BUILT SYSTEM lives in ~/.openclaw on the mini — LOCAL-ONLY, no remote, never pushed. A fresh session must read ~/.openclaw directly on the mini; it is not in any remote.
Current drift state: agent-os at this commit; ~/.openclaw has been re-homed under the F-A4 cutover. Gateway now runs as `openclawgw` (UID 555) under root LaunchDaemon `/Library/LaunchDaemons/ai.openclaw.gateway.plist`; the three-tier tamper lock is re-asserted and proven after the 2026-06-21 recovery. F-A4 Phase 5 egress wall (operator-owned CONNECT proxy + pf backstop) is still PENDING, so F-A4 is not fully closed.

**This is the ONLY state file. Every worker reads this first and updates it last.**
**If it's not in this file, it didn't happen. The repo is truth, not any prompt or any brain's memory.**

---

## NOW (where we are this exact moment)

> F-A1 CLOSED: Gmail capability broker live, 25/25 exit-gate PASS, ~/.openclaw committed (2bfba54).
> F-A2 CLOSED: reader credential containment complete. Broker proof loop passed; agent-side Gmail credential originals deleted after verified encrypted backup; legacy direct wrapper retired (`~/.openclaw` c9dcb2c).
> F-A2 RECOVERY: encrypted backup is `/Users/agent/.openclaw/credential-backups/fa2-p2-agent-gmail-originals-20260618T021538Z.tar.age`. Encryption is age passphrase mode; passphrase is operator-held only (not in any file, not in keychain) and is the SOLE recovery key — if lost, the backup is unrecoverable. Restore per F-A2 Part 2 runbook Step 7: decrypt with passphrase, restore both paths as `agent:staff`, re-apply modes `0600`/`0755`, then re-run broker health + reader loop. Retain indefinitely; do not delete except by deliberate operator decision after F-A2 is permanently settled.
> F-B: observability design complete, Q1–Q5 query scripts written and live-validated against broker audit log (38f02f0 / 3041a01).
> Deny block added to settings.json; standing `openclaw security audit` check wired (7642d70).
> Publish pipeline FIXED: `wrap-up` command ships; bundle now includes all four canonical docs inline; end-session false-positive eliminated; verification uses git ls-remote not CDN (CDN ?v= does not bypass server-side cache) (1fbc3a1).
> Front door FIXED: `start.sh` ships; one SSH command from MacBook, tmux/screen session, correct model preselected, reconnect-safe; `00_START_HERE.md` replaces `01_PICK_UP_WORK.md` as primary runbook.
> Doctrine WIRED: `CLAUDE.md` + `doctrine/` created; communication standard and session-close protocol (git-protocol-is-truth rule, ls-remote residual, corrected CDN principle) are now binding on all workers across all threads.
> Doctrine TEXT REPAIRED: wording in `CLAUDE.md` and `doctrine/COMMUNICATION_STANDARD.md` aligned to canonical verbatim spec; self-verification rule added to `SESSION_CLOSE_PROTOCOL.md`.
> F-A2 proof loop + Part 2 COMPLETE: broker enforcement re-proven with originals absent; operator audit/UI checks PASS; direct Gmail wrapper retired. F-A2 exit claim remains credential-theft containment only, not exfiltration containment.
> F-A3 DROP 1 COMPLETE: standalone research handoff enforcement wrapper built and tested (`~/.openclaw/scripts/research-handoff-gate.mjs`, `~/.openclaw` 3fd0b89). It extracts only `research_request`, canonicalizes null/missing to `{"kind":"none"}`, validates through the existing schema, emits only canonical JSON on pass, and hard-fails with sanitized dedicated logging on reject. Not wired into live main→researcher path yet.
> F-A3 DROP 2 COMPLETE: adversarial proof suite added and passed (`~/.openclaw/scripts/test-research-handoff-gate.mjs`, `~/.openclaw` 67004c9). Valid cases emit canonical JSON; injected prose, unsupported kinds, extra injected fields, malformed input, URLs, and email addresses hard-fail with no researcher payload and sanitized logs. Extra fields hard-fail rather than strip. Case 10 found no schema-content gap: enum fields and noun constraints catch URL/email/prose smuggling.
> F-A3 CLOSED: live main→researcher path now routes through `research-handoff-gate` (`~/.openclaw` c5e15e5). Main can no longer spawn `email-researcher` directly and no longer has shell/web extras; only the gate can spawn the researcher after validating canonical `research_request` JSON. Clean run spawned first live researcher session with canonical JSON only. Injection run hard-failed at the gate with sanitized reject log and no researcher session. F-A3 is handoff containment only; exfiltration containment still requires F-A4 egress allowlist.
> F-A4 IN BUILD: gateway re-home and tamper-lock are EXECUTED and PROVEN; Phase 5 egress wall is still pending. Approach remains native managed proxy + root/operator-owned filtering proxy + pf backstop. Native container sandbox / default-deny was DISPROVED as the F-A4 answer in F-A4-1/1b and reverted: web_search runs in the host gateway process outside the container path, and enabling the Docker sandbox broke F-A1/F-A2/F-A3 load-bearing paths.
> F-A4 LIVE PROXY CAPTURE PROVEN (DROP_F-A4-2, 2026-06-19, OpenClaw 2026.6.5 / 5181e4f): throwaway loopback CONNECT proxy + temporary foreground gateway proved the managed proxy is the chokepoint. Allow run succeeded with forced `email-researcher` web_search (`toolSummary.calls=1`, real source returned). Deny-all run failed closed with no result and repeated denied CONNECTs. Proof log retained at `/tmp/fa4-proxy-20260619.jsonl`.
> F-A4 ENDPOINT CORRECTION FROM LIVE TEST: this install did NOT hit `api.openai.com` for the Codex/web_search proof. Captured runtime/search hosts were `chatgpt.com` (Codex Responses backend), `search.parallel.ai` (web_search provider), and `html.duckduckgo.com` (fallback/probe). Earlier source-analysis allowlists that centered `api.openai.com` are stale for this machine.
> F-A4 CUTOVER EXECUTED AND PROVEN (2026-06-21): gateway re-homed to dedicated service user `openclawgw` (UID 555) under root LaunchDaemon `/Library/LaunchDaemons/ai.openclaw.gateway.plist`. Three-tier ownership built; 5-point tamper-lock proof passed. F-A1 Gmail broker, F-A3 handoff gate, and Telegram were re-verified under the new user.
> F-A4 TAMPER-LOCK REVERTED THEN RE-ASSERTED (2026-06-21): during a later OpenAI-auth fix, `sudo chown -R openclawgw:staff /Users/agent/.openclaw` flattened the three-tier ownership and `.openclaw` 0550 lock. Recovery re-ran runbook §4.1-4.3, restoring controls (`openclaw.json`, `exec-approvals.json`) to `root:openclawgw 0440`; runtime dirs to `openclawgw:openclawgw`; secrets to `0600` owner-only; `.openclaw` itself to `root:openclawgw 0550` with the `agent` read-only directory ACL; `.git` back to `agent:staff`. The 5-point lock proof was re-run and all five conditions were GOOD: `agent` cannot append/unlink/create/write-service-env; `agent` has no file-read on the config, matching the runbook because only the directory is ACL'd for read/search. Tamper protection is back in force.
> F-A4 TRUST BOUNDARY STATUS: the old `agent`-owned config/LaunchAgent blocker is resolved. `openclawgw` cannot write the root-owned controls, and `agent` cannot replace them via directory-write attack. Remaining F-A4 blocker is Phase 5: no permanent root/operator-owned CONNECT proxy + pf backstop is installed yet, so gateway egress is not fully allowlist-confined.
> F-A4 MINIMUM EGRESS ALLOWLIST (corrected by DROP_F-A4-2): gateway/runtime allow `chatgpt.com`, `search.parallel.ai`, `html.duckduckgo.com`, `api.telegram.org`, and loopback Ollama (`127.0.0.1:11434` / local only as needed). Broker is separate from gateway and needs its own handling for Google: `gmail.googleapis.com`, `oauth2.googleapis.com`, `accounts.google.com`, `www.googleapis.com`. Maintenance/bootstrap may need `registry.npmjs.org` / npm registry only when intentionally upgrading/installing. `openclaw proxy validate` defaults to `example.com`; either allow `example.com` for validation or use validator options for explicit allowed/denied URLs.
> OPENAI API KEY ROTATED (2026-06-21): prior key was plaintext-exposed during the auth detour and is revoked. New key was set in `models.providers.openai.apiKey` the custody-preserving way: written as gateway user with config briefly opened, then re-locked to `0440`; key was never echoed to shell/history. Current key lives inline in config as plaintext; future cleanup is to migrate it to a file SecretRef like the Telegram bot token.
> MODEL REF FIXED (2026-06-21): default model migrated `openai/gpt-4o` -> `openai/gpt-5.5`. `gpt-4o` is retired/not in OpenClaw 2026.6.5 bundled catalogs; this dead ref, set during the auth detour, was the actual cause of Lloyd's "Something went wrong" failures, not the key. `openclaw doctor --fix` flagged and partially upgraded it; recovery completed the fix by setting `default model.primary` to `gpt-5.5` and removing the dead `gpt-4o` map key. Gateway restarted via `launchctl kickstart -k system/ai.openclaw.gateway`; Lloyd confirmed responding end-to-end on the new key + model.
> NATIVE FEATURE SCOPE CHANGE: F-B is cut to about 25% of the original custom scope because OpenClaw already has native JSONL logs with agent/session/trace context, OpenTelemetry hooks, and redaction primitives. Build only zero-silent-failures alerting and move operational logs off `/tmp`. F-C/F-D are reframed to configuring native `exec-approvals.json` and dispatch/confirm policy, not building a new approval registry. Caveat: exec approvals are an intent guardrail, not hostile containment; `flip-to-full` skips them.
> UPGRADE SAFETY: banked until AFTER F-A4 closes. Do not upgrade OpenClaw mid-foundation. Version truth is on-machine `OpenClaw 2026.6.5 (5181e4f)`. Reconcile `update-check.json` reports such as 2026.6.8 versus GitHub/latest-page inconsistencies with on-machine commands, not the flaky web page.

VERIFIED (vendor security doc, 2026-06-15):
- Reader-agent pattern (read-only/tool-disabled agent summarizes untrusted content → passes summary to main) is the VENDOR-RECOMMENDED mitigation for untrusted-content injection. Current Path B design matches it. Not over-built.
- Prompt injection does not require public DMs — untrusted CONTENT (email/web/docs) is the vector even with single-operator DMs. Confirms the email reader is the live injection surface.
- Native `openclaw security audit` (`--deep`/`--fix`/`--json`) exists and checks tool blast radius, exec/approval drift, network exposure, and "sandbox docker configured but sandbox mode off" (= current state). Adopt for drift detection.
- SUPERSEDED 2026-06-19: Native sandbox default-deny is documented, but F-A4-1/1b proved it is not the F-A4 answer for this system because web_search egress runs in the host gateway process and the sandbox broke broker/gate paths.
- SUPERSEDED 2026-06-19: Native Docker DOCKER-USER enforcement is documented, but agent-owned Colima makes it an invalid hostile-agent enforcement point here because `agent` can modify/flush its own VM rules.

VERIFIED 2026-06-15 (sandbox runtime — agent-owned instance LIVE; later F-A4 finding says this is build substrate, NOT the egress trust boundary):
- agent runs its OWN Colima instance (Option B), using admin-installed binaries (`/opt/homebrew`, read-only shared) — NO agent install, NO admin-socket sharing, NO permission changes. Boundary held.
- agent socket: `unix:///Users/agent/.colima/default/docker.sock`, perms `srw-------` owner agent. Separate daemon from admin's. `docker info` healthy: Ubuntu 24.04 aarch64, overlayfs, iptables firewall backend present.
- OPERATIONAL NOTE: agent's Colima MUST be started from a plain agent SSH session, NOT via Codex — Codex's session sandbox blocks the `~/.colima` home writes Colima needs.

RECONCILED SPINE OF RECORD (2026-06-16): Two independent reviews (Claude + ChatGPT) converged.
Governing principle: "OpenClaw is the runtime. Agent OS security is the broker, policy, egress,
typed-handoff, audit, and skill-governance layer AROUND it." OpenClaw is harness, NOT the trust boundary.
Correction adopted: Gmail needs a CAPABILITY broker (enforces allowed semantic operations:
read/search/draft only), not merely a credential proxy that hides the key. Credential-hiding alone
is insufficient because `gmail.compose` is adjacent to send-capable surfaces.

**FLAG:** A full Mac reboot was not tested (only a controlled daemon restart) — verify auto-start on next reboot.
**FLAG:** OpenClaw native container sandbox remains off. F-A4-1/1b proved it is not the correct F-A4 egress wall for this system: it broke broker/gate paths and did not contain the host-gateway web_search path.
**FLAG:** Phase 1.4 must isolate `~/.ssh`, `~/.aws`, and secrets paths; OpenClaw 2026.6.5 has no exec/tool path-deny control.
**FLAG:** Heartbeat agent replied `NO_REPLY` instead of `HEARTBEAT_OK` on its first restricted run — verify the output is interpretable as a health signal in a later check.
**FLAG:** Historical pre-cutover `EPERM: chmod ~/.openclaw/state` was caused by OpenClaw 2026.6.5 unconditionally chmodding state inside a repo-only managed sandbox. Post-cutover, active runtime state is under `openclawgw`; if this reappears, diagnose against the new ownership rather than applying broad recursive chown.
**FLAG:** VERIFIED emergency restart path after F-A4 cutover: first stop any attached CLI/supervisor retry source, then run `sudo launchctl kickstart -k system/ai.openclaw.gateway`; do not use `openclaw gateway stop`/`restart` on this Mac. Telegram `/stop` remains reasoning-halt only.
**FLAG:** Container runtime prep is DONE via agent-owned Colima, but agent-owned Colima/DOCKER-USER is not a valid hostile-agent wall: the agent has enough control inside that VM to edit/flush its own rules. Enforcement point cannot be owned by the contained party.
**FLAG:** Egress allowlist is IN BUILD under F-A4. Gateway identity/config custody is locked, but outbound gateway egress is not fully contained until Phase 5 installs the permanent root/operator-owned CONNECT proxy plus pf backstop. Egress alone does not unlock sensitive data.
**FLAG:** OpenAI API key currently lives inline in `openclaw.json` as plaintext after the 2026-06-21 recovery. Future cleanup: migrate to file SecretRef custody like `secrets/telegram.json`.
**FLAG:** Doctor flagged stray state dir `/Users/dannybigdeals/.openclaw`; active state correctly remains `~/.openclaw/state`. Cleanup deferred.
**FLAG:** Instruction/memory-file drift detection is DEFERRED: add `HEARTBEAT.md` and all SOUL/AGENTS-equivalent files to the `~/.openclaw` baseline so persistent instruction edits trip the drift check.
**SENSITIVE-DATA GATE:** Sensitive data stays HELD until ALL are PASS: Platform hardening (F-A0) | Gmail capability broker (F-A1) | Reader credential containment (F-A2) | Typed handoff (F-A3) | Egress allowlist (F-A4) | Observability (F-B) | Action policy (F-C) | Dispatch/confirm template (F-D) | Negative injection tests | Secret/log redaction tests. NOTE: broker alone does NOT lift the hold.
**FLAG:** Notify-tier build (`1.2b-build`) is DEFERRED and non-urgent; the hooks mechanism audit and safe design constraints are recorded.
**FLAG:** `~/.openclaw` is a local-only drift repo at `b20dda1`; live `openclaw.json` is ignored, the redacted snapshot and security policy files are tracked, and the root `.gitignore` is an allowlist.
**FLAG:** Gmail uses `gmail.compose`; never-send is a three-layer software guarantee, not a scope boundary. The operator reviews and sends every draft manually.
**FLAG:** Gmail is on-demand pull. Pub/Sub, gcloud, webhook delivery, and real-time push are DEFERRED.
**FLAG:** Draft deletion is not exposed by the safe wrapper; test and unwanted drafts are removed manually in Gmail UI.
**FLAG:** Headless Gmail auth uses gog's file keyring inside the broker-owned `gmailbroker` tree. Agent-side Gmail credential originals have been deleted; the reader reaches Gmail only through the capability broker. This does NOT provide exfiltration containment.
**FLAG:** Email instruction/data separation follows the CaMeL dual-plane pattern: paired Telegram operator instructions are commands; email content is inert untrusted data.
**FLAG:** Agent separation is containment, not formal DLP. Research-question smuggling remains a residual injection risk; the loop is supervised-use and non-sensitive ONLY until the full sensitive-data gate passes.
**FLAG:** KNOWN ISSUE — sub-agent completion delivery: parent `main` session yields before the delegated reader's result surfaces, causing a recovery re-run and, in Part C Test 2, a duplicate draft. Benign under supervision; must be fixed before unsupervised operation. The same yield-before-child-result behavior occurred in the earlier failed run.
**FLAG (NEW, verify read-only):** Confirm `hooks.gmail.allowUnsafeExternalContent` is unset/false and external-content wrapping (untrusted-content markers) is intact on the live Gmail path. Vendor audit tracks this flag as insecure/dangerous; if accidentally enabled it bypasses the CaMeL dual-plane separation at the PLATFORM layer regardless of agent design. Fast read-only check via `openclaw security audit`.
**FLAG (SUPERSEDED 2026-06-19):** Older Plan C / native-sandbox notes are stale. F-A4 sweep found agent-owned DOCKER-USER enforcement is theater because the agent can modify the enforcement point. F-A4-1/1b found Docker sandbox default-deny is not the web_search containment path because web_search egress lives in the host gateway process and the sandbox broke F-A1/F-A2/F-A3.
**FLAG (RUNBOOK GAP, 2026-06-21):** Fold recovery findings into `docs/F-A4_CUTOVER_RUNBOOK.md`: secrets must be `0600` owner-only (`0440` is a trap for runtime secrets), and any recursive `chown -R` over the whole `.openclaw` tree destroys the lock. Post-cutover ownership changes must be surgical, never recursive.

## F-A4 pre-flight checks before permanent build

- Run `openclaw security audit --deep` and require 0 critical findings; last audit-era work had no critical blocker, but verify on the day of build.
- Verify `gateway.bind` remains loopback and Control UI is not exposed beyond localhost.
- Verify `hooks.gmail.allowUnsafeExternalContent` is unset/false and Gmail external-content wrapping remains intact.
- Verify sensitive config/secrets permissions remain 0700/0600, especially `~/.openclaw`, SecretRef files, and broker-owned trees.
- Verify permanent proxy config and `proxy.proxyUrl` remain non-writable/non-repointable by `agent` and `openclawgw`; root/operator-owned placement is required before F-A4 can close.

## Doctrine additions from F-A4

- Native-first → sweep → build. Prefer a native OpenClaw mechanism only after source/docs and live behavior prove it covers this install's actual path.
- Enforcement point cannot be owned by the contained party. This killed both agent-owned Colima/DOCKER-USER Plan C and openclaw.json-only proxy enforcement for the same reason.
- Do not equate process-level proxying with OS sandboxing. Managed proxy is sufficient for well-behaved gateway HTTP/WebSocket clients once operator-owned/fail-closed, but it is not a raw-socket containment mechanism.

---

## NEXT (the single bounded task the next worker does)

> **LOCKED SEQUENCE (frozen — do not reorder, do not research the next phase mid-build):**
> F-A0  Platform hardening audit        ← CLOSED (e47e91c)
> F-A1  Gmail capability broker         ← CLOSED (2bfba54)
> F-A2  Reader CREDENTIAL containment   ← CLOSED (`~/.openclaw` c9dcb2c)
> F-A3  Typed reader → researcher handoff ← CLOSED (`~/.openclaw` c5e15e5)
> F-A4  Egress allowlist                  ← IN BUILD (gateway re-home/tamper-lock proven; Phase 5 proxy+pf still pending)
> F-B   Observability substrate         ← RESCOPED: native logs/OTel/redaction exist; build alerting + log placement
> F-C   Action policy registry          ← RESCOPED: configure native exec approvals/policy; do not build a registry first
> F-D   Generalized dispatch / confirm split ← RESCOPED around native policy + typed handoff patterns
> THEN: capability expansion → Command Center → browser/form-fill → sensitive-data workflows LAST.
>
> **F-A2 RELABEL (operator-locked 2026-06-16):** F-A2 achieves **Reader Credential Containment ONLY** —
> the reader cannot steal credentials or call raw Gmail. F-A2 does NOT achieve exfiltration containment.
> **Exfiltration containment is NOT achieved until BOTH F-A3 (Typed Handoff) AND F-A4 (Egress Allowlist) pass.**
> F-A2's exit gate must NOT claim the reader is contained against leakage — only against credential theft.
>
> **IMMEDIATE NEXT: F-A4 Phase 5 — permanent operator-owned proxy + pf backstop.**
> Goal: install/configure the root/operator-owned CONNECT filtering proxy, set the already-locked managed-proxy config, and load the root-owned pf rule that forces `openclawgw` egress through the proxy and drops everything else.
> Known-good mechanism: OpenClaw managed proxy captures gateway/web_search egress and fails closed when the proxy denies. Known-good trust boundary: gateway now runs as `openclawgw` with root-owned `0440` controls and `.openclaw` `root:openclawgw 0550`; Phase 5 still needs the actual proxy+pf wall.
> Constraints: preserve F-A1 broker-only Gmail and F-A3 typed handoff; do not touch the gmail broker except to account for its separate Google egress. F-A4 must be proven against outbound leakage attempts before any sensitive-data gate can advance.

**PARKED (publish-pipeline hardening) — RESOLVED 2026-06-17 (1fbc3a1):**
> Both defects fixed via `scripts/wrap-up.sh` (replaces `end-session.sh` as the session-close command):
> (1) False-positive guard eliminated — freshness check looks at last 10 commits, not "is CONTROL.md currently uncommitted." Incremental-commit sessions work cleanly.
> (2) Canonical docs now inlined in bundle (~98KB total, no fetch ceiling hit). `bundle-for-claude.sh` includes all four docs.
> (3) Verification uses `git ls-remote` (real-time git protocol) not CDN raw URL — CDN ?v= cache-buster does NOT bypass GitHub server-side cache (can lag 5+ min).
> (4) `--dry-run` mode shows full plan + bundle preview without committing or pushing.
> **Session close is now: `./scripts/wrap-up.sh "what shipped"` — one command, proven confirmation.**

**SWAP-CANDIDATES (audit-gated — source-read REQUIRED before any adoption; do NOT install on architect's research alone):**
- Notify-tier custom hook → EVALUATE vs native telemetry (logging/OTel/Prometheus/redaction). Lean: DROP custom if native covers the notify need. Gate: confirm against current observability docs.
- Custom hash-chain audit fallback → SPLIT: misconfiguration/drift role → adopt native `openclaw security audit`. Audit-LOG-INTEGRITY (tamper-evidence) role → evaluate clawdstrike/ClawGuard SOURCE first; custom fallback only if source read fails. (Reminder: a security skill is a perfect trojan — ClawHavoc campaign wrote malware into SOUL.md/MEMORY.md. Source read is non-negotiable.)
- Workspace backup (`~/.openclaw` single point of loss) → ADOPT keepmyclaw/claw-sync ONLY after source read, ELSE roll minimal encrypted local snapshot. Lean: minimal self-rolled given sensitivity.
- KEEP (do not swap): confined gog wrapper + three-layer no-send (load-bearing, vendor pattern offers no replacement). REJECT (conscious): Composio/universal-connector (dissolves the scoping that is the actual enforcement).

**FLAG:** When Foundations 1 (dispatch/confirm split) and 4 (action-policy + deny-by-default) are built, migrate those invariants from docs/ into live agent doctrine (workspace AGENTS.md / doctrine/) so the running system enforces them, not just the plan. Not now — enforcing mechanism doesn't exist yet.
**FLAG (doc reconciliation pending):** Three docs still reference dead/stale items and must be reconciled in a later doc-cleanup pass (NOT now): (a) `PHASE_2_EMAIL_ASSISTANT` + `ROADMAP` still cite macOS pf as egress start — pf is ELIMINATED (expressibility verify NO). (b) `SECURITY_STANDARD` §4 lists "send structurally impossible ✓ BUILT" — currently COOPERATIVE (3 agent-side layers); becomes structural only after F-A1 capability broker. (c) `ROADMAP` Theme 2 egress order "allowlist first" superseded by locked spine (broker first). Reconcile these in the docs themselves when the cleanup session runs.

---

## DONE (reverse chronological — newest first, one line each)

<!-- Workers append here. Format: YYYY-MM-DD | worker | what shipped | commit -->
- 2026-06-21 | codex/operator | F-A4 recovery: gateway tamper-lock re-asserted after recursive chown regression; 5-point proof re-passed; OpenAI key rotated; default model fixed `gpt-4o` -> `gpt-5.5`; Lloyd live | this commit
- 2026-06-21 | operator | F-A4 cutover executed and proven: gateway re-homed to `openclawgw` UID 555 under root LaunchDaemon; three-tier ownership built; F-A1 broker, F-A3 gate, and Telegram re-verified | machine state
- 2026-06-19 | codex | F-A4 Drop 2 CLOSED: live throwaway proxy proved managed proxy captures/fails closed for gateway/web_search egress; endpoint allowlist corrected to chatgpt.com + search.parallel.ai + html.duckduckgo.com | no persistent config change; proof log /tmp/fa4-proxy-20260619.jsonl
- 2026-06-18 | codex | F-A3 CLOSED: live main→gate→researcher path wired; clean researcher run canonical-only; injection hard-failed at gate with no researcher spawn | ~/.openclaw c5e15e5
- 2026-06-17 | codex | F-A3 Drop 2: adversarial handoff-gate tests pass; injection/URL/email/extra-field/malformed cases hard-fail with sanitized logs | ~/.openclaw 67004c9
- 2026-06-17 | codex | F-A3 Drop 1: standalone research handoff gate built/tested; validates existing schema and logs sanitized hard-fail rejects | ~/.openclaw 3fd0b89
- 2026-06-17 | codex | F-A2 CLOSED: verified encrypted backup, deleted agent-side Gmail credential originals, re-proved broker reader loop, retired legacy direct wrapper | ~/.openclaw c9dcb2c
- 2026-06-17 | claude-code | F-A2-STAGE-R: runbook revised — restore-to-captured, two-actor flow, audit query flag | this commit
- 2026-06-17 | claude-code | F-A2-STAGE: proof loop runbook written; restore dry-run proven clean; broker confirmed live; live config untouched | a1c17c2
- 2026-06-17 | claude-code | DROP 4-FIX: doctrine text aligned to canonical spec; self-verification rule added to SESSION_CLOSE_PROTOCOL | 6b317f0
- 2026-06-17 | claude-code | DROP 4: CLAUDE.md + doctrine/ wired; communication standard + session-close protocol (git-protocol-is-truth) binding on all workers | 35a01ee
- 2026-06-17 | claude-code | Front door: start.sh + 00_START_HERE.md; tmux/screen session, correct model, reconnect-safe | this commit
- 2026-06-17 | claude-code | Publish pipeline fixed: wrap-up.sh ships; inline docs; ls-remote verification; dry-run mode | 1fbc3a1
- 2026-06-16 | claude-code | Deny block added to settings.json; standing `openclaw security audit` check wired | 7642d70
- 2026-06-16 | claude-code | F-B observability: Q1–Q5 live-validated against broker audit log | 3041a01
- 2026-06-16 | claude-code | F-B observability: design doc + Q1–Q5 query scripts written | 38f02f0
- 2026-06-16 | claude-code | F-A2 Part 1 wired: broker config active, old credential paths intact pending proof loop | b1ee06b / ~/.openclaw 20857ba
- 2026-06-16 | claude-code | F-A1 CLOSED: Gmail capability broker live, 25/25 exit-gate PASS, ~/.openclaw committed | 2bfba54
- 2026-06-15 | claude-code | F-A0 CLOSED: platform hardening audit complete, all findings remediated | e47e91c
- 2026-06-14 | codex | Phase 2 email-assistant workstream — Verified Path B on live threads; read/draft loop, three-layer no-send, injection handling, research-query boundary, and unchanged Sent folder all passed | ~/.openclaw b20dda1
- 2026-06-13 | codex | Gmail compose connection — Granted only readonly + compose + OIDC, verified reads and real Gmail drafts, and proved sending blocked at wrapper, baked-binary, and `gmail_no_send` layers | a2065e8
- 2026-06-13 | codex | Gmail confinement — Built pinned gogcli v0.25.0 production/auth binaries, strict draft wrapper, file-keyring injection, and live-token-safe local drift tracking | a2065e8
- 2026-06-13 | codex | Sanitized drift repo — Replaced live-config tracking with a redacted deterministic snapshot and root allowlist `.gitignore`; secrets and runtime state cannot enter unscoped staging | a2065e8
- 2026-06-12 | codex | 2.A-discovery — Scoped the safe email assistant; Gmail `gmail.readonly` and reader routing are available, but stock setup is NO-GO because hook secrets persist plaintext | this commit
- 2026-06-12 | codex | 1.5b — Verified launchd kickstart kills gateway-owned in-flight exec and auto-recovers; diagnosed EPERM as unconditional chmod versus managed-sandbox policy | this commit
- 2026-06-12 | codex | 1.4-discovery — NO-GO at hard gate: Docker binary and daemon socket absent; container kill and sandbox mapping deferred | this commit
- 2026-06-12 | codex | 1.5 — Live-tested kill switch: Gateway aborts run state in about 1s but does not kill an in-flight host exec; C.5/C.6 remain separate | this commit
- 2026-06-12 | codex | 1.2b-discovery — GO with constraints: settled hook payload, direct Telegram delivery, failure, scope, and async behavior; safe-list now drift-tracked | this commit
- 2026-06-12 | codex | 1.2a — Seeded Free-tier Git allowlist and hardened safe bins; enabled strict inline eval and Never-tier tool denies | this commit
- 2026-06-12 | codex | 1.1c — Routed heartbeat to a dedicated local-Qwen agent with mechanically restricted tools; re-baselined config | this commit
- 2026-06-12 | codex | 1.1 — Set and effectively verified strict exec baseline `allowlist` / `on-miss` / `deny`; corrected fail-closed plan claim | this commit
- 2026-06-12 | codex | DROP 1.0 pre-Phase-1 audit — NO-GO until fail-closed defaults, custom Notify, real abort tests, and loop gaps are incorporated | this commit
- 2026-06-11 | codex | 0.8 — Installed Clawhatch and scored a test skill | e59160b
- 2026-06-11 | codex | 0.7 — Git-baselined only `openclaw.json` in `~/.openclaw` | e59160b
- 2026-06-11 | codex | 0.6 — Configured isolated light-context heartbeat on local Qwen | e59160b
- 2026-06-11 | codex | 0.5 — Stored gateway and Telegram tokens as 0600 file SecretRefs; audit clean | e59160b
- 2026-06-11 | codex | 0.4 — Configured Codex OAuth primary, local Qwen fallback, and maxConcurrent 3 | e59160b
- 2026-06-11 | codex | 0.3 — Created, paired, and round-trip tested @LLoyd_entouragebot | e59160b
- 2026-06-11 | codex | 0.2 — Installed and verified the supervised OpenClaw launchd daemon | e59160b
- 2026-06-11 | codex | 0.1 — Installed OpenClaw 2026.6.5 user-space with Node 22.22.0 | e59160b

---

## DECISIONS LOG (only real decisions / direction changes — not routine progress)

<!-- Format: YYYY-MM-DD | decision | one-line why -->
- 2026-06-21 | OpenAI auth method is static API key, not OAuth/Codex login | OAuth login failed with EACCES during the reverted-ownership auth detour; API-key auth is the chosen method going forward and should not be re-litigated without a new build decision.
- 2026-06-21 | Default OpenAI model is `openai/gpt-5.5`; `openai/gpt-4o` is dead on this install | `gpt-4o` is retired/not in OpenClaw 2026.6.5 catalogs and caused Lloyd's "Something went wrong" failures; `openclaw doctor --fix` identified the stale ref and recovery completed the migration.
- 2026-06-21 | Post-cutover ownership changes must be surgical, never recursive over `.openclaw` | `sudo chown -R openclawgw:staff /Users/agent/.openclaw` flattened the three-tier lock; recovery proved recursive ownership changes can silently destroy the enforcement boundary.
- 2026-06-19 | CONTROL.md is the sole state doc; RUNWAY_TO_V1.md + master-state Google Doc retired; readable write-ups generated on demand, not maintained as parallel copies | Three parallel "state" artifacts drifted on every update (FA4_3 demonstrated it); one source of truth + on-demand views eliminates the drift class.
- 2026-06-19 | Native managed proxy is the F-A4 gateway egress mechanism, but only with an operator-owned trust boundary | Live proof showed gateway/model/web_search traffic routes through the managed proxy and fails closed; `agent`-writable `openclaw.json` means permanent enforcement must lock proxy URL/config outside agent control.
- 2026-06-19 | Correct F-A4 gateway allowlist to live-observed hosts: `chatgpt.com`, `search.parallel.ai`, `html.duckduckgo.com` | DROP_F-A4_2 showed this install uses `chatgpt.com` for Codex Responses and `search.parallel.ai` for web_search; `api.openai.com` was not hit in the proof.
- 2026-06-19 | Native container sandbox is not the F-A4 solution on this system | F-A4-1/1b reverted because Docker sandbox broke F-A1/F-A2/F-A3 paths and did not contain host-gateway web_search egress.
- 2026-06-19 | Enforcement point cannot be owned by the contained party | Agent-owned Colima/DOCKER-USER and agent-writable openclaw.json-only proxy enforcement both fail the same trust-boundary test.
- 2026-06-19 | F-B/F-C/F-D are audit-rescoped around native OpenClaw features | Native logging/OTel/redaction and exec-approvals reduce custom build scope; remaining work is alerting/log placement and correct policy configuration.
- 2026-06-18 | Gmail broker forbidden-method audit scans must be scoped to the run date | Unscoped scans surface historical F-A1 rejection tests such as legitimate `unknown_method` errors and create false positives; use `grep '"ts":"YYYY-MM-DD'` before forbidden-method grep.
- 2026-06-17 | GitHub raw CDN verification requires git ls-remote, not ?v= cache-buster | CDN ?v= query param does NOT bypass GitHub's server-side cache (lag can exceed 5 min); git ls-remote queries the git protocol layer directly and is authoritative and immediate. Confirmed live: plain URL and ?v=HASH both served stale content while ls-remote showed the correct new HEAD.
- 2026-06-16 | Settings deny block chosen over per-path allowlist for tool restriction | Deny block is fail-closed and applies uniformly; allowlist requires enumerating every safe path, leaving gaps on miss — deny is the right default for tools that should never be reached by the reader.
- 2026-06-16 | Spine of record = locked F-A0→F-D sequence; reviews converged, operator-accepted | Two independent model reviews reached the same architecture; churn was doc-vs-working-state drift, not a flawed plan. Spine is now frozen and not re-litigated phase-by-phase.
- 2026-06-16 | Gmail solution = self-rolled minimal CAPABILITY broker (semantic-operation enforcement), not just credential proxy | gmail.compose is send-adjacent; broker must enforce which operations are allowed (draft-only), not only hide the credential. Agent Vault / IETF CB4A = reference/future generic proxy, source-read before any adoption, NOT the Gmail solution.
- 2026-06-16 | Sensitive-data hold lifts ONLY when the full gate table passes (not broker alone) | Broker prevents credential theft; it does NOT prevent poisoned summaries, search/web exfiltration, or malicious drafts. Multiple required conditions, no single keystone.
- 2026-06-15 | Sandbox runtime = agent-owned Colima using shared read-only admin binaries; agent-owned VM+socket | Option B (full daemon/socket separation), zero install/socket-sharing/permission-change. Shared read-only BINARIES safe; shared SOCKET avoided as escalation risk. Launch from plain agent SSH (Codex sandbox blocks home writes).
- 2026-06-15 | Sensitive-data integration HELD until containment proven; reader stays supervised + non-sensitive | Prompt-injection→exfil is unsolved field-wide (vendor security doc states it explicitly); native process-level proxy is not an OS sandbox; removing the consequence leg (no sensitive data) is the only currently-sound posture. Aligns with vendor "model last / limit blast radius" stance.
- 2026-06-15 | SUPERSEDED 2026-06-19: Plan B separate-box eliminated; Plan C Docker/DOCKER-USER was then considered | Later F-A4 sweep killed Plan C on trust-boundary grounds because agent-owned Colima lets the contained party control the rules. Native managed proxy is now the F-A4 mechanism, with operator-owned placement required.
- 2026-06-15 | SUPERSEDED 2026-06-19: NEXT reframed egress-decision → sandbox-first | Later F-A4-1/1b disproved sandbox-first for this system: host-gateway web_search was outside container containment and broker/gate paths broke.
- 2026-06-15 | Plan A (host-pf UID-keyed proxy) eliminated for egress | pf-viability verify resolved NO: route-to≠proxy-redirect, rdr can't match UID, translation precedes filtering, no per-agent UID in one gateway.
- 2026-06-14 | Confined reader runs Path B: default Codex runtime with `tools.exec.mode="auto"`; OS-level exec allowlisting is not enforced | Live testing proved `auto` does not preserve the approvals-layer allowlist and embedded runtime requires a separate OpenAI API key. Accepted confinement is OAuth scope + three-layer no-send + research validator + coming egress; the reader remains supervised/non-sensitive until egress and isolation close the temporary host-shell gap. Reconsider Path A if sensitive unsupervised use is needed first.
- 2026-06-14 | Phase order changed to foundations-first per end-state architecture; egress/containment moved ahead of new capabilities | Containment is the unlock for unattended use; capability-first leaves capabilities stuck in supervised-mode and risks per-capability rebuild
- 2026-06-13 | Gmail draft-only uses `gmail.readonly` + `gmail.compose` with a three-layer software no-send barrier | Readonly cannot create Gmail drafts; wrapper allowlisting, a policy-compiled gog v0.25.0 binary, and `gmail_no_send` all independently block send paths
- 2026-06-13 | Gmail authentication and runtime use separate binaries and a file keyring | The auth bootstrap has no Gmail commands, the production binary has no auth/send commands, and macOS Keychain was unreliable in the headless session
- 2026-06-13 | Gmail remains on-demand pull; Pub/Sub/gcloud push is deferred | Pull satisfies the supervised workflow without adding webhook secrets, public ingress, or cloud infrastructure
- 2026-06-13 | SUPERSEDED 2026-06-16: Email automation follows a CaMeL-style dual-plane model and remains supervised/non-sensitive until the full sensitive-data gate passes | Email is untrusted data, Telegram is the command plane, but agent separation cannot formally prevent injected text from being smuggled into a research query. Original shorthand "until egress control exists" is superseded; egress alone does not lift the hold.
- 2026-06-13 | `~/.openclaw` tracks a sanitized snapshot and explicit security artifacts under a root allowlist | Live config, credentials, workspaces, and runtime state remain ignored while meaningful drift stays reviewable
- 2026-06-12 | SUPERSEDED 2026-06-13: stock webhook Gmail setup was rejected | It wrote plaintext hook secrets and introduced unnecessary push ingress; the implemented design uses on-demand pull through the confined wrapper
- 2026-06-12 | SUPERSEDED 2026-06-13: read-only OAuth and macOS Keychain were the initial target | Real Gmail drafts require compose scope, and headless Keychain access proved unreliable; the live design uses three-layer software no-send plus a protected file keyring
- 2026-06-12 | SUPERSEDED 2026-06-13: dedicated webhook routing was the initial reader plan | The implemented on-demand design delegates from the paired Telegram main agent to restricted reader and research agents
- 2026-06-12 | SUPERSEDED 2026-06-21: old emergency panic sequence targeted `gui/501`; new gateway is system LaunchDaemon | Original proof used `launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway`; after F-A4 cutover use `sudo launchctl kickstart -k system/ai.openclaw.gateway` instead.
- 2026-06-12 | Fix the state-dir EPERM in OpenClaw code/version, not with chown/chmod | State dir is already owned by runtime UID 501 at 0700; 2026.6.5 unconditionally chmods it during CLI bootstrap and the repo-only managed sandbox rejects that metadata write
- 2026-06-12 | Phase 1.4 is blocked pending an operator decision to install a Docker-compatible runtime | Docker binary and `/var/run/docker.sock` are absent, so neither OpenClaw sandboxing nor container-kill proof can run
- 2026-06-12 | Daily panic command is standalone `/stop` in the affected Telegram chat, but it is only a run/future-step stop until process-group kill enforcement exists | Live `sessions.abort` returned in about 1s while the inert shell continued for about 109s; `/stop` and queue interrupt share the same embedded-run abort primitive
- 2026-06-12 | Keep C.5 receive/acknowledge separate from C.6 interrupt/terminate | The live test proved OpenClaw can acknowledge abort while an in-flight host process continues
- 2026-06-12 | Notify uses typed `after_tool_call`, filters internally to main + explicit action classes, and sends fixed metadata through the direct Telegram outbound adapter | The hook sees secret-bearing args/results and has no declarative tool/agent scope; direct delivery avoids a message-tool loop
- 2026-06-12 | Notify requires a persistent secret-free outbox, retry/deduplication, startup drain, and visible terminal-failure state | Native `after_tool_call` is fire-and-forget and logs send failures without affecting the completed action
- 2026-06-12 | Track `exec-approvals.json` with `openclaw.json` at baseline `b77a0f8` | The safe-list is security state and must participate in drift detection; direct scan confirmed no secrets
- 2026-06-12 | Main Free seed is exact `git status` / `git diff` / `git log` / `git show`; safe bins are `cut`, `uniq`, `head`, `tail`, `tr`, `wc`, and hardened `grep`; `strictInlineEval` is true; Never denies `gateway`, `cron`, and `sessions_*` | Off-list commands remain `on-miss`; phone “allow always” is the durable path for intentional safe-list growth
- 2026-06-12 | Defer `~/.ssh`, `~/.aws`, and secrets path isolation to Phase 1.4 sandboxing | OpenClaw 2026.6.5 tool deny rules match tool IDs, not host filesystem paths
- 2026-06-12 | Use explicit `agents.list[]` entries for `main` and specialized agents; heartbeat uses `tools.profile: minimal`, adds `read`/`message`, and denies `group:runtime`, `write`, `edit`, `apply_patch`, `group:sessions`, `gateway`, and `cron` | Per-agent heartbeat blocks route heartbeats exclusively to those agents; this became the template for the Phase 2 email-assistant reader split
- 2026-06-12 | Main-agent exec uses `allowlist` / `on-miss` / `deny`; fail-closed is configured, not default | DROP 1.0 proved OpenClaw 2026.6.5 otherwise resolves to `full` / `off` / `full`
- 2026-06-12 | Phase 1.6 must combine enabled native loop detection with custom iteration, cost, and durable-trip controls | Native coverage has hash/no-progress/stuck detectors but no general iteration cap, true cost breaker, or persistent trip latch
- 2026-06-12 | Phase 1.5 kill-switch tests target `/stop`, `/queue interrupt`, and `sessions.abort` | Approval denial blocks one pending command, steer waits for a boundary, and goal state does not cancel a run
- 2026-06-12 | Build a custom typed Notify-tier plugin/hook before Phase 1.2 | OpenClaw has tool observation and telemetry but no declarative notify-only side-effect tier
- 2026-06-12 | Explicitly configure `askFallback: deny` in Phase 1.1 | OpenClaw 2026.6.5 currently resolves the unconfigured host exec baseline to `full/off/full`
- 2026-06-11 | Git-baseline OpenClaw config separately in `~/.openclaw` at e59160b | Tracks config drift without committing the state directory
- 2026-06-11 | Keep the real OpenClaw config in SecretRef object form despite Clawhatch compatibility bug | The Clawhatch bug was logged; security was not weakened to accommodate it
- 2026-06-11 | Raise heartbeat timeout to 180s | Qwen completes locally in about 47s instead of falling back to paid Codex
- 2026-06-11 | Store gateway and Telegram tokens as 0600 file SecretRefs | Keeps plaintext secrets out of `openclaw.json`
- 2026-06-11 | Reuse existing Codex CLI OAuth | Enables Codex runtime without storing a plaintext API credential
- 2026-06-11 | Install OpenClaw user-space with its own Node 22.22.0 | Homebrew installation path was unwritable
- 2026-06-11 | Adopt OpenClaw as foundation; doctrine ports on top | OpenClaw provides natively what the old custom build reimplemented
- 2026-06-11 | Repo-as-truth workflow; Codex-primary; Claude-as-consultant | Old flow made the human the integration layer — slow, drift-prone

---

## OPEN VERIFICATION GATES (must not be skipped — security-critical)

- [ ] **Aquaman source audit + native-SecretRef comparison** (Phase 6) — before ANY real SSN.
- [ ] **ClawGuard source read** (legacy numbered Phase 2 doctrine/audit inventory) — before it carries audit integrity. Custom hash-chain fallback ready.
- [ ] **Browser `fill` tool-side secret resolution test** (Phase 6) — does fill resolve a SecretRef without returning the value to the LLM?

---

## LEGACY NUMBERED PHASE MAP (detail inventory in docs/OPENCLAW_BUILD_PLAN.md; execution order is foundations-first)

- **0** Clean stand-up: install, onboard, new bot, Codex+Qwen routing, secrets audit, git-baseline config
- **1** Trust model as config: tiers, approvals, sandbox, reader-agent split designed, config-self-mod defenses
- **2** Doctrine as skills: SOUL/AGENTS, Steinberger orchestrator pattern, ClawGuard audit, Skill Workshop. This remains open and is distinct from the completed Phase 2 email-assistant workstream.
- **3** Integrations: Gmail brief, cron, web search, memory/lifestreams, Inferred Commitments
- **4** Command Center: custom WS app per v4 mock (7 surfaces) + Recurring Registry awareness layer
- **5** Evals + observability (Opik/OTel) + reviewer access
- **6** Sensitive form-fill (SSN): Aquaman-or-native, reader-agent isolation live, max-rigor proof gate

---

## HOW TO UPDATE THIS FILE (workers read this)

1. When you START: read NOW + NEXT. That's your task. Don't invent scope.
2. When you FINISH: move NEXT→DONE (one line), write the new NEXT (one bounded step), update NOW.
3. If you made a real decision: add to DECISIONS LOG.
4. Commit with the structured message (see templates/COMMIT_FORMAT.md).
5. Never leave this file stale. Session close is `./scripts/wrap-up.sh "what shipped"` — it checks freshness and refuses to wrap if CONTROL.md looks untouched.
```

## Recent git log (20)
```
0b973f6 [codex] publish: print bundle freshness reference
551aa14 [codex] F-A4: record recovery state in CONTROL
929e2e0 docs: patch cutover runbook — rollback ownership integrity, cert preflight, inline foundation proofs
191b40c docs: assemble F-A4 gateway re-home cutover runbook (draft, operator-by-hand)
5269c64 docs: patch F-A4 Phase 5 — broker UID gate, broker-read proof, cert check, honest close-out
b37299d docs: draft F-A4 egress wall artifacts
85a2403 docs: draft F-A4 gateway LaunchDaemon plist
ec771af docs: verify F-A4 credential custody
d588532 docs: verify F-A4 egress lock design
3f10cf6 docs: map F-A4 gateway rehome ownership
bbd2839 docs: retire parallel state docs
7120829 docs: sync post-audit F-A4 state
e8e8fcb Record F-A3 closure
cc50884 [claude-code] F-A3 Drop 2 adversarial gate proof
0a97513 [claude-code] F-A3 Drop 1 handoff gate
839e67d Record F-A2 recovery backup
c6c75c3 Close F-A2 reader credential containment
7bc2c36 [claude-code] F-A2-STAGE-R: runbook revised — restore-to-captured modes, two-actor flow, audit query honestly flagged
a1c17c2 [claude-code] F-A2-STAGE: proof loop runbook written; restore dry-run clean; broker live; live config untouched
6b317f0 [claude-code] DROP 4-FIX: doctrine text aligned to canonical spec; self-verification rule added to SESSION_CLOSE_PROTOCOL
```

## Repo tree (no node_modules / .secrets / state)
```
.gitignore
00_START_HERE.md
00_TEARDOWN.md
01_PICK_UP_WORK.md
BUILD_STATE.md
CLAUDE.md
CONTROL.md
HANDOFF_BRIEF.md
ITERATION_LOG.md
README.md
SETUP.md
WORKER_PROTOCOL.md
audits/2026-06-12-gmail-connector-discovery.md
audits/2026-06-12-hooks-mechanism-audit.md
audits/2026-06-12-killswitch-test.md
audits/2026-06-12-panic-button-test.md
audits/2026-06-12-pre-phase1-audit.md
audits/2026-06-12-sandbox-killswitch-discovery.md
audits/F-A0-platform-hardening-audit.md
audits/F-A1-negative-test-results.md
docs/AGENT_OS_END_STATE_ARCHITECTURE.md
docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
docs/AGENT_OS_ROADMAP_BEST_PRACTICES.md
docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md
docs/F-A1_DEPLOY_LIST.md
docs/F-A1_GMAIL_BROKER_DESIGN.md
docs/F-A1_GMAIL_BROKER_DESIGN_ADDENDUM.md
docs/F-A2_PROOF_RUNBOOK.md
docs/F-A4_CUTOVER_RUNBOOK.md
docs/F-A4_LOCK_2A_OWNERSHIP_MAP.md
docs/F-A4_LOCK_2A_VERIFY_EGRESS_LOCK.md
docs/F-A4_LOCK_2B_0READ_CREDENTIAL_CUSTODY.md
docs/F-A4_LOCK_2B_LAUNCHDAEMON_PLIST_DRAFT.md
docs/F-A4_LOCK_PHASE5_EGRESS_WALL_DRAFT.md
docs/F-B_OBSERVABILITY_DESIGN.md
docs/OPENCLAW_BUILD_PLAN.md
docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md
docs/OPENCLAW_DEEP_DIVE_CONFIG.md
docs/OPENCLAW_ECOSYSTEM_AND_COVERAGE.md
docs/OPENCLAW_FIELD_NOTES.md
docs/OPENCLAW_RESEARCH_ADDENDUM.md
docs/PHASE_2_EMAIL_ASSISTANT.md
docs/PRIOR_BUILD_LEARNINGS.md
doctrine/COMMUNICATION_STANDARD.md
doctrine/SESSION_CLOSE_PROTOCOL.md
drafts/fa4-phase5/agent-os-egress-proxy.mjs
drafts/fa4-phase5/agent-os-egress.anchor
drafts/fa4-phase5/ai.agent-os-egress-pf.plist
drafts/fa4-phase5/ai.agent-os-egress-proxy.plist
drafts/fa4-phase5/allowlist.txt
drafts/fa4-phase5/pf.conf.fragment
drafts/fa4-phase5/phase5-proof-commands.sh
scripts/bundle-for-claude.sh
scripts/end-session.sh
scripts/observability/q1-silent-failures.mjs
scripts/observability/q2-orphan-correlations.mjs
scripts/observability/q3-unclosed-runs.mjs
scripts/observability/q4-egress-denials.mjs
scripts/observability/q5-out-of-band-drafts.mjs
scripts/secret-scan.sh
scripts/start-session.sh
scripts/start.sh
scripts/wrap-up.sh
src/gmail-broker/f-a1-test-suite.mjs
src/gmail-broker/gmail-broker.mjs
templates/COMMIT_FORMAT.md
templates/DROP_FORMAT.md
```

## Tests status (last run, if recorded)
```
(no TEST_STATUS.txt — run tests and record)
```

## Open verification gates
## OPEN VERIFICATION GATES (must not be skipped — security-critical)

- [ ] **Aquaman source audit + native-SecretRef comparison** (Phase 6) — before ANY real SSN.
- [ ] **ClawGuard source read** (legacy numbered Phase 2 doctrine/audit inventory) — before it carries audit integrity. Custom hash-chain fallback ready.
- [ ] **Browser `fill` tool-side secret resolution test** (Phase 6) — does fill resolve a SecretRef without returning the value to the LLM?

---

---
## Canonical reference docs (inlined — all four, ~98KB total)

### AGENT_OS_END_STATE_ARCHITECTURE.md
```markdown
# Agent OS — End-State Architecture

**Purpose:** define what this system is *for* and the bedrock that makes it safe, so every future phase builds toward a deliberate end state instead of accreting. This is the spine the plan reorganizes around. Companion to the Security Design Standard (prompt-injection patterns) and the Roadmap Best-Practices Brief (per-domain research).

**Status:** v1, drafted [next session]. Supersedes the capability-first phase ordering in the prior plan.

---

## 1. What this is (the destination)

A **personal life-operations agent**: a Command Center that dispatches agents on open-ended tasks and brings results back to Daniel, handling low-stakes things autonomously and proposing higher-stakes things for approval — with the boundary between the two **evolving over time as trust accrues**.

Concretely, the end state can:
- Be sent on open-ended research ("find me better insurance rates," "what's the best way to do X")
- Watch a video / read a long thing and bring back findings
- Triage email and family logistics, help get life in order
- Build budgets from spending, plan vacations
- Fill out forms (gather + draft every field; submission gated)
- Eventually: notice context (e.g. an upcoming vacation) and proactively propose actions (e.g. "shut off the AC while you're away") — **evolving to autonomy on the low-stakes ones**

The defining property is **open-endedness**: Daniel hands a goal, the system figures out the steps. This is what makes it truly agentic — and it's also the single hardest thing to secure. The entire architecture below exists to make open-ended dispatch safe.

**Not required perfect on day one.** Starts fully supervised; capabilities and autonomy accrete over time. The bedrock must be strong enough that this evolution is *additive*, never a rebuild.

---

## 2. The central tension (and its resolution)

**Tension:** The security literature's hardest finding is that you *cannot* secure a general-purpose, open-ended agent against prompt injection with current models — only application-specific agents with defined trust boundaries. But the end state *wants* open-ended dispatch.

**Resolution — the load-bearing law of the whole system:**

> **The open-ended part and the consequential part are permanently separated. Gathering agents can research/read/watch/summarize/propose, but structurally CANNOT act. All action is a separate, gated path.**

Open-ended exploration is safe *because its only output is a proposal to the system, never an action.* A fully-injected research agent that "decides" to wire money or delete a file simply cannot — it has no action path. It can only emit a proposal, which goes through the policy layer (§3.4), which routes anything consequential to Daniel.

This is the same pattern as the existing draft-only email loop (reader drafts, can't send), generalized to the whole system. The template is already built; the end state generalizes it.

---

## 3. The four foundations (the bedrock)

These are built as **shared substrate underneath all capabilities**, not per-capability. Building them per-capability is the rebuild trap. They must exist (at least in v1 form) before the Command Center.

### 3.1 Foundation 1 — The Dispatch/Confirm Split (structural law)
- **Gather plane:** open-ended agents. Read, research, watch, summarize, draft, propose. No action tools at all. Live behind the egress allowlist (3.2). As "wild" as desired because they cannot act.
- **Act plane:** a *fixed menu* of defined operations (send email, submit form, change a setting, control a device, move money…). Never open-ended. Every action is one of a known set, each with a policy classification (3.4).
- A gathering agent's proposal **cannot** become an action except by passing through the policy layer. There is no bypass. This is structural, not behavioral — not "the agent is told not to act," but "the agent has no capability to act."
- **Why it's foundational:** retrofitting "these agents actually can't act" onto a system that assumed they could is a teardown. Get it in first; every capability inherits it.

### 3.2 Foundation 2 — Containment (the unlock)
Built in value order (per "Caging the Agents," arXiv:2603.17419, and "Silent Egress," arXiv:2602.22450):
1. **Network egress allowlist** — default-deny, no wildcards, enforced at tool-execution/network layer (not prompt layer, which barely works). This is what lets gather agents run *wild and unattended* without being an exfiltration risk — a hijacked research agent can't phone home.
2. **Workload isolation** — agents in a container/VM, not just a user account.
3. **Credential proxy** — agents call a broker that holds secrets and makes the authenticated call; the agent never sees the raw token. (Generalizes the draft-safe wrapper to all secrets.)
- **Why it's foundational + reordered EARLY:** containment is what graduates the system out of "supervised, non-sensitive only." It has leverage no single capability has — it unlocks unattended operation for *everything*. Hence it moves ahead of new capabilities in the sequence.

**Runtime + confinement law for agents (resolved 2026-06-14 after live testing — Path B):**
A confinement model is only real if the runtime enforces it, and live testing settled which configurations actually work in OpenClaw 2026.6.5:
- `tools.exec.mode: "allowlist"` is REJECTED by the Codex harness. An `openai/*` ref defaults to Codex.
- The embedded `openclaw` runtime accepts allowlist mode but requires a separate OpenAI **API-key** auth profile (`auth.order.openai`, `agentRuntime.id: "openclaw"`) — NOT the ChatGPT/Codex subscription. (Subscription auth only works through the Codex harness.)
- `tools.exec.mode: "auto"` on Codex was tested and does NOT preserve allowlist confinement: a per-agent approvals allowlist did NOT override `auto` — an off-allowlist command (`ls /`) executed. So "auto + strict approvals" is NOT a safe confinement substitute. [Proven live 2026-06-14.]

**Decision — confined agents run the field-standard way (Path B):** default Codex runtime on the existing subscription, `tools.exec.mode: "auto"`. We do NOT enforce OS-level exec-allowlist on the reader. This matches what every OpenClaw Gmail setup does; the exec-allowlist was a non-standard belt that fought the platform and required a separate API-billing relationship.

**Why this is correct, not a compromise:** the confinement that matters is layered and runtime-independent, and the gap Path B leaves is temporary and closes as the foundations land:
- (1) **OAuth scope** (readonly+compose, no send/modify/delete) — the load-bearing control, per the field and the wild failure cases.
- (2) **Three-layer software no-send** — proven, runtime-independent; a hijacked reader CANNOT send/forward email regardless of exec mode.
- (3) **Schema-validated research channel** — blocks exfil-via-research-query.
- (4) **Egress control (Foundation 2, next)** — the real exfil defense; holds at the network layer even when the model is fully hijacked. This is what closes the serious half of the Path B gap (a hijacked reader could run read-oriented shell commands, but cannot get data OFF the machine once egress is locked).
- (5) **Workload isolation (Foundation 2, later)** — moves confined-agent shell execution into a throwaway container, closing the host-exposure half of the gap.
- (6) **Dispatch/confirm split + deny-by-default policy (Foundations 1 & 4)** — gate any action a hijacked agent could propose.

**The Path B gap, stated honestly + its expiry:** today, a reader hijacked by a malicious email could run read-oriented shell commands on the host (proven: `ls /` executes under `auto`). It CANNOT send email (blocked 3 ways) and CANNOT exfiltrate once egress lands. The reader therefore stays **supervised / non-sensitive ONLY until egress + isolation land**, at which point this gap closes more completely than an exec-allowlist ever would. This is a sequenced decision with a defined expiry, not a permanent accepted risk. **Revisit trigger:** if any confined agent must handle sensitive data unsupervised before egress/isolation exist, OR reconsider OS-level confinement (Path A: embedded runtime + API key) at that point.

**Implication:** egress (Foundation 2) is now the highest-leverage next foundation — it is both the planned exfil defense AND the control that retroactively closes the Path B gap and graduates the system out of supervised-only operation. Exec-allowlist is downgraded from a Foundation law to optional hardening, superseded by egress + isolation for the confined-agent threat.

**Platform-mechanics gate (mandatory before any foundation/capability build drop):**
Best-practices/pattern research is necessary but NOT sufficient. Before writing a build drop, also research the OpenClaw-specific mechanics (runtime / exec / sandbox / egress / AUTH) per the Platform Mechanics Reference: how the layer actually enforces this, what silent defaults bite (`openai/*`→Codex; embedded→API-key; `exec.mode=allowlist`→Codex rejection; `auto`→allowlist NOT enforced; sandbox network→`none`; env doesn't inherit into sandbox; self-logging gaps for cron/subagent/heartbeat), and whether the intended config is platform-supported — proven from docs/schema, then VERIFIED against the live install with a read-only diagnostic. The 2026-06-14 runtime saga (allowlist→Codex-reject→embedded→API-key→auto-doesn't-confine→Path B) was a chain of platform dependencies discoverable upfront; finding them via failed live runs is the failure mode this gate prevents. Applies to egress (Foundation 2), observability (Foundation 3), policy/exec (Foundation 4) next — see the Platform Mechanics Reference §9 VERIFY gate.

### 3.3 Foundation 3 — Observability Substrate (the trust gate AND the promotion evidence)
- Correlation IDs on every message, plan, and tool call; full end-to-end trace per run.
- Every run reconstructable from logs; run-replay (rewind, fork with modified input, verify a fix).
- Immutable / append-only enough to be trustworthy.
- **Zero silent failures as a queryable property:** every tool call has a traced result; every failure produces a *delivered* notification; "did anything fail silently in the last N days?" returns a real answer. (The Tiger silent-FAIL bug is the failure this prevents.)
- **Dual role:** this is both the V1 trust gate (is it working?) *and* the evidence base that justifies promoting an action from confirm→auto (§3.4). You don't promote on a hunch; you promote because the trail proves it proposed correctly N times.
- GitHub tooling to evaluate here: `agent-topology-visualizer` (renders trust boundaries), `agent-dashboard` (real-time health). See §6.

### 3.4 Foundation 4 — Evolvable Action-Policy Layer (what makes earned autonomy real)
- **One inspectable definition** of every action class and its current gate: `auto` (execute + notify after), `confirm` (propose, wait for Daniel), or `deny`. Every capability and the Command Center consult this at action time. Actions do **not** each hardcode their own gate.
- **Promotion model:** moving an action from `confirm` → `auto` is a *policy edit*, not a code change. The capability that performs the action never changes; only its classification moves. This is how the system "evolves to autonomy" without a rebuild.
- **Promotion criteria = observability evidence:** an action class earns `auto` when the audit trail shows it proposed correctly over time. Daniel makes the promotion; the trail justifies it.
- **THE PERMANENT INVARIANT — deny-by-default:** any action class not explicitly classified is treated as **confirm/high-stakes** until Daniel says otherwise. The failure mode of forgetting to classify something is "it asks unnecessarily," never "it acted when it shouldn't have." **This default does not evolve. It is a foundational law.**
- High-stakes classes (money movement, deletion, access/permission changes, anything irreversible) **cannot be promoted to `auto`** without an explicit, deliberate Daniel action — and some should be permanently `confirm` regardless of trust.

---

## 4. How the named capabilities decompose onto the split

Each capability = a **safe-gather half** (open-ended, behind containment) + a **gated-act half** (fixed menu, policy-classified). This is the test every future capability must pass.

| Capability | Safe-gather (open-ended, can't act) | Gated-act (menu, policy-classified) |
|---|---|---|
| Insurance hunt | Research rates, compare, summarize, draft recommendation | Switch/purchase a policy → `confirm` (likely permanent) |
| Budget building | Read spending, categorize, model, propose budget | Move money / pay → `confirm` (likely permanent); categorize-only → could earn `auto` |
| Vacation planning | Research, build itinerary, draft bookings | Book/pay → `confirm`; *propose* "shut off AC while away" → starts `confirm`, can earn `auto` |
| Email/family ops | Read threads, triage, draft replies, summarize | Send → `confirm` → low-stakes replies could earn `auto` over time |
| Form completion | Find form, read it, draft every field, show filled draft | Submit → `confirm` (promote per-form-class as trust accrues) |
| Research / watch video | Gather, watch, summarize, bring findings back | (usually no act half — pure gather, safe to run fully unattended early) |
| Home/device control | Detect context, propose action | Execute (e.g. AC off) → `confirm` first, earn `auto` once proven |

The AC-off-for-vacation example end to end: gather agent infers the trip and proposes "turn off AC." Day one, policy has that action class as `confirm` → it asks. After it's proposed correctly enough times and the trail proves it, Daniel edits policy to promote that class to `auto, notify after`. Nothing about the agent or the device capability changes. That's evolution without rebuild.

---

## 5. Corrected phase sequence (foundations-first)

Prior plan was capability-first (email → more capabilities → Command Center). Corrected:

**Built / in progress**
- Phase 2 email assistant (draft-only, proven no-send, injection-resistant loop) — this is the *template* for the dispatch/confirm split, already instantiated for one capability.

**Foundations (before broad capability expansion)**
- **F-A. Containment** — egress allowlist (first), then workload isolation, then credential proxy. *The unlock; reordered early.*
- **F-B. Observability substrate** — correlation-ID tracing, run-replay, zero-silent-failure as queryable. Evaluate topology-visualizer/dashboard here.
- **F-C. Action-policy layer** — the auto/confirm/deny registry, deny-by-default invariant, promotion model wired to observability evidence.
- **F-D. Dispatch/confirm split generalized** — promote the email loop's pattern to a system-wide standard every capability and the Command Center inherit. (Includes: every inter-agent handoff is a validated schema enforced by a deterministic check — the research-request validator pattern, made standard. MAST's #1 failure category is spec/coordination; this is the defense.)

**Capability expansion (on top of foundations, additive & safe)**
- Each new capability = safe-gather + gated-act, passing the §4 test and the Security Standard §6 checklist. Calendar, budgets, insurance, vacation, forms, home control — accrete one at a time.

**Command Center (the destination, P2 — still gated)**
- Dispatcher of open-ended gather tasks + confirmation surface for the action menu. Hard-held behind the 8 behavioral tests AND the foundations existing. It must not become a path that bypasses any trust boundary (Roadmap Brief, Theme 4).

**V1 trust milestone** — defined as *measurable properties of the observability substrate*: 30 days of daily use, full audit trails, zero silent failures (queryable, not asserted), and ≥1 action class successfully promoted confirm→auto on the strength of the trail. Not a vague duration — a demonstrated property.

---

## 6. GitHub / ecosystem findings folded in

Out of a 5,400+ skill ecosystem that is overwhelmingly capability-maximalist (the opposite of this architecture's discipline — admire, don't adopt):
- **Adopt-for-evaluation (observability phase F-B):** `agent-topology-visualizer` (SVG architecture/trust-boundary diagrams), `agent-dashboard` (real-time agent health). Directly serve Foundation 3.
- **Shelf as defensive gate (only if community code is ever installed):** `antivirus` / `agent-skills-audit` / `authensor-gateway` (scan skills for malicious patterns). 
- **Cross-check, don't adopt:** `anti-amnesia` (durable agent memory) — pressure-test our hand-rolled canonical-files state discipline against it.
- **Reference:** community hardening guides (the "setup guide I wish I had," NetworkChuck VPS guide) — skim the security-checklist sections as a sanity check.
- **Explicitly declined:** home automation skills (we build our own gated device control), social posting, on-chain/crypto, voice/phone surfaces, n8n bulk-automation, `agent-passport` (third-party consent-gate at our most sensitive boundary — our hand-built confirmation is correct). Each is an unbounded capability with a fresh trust boundary; adopting them trades away the narrowness that is the moat.

---

## 7. The one-paragraph end state

A personal life-operations agent where open-ended agents are dispatched to research, watch, gather, and propose — running wild but safe because they sit behind a containment foundation and *structurally cannot act* — while a single evolvable policy layer decides which proposed actions execute automatically (low-stakes, trust earned via the audit trail) versus which ask Daniel (everything unclassified, by permanent default, and all high-stakes), all observable end-to-end with zero silent failures, so the boundary between "handle it" and "ask me" can move toward autonomy over time without ever rebuilding the bedrock.
```

### AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md
```markdown
# OpenClaw Platform Mechanics Reference

**Purpose:** the platform-specific behavior of OpenClaw 2026.6.5 — runtime, exec, sandbox, egress, auth, observability, cron — mapped from the docs and issue tracker AHEAD of building, so build drops start from a *verified config recipe* instead of discovering incompatibilities mid-run. This is the artifact that closes the "we keep finding platform answers reactively" gap.

**Status:** v1, 2026-06-14. Companion to the End-State Architecture (the platform-mechanics gate references this file). Living document — deepen each section before its phase; update when OpenClaw version changes (mechanics are version-specific — this is 2026.6.5).

**The rule it enforces:** No build drop for a phase is written until that phase's section here is filled and marked VERIFIED. Principles research ≠ platform research. The landmines below were all discoverable in docs; finding them via failed runs is the failure mode this prevents.

---

## 0. The landmine catalog (silent defaults that bite)

Quick-reference list of platform behaviors that fail silently or surprisingly. Check this before any config change.

1. **`openai/*` model ref → Codex harness by default.** Selecting an OpenAI model silently routes the agent to the Codex app-server runtime unless you pin otherwise.
2. **Codex harness REJECTS `tools.exec.mode: "allowlist"`** outright ("Codex app-server local execution is not available when tools.exec.mode=allowlist"). [Hit live 2026-06-14.]
3. **Embedded `openclaw` runtime needs separate OpenAI API-key auth** — it can't use your Codex/ChatGPT subscription OAuth. Pinning `agentRuntime.id: "openclaw"` without API-key auth → "No API key found for provider openai". [Hit live 2026-06-14.]
4. **Sandbox `docker.network` defaults to `"none"`** — no egress at all. Allowed web tools silently fail; package installs fail. Must set `"bridge"` for outbound. `"host"` is blocked; `"container:<id>"` is break-glass only.
5. **Sandbox has its OWN tool filter** (`tools.sandbox.tools`) separate from agent `tools.allow`. A tool allowed at agent level still fails if the sandbox filter doesn't also permit it.
6. **Env vars do NOT inherit into the sandbox.** Host env (API keys) invisible inside the container; must use `sandbox.docker.env` (which is Docker-inspectable — secret exposure) or a custom image/mounted secret.
7. **macOS Keychain is unreliable headless/over-SSH** (error -50, interaction-required, write-verify timeout). Use gog file keyring for headless. [Hit live, earlier session.]
8. **Self-reported tool logging is honor-system and has gaps** — cron jobs, sub-agents, heartbeat run in isolated contexts and DON'T share the main session's logging. "Zero silent failures" requires gateway-level/OTel logging, not agent self-logging. [GitHub #13131.] **This is the big one for the V1 trust gate.**
9. **`exec.mode=allowlist` rejects shell chaining (`&&`, `||`, `;`) and redirections** unless every segment is allowlisted. Safe-bins reject positional file args / path-like tokens.
10. **EPERM chmod `~/.openclaw/state`** — known managed-sandbox bug on this install; ignore it, re-run outside the managed sandbox.
11. **Whole-agent `agentRuntime` keys are ignored/stripped by doctor** — runtime pins must be model-scoped (`models["provider/model"].agentRuntime.id`).
12. **Sandbox inheritance guard:** a sandboxed requester can't spawn an unsandboxed sub-agent (`sessions_spawn` rejects it). Matters when composing the dispatch/confirm split under sandboxing.

---

## 1. Runtime + auth (VERIFIED 2026-06-14)

**Three runtimes, three behaviors:**
- **Codex** (default for `openai/*`): app-server harness. Owns native thread/resume/compaction. REJECTS `exec.mode=allowlist`. Uses Codex/ChatGPT OAuth (your current auth). Maps host-exec misses to Codex Guardian review under `auto` mode.
- **Embedded `openclaw`** (pin `models["..."].agentRuntime.id: "openclaw"`): OpenClaw's own loop. ACCEPTS allowlist mode. BUT needs direct OpenAI API-key auth (`auth.order.openai`), a separate billing path from the Codex subscription.
- **ACP** (`runtime: "acp"`): external harnesses (Claude Code, Gemini, etc.). Runs on host OUTSIDE OpenClaw's sandbox/tool enforcement. Not for confined OpenClaw-native agents.

**Verified outcome (Path B, 2026-06-14):** Run a confined agent on default Codex runtime + `tools.exec.mode: "auto"`. This runs on existing Codex/subscription auth (no API key) BUT does **NOT** enforce OS-level exec-allowlist confinement — TESTED LIVE: with a strict per-agent exec-approvals allowlist still in place, an off-allowlist command (`ls /`) EXECUTED. The "stricter of the two layers" claim did NOT hold; `auto` mode did not defer to the approvals-layer allowlist. So **auto + strict-approvals is NOT a confinement substitute.**

The two configurations that actually exist:
- **Codex + `auto`:** runs on subscription auth, NO OS-level exec confinement (accepted under Path B — confinement comes from OAuth scope + 3-layer no-send + research validator + coming egress, not exec-allowlist).
- **Embedded `openclaw` + `allowlist`:** real OS-level exec confinement, BUT needs separate OpenAI API-key auth (Path A).

There is NO "confined on subscription auth" option. **Decision: Path B** (Codex + auto, lean on the other layers + egress). See End-State Architecture "Runtime + confinement law."

**Do NOT:** claim auto+approvals confines (disproven); pin embedded runtime without provisioning API-key auth.

---

## 2. Exec / approvals model (VERIFIED 2026-06-14)

- **`tools.exec.mode` values:** `deny` | `allowlist` | `ask` | `auto` | `full`. The normalized policy knob.
  - `allowlist`: deterministic matches run; misses STOP and wait for operator. Strict but Codex-incompatible.
  - `auto`: deterministic matches run; misses go to native auto-reviewer (Codex Guardian), then human fallback. Codex-compatible. **Reviewer can auto-approve a low-risk miss** — and a strict approvals layer does NOT reliably block this (disproven live: `ls /` executed under auto). Treat `auto` as NOT confined.
  - `deny`/`full`: block all / run all (full = YOLO).
- **Two layers:** `tools.exec.*` (mode) AND `exec-approvals.json` (per-agent `security`/`ask`/`askFallback`/allowlist). The docs describe effective policy as the *stricter* of the two — but this was DISPROVEN live 2026-06-14 for `auto` mode: an off-allowlist command executed despite a strict approvals-layer allowlist. **Do not rely on "stricter wins" to make `auto` confine.** The only mode that actually enforces allowlist confinement is `allowlist` itself — which the Codex harness rejects (so it requires the embedded runtime + API-key auth). [Landmine #2, #3; the runtime saga.]
- **`askFallback: "deny"`** = unanswered prompts default to denial. **`autoAllowSkills: false`** = don't auto-trust ClawHub skills. Keep both strict regardless (defense-in-depth), but know they do NOT make `auto` confine.
- **Allowlist enforcement:** matches resolved binary paths (no basename match); pin actual script paths, not wildcards (`python3 *` ≈ `full`). Chaining/redirections rejected unless all segments allowlisted.
- **`elevated` mode** bypasses sandbox to host with its own approval gates — keep off for confined agents.

---

## 3. Sandbox / workload isolation (VERIFIED for Foundation 2 — egress)

- **`agents.defaults.sandbox.mode`:** `off` | `non-main` | `all`. ("non-main" keys off session.mainKey, so group/channel sessions count as non-main and get sandboxed.) Your agents currently run `mode: off`.
- **`sandbox.scope`:** how many containers (session vs shared).
- **`sandbox.workspaceAccess`:** `none` mirrors eligible skills into the sandbox workspace.
- **Sandbox is Docker-based.** `readOnlyRoot: true` blocks writes. `user` must be root for installs. Sandbox exec does NOT inherit host `process.env`.
- **Sandbox has its own tool filter** (`tools.sandbox.tools`) — separate gate from agent `tools.allow`. Both must permit a tool. [Landmine #5.]
- **Inheritance guard:** sandboxed requester can't spawn unsandboxed child.
- **What's NEVER sandboxed:** the Gateway process itself; anything in `tools.elevated`.

---

## 4. Egress / network control — Foundation 2 (DECISION AMENDED 2026-06-14b)

> **Amendment note (2026-06-14c):** Plan A (host-side reader + UID-keyed pf-forced proxy) is
> **ELIMINATED on evidence.** The 2026-06-14b decision adopted Plan A *gated behind OPEN VERIFY
> item #1 (pf viability on this macOS build)*. That verify ran (read-only pf-viability drop,
> 2026-06-14) and resolved **NO**: host-pf cannot enforce same-host UID-keyed redirect-to-proxy
> on this macOS version. Plan A is therefore off the table — not on preference, on a failed
> verify gate. Decision status returns to OPEN among the surviving plans. Findings below.

### Verify item #1 result (pf-viability drop, 2026-06-14) — Plan A eliminated
- `pf route-to` performs policy routing, **not** transparent proxy redirection — it changes the
  egress path/interface but does not hand the connection to a local proxy listener.
- `pf rdr` (redirect) **cannot match on UID/user** — the redirect grammar has no user selector;
  only inbound/destination tuples. So "redirect this UID's 443 to the local proxy" is
  unexpressible: the two features that would compose (UID match + redirect) do not compose.
- pf **address translation precedes filtering**, so even a filter-stage UID match cannot drive a
  translation decision.
- There is **no per-agent UID** within one OpenClaw gateway (gateway runs as a single UID;
  per-UID separation needs a *separate gateway/service instance*), so the dedicated-reader-UID
  premise Plan A depended on does not hold without additional infrastructure.
- Net: the UID-keyed-pf mechanism is not viable on this host. Squid/tinyproxy as *engines* remain
  fine; the missing piece is an enforceable, non-bypassable **forced-routing** layer on macOS.

### Why the Docker decision was narrowed (verify-drop findings, 2026-06-14)

The egress-verify drop established that containerizing the confined reader is NOT a config
change — it is a port:
- `gog-gmail-draft-safe` is a **macOS arm64 Mach-O** → cannot execute in a Linux sandbox even
  if mounted; needs a Linux arm64 rebuild of the safe-send binary.
- Node is host Homebrew Mach-O → needs Linux Node in a custom image.
- Wrapper UID-checks the keyring password file (host UID 501 must equal process UID) → fails
  closed on mismatch; container needs deliberate UID handling.
- gog home is a full writable credential store (OAuth client metadata, credentials index,
  encrypted keyring + lock) → needs writable, protected mounts, not a single secret file.
- A Docker bridge gives outbound connectivity but is **not itself an allowlist** — DOCKER-USER
  iptables rules still required on top.

Net: containerizing forces a rebuild AND revalidation of the load-bearing no-send chain (§8:
scope is the load-bearing control; the 3-layer no-send is the proven belt). Re-proving that
through a freshly-built Linux binary is a new attack surface for no current functional gain,
because the reader stays supervised until egress lands regardless.

### Field-standard reality (researched 2026-06-14)

Per-application outbound domain control, everywhere it is done (AWS, GCP, Qovery, Databricks):
**a forward proxy that filters on destination hostname / TLS SNI, default-deny**, app pointed
at it. Squid is the default engine; tinyproxy is the lightweight option. SNI/host-header
filtering keeps TLS end-to-end (no MITM cert to install in the reader).

**The load-bearing distinction:** the proxy allowlists domains; a SEPARATE forced-routing
layer is what stops the app bypassing the proxy. Env-var proxying (`HTTPS_PROXY`,
`NODE_USE_ENV_PROXY`) is **cooperative only** — a hijacked process ignores it and opens a
direct socket. Env vars are a convenience, NOT an exfil control. The enforcement must be a
layer the reader cannot opt out of.

### macOS enforcement mechanism

**(Superseded — see verify item #1 result above: this mechanism was eliminated. Retained only to explain what was attempted.)**

No Linux netns, no NetworkPolicy on macOS. The one host-level chokepoint for same-host
outbound is **pf, keyed on UID** (pf's only usable selector for own-box traffic is user/group,
not PID). The candidate recipe was:
- Run the reader under a **dedicated UID**.
- `route-to lo0` all of that UID's outbound 80/443 → a **local allowlisting forward proxy**.
- Run the proxy under a **DIFFERENT UID** so its own egress is not re-redirected (the UID is
  the filter that prevents the proxy looping its own traffic).

**Note (2026-06-14c):** an earlier pass argued UID-keyed forced routing was the legitimate macOS mechanism. The pf-viability verify (above) supersedes that: the UID-match and redirect features do not compose on this macOS build, so the mechanism is eliminated regardless of standardness. Operational fragility was not even the deciding factor — expressibility was.

### DECISION STATUS (2026-06-14c): OPEN — operator decision required
Plan A eliminated (above). Surviving options:

- **Plan B — separate egress box.** A small always-on box (Pi/spare machine) is the only internet
  route for the reader; allowlist at its interface. Field-standard and robust. Cost: added
  hardware + a network hop + its own setup. **No new software prerequisite on the Mini.**
- **Plan C — Docker container egress (revived from shelf).** Containerize the reader on an
  `internal:true` Docker network with a Squid allowlist forward proxy; enforcement runs inside
  Docker Desktop's Linux VM (iptables/DOCKER-USER), which sidesteps macOS pf entirely — this is
  the field-standard mechanism and the reason Docker keeps recurring. **Hard prerequisite: Docker
  is NOT installed (FLAG), so this path starts with an operator decision to install a container
  runtime.** Also carries the §4 port costs already documented above (Mach-O→Linux rebuild of the
  safe-send binary, gog file-keyring UID handling, writable protected credential mounts, and the
  bind-validator constraint that rejects mounting `~/.openclaw` subdirs — so the reader's keyring/
  wrapper chain must be re-homed or re-proven). **Net answer to the standing §4 VERIFY question
  "does sandboxing the reader break the keyring/wrapper": YES, in the specific ways listed — it
  requires re-homing the credential chain, not a transparent lift-and-shift.**

**This choice is the operator's (Plan B vs install-Docker-for-Plan-C). It is NOT resolved here.**
The next build step cannot proceed until it is made.

#### Considered, NOT adopted (recorded as input only — not decisions)
- *Cooperative env-var proxying alone* (`HTTPS_PROXY`/`NODE_USE_ENV_PROXY`): a hijacked process
  ignores it. Convenience, not an exfil control. Only valid as belt alongside a forced layer.
- *Credential-broker / exec-profile-narrowing as a PRECURSOR to egress*: field research this
  session noted the reader's host `exec` (mode auto) lets a hijacked reader read its own keyring,
  making egress the *last* link rather than the first. Whether to narrow the reader's exec/tool
  profile (or broker the credential) BEFORE building egress is a **sequencing question for the
  operator** — recorded here as an option, explicitly not a change to the foundations-first order
  in CONTROL.md.
## 5. Observability / audit — Foundation 3 (RESEARCHED; critical finding)

**THE key finding for the V1 "zero silent failures" gate:**
- **Agent self-logging is honor-system and has structural gaps:** cron jobs, sub-agents, and heartbeat sessions run in isolated contexts and DON'T share the main session's logging; the agent could skip entries; no centralized view. [GitHub #13131.] **So "zero silent failures" CANNOT be built on agent self-reporting.** It must be built on gateway-level / OTel instrumentation that captures every tool call regardless of session type.
- **Built-in OTel support (v2026.2+):** `diagnostics.otel` config (`enabled`, `endpoint`, `serviceName`, `traces`, `metrics`, `logs`). Emits spans: `openclaw.request` (root, full lifecycle) → `openclaw.agent.turn` → `tool.*` children. This is the spine for correlation-ID tracing and run-replay.
- **Plugin hooks for deeper capture:** `before_tool_call`, `before_agent_reply`, `agent_end`, `subagent_spawned`, `cron_changed`, etc. Hooks include `runId`/`ctx.runId` (and `ctx.jobId` for cron) + a W3C trace context for OTEL correlation. A native plugin captures what a network proxy can't (skill loads, memory recall, sub-agent routing, heartbeat decisions).
- **Existing tooling to evaluate (don't rebuild):** `henrikrexed/openclaw-observability-plugin` (OTel traces/metrics/logs + built-in dashboard), Opik (`opik-openclaw`, self-hostable, LLM-as-judge eval), Arize. Plus the GitHub topology-visualizer/agent-dashboard from the earlier ecosystem scan.

**Verified design direction for Foundation 3:** built-in `diagnostics.otel` for operational metrics + a lifecycle plugin (or existing observability plugin) for tool-call/trace capture across ALL session types (incl. cron/heartbeat/sub-agents) → local OTel collector → queryable store. "Zero silent failures" = a query over gateway-captured tool spans showing every call has a traced result and every failure a delivered notification. NOT agent self-report.

---

## 6. Automation / cron / heartbeat — (RESEARCHED; for autonomy phases)

- **Cron:** precise schedules + one-shot reminders; ALL cron executions create task records (auditable). Exact user-requested reminders belong to cron.
- **Heartbeat:** routine monitoring (inbox/calendar/notifications) batched every ~30 min. This is the mechanism for proactive "notice the vacation, propose AC-off" behavior — but see observability gap (heartbeat runs isolated, needs gateway-level logging).
- **Standing orders:** persistent operating authority in workspace files (AGENTS.md), injected every session — combine with cron for time-based enforcement. This is where the dispatch/confirm doctrine + deny-by-default live operationally once foundations exist.
- **Task Flow / Background Tasks:** durable multi-step orchestration with a task ledger (`openclaw tasks flow list|show|cancel`) — auditable detached work.
- **Cost caution:** heartbeat + cron creep token spend; small config edits compound. Budget/monitor via OTel cost metrics.

---

## 7. Secrets / credentials — (RESEARCHED; for credential-proxy foundation)

- **gog file keyring** for headless (Keychain unreliable over SSH). Tokens encrypted (AES-256-GCM per some guides).
- **Sandbox secret delivery:** env doesn't inherit; `sandbox.docker.env` is Docker-inspectable (metadata exposure) — use custom image / mounted secret file for real secrets.
- **Credential-proxy pattern** (Foundation 2/secrets): agent calls a broker that holds the credential — generalizes the draft-safe wrapper. The wrapper already instantiates this for Gmail.
- **Least privilege / dedicated account:** community standard is a dedicated Gmail account for the bot, minimal scope, short-lived where possible.

---

## 8. Field-standard baseline (what OpenClaw Gmail users actually do)

So we calibrate against reality, not over-engineer:
- gogcli (`gog`) + OAuth, scopes in OS keyring. (Universal.)
- `gmail.readonly` first, `draft-not-send` forever for most. (Consensus.)
- Confinement = OAuth scope + draft-not-send + least privilege ("house-sitter key"). NOT OS-level exec-allowlist — that's an uncommon belt, and on Codex `auto` it isn't enforced anyway (disproven live); enforcing it requires the embedded runtime + API key (Path A), which we declined for the reader (Path B). The field doesn't wear this belt; neither do we, for now.
- Cheap always-on box (VPS/Pi/Mac mini). Dedicated bot Gmail account recommended.
- Real failure mode in the wild: agent granted modify/delete scope bulk-deleted email (Meta safety director incident). Lesson: SCOPE is the load-bearing control. Our three-layer no-send is already stronger than the norm.

---

## 9. Per-phase VERIFY gate status

| Phase | Section | Status |
|---|---|---|
| Email loop runtime/exec | §1, §2 | VERIFIED (live 2026-06-14) |
| Foundation 2 — egress/sandbox | §3, §4 | DECISION OPEN — Plan A (host-pf) ELIMINATED on verify (pf non-viable on this macOS build); choose Plan B (separate box) vs Plan C (Docker — requires runtime install). Operator decision gates the build. |
| Foundation 3 — observability | §5 | RESEARCHED — design direction set; confirm OTel plugin choice before build |
| Foundation 4 — action-policy/exec | §2, §6 | RESEARCHED — standing orders + exec model mapped |
| Secrets/credential proxy | §7 | RESEARCHED |
| Cron/heartbeat autonomy | §6 | RESEARCHED |

Before each phase's build drop: re-read its section, resolve OPEN VERIFY items with a read-only diagnostic against the live install, mark VERIFIED, THEN write the build drop.
```

### AGENT_OS_SECURITY_DESIGN_STANDARD.md
```markdown
# Agent OS — Security Design Standard (Prompt-Injection Resistance)

**Purpose:** a reference standard every Agent OS capability is checked against BEFORE it's built. Derived from primary sources, not improvised per-drop. Each future phase (and the current email loop) gets reviewed against this.

**Status:** v1, June 13 2026. Living document — update as new capabilities and new literature land.

---

## 0. The governing principle

You cannot build a general-purpose agent immune to prompt injection with current models. You CAN build application-specific agents that are provably resistant, by constraining capability and defining trust boundaries.

Source: Beurer-Kellner et al., "Design Patterns for Securing LLM Agents against Prompt Injections" (arXiv 2506.08837, June 2025) — authored by IBM, Google, Microsoft, ETH Zurich, EPFL, Invariant Labs, Swisscom.

Author recommendation #1: prioritize application-specific agents that adhere to secure design patterns and clearly define trust boundaries.

**Implication for Agent OS:** never build "an agent that can do email." Build "an agent that drafts email replies and provably cannot send." Every capability is scoped to a specific job with a defined trust boundary, not a general grant.

---

## 1. The two foundational rules (apply everywhere)

**Rule A — Single trusted command channel.**
Only the operator (Daniel, via Telegram) issues commands. Nothing observed through a tool — email bodies, web pages, file contents, calendar events, tool outputs — is ever an instruction. It is all DATA.

**Rule B — Untrusted data cannot reach the action-decision path.**
It is not enough that untrusted text "shouldn't" be obeyed. The architecture must make it so untrusted content structurally cannot influence which tool fires or with what parameters. This is the difference between "the model usually resists" and "the model cannot."

Both rules are architectural, not prompt-based. A system-prompt instruction to "ignore injected commands" is a weak supplement, never the primary control.

---

## 2. The six design patterns (the toolbox)

From the paper, §3.1. Pick the ones that fit each capability.

1. **Action-Selector.** The LLM may only pick from a fixed set of pre-defined tool calls; it cannot generate free-form actions. Most constrained, most resistant. Fits anything that's really a menu of operations.

2. **Plan-Then-Execute.** The LLM builds a fixed, immutable plan from the operator's request FIRST, before touching any untrusted data. Untrusted data can change the plan's *inputs* but never the *plan itself* (the sequence of tool calls). Stops injected data from adding new actions.

3. **LLM Map-Reduce.** Fan untrusted items out to isolated sub-agents that each process one item with no cross-contamination, then reduce. Good for "process N untrusted documents."

4. **Dual LLM.** A privileged LLM handles trusted operator input and orchestrates. A quarantined LLM processes untrusted data and CANNOT issue privileged actions or modify the plan. (Willison's pattern; CaMeL extends it.)

5. **Code-Then-Execute.** The privileged LLM emits code/a plan in a structured language; an interpreter runs it while tracking data provenance, blocking tool calls whose inputs trace to untrusted sources. CaMeL is this pattern. Strongest, heaviest.

6. **Context-Minimization.** After the operator's request is turned into a sanitized structured action, DROP the original untrusted text from context so it can't influence later steps (post-processing, formatting, follow-on calls). Cheap, broadly applicable.

**Trade-off, stated by the authors:** these patterns constrain agents to prevent them solving *arbitrary* tasks. That constraint IS the security. Resist the urge to make a capability "more general" — generality is the attack surface.

---

## 3. Email & Calendar Assistant — the paper's own case study (§4.3)

The paper analyzes THIS use case directly. For an email/calendar assistant it endorses three designs, all of which Agent OS should implement in combination:

- **User confirmation** — operator approves before any consequential action (send). In Agent OS: never-send is enforced 3 ways AND the operator is the only one who can send (by copying from the draft). Strongest single control. ✓ BUILT.
- **Plan-Then-Execute / Code-Then-Execute** — fix the action plan from the operator request before reading email.
- **Dual LLM** — quarantined reader processes email content; privileged plane orchestrates. ✓ BEING BUILT (reader/researcher split).

---

## 4. Coverage scorecard — current email loop vs. the standard

| Control | Pattern | Status |
|---|---|---|
| Operator-only command channel (Telegram) | Rule A | Designed into loop |
| Email content treated as inert data | Rule A / Dual LLM | Reader doctrine (being added) |
| Send structurally impossible | Action-Selector (wrapper allowlist) + capability restriction | ✓ BUILT + PROVEN (3 layers) |
| Operator reviews every draft | User confirmation | ✓ BUILT (draft-only, manual send) |
| Quarantined reader / separate research plane | Dual LLM | Being built |
| Research agent cannot see raw email | Dual LLM / least-privilege | Being built (web_search only, no Gmail) |
| Sanitized structured research questions, raw email dropped | Context-Minimization (strong) | PARTIAL — see gap below |
| Provenance tracking (input→action) | Code-Then-Execute / CaMeL | NOT BUILT — future, heavy |
| Egress control (data can't leave) | — | NOT BUILT — explicitly deferred |

---

## 5. Known gaps & residual risks (be honest, track them)

1. **Research-question smuggle path (the gap Codex flagged).** The reader emits "research questions" to the researcher. If the reader is injected, those questions are a potential exfil channel. The standard's fix is *strong context-minimization*: the research question must be a MINIMIZED, STRUCTURED extraction (ideally constrained to a fixed schema / enum of question types), not free-form text. Treat free-form reader→researcher text as a smuggle path until it's schema-constrained.

2. **No provenance tracking.** Agent OS uses agent-separation (Dual LLM), not value-level provenance (Code-Then-Execute/CaMeL). This is a deliberate weight trade-off. It means the boundary is "the researcher never receives raw email," not a cryptographic guarantee no email-derived byte reaches a query. Acceptable for supervised, non-sensitive use; NOT acceptable for unattended sensitive mail.

3. **No egress control.** Nothing yet prevents a compromised plane from exfiltrating via an allowed channel. Loop is therefore gated: supervised, non-sensitive ONLY until egress control is built.

4. **Keyring password same-user exposure.** Accepted trade-off for headless operation (documented in Phase 2 connect).

---

## 6. Pre-build checklist (run this against EVERY future capability)

Before any new capability (calendar, more agents, command center) is built, answer:

1. What is the specific, bounded task? (If the answer is "general X," stop — narrow it.)
2. What is the trust boundary — what's the trusted command source, what's untrusted data?
3. Which of the 6 patterns apply? (Name them.)
4. Can untrusted data influence which tool fires or its parameters? (If yes, redesign until no.)
5. What's the most dangerous action this capability can take, and is it structurally unreachable from untrusted input?
6. Does the operator confirm consequential actions?
7. Is untrusted context minimized/dropped before post-processing?
8. What are the residual risks, and is the capability gated (supervised/non-sensitive) until they're closed?
9. Is there an egress path? Is data prevented from leaving via allowed channels?
10. Is there a test that PROVES the injection boundary holds (not just that it's designed)?

A capability doesn't ship until 1–10 are answered and the item 10 test passes.

---

## 7. Primary sources

- Beurer-Kellner et al., "Design Patterns for Securing LLM Agents against Prompt Injections," arXiv:2506.08837 (2025). The six patterns + the email-assistant case study. Authors: IBM, Google, Microsoft, ETH Zurich, EPFL, Invariant Labs, Swisscom.
- Google DeepMind, "Defeating Prompt Injections by Design" (CaMeL), 2025. The code-then-execute / provenance-tracking instantiation.
- Microsoft MSRC, "How Microsoft defends against indirect prompt injection" — Spotlighting (mark untrusted content) + FIDES (information-flow control) + the design-patterns consortium.
- Willison, "The Dual LLM Pattern for Building AI Assistants That Can Resist Prompt Injection."
- OWASP LLM Top 10 — LLM01 Prompt Injection — for compliance-framework mapping.
- Reference implementation: github.com/ReversecLabs/design-patterns-for-securing-llm-agents-code-samples (educational, not production).

---

## 8. The one-line standard

**Every Agent OS capability is an application-specific agent with a defined trust boundary, built from the named patterns, where the most dangerous action is structurally unreachable from untrusted data, the operator confirms consequential actions, and an injection-boundary test PROVES it before ship.**
```

### AGENT_OS_ROADMAP_BEST_PRACTICES.md
```markdown
# Agent OS — Roadmap Best-Practices Brief

**Purpose:** the research pass that should have run before each phase, done up front for the whole remaining vision. Every future drop starts from this instead of improvising. Companion to AGENT_OS_SECURITY_DESIGN_STANDARD.md (which covers prompt-injection specifically); this brief covers the other domains each phase touches.

**Method:** primary sources pulled June 13 2026. Each section = the established patterns, the named failure modes, the load-bearing source, and a pre-build checklist. Update as phases land and literature moves.

---

## How to use this

Before ANY future phase is built:
1. Read the matching section here + the security standard's section-6 checklist.
2. Answer the phase's pre-build checklist in the drop's discovery phase.
3. If the phase introduces a capability the brief doesn't cover, research it first and add a section. No more discovering architecture mid-build.

---

## PHASE THEME 1 — More agents / orchestration (researcher, calendar agent, future roster)

**The decision to make first: do you even need another agent?**
The literature is blunt that multi-agent is over-used. A single agent with a concatenated toolbox is competitive with multi-agent for tasks that fit one context window. Multi-agent is justified in exactly two cases: (1) a **privileged-information boundary** exists between agents (your reader-can't-send, researcher-can't-see-email split — legitimate), or (2) multiple distinct principals/stakeholders. If neither holds, adding an agent adds failure surface for no gain.

**The failure data (your single most useful orchestration source):**
MAST taxonomy — "Why Do Multi-Agent LLM Systems Fail?" (Cemri et al., NeurIPS 2025, arXiv:2503.13657). 1,600+ annotated traces across 7 frameworks, expert-validated (κ=0.88). Production multi-agent systems fail at **41–86.7%** rates. 14 failure modes in 3 root categories:
- **Specification issues (~44%)** — ambiguous agent roles/contracts. The largest category. Your defense: explicit, tight agent contracts (you already write these as AGENTS.md doctrine — keep them schema-precise, not prose-vague).
- **Inter-agent misalignment (~32%)** — agents talk past each other, duplicate work, drop responsibilities. Defense: explicit handoff contracts (every handoff has a defined input/output shape — your schema-constrained research request is exactly this pattern; apply it to every handoff).
- **Verification gaps** — no agent owns quality control. Defense: a dedicated verify step (your Buela validator role; make sure it actually runs, not just exists).

**Hard rules from the literature:**
- **Never let one agent trigger another without a cycle check** in the orchestration layer (prevents runaway spawn loops). Your `requireAgentId: true` + exact `allowAgents` list + no nested spawning is the right shape — keep it.
- One compromised agent propagates downstream ("Agent-in-the-Middle," error cascades — arXiv:2603.04474). Trust boundaries must be at the orchestration layer, not per-agent ad hoc.
- Anthropic's own long-running-agent guidance: the two big failure modes are context-loss incoherence and premature wrap-up near context limits; fix is context reset + structured handoff to a fresh agent. (You already do "fresh gmail-reader run for drafting" — that's this pattern.)

**Pre-build checklist (new agent):**
1. Does a privileged-info boundary or distinct principal justify this agent? If not, use a tool on an existing agent.
2. What is its EXACT input contract and output contract? (Schema, not prose.)
3. Every handoff to/from it: defined shape, validated at the boundary?
4. Who verifies its output? Is that verify step real?
5. Cycle check: can it (directly or transitively) trigger a spawn loop? Prove not.
6. Least privilege: minimal tool set, everything else denied by group?
7. Context: does it get a fresh context for distinct sub-tasks, or accumulate and drift?

---

## PHASE THEME 2 — Egress control (deferred, but the real gate for sensitive use)

**This is the most important deferred item and the literature is unusually clear on it.**

**Load-bearing source:** "Silent Egress: When Implicit Prompt Injection Makes LLM Agents Leak Without a Trace" (arXiv:2602.22450, Feb 2026). Uses observed network traffic as ground truth. Findings:
- Prompt-layer defenses offer **limited protection** against exfiltration.
- **Domain allowlisting blocks ~all attempted egress** (P(egress)≈0 with allowlist vs ≈0.89 without). Because the check runs at **tool-execution time**, it does NOT depend on the model resisting injection. This is the whole point — it's a control that works even when the model is fully compromised.
- 95% of successful exfiltration evades output-based safety checks.
- **Sharded exfiltration**: attackers split data across multiple requests to beat single-request DLP. So per-request content inspection is insufficient; you need the network boundary.

**Directly relevant to your platform:** "Caging the Agents: A Zero Trust Security Architecture for Autonomous AI" (arXiv:2603.17419, Feb 2026) — its hardening progression literally starts from an `openclaw-base` VM image. Four containment layers, in order of value:
1. **Kernel-level workload isolation** (gVisor / container).
2. **Credential proxy sidecar** (agent never holds raw credentials — relevant to your keyring exposure tradeoff).
3. **Network egress policy enforcement** (the allowlist).
4. **Prompt integrity framework** (trusted metadata envelopes + untrusted-content labeling + anti-injection rules — you already have the labeling via gog's `<<<EXTERNAL_UNTRUSTED_CONTENT>>>`).

**The five highest-ROI controls** (Schneider, "From LLM to agentic AI," Apr 2026), in priority order:
1. Outbound network allowlist (most exfil prevented by this one control).
2. Human approval for all write/delete/external-state changes. (You have this for send.)
3. Prompt-injection classifier on external inputs.
4. Audit MCP/tool permissions (list every tool, what it accesses, blast radius if compromised).
5. (defense-in-depth beyond these.)

**Implication for your roadmap:** your current loop is correctly gated "supervised, non-sensitive until egress control exists." This brief confirms that gate is not conservatism — it's the documented requirement. The egress phase (macOS `pf` allowlist → container isolation) is what unlocks unattended and sensitive use. Until then the loop stays supervised. Order of build when you get there: network allowlist FIRST (highest ROI), then workload isolation, then credential proxy.

**Pre-build checklist (egress phase):**
1. What is the COMPLETE list of domains each tool legitimately needs? (Default deny, no wildcards.)
2. Is the allowlist enforced at tool-execution/network layer, not prompt layer?
3. Does the research agent's web_search route through the allowlist? (Search is an egress channel.)
4. Sharded exfil: does the boundary catch slow/split leakage, or only single requests?
5. Is there a credential proxy so a compromised agent can't read raw secrets?
6. Workload isolation: is the agent in a container/VM, not just a user account?

---

## PHASE THEME 3 — Observability, audit trail & the V1 trust gate

**Your V1 milestone (30 days daily use, trustworthy audit trails, zero silent failures) IS an observability problem.** The literature gives you the standard.

**The framing (JetBrains/PyCharm eval+observability guide, May 2026):** evaluation determines if the agent CAN work; observability determines if it IS working. You need both. Your 8 behavioral tests = evaluation. Your audit-trail/zero-silent-failure requirement = observability. Don't let one substitute for the other.

**What "trustworthy audit trail" actually requires (consensus across sources):**
- **Structured logging with correlation IDs** on every message, plan, and tool call, so an end-to-end trace can be reconstructed. (This is how Anthropic does centralized token/trace collection.) Your silent-FAIL-notification bug from the OpenClaw v5 work is exactly the failure this prevents — a tool call whose result wasn't traced.
- **Record per step:** the agent's reasoning, which tool was called with what params, what data came back, how the decision was made. Start-to-finish.
- **Immutable logs / full lineage** for the trail to be trustworthy (can't be silently rewritten).
- **Conversation/run replay** — store complete runs so you can rewind, fork with a modified input, and verify a fix. This is how you debug non-deterministic multi-agent failures, where a stack trace is useless.

**"Zero silent failures" is a specific, achievable spec:** every tool call has a traced result; every FAIL produces a delivered notification (your Tiger silent-FAIL bug was a violation); every run is reconstructable from logs. Make "did anything fail without notifying?" a queryable property of the log, not a hope.

**Offline eval methodology (for your 8 tests — Towards Data Science, Mar 2026):**
- Start with the highest-signal metrics (routing accuracy, factual accuracy), easiest to implement.
- Small dataset (50–100 samples) run manually first to calibrate expectations.
- Every run creates a record (which version, which dataset, what scores, thresholds met y/n) — these accumulate into the audit trail that demonstrates systematic QA over time.
- Define acceptance criteria BEFORE the first run. (Your 8 tests should each have a pre-defined pass threshold, not a judgment call after the fact.)

**Pre-build checklist (any capability, observability side):**
1. Does every tool call this capability makes get logged with a correlation ID?
2. Can a full run be reconstructed from logs alone?
3. Does every failure path produce a DELIVERED notification (no silent FAIL)?
4. Are logs immutable / append-only enough to be trustworthy?
5. For the 8-test gate: does each test have a pre-defined pass threshold and a recorded result?
6. Can you query "did anything fail silently in the last 30 days?" and get a real answer?

---

## PHASE THEME 4 — Command Center (P2, hard-held behind 8 tests)

**Why the hold is correct, in the literature's terms:** a Command Center is a control surface that can trigger many capabilities. That makes it a high-blast-radius node. MAST says the largest failure category is specification/coordination; a central controller multiplies coordination surface. The 8-test gate is your verification-gap defense — don't relax it.

**When you build it, treat it as an orchestration node** and run the Theme-1 checklist on it, plus:
- It must not become a path that bypasses per-capability trust boundaries (e.g. a Command Center "send" button that skips the draft-only discipline).
- Every action it can trigger inherits that capability's own confirmation/egress gates — the Command Center doesn't get to be an exception.
- Cycle check is critical here: a controller that can trigger agents that can trigger the controller is a loop generator.

**Pre-build checklist:** Theme-1 checklist + "does any Command Center action bypass an existing trust boundary? (must be no)."

---

## PHASE THEME 5 — Secrets / credentials at scale

As capabilities grow you'll hold more tokens (Gmail today; calendar, others later). Current state: file keyring, password injected into the safe binary's child env, same-user exposure accepted.

**The pattern to move toward (from "Caging the Agents" layer 2):** a **credential proxy sidecar** — the agent calls a broker that holds the credential and makes the authenticated call; the agent never sees the raw secret. This is the same principle as your draft-safe wrapper (the wrapper holds Gmail capability, the reader never gets the token), generalized to all secrets.

**Rules (OWASP AI Agent Security cheat sheet + LLM Top 10):**
- Least-privilege, **short-lived tokens**, narrow scopes per tool. (Your gmail.compose-only is this.)
- Human approval for high-risk methods (write/delete/transfer) — never delegated to the model.
- Tenant/context isolation between capabilities (Gmail creds never reachable from the calendar agent, etc.).

**Pre-build checklist (new credential):**
1. Narrowest possible scope? Short-lived if possible?
2. Held by a broker/wrapper, not the agent? (Generalize the draft-safe pattern.)
3. Reachable ONLY by the one capability that needs it (group-denied everywhere else)?
4. Is the high-risk action behind human approval, structurally?

---

## The cross-cutting principles (true for every phase)

1. **Application-specific, not general** — every capability is a bounded job with a trust boundary (security standard §0).
2. **Controls at the system/network layer beat controls at the prompt layer** — because they hold even when the model is compromised. Allowlists, wrappers, validators > "the prompt tells it not to." (Silent Egress; your deterministic research-request validator is a textbook instance.)
3. **Every handoff is a validated contract** — schema, not prose (MAST specification failures).
4. **Every consequential action is human-confirmed** — structurally, not by model choice.
5. **Every run is fully traced; no silent failures** — observability is the V1 gate.
6. **Prove it, don't design it** — each capability ships only when a test PROVES its boundary holds (your no-send proof and injection test are the model for this).

---

## Primary sources

- Cemri et al., "Why Do Multi-Agent LLM Systems Fail?" (MAST taxonomy), arXiv:2503.13657, NeurIPS 2025. — orchestration failure modes.
- "Silent Egress: When Implicit Prompt Injection Makes LLM Agents Leak Without a Trace," arXiv:2602.22450, 2026. — egress is the real control.
- "Caging the Agents: A Zero Trust Security Architecture for Autonomous AI," arXiv:2603.17419, 2026. — four-layer containment, built on OpenClaw VMs.
- Schneider, "From LLM to agentic AI: prompt injection got worse," 2026. — five highest-ROI controls.
- OWASP "AI Agent Security Cheat Sheet" + LLM Top 10 (LLM01). — capability/credential discipline.
- Beurer-Kellner et al., arXiv:2506.08837 (the six patterns) — see security standard.
- Google DeepMind, "Towards a Science of Scaling Agent Systems," Dec 2025. — when multi-agent helps vs hurts.
- JetBrains, "LLM Evaluation and AI Observability for Agent Monitoring," 2026; "Production-Ready LLM Agents: Offline Evaluation," 2026. — eval + audit methodology.
- Anthropic long-running-agent guidance — context reset + structured handoff.
```

---
_To request a decision: tell Claude which CONTROL.md NEXT or which doc section you need a call on._
