---
name: code-review
description: Review a pull request against the project's review doctrine and post the review as a PR comment. Use when the user says '/code-review <PR_URL>', 'review this PR', 'review pull request', or provides a GitHub PR URL for code review.
---

# Code Review

Review a pull request against the project's review doctrine and post the review as a PR comment.

## Doctrine

Read the doctrine **before reading the diff**:

- If the target repo has a `CODE_REVIEW.md` at its root, read that. It is the canonical reviewer checklist for this project (philosophy, doctrine alignment rules, language-specific standards, output format).
- Otherwise, fall back to the bundled [CODE_REVIEW.md](./CODE_REVIEW.md) shipped with this skill.

Also read, if present, the repo's `CODING_STANDARDS.md`, `CONTEXT.md`, `AGENTS.md`, and `docs/adr/`. The PR must be evaluated against repo doctrine, not just generic principles.

## Usage

```
/code-review <PR_URL>
```

If no URL is provided, ask the user for one.

## Process

1. **Identify the repo.** Parse the PR URL → `<owner>/<repo>` and PR number. If the current working directory is not a checkout of that repo, switch to one (or work via `gh` against the URL — no checkout needed for read-only review).

2. **Read doctrine.** Per the section above. Do not skip this step — every section of the review references repo doctrine.

3. **Fetch the PR.**
   ```bash
   gh pr view <PR_URL> --json title,body,headRefName,baseRefName,author
   gh pr diff <PR_URL>
   ```
   For large PRs, also list the changed files: `gh pr view <PR_URL> --json files`.

4. **Review.** Apply the process and standards from the loaded `CODE_REVIEW.md`:
   - Initial assessment (red flags).
   - Doctrine alignment (against `CODING_STANDARDS.md`, `CONTEXT.md`, ADRs, `AGENTS.md`).
   - Deep analysis (Convention over Configuration, Programmer Happiness, Conceptual Compression).
   - Craftsmanship test.

5. **Format the review** using the **Output Format** section of `CODE_REVIEW.md` (Overall Assessment / Critical Issues / Improvements Needed / What Works Well / Refactored Version).

6. **Post the review** as a PR comment:
   ```bash
   gh pr comment <PR_URL> --body "$(cat <<'EOF'
   <review body>
   EOF
   )"
   ```

7. **Confirm to the user** that the review was posted, and print the review body to the local log so they can read it without opening GitHub.

## Guardrails

- Always read doctrine first. The review is graded against repo rules, not generic taste.
- Always post the review as a PR comment — do not just display it locally.
- For large PRs, focus on the most significant changes first; flag any sections you skipped at the bottom of the review.
- If `CODE_REVIEW.md` is missing both in the repo and in this skill bundle, stop and tell the user the review doctrine is unavailable. Do not improvise.
