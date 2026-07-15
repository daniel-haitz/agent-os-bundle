#!/usr/bin/env bash
# bundle-for-claude.sh
# GOVERNING PRINCIPLE: The public raw URL is the only source of truth for publish success.
# Local success is not success.
#
# Builds a SANITIZED bundle of repo state and pushes it to the PUBLIC bundle repo so
# Claude.ai can fetch it. Canonical reference docs are inlined so a fresh Claude thread
# gets full context without a manual paste.
#
# Usage: ./scripts/bundle-for-claude.sh [--dry-run]
# --dry-run: generate the bundle locally and print a preview; do NOT push.

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) echo "ERROR: unexpected argument: $arg"
       echo "Usage: ./scripts/bundle-for-claude.sh [--dry-run]"
       exit 1 ;;
  esac
done

# ---- config (edit these once) ----
PRIVATE_REPO="${PRIVATE_REPO:-$HOME/agent-os}"
BUNDLE_REPO="${BUNDLE_REPO:-$HOME/agent-os-bundle}"
BUNDLE_FILE="BUNDLE.md"
MANIFEST_FILE="docs/CANONICAL_PUBLICATION_MANIFEST.md"
# ----------------------------------

cd "$PRIVATE_REPO"
VALIDATION_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "ABORT: missing publication manifest: $MANIFEST_FILE"
  exit 1
fi

MANIFEST_PATHS="$(awk '
  /^```text$/ { in_block=1; next }
  /^```$/ && in_block { exit }
  in_block && NF && $0 !~ /^#/ { print }
' "$MANIFEST_FILE")"

if [ -z "$MANIFEST_PATHS" ]; then
  echo "ABORT: publication manifest has no machine-readable paths."
  exit 1
fi

path_declared_in_manifest() {
  local required="$1"
  local entry
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if [ "$entry" = "$required" ]; then
      return 0
    fi
    case "$entry" in
      */)
        case "$required" in
          "$entry"*) return 0 ;;
        esac
        ;;
    esac
  done <<< "$MANIFEST_PATHS"
  return 1
}

CRITICAL_PUBLICATION_PATHS=(
  "CONTROL.md"
  "OPERATING_CONSTITUTION.md"
  "docs/AGENT_OS_ARCHITECTURE_DECISIONS.md"
  "docs/AGENT_OS_CHANGE_CONTROL_STANDARD.md"
  "docs/AGENT_OS_END_STATE_ARCHITECTURE.md"
  "docs/AGENT_OS_GMAIL_RECOVERY_RUNBOOK.md"
  "docs/AGENT_OS_OBLIGATION_REGISTER.md"
  "docs/AGENT_OS_PLATFORM_MECHANICS_REFERENCE.md"
  "docs/AGENT_OS_SECURITY_DESIGN_STANDARD.md"
  "docs/CANONICAL_PUBLICATION_MANIFEST.md"
  "docs/F-A1_GMAIL_BROKER_DESIGN.md"
  "docs/F-A2_PROOF_RUNBOOK.md"
  "docs/F-A4_CUTOVER_RUNBOOK.md"
  "docs/ADR-014_OPENCLAW_2026_6_11_BASELINE.md"
  "audits/F-A0-platform-hardening-audit.md"
  "audits/F-A1-negative-test-results.md"
  "scripts/wrap-up.sh"
  "scripts/bundle-for-claude.sh"
)

for required in "${CRITICAL_PUBLICATION_PATHS[@]}"; do
  if ! path_declared_in_manifest "$required"; then
    echo "ABORT: critical canonical path is not covered by manifest: $required"
    exit 1
  fi
done

PUBLISHED_LIST="$(mktemp /tmp/agent-os-published-files-XXXXXX.txt)"
STALE_CANDIDATES="$(mktemp /tmp/agent-os-stale-published-XXXXXX.txt)"
DRY_RUN_OUT=""
trap 'rm -f "$PUBLISHED_LIST" "$STALE_CANDIDATES" ${DRY_RUN_OUT:-}' EXIT
MISSING_COUNT=0

while IFS= read -r path; do
  [ -z "$path" ] && continue
  case "$path" in
    */)
      if ! git ls-files --error-unmatch "$path"* >/dev/null 2>&1; then
        echo "ABORT: manifest directory has no tracked files: $path"
        MISSING_COUNT=$((MISSING_COUNT + 1))
      else
        git ls-files "$path" >> "$PUBLISHED_LIST"
      fi
      ;;
    *)
      if [ ! -f "$path" ]; then
        echo "ABORT: manifest file missing: $path"
        MISSING_COUNT=$((MISSING_COUNT + 1))
      else
        printf '%s\n' "$path" >> "$PUBLISHED_LIST"
      fi
      ;;
  esac
done <<< "$MANIFEST_PATHS"

sort -u "$PUBLISHED_LIST" -o "$PUBLISHED_LIST"
PUBLISHED_COUNT="$(wc -l < "$PUBLISHED_LIST" | tr -d ' ')"

if [ "$MISSING_COUNT" -ne 0 ]; then
  echo "ABORT: publication manifest validation failed; missing files count: $MISSING_COUNT"
  exit 1
fi

if [ "$PUBLISHED_COUNT" -eq 0 ]; then
  echo "ABORT: publication manifest expanded to zero files."
  exit 1
fi

MANIFEST_COMMIT="$(git log -1 --format=%H -- "$MANIFEST_FILE")"
WRAP_UP_COMMIT="$(git log -1 --format=%H -- scripts/wrap-up.sh)"
BUNDLE_SCRIPT_COMMIT="$(git log -1 --format=%H -- scripts/bundle-for-claude.sh)"

# 1. Hard secret scan BEFORE anything leaves the private repo.
echo "Scanning for secrets before bundling..."
if [ -f scripts/secret-scan.sh ]; then
  ./scripts/secret-scan.sh || { echo "ABORT: secret scan failed. Nothing bundled."; exit 1; }
fi

# 2. Write the bundle — CONTROL.md + git state + manifest-declared canonical files inline.
if [ "$DRY_RUN" = true ]; then
  OUT="$(mktemp /tmp/bundle-dry-run-XXXXXX.md)"
  DRY_RUN_OUT="$OUT"
else
  OUT="$BUNDLE_REPO/$BUNDLE_FILE"
fi

{
  echo "# AGENT OS — STATE BUNDLE FOR CLAUDE"
  echo "_Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ) · commit: $(git rev-parse --short HEAD)_"
  echo ""
  echo "This is a sanitized snapshot for Claude.ai review. Secrets are excluded by .gitignore + scan."
  echo ""
  echo "---"

  echo "## CONTROL.md (current state)"
  echo '```markdown'
  cat CONTROL.md
  echo '```'
  echo ""

  echo "## Recent git log (20)"
  echo '```'
  git log --oneline -20
  echo '```'
  echo ""

  echo "## Repo tree (no node_modules / .secrets / state)"
  echo '```'
  git ls-files | grep -vE '(^\.secrets/|node_modules/|^state/)' | head -200
  echo '```'
  echo ""

  echo "## Tests status (last run, if recorded)"
  echo '```'
  [ -f TEST_STATUS.txt ] && cat TEST_STATUS.txt || echo "(no TEST_STATUS.txt — run tests and record)"
  echo '```'
  echo ""

  echo "## Open verification gates"
  awk '/^## Open verification gates$/{found=1} found{print} found && /^## / && $0 !~ /^## Open verification gates$/{exit}' CONTROL.md
  echo ""

  echo "## Publication validation"
  echo '```text'
  echo "manifest commit: $MANIFEST_COMMIT"
  echo "published files: $PUBLISHED_COUNT"
  echo "missing files count: $MISSING_COUNT"
  echo '```'
  echo ""

  echo "## Governance enforcement"
  echo '```text'
  echo "wrap-up.sh commit: $WRAP_UP_COMMIT"
  echo "bundle-for-claude.sh commit: $BUNDLE_SCRIPT_COMMIT"
  echo "last validation timestamp: $VALIDATION_TS"
  echo '```'
  echo ""

  echo "---"
  echo "## Canonical publication manifest"
  echo '```markdown'
  cat "$MANIFEST_FILE"
  echo '```'
  echo ""

  echo "## Canonical published files"
  echo ""

  while IFS= read -r file; do
    echo "### $file"
    echo '```markdown'
    cat "$file"
    echo '```'
    echo ""
  done < "$PUBLISHED_LIST"

  echo "---"
  echo "_To request a decision: tell Claude which CONTROL.md NEXT or which doc section you need a call on._"
} > "$OUT"

# 3. Dry-run exits here — show preview, print size.
if [ "$DRY_RUN" = true ]; then
  LINES=$(wc -l < "$OUT" | tr -d ' ')
  BYTES=$(wc -c < "$OUT" | tr -d ' ')
  echo ""
  echo "=== DRY RUN — bundle generated, NOT pushed ==="
  echo "Size: ${LINES} lines / ${BYTES} bytes"
  echo "Preview (first 25 lines):"
  echo "---"
  head -25 "$OUT"
  echo "..."
  echo "=== END PREVIEW ==="
  echo "(Full bundle in $OUT — inspect before pushing)"
  exit 0
fi

# 4. Publish manifest-declared files. Managed publication paths are reconciled to
# the manifest so stale mirror artifacts do not survive refactors.
while IFS= read -r file; do
  mkdir -p "$BUNDLE_REPO/$(dirname "$file")"
  cp "$PRIVATE_REPO/$file" "$BUNDLE_REPO/$file"
done < "$PUBLISHED_LIST"

# 5. Commit + push the public bundle.
cd "$BUNDLE_REPO"
git ls-files CONTROL.md OPERATING_CONSTITUTION.md docs audits scripts > "$STALE_CANDIDATES" || true
while IFS= read -r tracked; do
  [ -z "$tracked" ] && continue
  if ! grep -Fxq "$tracked" "$PUBLISHED_LIST"; then
    git rm -q --ignore-unmatch "$tracked"
  fi
done < "$STALE_CANDIDATES"

git add "$BUNDLE_FILE"
while IFS= read -r file; do
  git add "$file"
done < "$PUBLISHED_LIST"
git commit -m "bundle: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null 2>&1 \
  || { echo "  (bundle unchanged — no new commit needed)"; }
git push -q

# 6. Print cache-proof raw URL.
REMOTE_URL=$(git remote get-url origin)
SLUG=$(echo "$REMOTE_URL" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
BRANCH=$(git rev-parse --abbrev-ref HEAD)
CACHE_BUSTER=$(git rev-parse --short HEAD)
echo ""
echo "=== PASTE THIS URL TO CLAUDE ==="
echo "https://raw.githubusercontent.com/$SLUG/$BRANCH/$BUNDLE_FILE?v=$CACHE_BUSTER"
echo ""
echo "Docs base URL:"
echo "https://raw.githubusercontent.com/$SLUG/$BRANCH/docs/"
echo "================================"
