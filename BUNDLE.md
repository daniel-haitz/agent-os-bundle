# AGENT OS — STATE BUNDLE FOR CLAUDE
_Generated: 2026-06-12T14:09:16Z · commit: af137e9_

This is a sanitized snapshot for Claude.ai review. Secrets are excluded by .gitignore + scan.

---
## CONTROL.md (current state)
```markdown
# CONTROL.md — Single Source of Truth

**This is the ONLY state file. Every worker reads this first and updates it last.**
**If it's not in this file, it didn't happen. The repo is truth, not any prompt or any brain's memory.**

---

## NOW (where we are this exact moment)

> Phase 0 COMPLETE. OpenClaw 2026.6.5 live, daemon supervised, @LLoyd_entouragebot paired + round-trip confirmed, Codex primary + Qwen heartbeat, secrets audit clean, config baseline e59160b, Clawhatch installed.

**FLAG:** A full Mac reboot was not tested (only a controlled daemon restart) — verify auto-start on next reboot.

---

## NEXT (the single bounded task the next worker does)

> Phase 1, Step 1.1 — trust model as config (capability tiers + approvals). Get a Claude drop before building.

---

## DONE (reverse chronological — newest first, one line each)

<!-- Workers append here. Format: YYYY-MM-DD | worker | what shipped | commit -->
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
- [ ] **ClawGuard source read** (Phase 2) — before it carries audit integrity. Custom hash-chain fallback ready.
- [ ] **Browser `fill` tool-side secret resolution test** (Phase 6) — does fill resolve a SecretRef without returning the value to the LLM?

---

## PHASE MAP (the spine — detail lives in docs/OPENCLAW_BUILD_PLAN.md)

- **0** Clean stand-up: install, onboard, new bot, Codex+Qwen routing, secrets audit, git-baseline config
- **1** Trust model as config: tiers, approvals, sandbox, reader-agent split designed, config-self-mod defenses
- **2** Doctrine as skills: SOUL/AGENTS, Steinberger orchestrator pattern, ClawGuard audit, Skill Workshop
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
5. Never leave this file stale. `end-session.sh` enforces this.
```

## Recent git log (20)
```
af137e9 [codex] Phase 0 complete: OpenClaw install, daemon, Codex+Qwen, secrets, heartbeat, baseline, Clawhatch, Telegram bot paired
e9eed48 [human] teardown: clear old build, install OpenClaw workflow kit (clean slate)
38bd551 Final state before OpenClaw teardown
bd01962 2026-06-10: Log C.5 live-proof + token-in-logs learning; note open items (poller loop wiring, §8e offset hardening)
66d98d7 C.5 fix: suppress httpx request logging so bot token never reaches logs; test asserts token absent from log output
64200a8 C.5b: inbound Telegram poller — allowlist, offset, plain-approve correlation, stop/halt kill switch (receive+record+ack); test-first
71d958f C.5a: telegram_message_id field + list_pending + set_telegram_message_id + approval ping send (test-first); phrase validation
5837c5d 2026-06-10: Correct stale Keychain status — migration verified complete
a177fb2 2026-06-09: Refine C.5 scope — plain-approve default + stop/halt command (kill switch)
f3ab954 2026-06-09: Add Trust Boundary / Prompt-Injection Defense doctrine (foundational, binding all phases)
3aba423 2026-06-09: Add pre-C.5 audit note to BUILD_STATE Notes
0725f9d 2026-06-09: Pre-C.5 independent audit report
a9ae6c2 2026-06-09: Lock C.5 scope (ingestion + reply-to); split wakeup to C.6
634b9e4 2026-06-09: Wire NOTIFY-tier tool notifications into executor (INFORMATIONAL, log-only)
edf06bc 2026-06-09: Add standalone Telegram smoke-test script (manual run-once)
4ff551d BUILD_STATE: reviewer Medium #3 (plaintext chat ID) closed
8e7ff16 2026-06-09: Scrub plaintext Telegram chat ID; add scanner heuristic (closes reviewer Medium #3)
a67314e BUILD_STATE: mark all C.4 entry conditions resolved; update HANDOFF_BRIEF
a78a98e Guard-rail tests: run_shell fence, write_file tier, bundle execution
598fd45 Fix 4 (LOW): approval-creation idempotency under crash-retry
```

## Repo tree (no node_modules / .secrets / state)
```
.gitignore
00_TEARDOWN.md
01_PICK_UP_WORK.md
CONTROL.md
README.md
SETUP.md
WORKER_PROTOCOL.md
docs/OPENCLAW_BUILD_PLAN.md
docs/OPENCLAW_DECISIONS_AND_ADDITIONS.md
docs/OPENCLAW_DEEP_DIVE_CONFIG.md
docs/OPENCLAW_ECOSYSTEM_AND_COVERAGE.md
docs/OPENCLAW_FIELD_NOTES.md
docs/OPENCLAW_RESEARCH_ADDENDUM.md
docs/PRIOR_BUILD_LEARNINGS.md
scripts/bundle-for-claude.sh
scripts/end-session.sh
scripts/secret-scan.sh
scripts/start-session.sh
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
- [ ] **ClawGuard source read** (Phase 2) — before it carries audit integrity. Custom hash-chain fallback ready.
- [ ] **Browser `fill` tool-side secret resolution test** (Phase 6) — does fill resolve a SecretRef without returning the value to the LLM?

---

---
_To request a decision: tell Claude which CONTROL.md NEXT or which doc section you need a call on._
