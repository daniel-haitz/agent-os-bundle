# Sandbox and Container Kill-Switch Discovery

**Date:** 2026-06-12  
**Installed OpenClaw version:** 2026.6.5  
**Verdict:** **NO-GO — Docker prerequisite absent.**

The Docker presence gate failed. Per DROP 1.4-discovery's hard-gate rule, technical
discovery stopped after Task 1. No sandbox was enabled, no container was created, no
OpenClaw configuration changed, and no permission repair was attempted.

## Task 0 — Pending Push

**SETTLED.** Commit `ea1e3f0` (Phase 1.5 kill-switch verification) was pushed to
`origin/main`. The branch was clean and synchronized immediately after the push.

## Task 1 — Docker Presence Gate

**SETTLED: ABSENT.**

Observed:

- `command -v docker` returned no path.
- `docker version`, `docker info`, `docker ps`, and `docker images` all failed with
  `command not found: docker`.
- `/var/run/docker.sock` does not exist.
- There is therefore no accessible Docker daemon and no Docker-backed OpenClaw sandbox
  image to inspect.
- `openclaw sandbox list --json` could not run because the existing
  `EPERM: chmod ~/.openclaw/state` regression stopped CLI startup. This does not alter
  the Docker conclusion: both the binary and daemon socket are absent independently.

## Blocked Work

The following work was not performed because the drop explicitly required stopping after
the Docker gate:

- **Container kill-switch live test:** not run. There was no container runtime in which
  to start or kill the inert workload.
- **Sandbox configuration map:** not continued. The rogue-container and Codex nesting
  questions remain open for a future discovery pass after a container runtime exists.
- **EPERM root-cause diagnostic:** not continued. The known EPERM flag remains unresolved;
  no `chmod` or `chown` was run.
- **Tracked `openclaw.json` secret inspection:** not continued in this drop. Prior Phase 0
  SecretRef work and audits remain the current evidence, but Task 5 was not re-verified.

## Prerequisite Decision

Before Phase 1.4 can proceed, the operator must choose whether to install and operate a
Docker-compatible runtime on the mini. Installation is explicitly outside this drop.

After that decision and installation, rerun 1.4 discovery from Task 1 and complete:

1. Daemon/socket/access verification.
2. Throwaway-container `docker kill` proof against an in-flight inert process.
3. Exact OpenClaw sandbox mode/scope/exec-host mapping.
4. Codex nested-sandbox compatibility assessment.
5. Host-home mount isolation confirmation.
6. EPERM ownership/mode diagnosis.
7. Tracked-config secret re-verification.

## State and Cleanup

- No sandbox or OpenClaw config was changed.
- No container or `/tmp` test artifact was created.
- No permission mutation was applied.
- The previously tracked OpenClaw drift baseline remained clean before the Docker gate.
