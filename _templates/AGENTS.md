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

Reviewer doctrine lives in `docs/CODE_REVIEW.md`. The `/code-review` skill reads it before reviewing a PR.

### Domain

Shared domain language: `docs/CONTEXT.md`. Maintained via `/grill-with-docs`.

### Architectural decisions

ADRs live under `docs/adr/NNNN-*.md`. Template at `docs/adr/0000-template.md`.

### Issue tracker

GitHub Issues. Label vocabulary:
- Category: `bug`, `enhancement`.
- Issue state: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.
- Type marker: `prd` (parent PRD issues, applied by `/to-prd`).
- PR status: `needs-review`, `changes-requested`, `ready-to-merge`.

PR status labels are shared GitHub labels, but represent pull request review state only:
- `needs-review` — PR is open and ready for review.
- `changes-requested` — review found required changes.
- `ready-to-merge` — review accepted the PR and it can be merged.

Keep exactly one PR status label on each open PR. Maintainers and agents can filter pull requests by these labels in GitHub or with `gh pr list --search "label:<label>"`.

### AFK loop

`.looper/PROMPT_BUILD.md` — implements PRD sub-issues one at a time. Trigger: `looper run --prompt .looper/PROMPT_BUILD.md --var PRD_ISSUE=<n>`.
