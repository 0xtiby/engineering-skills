# tiby-skills

Personal agent skill set, written against the [AGENTS.md convention](https://agents.md). The `/setup-harness` skill writes `AGENTS.md` as the canonical file in each scaffolded repo and creates `CLAUDE.md` as a symlink so Claude Code picks it up too.

---

## 1. Built on Matt Pocock's work

This collection leans **heavily** on [Matt Pocock's `mattpocock/skills`](https://github.com/mattpocock/skills). Most engineering skills here are either **direct copies** of Matt's originals or **light forks** with documented patches. Matt's design — small `SKILL.md` files with progressive disclosure, an HITL/AFK split, the grill → PRD → issues → triage pipeline — is the architectural backbone. Credit goes there first.

## 2. What's different from Matt's set

Three structural differences:

1. **AFK runtime is `looper`, not `sandcastle`.** Matt pairs his skills with [`mattpocock/sandcastle`](https://github.com/mattpocock/sandcastle), a containerized RALPH loop. I use [`@0xtiby/looper`](https://github.com/0xtiby/looper), which is stateless, CLI-agnostic (claude / codex / opencode / pi), and driven by a prompt file + sentinel (`:::LOOPER_DONE:::`). The AFK build prompt is therefore a **looper template** (`.looper/PROMPT_BUILD.md`), not a sandcastle prompt.

2. **Per-repo doctrine files: `CODING_STANDARDS.md` + `CODE_REVIEW.md`.** Matt's `tdd` skill ships engineering rules as sidecars (tests, mocking, deep modules, …); his code-reviewer is a Claude sub-agent (Claude Code only). I unify both into per-repo files: `/setup-harness` writes `CODING_STANDARDS.md` (writer doctrine — TDD, tests, mocking, interface design, deep modules) and `CODE_REVIEW.md` (reviewer doctrine — checklist, standards, output format) into every repo. The `/tdd` and `/code-review` skills read those files; the looper build prompt reads `CODING_STANDARDS.md` directly. **Single source of doctrine, multiple delivery surfaces.**

3. **Self-constructing harness via `/setup-harness`.** Matt's `setup-matt-pocock-skills` writes `docs/agents/{issue-tracker,triage-labels,domain}.md` so other skills know the repo's conventions. My equivalent writes the full per-repo bootstrap in one go: `CONTEXT.md`, `CODING_STANDARDS.md`, `AGENTS.md` (with a `## Agent skills` block), `docs/adr/`, `.looper/{config.json,PROMPT_BUILD.md}`, `scripts/run_silent`, optional `prek.toml`. Hardcoded to GitHub + a single context layout — no pluggability, lower interview surface.

A handful of smaller divergences: GitHub-only (no GitLab / local-markdown branching), `/to-prd` and `/to-issues` apply `ready-for-agent` directly (skip `needs-triage`), `## Parent` heading kept verbatim from Matt's `to-issues` template.

## 3. Workflow

```
            ┌──────────────────┐
            │  /repo-create    │  new GitHub repo
            └────────┬─────────┘
                     ▼
            ┌──────────────────┐
            │  /setup-harness  │  per-repo doc set + looper prompt
            └────────┬─────────┘
                     ▼
            ┌──────────────────┐  ┌──────────────────────────┐
            │ /repo-setup-ci   │  │ /repo-branch-protection  │  optional
            └──────────────────┘  └──────────────────────────┘
                     │
                     ▼
            ┌──────────────────┐
            │ /grill-with-docs │  populate CONTEXT.md + ADRs
            └────────┬─────────┘
                     ▼
            ┌──────────────────┐
            │     /to-prd      │  PRD as GitHub issue
            └────────┬─────────┘
                     ▼
            ┌──────────────────┐
            │   /to-issues     │  vertical slices as ready sub-issues
            └────────┬─────────┘
                     ▼
            ════════════════════════════════
                  HITL → AFK boundary
            ════════════════════════════════
                     │
                     ▼
            ┌──────────────────────────────────────┐
            │  looper run --prompt                 │
            │    .looper/PROMPT_BUILD.md           │
            │    --var PRD_ISSUE=<n>               │
            │                                      │
            │  reads CONTEXT.md, AGENTS.md,        │
            │  CODING_STANDARDS.md directly        │
            │  → TDD → 4-validator gate → commit   │
            │  → close → repeat → PR               │
            └──────────────────────────────────────┘
```

Side-channels:

- `/triage` — externally-sourced issues (bug reports, contributor enhancements). Outputs of `/to-prd` and `/to-issues` skip it.
- `/code-review` and `/fix-code-review` — run on the PR opened by looper (or any PR). The reviewer reads `CODE_REVIEW.md` + `CODING_STANDARDS.md`; the fixer fetches review comments, applies them, validates, commits, and pushes — no manual gate.
- `/diagnose`, `/zoom-out`, `/improve-codebase-architecture`, `/grill-me`, `/tdd` — interactive engineering helpers. Invoked ad-hoc, not part of the linear flow.
- `/write-a-skill` — used while authoring this very directory.

## 4. Skill index

### Bootstrap & setup

| Skill | One-liner |
|---|---|
| `repo-create` | Create a new GitHub repository interactively. |
| `repo-setup-ci` | Install GitHub Actions workflows (test on PR, semantic-release on main) on a fresh repo. |
| `repo-branch-protection` | Apply branch protection rules (required reviews, status checks, force-push blocking) to a repo's default branch. |
| `setup-harness` | Bootstrap the per-repo harness — `CONTEXT.md`, `CODING_STANDARDS.md`, `CODE_REVIEW.md`, `AGENTS.md`, `docs/adr/`, `.looper/PROMPT_BUILD.md`, optional `prek.toml`. |

### Pre-coding alignment & artifacts

| Skill | One-liner |
|---|---|
| `grill-me` | Stress-test a plan or design through relentless interview until shared understanding. |
| `grill-with-docs` | Grill against the existing domain model and update `CONTEXT.md` + ADRs inline as decisions crystallise. |
| `to-prd` | Synthesize current conversation context into a PRD and publish it as a GitHub issue (labelled `ready-for-agent`). |
| `to-issues` | Break a PRD into independently-grabbable GitHub sub-issues using tracer-bullet vertical slices. |
| `triage` | Move externally-sourced GitHub issues through the `bug`/`enhancement` × `needs-triage`/`needs-info`/`ready-for-agent`/`ready-for-human`/`wontfix` state machine. |

### Engineering helpers

| Skill | One-liner |
|---|---|
| `tdd` | Red-green-refactor loop with vertical slices. **HITL only** — references `CODING_STANDARDS.md`; AFK loops read that file directly instead. |
| `diagnose` | Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test. |
| `improve-codebase-architecture` | Find deepening opportunities in a codebase, informed by `CONTEXT.md` and ADRs. |
| `zoom-out` | Step out of the local view and give broader context / higher-level perspective on the current code. |

### Code review

| Skill | One-liner |
|---|---|
| `code-review` | Review a pull request against the repo's `CODE_REVIEW.md` doctrine and post the review as a PR comment. |
| `fix-code-review` | Fetch review comments, apply fixes, validate, commit, and push — runs end-to-end without manual gates. |

### Meta

| Skill | One-liner |
|---|---|
| `write-a-skill` | Create new agent skills with proper structure, progressive disclosure, and bundled resources. |

---

## Layout

```
tiby-skills/
├── README.md                   ← this file
├── _doctrine/                  ← canonical engineering doctrine (single source)
├── _scripts/                   ← sync-doctrine.sh
├── _templates/                 ← per-repo file templates written by /setup-harness
├── grill-with-docs/  tdd/  to-issues/  to-prd/  triage/    ← forked from Matt
├── diagnose/  improve-codebase-architecture/  zoom-out/    ← Matt verbatim
├── grill-me/  write-a-skill/                               ← Matt verbatim
├── repo-create/  repo-setup-ci/  repo-branch-protection/   ← mine
├── code-review/  fix-code-review/                          ← mine
└── setup-harness/                                          ← mine
```

Files prefixed `_` aren't skills — they're shared infrastructure. Everything else is an agent skill (`SKILL.md` plus optional sidecars).
