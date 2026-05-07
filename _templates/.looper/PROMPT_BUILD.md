# Build Mode: Looper (PRD Sub-Issues)

You are in build mode. You must:

1. Implement exactly one ready sub-issue of the PRD identified by `{{PRD_ISSUE}}` per iteration, applying TDD per `@CODING_STANDARDS.md` (sections: TDD, Tests, Mocking).
2. Follow the phases below in order, starting at Phase 0.

Do not treat this prompt as documentation. Do not ask the user to confirm. Start now. Do **not** invoke any HITL skill (`/tdd`, `/grill-*`, `/triage`, etc.) — you are running headless.

**Context**
- PRD input: {{PRD_ISSUE}}
- Iteration: {{ITERATION}} / {{MAX_ITERATIONS}}
- Session: {{SESSION_ID}}
- Base branch: {{BASE_BRANCH}}

---

## Path Discovery

**NEVER guess file paths.** Use Glob/Grep to verify paths exist before editing. For new files, verify the parent directory exists.

---

## Phase 0: Worktree Setup

```bash
PRD_ISSUE_INPUT='{{PRD_ISSUE}}'
PRD_ISSUE_NUMBER="$PRD_ISSUE_INPUT"

# Accept either a bare issue number (`123`) or a GitHub issue URL and normalize
# to the numeric issue number used in gh commands, commit messages, and PR text.
case "$PRD_ISSUE_NUMBER" in
  https://github.com/*/issues/[0-9]*) PRD_ISSUE_NUMBER="${PRD_ISSUE_NUMBER##*/}" ;;
esac

if ! printf '%s' "$PRD_ISSUE_NUMBER" | grep -Eq '^[0-9]+$'; then
  echo "PRD_ISSUE must be a numeric issue number or GitHub issue URL: $PRD_ISSUE_INPUT"
  echo ":::LOOPER_DONE:::"
  exit 1
fi

PRD_TITLE="$(gh issue view "$PRD_ISSUE_NUMBER" --json title -q '.title')"
PRD_SLUG="$(printf '%s' "$PRD_TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"

if [ -z "$PRD_SLUG" ]; then
  PRD_SLUG="prd"
fi

BRANCH="feat/$PRD_SLUG-$PRD_ISSUE_NUMBER"
WORKTREE=".worktrees/$BRANCH"

if [ ! -d "$WORKTREE" ]; then
  git fetch origin {{BASE_BRANCH}}
  git worktree add "$WORKTREE" -b "$BRANCH" "origin/{{BASE_BRANCH}}" 2>/dev/null \
    || git worktree add "$WORKTREE" "$BRANCH"
  cd "$WORKTREE"
  {{INSTALL_CMD}}
else
  cd "$WORKTREE"
fi
```

All work happens inside `$WORKTREE`. Use `$PRD_ISSUE_NUMBER` for every `gh` command, issue reference, and PR body. Branches are explicit and title-based: `feat/<slugified-prd-title>-$PRD_ISSUE_NUMBER` (for example, `feat/add-twitter-login-12`). Never use raw `{{PRD_ISSUE}}` in branch names or worktree paths.

---

## Phase 1: Find a Ready Sub-Issue

Children of the PRD are discovered via body-ref. Each child contains a `## Parent` heading immediately followed by `#$PRD_ISSUE_NUMBER` and carries the `ready-for-agent` label.

```bash
gh issue list \
  --label ready-for-agent \
  --search "in:body \"Parent\" \"#$PRD_ISSUE_NUMBER\"" \
  --state open \
  --json number,title,body,labels
```

Filter: keep only issues whose body literally contains a `## Parent` heading whose next non-empty line is `#$PRD_ISSUE_NUMBER` (guard against false-positive mentions).

For each candidate, parse its `## Blocked by` section. A child is **ready** when every issue listed under `Blocked by` is closed (or the section says `None - can start immediately`):

```bash
gh issue view <blocker-number> --json state -q '.state'
```

Decision tree:

- **No open children remain** → go to **Phase 6: Create PR**.
- **Open children exist but all are blocked** → emit `:::LOOPER_DONE:::` (human must unblock).
- **At least one ready child** → pick the lowest-numbered ready child and continue.

---

## Phase 2: Gather Context

1. Read the chosen sub-issue: `gh issue view <number> --json title,body`
2. Read the parent PRD: `gh issue view "$PRD_ISSUE_NUMBER" --json title,body`
3. Read `AGENTS.md` (or `CLAUDE.md`) for architecture, conventions, and commands.
4. Read `docs/CONTEXT.md` for domain language. Use its terms in test names and identifiers.
5. Read `CODING_STANDARDS.md` (sections: TDD, Tests, Mocking) for the rules to apply in Phase 3.
6. Find an existing test file in the area you're touching — follow its patterns.
7. Explore the codebase enough to confirm the behavior doesn't already exist and to understand neighboring patterns.

If `CODING_STANDARDS.md` is missing, emit `:::LOOPER_DONE:::` and report that the harness is incomplete (run `/setup-harness`).

---

## Phase 3: Implement

Apply TDD per `@CODING_STANDARDS.md`. The sub-issue's `## Acceptance criteria` checklist drives the test list — each criterion gets one RED → GREEN cycle. Refactor only when green. Mock only at system boundaries.

---

## Phase 4: Validate

```bash
./scripts/run_silent "build" {{BUILD_CMD}}
./scripts/run_silent "lint" {{LINT_CMD}}
./scripts/run_silent "test" {{TEST_CMD}}
./scripts/run_silent "typecheck" {{TYPECHECK_CMD}}
```

All four must pass. If any fails:

1. **First attempt** — targeted fix based on the error.
2. **Second attempt** — alternative approach.
3. **Third attempt** — stop. Do NOT commit broken code. Emit `:::LOOPER_DONE:::`.

The human decides what to do (fix manually, close the issue, rewrite the sub-issue).

---

## Phase 5: Commit & Close

When all four validators pass:

```bash
git add -A
git commit -m "$(cat <<EOF
feat: <sub-issue title>

<2–3 sentence prose paragraph describing the capability that was added or
changed, in domain terms (use docs/CONTEXT.md vocabulary). Wrap at ~72 columns.
Describe the user-visible behavior, not the implementation.>

Key changes:
- <feature or behavior 1, one line>
- <feature or behavior 2, one line>
- <feature or behavior 3, one line>
- <tests added/updated, one line>

<Optional further sections — only when relevant. Each is a single label
followed by a colon and one or more sentences. Examples: "Security:" for
authz/input-validation/secret-handling impact, "Migration:" for schema or
data changes, "Breaking:" for API/contract breaks. Omit the section
entirely when nothing applies — do not write "None".>

Closes #<number>
Refs #$PRD_ISSUE_NUMBER
EOF
)"
git push -u origin HEAD

gh issue close <number>
```

The commit body is the durable record of *what* and *why* for this slice — write it for a future agent or human reading `git log` six months from now. Subject line stays under 72 chars; body wraps at ~72.

After `git push -u origin HEAD` and `gh issue close <number>`, re-run child discovery for this PRD using the exact Phase 1 discovery and filtering rules.

- **If any open child remains** → stop this iteration and let looper continue. Do **not** emit `:::LOOPER_DONE:::`.
- **If no open children remain** → continue immediately to **Phase 6: Create PR** in this same iteration.

Do not emit `:::LOOPER_DONE:::` after a successful sub-issue unless Phase 6 has completed or human intervention is required.

---

## Phase 6: Create PR

Only reached when every child of PRD #$PRD_ISSUE_NUMBER is closed.

Before opening the PR, gather what was actually built:

```bash
# All sub-issues of this PRD
gh issue list --search "in:body \"Parent\" \"#$PRD_ISSUE_NUMBER\"" --state closed --json number,title,body
# All commits on this branch
git log origin/{{BASE_BRANCH}}..HEAD --pretty=format:"- %s%n%b"
```

Compose a PR body that summarizes the **whole** PRD's work — not just the last sub-issue. Use `docs/CONTEXT.md` vocabulary throughout.

Create the PR with `needs-review` so maintainers can filter pull requests that are waiting for review. `/setup-harness` provisions the PR status labels for the repository. Keep only one PR status label active on a PR at a time.

```bash
PR_URL=$(gh pr create \
  --base {{BASE_BRANCH}} \
  --label needs-review \
  --title "feat: <PRD title>" \
  --body "$(cat <<EOF
## Summary

<2–4 sentence high-level summary of the capability shipped by this PRD, from the user's perspective.>

Closes #$PRD_ISSUE_NUMBER

## Sub-issues delivered

- #<n1> — <title> — <one-line outcome>
- #<n2> — <title> — <one-line outcome>
- #<n3> — <title> — <one-line outcome>

## What changed

Group by area/module, not by commit:

- **<area or module>** — <what changed and why, 1–2 lines>
- **<area or module>** — <what changed and why, 1–2 lines>

## Tests

- <new test files / suites added, one line each>
- <existing tests updated, one line each>

## Notes

<Anything reviewers should pay extra attention to: tricky tradeoffs, follow-ups intentionally deferred, schema/migration impact, breaking changes. Omit if nothing applies.>
EOF
)")

gh pr edit "$PR_URL" \
  --remove-label changes-requested \
  --remove-label ready-to-merge \
  --add-label needs-review
```

Emit `:::LOOPER_DONE:::`.

---

## Guardrails

1. **Single task per iteration** — one sub-issue, then stop.
2. **Test first** — RED before GREEN, per `@CODING_STANDARDS.md`.
3. **Validate before commit** — never commit failing code.
4. **Worktree first** — all work happens inside `.worktrees/feat/<slugified-prd-title>-$PRD_ISSUE_NUMBER`.
5. **Body-ref + label discovery** — `## Parent` heading + `ready-for-agent` label, no native sub-issue API.
6. **No PRD mutation** — never edit or close the PRD issue.
7. **No HITL skills** — read `CODING_STANDARDS.md`, `docs/CONTEXT.md`, `AGENTS.md` directly.
8. **Use `run_silent`** — wrap every validation command.
