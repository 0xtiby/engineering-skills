---
name: fix-code-review
description: Fix code review comments from a GitHub PR. Use when the user says '/fix-code-review <PR_URL>', 'fix review comments', 'fix PR feedback', 'address review comments', or wants to resolve PR review feedback.
---

# Fix Code Review

Fetch review comments from a GitHub PR, fix them, validate, commit, and push. Runs end-to-end without prompting the user.

## Usage

`/fix-code-review <pr-url>`

Example: `/fix-code-review https://github.com/owner/repo/pull/42`

## Process

1. **Discover branch**: Find the PR's head branch and switch to the correct worktree
2. **Fetch PR comments**: Use `gh` CLI to get all review comments
3. **Parse comments**: Extract file paths, line numbers, and feedback
4. **Plan**: Build the fix list (logged for transparency, not gated)
5. **Apply fixes**: Make the code changes
6. **Validate**: Run the project's validation commands to ensure fixes don't break anything
7. **Commit & push**: Commit the fixes and push to the PR's head branch
8. **Move PR back to review**: Apply `needs-review` and remove the other PR status labels
9. **Summarize**: Show what was fixed

## Step 1: Discover PR Branch and Worktree

Before doing anything, find and switch to the correct working directory:

1. Get the PR's head branch:
   ```bash
   gh pr view <pr-number> --json headRefName --repo <owner/repo>
   ```
2. Check if a worktree already exists at `.worktrees/<head-branch-name>`
3. If it exists, work in that directory
4. If not, create it:
   ```bash
   git fetch origin <head-branch-name>
   git worktree add .worktrees/<head-branch-name> origin/<head-branch-name>
   ```

All subsequent steps run from this worktree directory.

## Step 2: Fetch All Comments

GitHub PRs have 3 types of comments - fetch ALL of them:

```bash
# 1. Review comments (line-specific feedback on the diff) - MOST IMPORTANT
gh api repos/<owner>/<repo>/pulls/<pr-number>/comments

# 2. Reviews with their body comments (approve/request changes summary)
gh pr view <pr-number> --json reviews --repo <owner/repo>

# 3. Issue comments (general conversation, not tied to code lines)
gh pr view <pr-number> --json comments --repo <owner/repo>
```

**Important**: `gh pr view --json comments` returns conversation comments, NOT the line-specific review comments. You MUST use the API endpoint to get line-specific feedback.

Parse the response to extract:

**From review comments (API):**
- `path` - File path
- `line` or `original_line` - Line number
- `body` - Comment body (the feedback to address)
- `user.login` - Author
- `diff_hunk` - Context of the code being commented on

**From reviews:**
- `body` - Review summary comment
- `state` - APPROVED, CHANGES_REQUESTED, COMMENTED
- `author.login` - Reviewer

**From issue comments:**
- `body` - General feedback
- `author.login` - Commenter

## Step 3: Build Fix Plan

For each comment, analyze:
- What change is being requested?
- Which file/lines need modification?
- What's the proposed fix?

Print the plan for transparency (so the human can read the log), but **do not gate on confirmation**:

```
## Fix Plan

1. **src/lib/auth.ts:42** - "Add error handling for null user"
   → Add null check before accessing user properties

2. **src/components/Button.tsx:15** - "Use semantic HTML"
   → Change div to button element

3. **src/features/settings/index.ts:8** - "Missing export"
   → Add missing export statement
```

If a comment is genuinely ambiguous (multiple plausible fixes with different semantics), pick the most conservative interpretation and note it in the commit message. Do not stop and ask.

## Step 4: Apply Fixes

For each fix:
1. Read the file
2. Apply the change
3. Verify syntax is valid

## Step 5: Validate

Run the project's validation commands (build, lint, tests, typecheck). If validation fails:

1. Targeted fix based on the error.
2. Alternative approach.
3. Third attempt — stop. Do NOT commit broken code. Report the failure and exit.

## Step 6: Commit & Push

```bash
git add -A
git commit -m "$(cat <<'EOF'
fix(review): address review comments on PR #<pr-number>

<2–3 sentence prose describing the substance of the changes (not "fixed
review comments" — explain what behavior or code quality issue was
corrected). Wrap at ~72 columns.>

Comments addressed:
- <file:line> — <one-line summary of the fix>
- <file:line> — <one-line summary of the fix>

Refs PR #<pr-number>
EOF
)"
git push origin HEAD
```

## Step 7: Move PR Back to Review

GitHub labels are shared between issues and PRs, but these labels represent PR review state only. After pushing fixes, keep only `needs-review` active so maintainers can filter PRs waiting for another review:

```bash
gh label create needs-review --repo <owner/repo> --description "PR status: ready and waiting for review" --color 5319E7 2>/dev/null || true
gh label create changes-requested --repo <owner/repo> --description "PR status: reviewed and requires changes before merge" --color D73A4A 2>/dev/null || true
gh label create ready-to-merge --repo <owner/repo> --description "PR status: reviewed and ready to merge" --color 0E8A16 2>/dev/null || true

gh pr edit <pr-number> --repo <owner/repo> \
  --remove-label changes-requested \
  --remove-label ready-to-merge \
  --add-label needs-review
```

## Step 8: Summarize

Post the summary as a new PR comment, then print the same summary locally:

```bash
gh pr comment <pr-number> --repo <owner/repo> --body "$(cat <<'EOF'
## Summary

Fixed 3/3 review comments:
- ✅ src/lib/auth.ts:42 - Added null check
- ✅ src/components/Button.tsx:15 - Changed to semantic button
- ✅ src/features/settings/index.ts:8 - Added export

Validation: ✅ Build passed, ✅ Lint passed, ✅ Tests passed
Pushed: <commit-sha> to <branch>
PR status: `needs-review`
EOF
)"
```

## Guardrails

- Print the plan for the log, but do not gate on confirmation — proceed straight through.
- Validate after fixes. Never commit broken code.
- If a comment is genuinely ambiguous, pick the conservative interpretation and note it in the commit message.
- Handle PR URLs from any GitHub repo (parse owner/repo from URL).
