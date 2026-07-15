# Agent OS Gmail Credential Recovery Runbook

**Status:** Approved recovery governance. This document does not authorize a recovery operation; every recovery requires explicit, incident-specific operator approval.

## Purpose

This runbook governs break-glass recovery of the Gmail credentials used by the Agent OS Gmail broker.

Recovery restores service without weakening the established credential-custody boundary. Availability does not take priority over broker custody, least privilege, auditability, or post-recovery validation.

## Authority and stop conditions

- Only the human operator may authorize access to the encrypted backup or use of its passphrase.
- AI agents, OpenClaw agents, the `agent` account, and the `openclawgw` account do not gain recovery authority from access to this document, prior conversations, memory, or tool availability.
- Recovery must have an explicitly approved scope, rollback plan, temporary working location, cleanup plan, and validation plan before decryption.
- If observed runtime state, `CONTROL.md`, this runbook, or the approved broker architecture conflict, stop mutation and reconcile them first.
- If recovery would place Gmail credentials in any agent-readable location, stop. That action reopens the Gmail security boundary and requires explicit architecture review before proceeding.

## Encrypted backup record

The retained break-glass backup is:

```text
/Users/agent/.openclaw/credential-backups/fa2-p2-agent-gmail-originals-20260618T021538Z.tar.age
```

The backup uses age passphrase encryption.

- The passphrase is operator-held only.
- The passphrase must not be stored in Agent OS files, OpenClaw configuration, agent memory, shell history, logs, tickets, chat messages, environment files, or the macOS Keychain.
- The passphrase is the sole recovery key for this backup. If it is lost, the backup is unrecoverable.
- Do not delete or replace the encrypted backup except through a separate, deliberate operator-approved retention decision.
- Do not transmit the encrypted backup or decrypted contents to an AI service, connector, plugin, remote workspace, or unapproved host.

## Break-glass recovery process

### 1. Observe and document

Before mutation:

1. Confirm the failure is a credential-recovery problem rather than a socket, launchd, permissions, keyring-backend, proxy, connector, or upstream-service problem.
2. Record the observed failure, affected service, current ownership and modes, and relevant sanitized error evidence.
3. Confirm the current phase, blockers, and sensitive-data hold in `CONTROL.md`.
4. Inventory the current broker credential state without exposing secret material.
5. Define the exact files to restore, the intended broker-owned destination, rollback, and post-recovery tests.

### 2. Approve the bounded recovery

The operator must explicitly approve:

- use of the encrypted backup;
- the broker-owned destination;
- the temporary working directory;
- the identities permitted to access plaintext;
- rollback and cleanup;
- the required validation plan.

Approval to recover service does not authorize broader Gmail scopes, new connectors, agent-readable credentials, credential migration, or architecture changes.

### 3. Prepare protected handling

- Use an operator-controlled local temporary directory that is not under an Agent OS workspace, OpenClaw state directory, synchronized folder, or connector-visible location.
- Restrict the temporary directory to the operator or root before decryption.
- Keep decrypted files owner-only.
- Do not place the passphrase in command arguments, persistent environment files, shell history, logs, or scripts.
- Do not print, inspect through an AI tool, or copy plaintext credential contents into diagnostic output.
- If an encrypted backup of the current broker credential state is needed for rollback, create it under separate operator custody before replacement.

### 4. Restore only to broker custody

- Restore only the credential material required by the approved Gmail broker.
- The final credential destination must be owned by `gmailbroker` and inaccessible to `agent`, `openclawgw`, and other unapproved identities.
- Apply owner-only file and directory permissions appropriate to the broker credential store.
- Preserve the approved Gmail-only scope posture. Scope expansion requires separate approval and architecture review.
- Do not restore legacy direct wrappers, general Gmail clients, connector credentials, or agent-readable fallback paths.
- Do not modify OpenClaw configuration, connectors, approval policy, egress policy, launchd services, or broker capabilities as an incidental part of credential recovery.

### 5. Remove plaintext recovery material

After the broker-owned copy is installed and before normal operation resumes:

1. Remove decrypted temporary files and temporary working directories.
2. Clear transient passphrase variables or input channels.
3. Confirm no plaintext copies remain in shell history, logs, workspaces, synchronized storage, `/tmp`, or operator tooling.
4. Preserve only the approved encrypted backup and any separately approved encrypted rollback artifact.

## Required post-recovery validation

Recovery is incomplete until all applicable checks pass:

1. Confirm the broker credential tree is owned by `gmailbroker` with owner-only permissions.
2. Confirm `agent` cannot read the recovered credential material.
3. Confirm `openclawgw` cannot read the recovered credential material.
4. Confirm the broker runs as `gmailbroker`.
5. Confirm `/var/run/agent-os` and the Gmail broker socket retain their approved ownership and modes.
6. Run broker `health_check` successfully.
7. Run broker `search_threads` successfully without exposing message content in validation output.
8. Confirm the broker exposes only its approved semantic capability set and no send operation.
9. Confirm direct main execution remains approval-gated and that denial blocks execution.
10. Confirm no legacy wrapper, alternate Gmail client, restored credential copy, or recovery fallback has become reachable by an agent.
11. Confirm audit output and recovery logs contain no passphrase, token, decrypted credential, full message body, or draft body.
12. Restart the relevant broker service and repeat health, search, ownership, and denial checks.
13. Reconcile `CONTROL.md` with the verified outcome, remaining blockers, backup disposition, and any boundary reopened during recovery.

The known Codex Apps Gmail connector blocker remains separate from credential recovery. Recovery does not prove broker-only Gmail mediation and does not lift the sensitive-data hold while that connector surface remains available.

## Failure and rollback

- If any custody, permission, capability, denial, cleanup, or restart check fails, stop normal operation.
- Restore the pre-recovery broker state when the approved rollback permits it, or leave the broker stopped and document the blocker.
- Do not weaken permissions, restore credentials to an agent-readable path, enable a direct connector, or broaden Gmail scopes to make validation pass.
- Any deviation from broker-only custody requires explicit architecture review and a new approved recovery plan.

## Recovery record

The operator must retain a secret-free recovery record containing:

- incident and approval reference;
- recovery date and operator;
- backup identifier, without passphrase or secret contents;
- files and destinations changed;
- backup and rollback locations;
- ownership and mode results;
- validation commands and sanitized results;
- cleanup confirmation;
- remaining blockers;
- documentation reconciliation and commit reference.
