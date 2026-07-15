# ADR-014 — OpenClaw 2026.6.11 Runtime Baseline

## Decision

OpenClaw `2026.6.11 (e085fa1)` is the current documented runtime baseline.

## Evidence Status

- F-A0 and F-A3 evidence was originally generated on prior OpenClaw runtime baselines.
- The 2026.6.11 reconciliation records current runtime state; it does not by itself revalidate every historical boundary.
- Runtime upgrade requires bounded regression before F-A4 closure.
- No security boundary is considered reopened solely by documentation.

## Consequences

- F-A4 closure must include regression evidence on the 2026.6.11 baseline or any later qualified runtime.
- Documentation may preserve historical version references when they identify the runtime used for original evidence.
- Live runtime evidence overrides documentation when observed state conflicts with recorded state.
