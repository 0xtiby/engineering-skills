---
name: repo-setup-ci
description: Set up GitHub Actions CI workflows on a fresh repository. Asks the user which workflows to install (test on PR, semantic-release on main) and writes the corresponding files under .github/workflows/. Use when the user says 'setup ci', 'add ci', 'add github actions', 'configure workflows', or right after creating a new repo.
---

# Set Up CI

Install GitHub Actions workflows in the current repo by copying bundled templates from `<SKILL_DIR>/templates/` into `.github/workflows/`. Walk the user through which workflows they want, adjust a couple of values (Node version, package manager) if they deviate from defaults, then write the files.

## Prerequisites

- Run from inside a git repository. If `git rev-parse --show-toplevel` fails, ask the user to `cd` into the repo and stop.
- `gh` CLI authenticated (`gh auth status`) — only needed if hand-off to `repo-branch-protection` is requested at the end.

## Interview

Ask each question in order. Skip any answered in the user's initial message.

1. **Which workflows?** — multi-select:
   - **Test on PR** — runs `lint`, `typecheck`, `test` as parallel jobs on every PR and on push to `main`. Each job appears as its own status check (good for required-checks in branch protection).
   - **Release** — runs `semantic-release` on every push to `main`. Publishes to npm via OIDC trusted publishing.
   - At least one must be selected.

2. **Package manager** — *"pnpm, npm, or yarn?"* Default: **pnpm**. (Templates are pnpm-based; if npm/yarn, swap the install/run commands and remove the `pnpm/action-setup` step.)

3. **Node version** — Default: **22.14.0** (matches looper). Confirm or override.

4. **If Release was selected:**
   - Confirm the repo has `semantic-release` configured (or will be). If not, warn the user that the workflow will fail until `.releaserc` (or equivalent) and `package.json` `release` config are added.
   - Remind: **NPM trusted publishing must be configured on npmjs.com** for the package, linking it to this GitHub repo + the `release.yml` workflow. The workflow alone is not enough.

## Apply

For each selected workflow:

1. Create `.github/workflows/` if missing.
2. Copy `<SKILL_DIR>/templates/<name>.yml` → `.github/workflows/<name>.yml`.
3. If the user changed Node version or package manager, edit the copied file in place:
   - Node version → replace `node-version: 22.14.0`.
   - npm → replace the `pnpm/action-setup` step with nothing, swap `pnpm install --frozen-lockfile` → `npm ci`, swap `pnpm <script>` → `npm run <script>`, swap `cache: pnpm` → `cache: npm`.
   - yarn → equivalent swap with `yarn install --frozen-lockfile` and `yarn <script>`, `cache: yarn`.

Do **not** commit. Leave the new files in the working tree.

## Hand-off

After writing files, suggest two follow-ups in plain language:

1. **Branch protection** — "Set up branch protection now? Required status checks: `Lint`, `Typecheck`, `Test` (these are the job `name:` values that GitHub reports as check contexts)." Mention them only if `test.yml` was installed.
2. **Commit** — "Commit and push these workflow files." A natural-language request handles staging + Conventional Commit message + push.

## Report

Summarize:
- Files written (with paths).
- Required follow-ups: `semantic-release` config + npm trusted publishing (if Release was selected); branch protection updates if status-check names changed.

## Notes

- This skill runs **once on a fresh repo**. For modifying CI on existing repos, edit the workflow files directly — do not rerun this skill, as it overwrites without merging.
- If `.github/workflows/<name>.yml` already exists, **stop and ask** — do not overwrite silently.
- Do not invent additional workflows (deploy, codeql, dependabot, etc.). Stay scoped to test + release.
