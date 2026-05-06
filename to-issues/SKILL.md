---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable GitHub issues using tracer-bullet vertical slices. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues.
---

# To Issues

Break a plan into independently-grabbable GitHub issues using vertical slices (tracer bullets). GitHub-only — uses `gh issue create`.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes an issue reference (number, URL) as an argument, fetch it with `gh issue view <ref> --json title,body,comments` and read it fully.

### 2. Explore the codebase (optional)

If you haven't already explored the codebase, do so. Use `CONTEXT.md` vocabulary in titles and descriptions. Respect ADRs in the area you're touching.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' (require human interaction — architectural decisions, design review) or 'AFK' (implementable and mergeable without human interaction). Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests).
- A completed slice is demoable or verifiable on its own.
- Prefer many thin slices over few thick ones.
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice show:

- **Title** — short descriptive name.
- **Type** — HITL / AFK.
- **Blocked by** — which other slices (if any) must complete first.
- **User stories covered** — which user stories this addresses, if the source PRD has them.

Ask:

- Does the granularity feel right? (too coarse / too fine)
- Are dependency relationships correct?
- Should any slices be merged or split further?
- Are HITL/AFK markings correct?

Iterate until approved.

### 5. Publish to GitHub

For each approved slice, create a GitHub issue with `gh issue create`. Apply the **`ready-for-agent`** label directly — the grill→PRD→issues path is the "already evaluated" channel and skips `needs-triage`. Externally-sourced issues go through `/triage` instead.

Publish in dependency order (blockers first) so you can reference real issue numbers in the `Blocked by` field.

<issue-template>
## Parent

#<PRD_ISSUE_NUMBER>

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- #<other-sub-issue>

Or "None - can start immediately" if no blockers.

</issue-template>

Do NOT close or modify the parent PRD issue.

### 6. Hand-off

Tell the user the issues are published and ready. Suggested next step: `looper run --prompt .looper/PROMPT_BUILD.md --var PRD_ISSUE=<n>`.
