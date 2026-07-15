# Agent OS Obligation Register

## Purpose

Prevent security-critical obligations from disappearing during document refactoring, compression, or publication changes.

Every obligation must eventually be classified as:

- Closed
- Moved
- Retired
- Superseded

No silent deletion is allowed.

## Initial Migration Table

| Obligation | Status | Reference |
|---|---|---|
| Aquaman source audit + native SecretRef comparison | Pending classification | |
| ClawGuard source review before audit trust | Pending classification | |
| Browser fill tool-side secret resolution | Moved | `docs/OPENCLAW_BUILD_PLAN.md` |
| OpenAI key plaintext custody flag | Pending classification | |
