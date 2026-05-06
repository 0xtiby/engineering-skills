# {{REPO_NAME}}

{{REPO_DESCRIPTION}}

## Stack

- Package manager: {{PACKAGE_MANAGER}}
- Node: {{NODE_VERSION}}
- Default base branch: {{BASE_BRANCH}}

## Commands

Always wrap validation commands with `./scripts/run_silent` so output is suppressed on success and shown on failure.

- `./scripts/run_silent "build" {{BUILD_CMD}}`
- `./scripts/run_silent "lint" {{LINT_CMD}}`
- `./scripts/run_silent "test" {{TEST_CMD}}`
- `./scripts/run_silent "typecheck" {{TYPECHECK_CMD}}`

## Branching

Feature branches → PR to `{{BASE_BRANCH}}`. Worktrees live under `.worktrees/`.

## Agent skills

### Doctrine

Engineering doctrine (TDD, tests, mocking, interface design, deep modules) lives in `CODING_STANDARDS.md`. Read it before writing code. The `/tdd` skill references it; `.looper/PROMPT_BUILD.md` reads it directly.

### Code review

Reviewer doctrine lives in `CODE_REVIEW.md`. The `/code-review` skill reads it before reviewing a PR.

### Domain

Shared domain language: `CONTEXT.md`. Maintained via `/grill-with-docs`.

### Architectural decisions

ADRs live under `docs/adr/NNNN-*.md`. Template at `docs/adr/0000-template.md`.

### Issue tracker

GitHub Issues. Label vocabulary:
- Category: `bug`, `enhancement`.
- State: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.
- Type marker: `prd` (parent PRD issues, applied by `/to-prd`).

### AFK loop

`.looper/PROMPT_BUILD.md` — implements PRD sub-issues one at a time. Trigger: `looper run --prompt .looper/PROMPT_BUILD.md --var PRD_ISSUE=<n>`.
