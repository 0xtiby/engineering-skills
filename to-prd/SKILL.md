---
name: to-prd
description: Turn the current conversation context into a PRD and publish it as a GitHub issue. Use when user wants to create a PRD from the current context.
---

# To PRD

Take the current conversation context and codebase understanding and produce a PRD published as a GitHub issue. Do NOT interview the user — just synthesize what you already know. GitHub-only.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use `docs/CONTEXT.md` vocabulary throughout the PRD. Respect ADRs in the area you're touching.

2. Sketch out the major modules you will need to build or modify. Actively look for opportunities to extract deep modules — small testable interfaces with rich implementations behind them.

   Check with the user that these modules match their expectations. Check which modules they want tests written for.

3. Write the PRD using the template below. Publish it with `gh issue create`. Apply two labels:
   - **`prd`** — marks the issue as a parent PRD (distinct from sub-issues, bug reports, enhancements). Used by tooling and humans to filter the issue list down to PRDs.
   - **`ready-for-agent`** — the conversation context that produced the PRD constitutes evaluation; `/triage` is for externally-sourced issues, so the PRD skips it.

   If the `prd` label does not exist on the repo yet, create it first: `gh label create prd --description "Parent PRD issue (broken into sub-issues by /to-issues)" --color 0E8A16`.

<prd-template>

## Problem Statement

The problem the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list. Each story:

1. As an <actor>, I want a <feature>, so that <benefit>.

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending.
</user-story-example>

This list should be extensive and cover all aspects of the feature.

## Implementation Decisions

- The modules that will be built/modified.
- The interfaces that will be modified.
- Technical clarifications from the developer.
- Architectural decisions.
- Schema changes.
- API contracts.
- Specific interactions.

Do NOT include specific file paths or code snippets — they go stale fast.

## Testing Decisions

- A description of what makes a good test (only test external behavior, not implementation details).
- Which modules will be tested.
- Prior art — similar tests in the codebase.

## Out of Scope

What is explicitly NOT covered by this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>

4. Tell the user the PRD issue number. Suggested next step: `/to-issues` to break it down.
