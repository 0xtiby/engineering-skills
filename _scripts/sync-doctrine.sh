#!/usr/bin/env bash
# Regenerates derived doctrine artifacts from tiby-skills/_doctrine/.
#
#   sync-doctrine.sh           Write derived files (overwrite).
#   sync-doctrine.sh --check   Exit non-zero if derived files don't match what would be written.
#
# Derived artifacts:
#   1. tdd/{tests,mocking,interface-design,deep-modules,refactoring}.md  (verbatim copies)
#   2. code-review/CODE_REVIEW.md  (verbatim copy)
#   3. _templates/CODING_STANDARDS.md  (assembled from _doctrine/*.md)
#   4. _templates/CODE_REVIEW.md  (verbatim copy)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCTRINE="$ROOT/_doctrine"
TDD_BUNDLE="$ROOT/tdd"
CODE_REVIEW_BUNDLE="$ROOT/code-review"
TEMPLATE_STANDARDS="$ROOT/_templates/CODING_STANDARDS.md"
TEMPLATE_REVIEW="$ROOT/_templates/CODE_REVIEW.md"

mode="${1:-write}"

# --- Build CODING_STANDARDS.md content in memory ---
build_standards() {
  cat <<'EOF'
---
title: Coding Standards
---

# Coding Standards

Doctrine for human and AFK work in this repo. Read by the `/tdd` skill, by `.looper/PROMPT_BUILD.md`, and by humans before writing code.

This file is the **single source of doctrine in the repo**. If a skill bundles fallback defaults, this file overrides them when present.

EOF
  for section in tdd tests mocking interface-design deep-modules refactoring; do
    echo
    echo "---"
    echo
    cat "$DOCTRINE/$section.md"
  done
}

# --- Decide what to do per file ---
sync_or_check() {
  local src="$1" dest="$2"
  if [ "$mode" = "--check" ]; then
    if ! diff -q "$src" "$dest" >/dev/null 2>&1; then
      echo "DRIFT: $dest does not match $src" >&2
      return 1
    fi
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "wrote $dest"
  fi
}

sync_or_check_inline() {
  local content="$1" dest="$2"
  if [ "$mode" = "--check" ]; then
    if ! diff -q <(printf '%s' "$content") "$dest" >/dev/null 2>&1; then
      echo "DRIFT: $dest does not match assembled output" >&2
      return 1
    fi
  else
    mkdir -p "$(dirname "$dest")"
    printf '%s' "$content" > "$dest"
    echo "wrote $dest"
  fi
}

drift=0

# tdd skill bundle sidecars
for f in tests mocking interface-design deep-modules refactoring; do
  sync_or_check "$DOCTRINE/$f.md" "$TDD_BUNDLE/$f.md" || drift=1
done

# code-review skill bundle sidecar (fallback when no repo CODE_REVIEW.md)
sync_or_check "$DOCTRINE/code-review.md" "$CODE_REVIEW_BUNDLE/CODE_REVIEW.md" || drift=1

# CODING_STANDARDS.md template
standards="$(build_standards)"
sync_or_check_inline "$standards" "$TEMPLATE_STANDARDS" || drift=1

# CODE_REVIEW.md template (single-file copy from doctrine)
sync_or_check "$DOCTRINE/code-review.md" "$TEMPLATE_REVIEW" || drift=1

if [ "$mode" = "--check" ] && [ $drift -ne 0 ]; then
  echo "Doctrine drift detected. Run sync-doctrine.sh to fix." >&2
  exit 1
fi
