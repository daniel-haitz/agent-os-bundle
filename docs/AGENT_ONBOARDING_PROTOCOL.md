# Agent OS External Agent Onboarding Protocol

## Audience

This protocol is for a fresh external AI agent that receives only the public raw Agent OS bundle URL.

The bundle is the agent's input context. Do not rely on prior chat memory, operator summaries, or inferred state.

## Authority Hierarchy

Use this order when sources conflict:

1. Live runtime evidence for observed facts, when actually available to the agent.
2. `CONTROL.md` for accepted current state, phase status, blockers, and approved next action.
3. `OPERATING_CONSTITUTION.md` and `docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md` for conduct and change discipline.
4. `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md` and other canonical architecture documents for settled design.
5. Historical status, handoff, runbook, and audit documents as context only unless `CONTROL.md` reactivates them.

A web-only external agent has no live runtime authority unless live evidence is separately supplied in the bundle or prompt. Documentation records validated reality; it is not runtime proof.

## Mandatory Reading Order

1. This onboarding protocol.
2. `CONTROL.md`.
3. `OPERATING_CONSTITUTION.md`.
4. `docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md`.
5. `docs/AGENT_OS_ARCHITECTURE_DECISIONS.md`.
6. Evidence and runbooks referenced by `CONTROL.md` for the current phase.

## Required First Response

Before proposing or executing work, report:

1. governing rules;
2. documented runtime baseline, clearly distinguished from live verification;
3. current phase;
4. completed phases and evidence limits;
5. active blockers;
6. approved next bounded action;
7. conflicts, stale references, and evidence gaps.

## Prohibitions

Do not:

- execute commands or request runtime changes;
- redesign architecture;
- reopen settled decisions without new runtime evidence;
- treat documentation as runtime proof;
- claim closure from partial evidence;
- trust prior chat memory over canonical bundle material;
- treat historical handoff or status documents as current instructions when they conflict with `CONTROL.md`.

## Stop Conditions

Stop and report the conflict or evidence gap if:

- `CONTROL.md` and another document disagree about current phase, blockers, or next action;
- a required canonical document is missing from the bundle;
- evidence is historical, provisional, or pending reconstruction and a closure claim depends on it;
- a requested action exceeds the approved scope in `CONTROL.md`;
- live runtime state is required but not available to the external agent.
