---
name: setup-harness
description: Bootstrap the personal project harness in a fresh git repo. Writes the per-repo doc set (CODING_STANDARDS.md and AGENTS.md at root; docs/CONTEXT.md, docs/CODE_REVIEW.md, and ADRs under docs/) and the looper build prompt (.looper/PROMPT_BUILD.md). Run once after `/repo-create`. Re-running edits in place. Use when user wants to set up the harness, configure looper for a new repo, or scaffold AGENTS/CODING_STANDARDS files.
disable-model-invocation: true
---

# Setup Harness

Bootstraps the project harness: per-repo doc set (`CODING_STANDARDS.md` and `AGENTS.md` at the repo root; `docs/CONTEXT.md`, `docs/CODE_REVIEW.md`, `docs/adr/`) plus the looper build prompt (`.looper/PROMPT_BUILD.md`). Generic only — stack-specific layers are applied by hand to template repos (eniem, future boilerplates).

## Process

### 1. Explore

Look at the current repo to understand its starting state. Don't assume; read what's there.

- `git remote -v` — confirm GitHub remote (this skill is GitHub-only).
- `AGENTS.md`, `CLAUDE.md` at the repo root — does either exist?
- `CODING_STANDARDS.md`, `docs/CONTEXT.md`, `docs/CODE_REVIEW.md`, `docs/adr/`, `.looper/`, `scripts/run_silent`, `scripts/ensure_pr_status_labels`, `prek.toml` — present already?
- `package.json` — infer package manager (`packageManager` field) and Node version (`engines.node`).

If a non-GitHub remote is detected, stop and tell the user this skill is GitHub-only.

### 2. Interview

Ask **one question at a time**, with a short explainer and a default. Do not dump all questions at once. Use the values explored in step 1 as defaults where applicable.

**Q1 — Package manager.**

> Explainer: which package manager runs `install`/`build`/`test`. Read from `package.json` if present.

Choices: `pnpm` (default) / `npm` / `yarn` / `bun`.

**Q2 — Node version.**

> Explainer: pinned Node major. Defaults to current LTS.

Default: `22` (or whatever LTS is current at run time).

**Q3 — Default base branch.**

> Explainer: where feature PRs target. Use `quality` if you have an integration gate; otherwise `main`.

Default: `main`.

**Q4 — Repo description.**

> Explainer: one line for AGENTS.md. What does this repo do?

No default — must be provided.

**Q5 — Pre-commit hooks (prek).**

> Explainer: scaffold `prek.toml` with lint + typecheck (pre-commit) and test (pre-push) hooks?

Default: yes.

**Q6 — Hand off to repo-setup-ci and repo-branch-protection?**

> Explainer: after harness scaffolding, run the GitHub-side meta-skills?

Default: yes (run both in sequence).

### 3. Derive command vars

From Q1 (package manager), derive:

| var | pnpm | npm | yarn | bun |
|---|---|---|---|---|
| `INSTALL_CMD` | `pnpm install` | `npm install` | `yarn install` | `bun install` |
| `BUILD_CMD` | `pnpm build` | `npm run build` | `yarn build` | `bun run build` |
| `LINT_CMD` | `pnpm lint` | `npm run lint` | `yarn lint` | `bun run lint` |
| `TEST_CMD` | `pnpm test` | `npm test` | `yarn test` | `bun test` |
| `TYPECHECK_CMD` | `pnpm typecheck` | `npm run typecheck` | `yarn typecheck` | `bun run typecheck` |

### 4. Draft and confirm

Show the user a draft of every file you're about to write. Let them edit before writing. Skip files that already exist with non-default content (offer to overwrite or merge).

### 5. Write

Write files to the repo from the templates in this skill folder, substituting **only** the placeholders listed below. Any other `{{...}}` left in the templates is intentional — it is either a looper-runtime variable (filled per iteration when the build loop runs) or a hand-edit placeholder (text the human replaces when authoring a new artifact).

**Substitute these (from the interview answers in steps 2–3):**

| Placeholder | Source |
|---|---|
| `{{REPO_NAME}}` | repo directory basename |
| `{{REPO_DESCRIPTION}}` | Q4 |
| `{{PACKAGE_MANAGER}}` | Q1 |
| `{{NODE_VERSION}}` | Q2 |
| `{{BASE_BRANCH}}` | Q3 |
| `{{INSTALL_CMD}}` / `{{BUILD_CMD}}` / `{{LINT_CMD}}` / `{{TEST_CMD}}` / `{{TYPECHECK_CMD}}` | derived in step 3 |

**Do NOT substitute these — leave them in the written file:**

| Placeholder | Filled by |
|---|---|
| `{{PRD_ISSUE}}` | looper, per iteration (`--var PRD_ISSUE=<n>`) |
| `{{ITERATION}}`, `{{MAX_ITERATIONS}}`, `{{SESSION_ID}}` | looper, per iteration |
| `{{Title — …}}` (ADR template) | the human, when authoring a new ADR |

If you find a `{{...}}` placeholder that isn't in either list, stop and ask — the templates may have drifted.

Write order:

1. `docs/CONTEXT.md` (skip if non-empty exists).
2. `CODING_STANDARDS.md` (skip if non-empty exists).
3. `docs/CODE_REVIEW.md` (skip if non-empty exists).
4. `AGENTS.md` (or edit existing — see file selection rule below).
5. `docs/adr/0000-template.md` (skip if exists).
6. `.looper/config.json` (skip if exists; offer to merge `vars`).
7. `.looper/PROMPT_BUILD.md` (skip if exists).
8. `scripts/run_silent` (chmod +x). Skip if exists.
9. `scripts/ensure_pr_status_labels` (chmod +x). Skip if exists.
10. `prek.toml` (only if Q5 = yes; skip if exists).
11. `.gitignore` — read `_templates/.gitignore.fragment` and append **only the lines** that aren't already present in the repo's `.gitignore` (per-line dedup, ignoring comments and blank lines as the matching key). Don't append the fragment as a whole if any of its lines are missing — diff line-by-line. If `.gitignore` doesn't exist, create it with the full fragment.
12. GitHub PR status labels — create or update the repository labels used by the PR lifecycle. GitHub labels are shared between issues and PRs, but these three represent PR review state only:
    ```bash
    ./scripts/ensure_pr_status_labels
    ```

**File selection rule for AGENTS.md / CLAUDE.md:**
- If `CLAUDE.md` exists, edit it (in-place, preserve user content).
- Else if `AGENTS.md` exists, edit it.
- Else create `AGENTS.md` and a `CLAUDE.md` symlink → `AGENTS.md`.

When editing existing files, find the `## Agent skills` block and update its body in-place; if not present, append it. Never overwrite surrounding sections.

### 6. Hand off (Q6 = yes)

Invoke `/repo-setup-ci`, then `/repo-branch-protection`. These are existing meta-skills.

### 7. Done

Tell the user setup is complete. Mention:
- `/grill-with-docs` to start populating `docs/CONTEXT.md` and ADRs.
- `/to-prd` then `/to-issues` to produce a PRD and ready sub-issues.
- `looper run --prompt .looper/PROMPT_BUILD.md --var PRD_ISSUE=<n>` to start the AFK loop.

Re-running this skill is safe — every step is idempotent or guarded.

## Templates

The file templates this skill writes live in `_templates/` adjacent to this skill. After cloning/installing this skill, the layout is:

```
setup-harness/
├── SKILL.md                    ← this file
└── templates/                  ← symlinked or copied from tiby-skills/_templates/
    ├── CODING_STANDARDS.md
    ├── AGENTS.md
    ├── docs/CONTEXT.md
    ├── docs/CODE_REVIEW.md
    ├── docs/adr/0000-template.md
    ├── .looper/config.json
    ├── .looper/PROMPT_BUILD.md
    ├── scripts/run_silent
    ├── scripts/ensure_pr_status_labels
    ├── prek.toml
    └── .gitignore.fragment
```

(During development, the templates live at `tiby-skills/_templates/` — promotion to `~/.claude/skills/setup-harness/templates/` happens at install time.)
