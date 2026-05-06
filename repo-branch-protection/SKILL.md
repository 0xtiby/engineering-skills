---
name: repo-branch-protection
description: Set up branch protection rules on a GitHub repository's default branch. Use when the user says 'setup branch protection', 'protect branch', 'branch protection', 'secure main branch', or wants to apply protection rules (required reviews, status checks, force-push blocking) to a repo. Asks each option with a one-line explanation.
---

# Set Up Branch Protection

Apply branch protection rules to a GitHub repository's default branch via the bundled `scripts/setup-branch-protection.sh`. Walk the user through each option, explain what it does in one line, then run the script with the chosen flags.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status`). If not, instruct the user to run `gh auth login` and stop.

## Interview

For every option below, **show the one-line explanation first**, then ask the question with the suggested default. If the user just confirms, use the default.

1. **Target repo** — auto-detect from the current directory with `gh repo view --json owner,name -q '.owner.login + "/" + .name'`. If that fails or the user is not in a repo, ask for `owner/name`. Then detect the default branch: `gh api repos/<repo> --jq '.default_branch'`.

2. **Admin bypass** — *"Lets repo admins merge PRs without going through the review/CI rules. Useful for solo maintainers who want rules ready for future contributors but not block themselves."*
   - Question: "Allow admins to bypass protection?"
   - Default: **yes** (maps to `enforce_admins=false`)

3. **Required approving reviews** — *"How many approvals a PR needs before it can be merged."*
   - Default: **1**

4. **Dismiss stale reviews** — *"When new commits are pushed to a PR, previous approvals are automatically dismissed so reviewers re-check the latest changes."*
   - Default: **true**

5. **Require code owner reviews** — *"PRs touching files listed in CODEOWNERS must be approved by their designated owner."*
   - Default: **false**

6. **Required status checks** — *"CI checks (by name) that must pass green before a PR can be merged. Empty means no required checks."*
   - Default: **empty** (comma-separated list, e.g., `lint,test`)

7. **Strict status checks** — *"Require the PR branch to be up-to-date with the base branch before merging, so checks reflect the post-merge state."*
   - Only ask if step 6 is non-empty. Default: **true**

8. **Allow force pushes** — *"Lets anyone rewrite history on the protected branch. Almost always a bad idea."*
   - Default: **false**

9. **Allow branch deletion** — *"Lets the protected branch itself be deleted."*
   - Default: **false**

10. **GitHub Actions can approve PRs** — *"Allows workflows (e.g. release-please, dependabot auto-merge) to create and approve PRs."*
    - Default: **true**

## Apply

Run the bundled script with the collected flags:

```bash
bash <SKILL_DIR>/scripts/setup-branch-protection.sh \
  --repo <owner/name> \
  --branch <default-branch> \
  --enforce-admins <true|false> \
  --approvals <N> \
  --dismiss-stale <true|false> \
  --code-owner-reviews <true|false> \
  --required-checks "<ctx1,ctx2>" \
  --strict-checks <true|false> \
  --allow-force-push <true|false> \
  --allow-deletions <true|false> \
  --actions-can-approve <true|false>
```

`<SKILL_DIR>` is the directory containing this `SKILL.md`.

## Report

After the script succeeds, summarize what was applied: list each option and its chosen value, plus the repo URL.

If the script fails, surface the exact error (likely permissions — only repo admins can set protection rules). Do not retry blindly.
