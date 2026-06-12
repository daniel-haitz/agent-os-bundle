# PRIOR_BUILD_LEARNINGS.md — What the first build taught us

The previous Agent OS build (custom Python, torn down) wasn't wasted — it produced hard-won lessons. These carry into the OpenClaw build regardless of foundation. Workers should internalize these.

## Process learnings (why this workflow exists)

1. **The human must not be the integration layer.** The old flow had Daniel SSHing files, pasting between Claude and ChatGPT, downloading bundles. That was the #1 source of slowness and drift. → This workflow makes the repo the courier.

2. **Prompt-vs-file truth ambiguity causes drift.** When a rich prompt summarized the files, workers assumed the prompt was truth and the files were stale. They weren't. → CONTROL.md is the ONLY truth; drops are pointers to it, never substitutes.

3. **Claude.ai is the wrong tool for ops debugging.** Shell quoting, Keychain semantics, Telegram setup burned expensive Claude tokens on cheap problems. → Codex/Claude-Code on the mini do ops; Claude.ai is the rare architecture/security consultant.

4. **One bounded task per session.** Scope creep produced messy handoffs. Workers that did "the next two steps" left unclear state. → NEXT is always exactly one step.

5. **Verification discipline.** Daniel repeatedly caught Claude asserting things without verifying. → "Claims must be checked before stated as fact." The three open verification gates exist because of this.

6. **Pressure-testing over validation.** Daniel wants gaps found, not encouragement. → Workers should surface problems, not paper over them. A correct STOP beats a confident wrong build.

## Technical learnings (carry into OpenClaw)

7. **Runtime output is a secret surface.** The token-in-logs incident: httpx logged the bot token in the getUpdates URL on every poll. The source secret-scanner was blind to it. → secret-scan runs on output/bundles too, not just source. Assume anything resolved is sensitive.

8. **Delivery proof ≠ local exit code.** Notification success must be confirmed at the API level (ok:true), not inferred from a process exiting 0. → carries to any OpenClaw notification/approval wiring.

9. **Doctrine as code, mechanically enforced.** Behavioral rules that rely on "the agent should follow this" fail silently. → tier enforcement lives in OpenClaw's exec.security/ask config + hooks, not in prose the model may ignore.

10. **Fail closed on ambiguity.** Every ambiguous/malformed/unknown input → do nothing, never default toward action. → OpenClaw's ask-fallback=deny aligns; keep this posture everywhere.

11. **Greenfield over migration — when the prior plan was confused.** The old build was a faithful implementation of not-yet-understood requirements. Rebuilding clean was right BECAUSE the thinking, not just the code, was being corrected. → The OpenClaw adoption is the same instinct applied correctly: don't port the confusion.

## The meta-learning

The single biggest miss of the prior build: **nobody searched "OpenClaw" to discover it was a real, mature, MIT-licensed product** — so weeks went into reimplementing what already shipped. → Before building ANY capability, check if the ecosystem already has it (ClawHub, awesome-openclaw, the decisions doc). Evaluate-before-build is now the rule. The docs/ folder captures that evaluation so it doesn't have to be redone.
