# Doctrine — canonical source

This directory holds the canonical engineering doctrine for the personal harness. Files here are the **single source of truth**; all other copies are derived.

## Files

- `tdd.md` — TDD philosophy, horizontal-slice anti-pattern, RGR workflow. AFK-safe (no "confirm with user" gates).
- `tests.md` — good vs bad tests with examples.
- `mocking.md` — mock at system boundaries only; designing for mockability.
- `interface-design.md` — accept dependencies, return results, small surface area.
- `deep-modules.md` — small interface + deep implementation.
- `refactoring.md` — refactor candidate checklist.
- `code-review.md` — reviewer's checklist: philosophy, doctrine alignment, language standards, feedback style, output format.

## Derived artifacts

`_scripts/sync-doctrine.sh` regenerates four artifacts from these files:

1. **`tdd/{tests,mocking,interface-design,deep-modules,refactoring}.md`** — direct copies into the `tdd` skill bundle (fallback when no repo `CODING_STANDARDS.md` exists).
2. **`code-review/CODE_REVIEW.md`** — direct copy into the `code-review` skill bundle (fallback when no repo `CODE_REVIEW.md` exists).
3. **`_templates/CODING_STANDARDS.md`** — concatenation in this order: `tdd.md` → `tests.md` → `mocking.md` → `interface-design.md` → `deep-modules.md` → `refactoring.md`, joined with `\n---\n` separators and a top-level frontmatter header. Written into target repos by `/setup-harness`.
4. **`_templates/CODE_REVIEW.md`** — direct copy of `code-review.md`. Written into target repos by `/setup-harness`.

CI / pre-commit runs `sync-doctrine.sh --check` to fail if copies have drifted.

## Editing rule

**Always edit files in `_doctrine/` first**, then run `sync-doctrine.sh` to regenerate the derived copies. Never edit `tdd/<sidecar>.md`, `code-review/CODE_REVIEW.md`, or anything in `_templates/` directly — those edits will be lost on the next sync.

## Provenance

`tests.md`, `mocking.md`, `interface-design.md`, `deep-modules.md`, `refactoring.md` are verbatim copies from Matt Pocock's `tdd` skill (`mattpocock/skills/skills/engineering/tdd/`). `tdd.md` is extracted from the same skill's SKILL.md, with HITL-specific lines removed (no "confirm with user", no "get user approval"). Future edits diverge as needed.
