# AGENT OS — STATE BUNDLE FOR CLAUDE
_Generated: 2026-06-12T02:14:29Z · commit: 38bd551_

This is a sanitized snapshot for Claude.ai review. Secrets are excluded by .gitignore + scan.

---
## CONTROL.md (current state)
```markdown
# CONTROL.md — Single Source of Truth

**This is the ONLY state file. Every worker reads this first and updates it last.**
**If it's not in this file, it didn't happen. The repo is truth, not any prompt or any brain's memory.**

---

## NOW (where we are this exact moment)

**Phase:** 0 — Clean stand-up (not started)
**Last worker:** — (none yet)
**Last commit:** — (none yet)
**Repo clean:** yes
**Blockers:** none

---

## NEXT (the single bounded task the next worker does)

> Phase 0, Step 0.1 — Install OpenClaw on the mini, pin version ≥2026.2.12, verify Node 22+.
> Acceptance: `openclaw --version` prints ≥2026.2.12; `node --version` ≥22.
> Do NOT proceed to 0.2 in the same session — one bounded step, then update this file.

---

## DONE (reverse chronological — newest first, one line each)

<!-- Workers append here. Format: YYYY-MM-DD | worker | what shipped | commit -->

---

## DECISIONS LOG (only real decisions / direction changes — not routine progress)

<!-- Format: YYYY-MM-DD | decision | one-line why -->
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
932594c Fix 3 (MEDIUM) + Fix 5 (LOW): write_file -> NOTIFY tier; audit blocked calls
c37107c Fix 2 (MEDIUM): real Telegram transport, secrets-safe
```

## Repo tree (no node_modules / .secrets / state)
```
.gitignore
.python-version
AGENT_OS_PLAN.md
BUILD_STATE.md
HANDOFF_BRIEF.md
ITERATION_LOG.md
README.md
audits/2026-06-09-pre-c4-audit.md
audits/2026-06-09-pre-c5-audit.md
docs/external_reviewer_workflow.md
docs/phase-a7-baseline.md
doctrine/closure.md
doctrine/constitution.md
doctrine/skills/README.md
doctrine/skills/buela_fail_response.md
doctrine/skills/coding.md
doctrine/skills/command_center.md
doctrine/skills/handoff.md
doctrine/skills/morning_brief.md
doctrine/skills/research.md
doctrine/skills/self_assignment.md
doctrine/tiers.md
doctrine/write_file_tier.md
evals/cases/closure_doctrine_001.yaml
evals/cases/closure_doctrine_002.yaml
evals/cases/closure_doctrine_003.yaml
evals/runner.py
learnings/.gitkeep
main.py
pyproject.toml
scripts/check_backup_health.sh
scripts/create_review_bundle.sh
scripts/install_hooks.sh
scripts/prove_c5_live.py
scripts/send_test_notification.py
src/__init__.py
src/agent/__init__.py
src/agent/graph.py
src/agent/safeguards.py
src/approvals/__init__.py
src/approvals/store.py
src/audit/__init__.py
src/audit/log.py
src/backup/__init__.py
src/backup/health.py
src/hooks/__init__.py
src/hooks/post_tool_use.py
src/hooks/pre_tool_use.py
src/llm/__init__.py
src/llm/router.py
src/notifications/__init__.py
src/notifications/models.py
src/notifications/router.py
src/notifications/store.py
src/notifications/telegram.py
src/notifications/telegram_poller.py
src/security/__init__.py
src/security/keychain.py
src/security/secrets.py
src/skills.py
src/state/__init__.py
src/state/models.py
src/state/trust.py
src/tools/__init__.py
src/tools/executor.py
src/tools/filesystem.py
src/tools/idempotency.py
src/tools/registry.py
tests/test_approvals.py
tests/test_audit_log.py
tests/test_backup_health.py
tests/test_c5a.py
tests/test_c5b.py
tests/test_closure_doctrine.py
tests/test_constitution.py
tests/test_executor.py
tests/test_filesystem_tools.py
tests/test_graph.py
tests/test_hooks.py
tests/test_idempotency.py
tests/test_llm_router.py
tests/test_notifications.py
tests/test_poller_logging.py
tests/test_review_bundle.py
tests/test_safeguards.py
tests/test_secrets_scan.py
tests/test_skills.py
tests/test_state.py
tests/test_telegram_transport.py
tests/test_trust.py
uv.lock
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
