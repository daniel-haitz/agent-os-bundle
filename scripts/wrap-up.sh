#!/usr/bin/env bash
# wrap-up.sh — Session-close command
#
# GOVERNING PRINCIPLE: GitHub remote state via git protocol is the source of
# truth for publication verification when reachable. Local success is not
# authoritative remote verification.
#
# Runs the full session-close sequence and PROVES the public mirror is current:
#   1. State-freshness check  — prompt if CONTROL.md looks untouched; never block on commit timing
#   2. Secret scan
#   3. Commit staged changes  — structured message, only if something is staged
#   4. Push private repo
#   5. Regenerate + push public bundle  (calls bundle-for-claude.sh)
#   6. VERIFY public bundle state via git protocol when reachable and local bundle content.
#
# Usage:
#   ./scripts/wrap-up.sh "what shipped"
#   ./scripts/wrap-up.sh --dry-run ["what shipped"]
#
# --dry-run: skip all pushes; regenerate bundle locally and show a preview.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# ── Parse arguments ─────────────────────────────────────────────────────────
SUMMARY=""
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *)
      if [ -z "$SUMMARY" ]; then
        SUMMARY="$arg"
      else
        echo "ERROR: unexpected argument: $arg"
        echo "Usage: ./scripts/wrap-up.sh [--dry-run] \"what shipped\""
        exit 1
      fi
      ;;
  esac
done

if [ -z "$SUMMARY" ] && [ "$DRY_RUN" = false ]; then
  echo "ERROR: provide a one-line summary of what shipped."
  echo "Usage: ./scripts/wrap-up.sh [--dry-run] \"what shipped\""
  exit 1
fi

BUNDLE_REPO="${BUNDLE_REPO:-$HOME/agent-os-bundle}"
PUBLIC_URL="https://raw.githubusercontent.com/daniel-haitz/agent-os-bundle/main/BUNDLE.md"

fail_wrapup() {
  echo "BLOCKED: $1"
  exit 1
}

check_runtime_baseline() {
  EXPECTED="$(sed -n 's/^- Installed OpenClaw version last verified.*: `OpenClaw \(.*\)`\.$/\1/p' CONTROL.md | head -1)"
  [ -n "$EXPECTED" ] || fail_wrapup "CONTROL.md has no parseable OpenClaw runtime baseline."
  ACTUAL="$(PATH=/Users/agent/.local/bin:$PATH openclaw --version 2>/dev/null | sed 's/^OpenClaw //')"
  [ -n "$ACTUAL" ] || fail_wrapup "openclaw --version unavailable; cannot verify runtime baseline."
  [ "$ACTUAL" = "$EXPECTED" ] || fail_wrapup "OpenClaw baseline drift: CONTROL.md=$EXPECTED live=$ACTUAL"
}

check_closed_phase_evidence() {
  for phase in F-A0 F-A1 F-A2 F-A3; do
    block="$(awk -v p="$phase" '
      $0 ~ "^- " p " " { found=1 }
      found && /^- F-A[0-9]/ && $0 !~ "^- " p " " { exit }
      found { print }
    ' CONTROL.md)"
    evidence_line="$(printf '%s\n' "$block" | grep -m1 "Evidence location:" || true)"
    validation_line="$(printf '%s\n' "$block" | grep -m1 "Validation date:" || true)"
    baseline_line="$(printf '%s\n' "$block" | grep -m1 "Runtime baseline:" || true)"
    status_line="$(printf '%s\n' "$block" | grep -m1 "Status:" || true)"

    [ -n "${evidence_line#*: }" ] && [ "$evidence_line" != "${evidence_line#*: }" ] || fail_wrapup "$phase missing evidence location."
    [ -n "${validation_line#*: }" ] && [ "$validation_line" != "${validation_line#*: }" ] || fail_wrapup "$phase missing validation date."
    [ -n "${baseline_line#*: }" ] && [ "$baseline_line" != "${baseline_line#*: }" ] || fail_wrapup "$phase missing runtime baseline."
    [ -n "${status_line#*: }" ] && [ "$status_line" != "${status_line#*: }" ] || fail_wrapup "$phase missing evidence status."

    printf '%s\n' "$validation_line" | grep -Eqi '202[0-9]-[0-9]{2}-[0-9]{2}|pending reconstruction|historical validation artifacts' \
      || fail_wrapup "$phase validation date lacks date or explicit reconstruction state."
    printf '%s\n' "$baseline_line" | grep -Eqi 'OpenClaw `?202[0-9]\.[0-9]+\.[0-9]+|pending reconstruction|historical validation artifacts' \
      || fail_wrapup "$phase runtime baseline lacks OpenClaw version or explicit reconstruction state."
  done
}

check_open_verification_gates() {
  gate_heading_count="$(grep -c '^## Open verification gates$' CONTROL.md || true)"
  [ "$gate_heading_count" -eq 1 ] || fail_wrapup "CONTROL.md must contain exactly one Open verification gates heading; found $gate_heading_count."

  gates="$(awk '/^## Open verification gates$/{found=1; next} found && /^## /{exit} found {print}' CONTROL.md)"
  printf '%s\n' "$gates" | grep -q '^- ' || fail_wrapup "Open verification gates section is empty."

  blockers="$(awk '/^## Active blockers$/{found=1; next} found && /^## /{exit} found && /^### B[0-9]/ { print $2 }' CONTROL.md)"
  while IFS= read -r blocker; do
    [ -z "$blocker" ] && continue
    printf '%s\n' "$gates" | grep -q "^- $blocker" || fail_wrapup "active blocker $blocker missing corresponding open verification gate."
  done <<< "$blockers"

  if grep -q '| .* | \(Open\|Moved\|Retired\|Superseded\) |' docs/AGENT_OS_OBLIGATION_REGISTER.md; then
    printf '%s\n' "$gates" | grep -qi 'obligation' || fail_wrapup "unresolved obligations exist but Open verification gates does not reference obligations."
  fi

  printf '%s\n' "$gates" | grep -q '2026.6.11' || fail_wrapup "Open verification gates missing required 2026.6.11 runtime validation reference."
}

check_obligation_register() {
  register="docs/AGENT_OS_OBLIGATION_REGISTER.md"
  [ -f "$register" ] || fail_wrapup "missing obligation register."
  awk -F'|' '
    BEGIN { rows=0; bad=0 }
    /^\|/ && $2 !~ /Obligation|---/ {
      rows++
      obligation=$2
      status=$3
      owner=$4
      reference=$5
      evidence=$6
      gsub(/^ +| +$/, "", obligation)
      gsub(/^ +| +$/, "", status)
      gsub(/^ +| +$/, "", owner)
      gsub(/^ +| +$/, "", reference)
      gsub(/^ +| +$/, "", evidence)
      if (obligation == "") {
        print "empty obligation"
        bad=1
      }
      if (status !~ /^(Open|Closed|Moved|Retired|Superseded)$/) {
        print "invalid obligation status: " status
        bad=1
      }
      if (owner == "") {
        print "obligation missing owner: " obligation
        bad=1
      }
      if (reference == "") {
        print "obligation missing canonical reference: " obligation
        bad=1
      }
      if (evidence == "") {
        print "obligation missing evidence: " obligation
        bad=1
      }
    }
    END {
      if (rows == 0) {
        print "obligation register has no rows"
        bad=1
      }
      exit bad
    }
  ' "$register" || fail_wrapup "obligation register schema/status validation failed."
}

echo "→ Running governance wrap-up checks..."
check_runtime_baseline
check_closed_phase_evidence
check_open_verification_gates
check_obligation_register

# ── 1. State-freshness check ─────────────────────────────────────────────────
# Drive off git history, not "is CONTROL.md uncommitted."
# The old end-session.sh guard blocked when CONTROL.md was committed incrementally —
# that pattern must work cleanly here.
#
# "Fresh" = CONTROL.md touched in the last 10 commits (covers multi-commit sessions),
# OR currently staged, OR currently modified.
# If none → operator may have forgotten to update it — prompt, don't block.

CONTROL_RECENT=$(git log -n 10 --name-only --format="" -- CONTROL.md 2>/dev/null || true)
CONTROL_STAGED=$(git diff --cached --name-only -- CONTROL.md)
CONTROL_MODIFIED=$(git diff --name-only -- CONTROL.md)

if [ -z "$CONTROL_RECENT" ] && [ -z "$CONTROL_STAGED" ] && [ -z "$CONTROL_MODIFIED" ]; then
  LAST_TOUCH=$(git log -1 --format="%h %s" -- CONTROL.md 2>/dev/null || echo "<no history>")
  echo ""
  echo "CONTROL.md hasn't changed recently (last touch: ${LAST_TOUCH})."
  printf "Is that right? [y/N] "
  if read -r CONFIRM < /dev/tty 2>/dev/null; then
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo "STOPPED. Reconcile CONTROL.md Current state, Phase status, blockers, and Next actions before wrapping up."
      exit 1
    fi
  else
    echo ""
    echo "STOPPED: non-interactive session and CONTROL.md looks stale."
    echo "Update CONTROL.md Current state, Phase status, blockers, and Next actions, then re-run wrap-up."
    exit 1
  fi
fi

# ── 2. Secret scan ────────────────────────────────────────────────────────────
echo "→ Running secret scan..."
./scripts/secret-scan.sh || { echo "BLOCKED: secret scan failed."; exit 1; }

# ── Dry-run: show plan, touch nothing ────────────────────────────────────────
# --dry-run is fully read-only. It shows what WOULD happen — staged changes
# that would be committed, bundle preview — without any side effects.
if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "=== DRY RUN PLAN ==="
  if ! git diff --cached --quiet; then
    WORKER="${WORKER:-claude-code}"
    echo "Would commit staged changes as:"
    echo "  [${WORKER}] ${SUMMARY:-<no summary provided>}"
    echo ""
    echo "Staged files:"
    git diff --cached --name-status
  else
    echo "Nothing staged; HEAD $(git rev-parse --short HEAD) would be used as bundle marker."
  fi
  echo ""
  echo "Would push private repo then regenerate public bundle:"
  ./scripts/bundle-for-claude.sh --dry-run
  echo ""
  echo "[DRY RUN COMPLETE] No commits, no pushes. Re-run without --dry-run to publish."
  exit 0
fi

# ── 3. Commit staged changes (if any) ────────────────────────────────────────
# We do NOT git add -A — the operator stages what belongs in this commit.
if ! git diff --cached --quiet; then
  WORKER="${WORKER:-claude-code}"
  COMMIT_MSG="[$WORKER] $SUMMARY"
  git commit -m "$COMMIT_MSG"
  echo "→ Committed: $(git rev-parse --short HEAD) — $COMMIT_MSG"
else
  echo "→ Nothing staged; HEAD is $(git rev-parse --short HEAD)"
fi

PRIVATE_HEAD=$(git rev-parse --short HEAD)

# ── 4. Push private repo ──────────────────────────────────────────────────────
git push -q
echo "→ Private repo pushed: $PRIVATE_HEAD"

# ── 5. Regenerate + push public bundle ───────────────────────────────────────
echo "→ Regenerating public bundle..."

if ! ./scripts/bundle-for-claude.sh; then
  echo ""
  echo "+────────────────────────────────────────────────────────────────────────+"
  echo "| PUBLISH FAILURE — bundle-for-claude.sh failed before the push step     |"
  echo "+────────────────────────────────────────────────────────────────────────+"
  echo "  Private repo: $PRIVATE_HEAD (pushed)"
  echo ""
  echo "HAND-FIX STEPS:"
  echo "  1. cd ~/agent-os"
  echo "  2. ./scripts/bundle-for-claude.sh"
  echo "  3. Verify: curl -s '$PUBLIC_URL' | head -3"
  exit 1
fi

# ── 6. VERIFY the push reached GitHub + bundle content is correct ─────────────
# GOVERNING PRINCIPLE: local success is not success.
#
# Two-layer verification — no CDN timing dependency:
# (a) git ls-remote — queries GitHub's git protocol layer in real time. This is
#     authoritative and immediate. GitHub's raw CDN (?v= cache-buster does NOT
#     bypass server-side cache; plain URL can serve stale content for 5+ minutes).
# (b) Local BUNDLE.md content — confirms the file we pushed embeds the correct
#     private HEAD hash. Together these prove: right content is on GitHub.
# The raw URL propagates to CDN within ~5 minutes and is printed for operator use.

BUNDLE_HEAD_LOCAL=$(git -C "$BUNDLE_REPO" rev-parse HEAD)
BUNDLE_HEAD_SHORT=$(git -C "$BUNDLE_REPO" rev-parse --short HEAD)

echo "→ Verifying push reached GitHub and bundle embeds correct commit..."

# (a) Remote HEAD via git protocol (bypasses CDN; returns authoritative state)
BUNDLE_HEAD_REMOTE=$(git -C "$BUNDLE_REPO" ls-remote origin HEAD 2>/dev/null | awk '{print $1}' || true)

PUSH_OK=false
REMOTE_VERIFIED=false
if [ "$BUNDLE_HEAD_REMOTE" = "$BUNDLE_HEAD_LOCAL" ]; then
  PUSH_OK=true
  REMOTE_VERIFIED=true
elif [ -z "$BUNDLE_HEAD_REMOTE" ]; then
  # Remote verification unavailable. Do not claim authoritative remote publication
  # verification; rely only on the clean push exit code and local bundle content.
  PUSH_OK=true
fi

# (b) Local content check — BUNDLE.md must embed the private HEAD we just pushed
LOCAL_BUNDLE_PREFIX=$(head -c 2000 "$BUNDLE_REPO/BUNDLE.md" 2>/dev/null || echo "")
BUNDLE_GENERATED=""
if [[ "$LOCAL_BUNDLE_PREFIX" =~ generated\ timestamp:\ ([0-9TZ:-]+) ]]; then
  BUNDLE_GENERATED="${BASH_REMATCH[1]}"
fi
BUNDLE_COMMIT=""
if [[ "$LOCAL_BUNDLE_PREFIX" =~ private\ source\ repository\ commit:\ ([a-f0-9]+) ]]; then
  BUNDLE_COMMIT="${BASH_REMATCH[1]}"
fi
CONTENT_OK=false
case "$BUNDLE_COMMIT" in
  "$PRIVATE_HEAD"|"$PRIVATE_HEAD"*) CONTENT_OK=true ;;
esac

if [ "$PUSH_OK" = true ] && [ "$CONTENT_OK" = true ]; then
  echo ""
  if [ "$REMOTE_VERIFIED" = true ]; then
    echo "PUBLISH CONFIRMED"
  else
    echo "PUBLISH COMPLETED — REMOTE VERIFICATION UNAVAILABLE"
  fi
  echo "  private HEAD  : $PRIVATE_HEAD (pushed)"
  echo "  bundle HEAD   : $BUNDLE_HEAD_SHORT"
  echo "  remote HEAD   : ${BUNDLE_HEAD_REMOTE:-<ls-remote failed>}"
  echo "  bundle embeds : $BUNDLE_COMMIT (correct)"
  echo "  raw URL (live in ~5 min): $PUBLIC_URL?v=$BUNDLE_HEAD_SHORT"
  echo ""
  NEXT_LINE=$(awk '
    /^## Next actions$/ { found=1; next }
    found && /^## / { exit }
    found && /^### Immediate bounded action$/ { immediate=1; next }
    immediate && NF { print; exit }
  ' CONTROL.md)
  echo "STATUS"
  echo "  did:     ${SUMMARY}"
  echo "  commit:  $PRIVATE_HEAD"
  if [ "$REMOTE_VERIFIED" = true ]; then
    echo "  bundle:  CONFIRMED on GitHub @ $BUNDLE_HEAD_SHORT (embed: $BUNDLE_COMMIT)"
    echo "  flags:   ${FLAGS:-none}"
  else
    echo "  bundle:  pushed locally @ $BUNDLE_HEAD_SHORT; remote verification unavailable (embed: $BUNDLE_COMMIT)"
    echo "  flags:   ${FLAGS:-remote verification unavailable}"
  fi
  echo "  next:    ${NEXT_LINE:-<check CONTROL.md Next actions>}"
  echo ""
  echo "PUBLISHED_REF: $BUNDLE_HEAD_SHORT @ ${BUNDLE_GENERATED:-<generated-unknown>} embeds $BUNDLE_COMMIT"
else
  echo ""
  echo "+────────────────────────────────────────────────────────────────────────+"
  echo "| PUBLISH FAILURE                                                        |"
  echo "+────────────────────────────────────────────────────────────────────────+"
  echo "  push reached GitHub : $PUSH_OK"
  echo "    remote HEAD       : ${BUNDLE_HEAD_REMOTE:-<ls-remote failed>}"
  echo "    local HEAD        : $BUNDLE_HEAD_LOCAL"
  echo "  bundle embeds       : '${BUNDLE_COMMIT:-<parse failed>}' (expected: $PRIVATE_HEAD)"
  echo ""
  echo "HAND-FIX STEPS:"
  echo "  1. cd ~/agent-os"
  echo "  2. ./scripts/bundle-for-claude.sh"
  echo "  3. Verify:"
  echo "     git -C ~/agent-os-bundle ls-remote origin HEAD"
  echo "     head -3 ~/agent-os-bundle/BUNDLE.md"
  echo ""
  echo "If the push keeps failing:"
  echo "  ssh -T git@github.com              (verify SSH key authenticates)"
  echo "  git -C ~/agent-os-bundle status   (check for uncommitted/conflicted state)"
  exit 1
fi
