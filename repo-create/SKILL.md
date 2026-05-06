---
name: repo-create
description: Create a new GitHub repository interactively. Use when the user says 'create repo', 'new repo', 'new repository', 'create github repo', or wants to bootstrap a new GitHub repository. Asks for owner (personal or organization), visibility, and offers to set up branch protection afterwards.
---

# Create GitHub Repository

Create a new GitHub repository via the `gh` CLI. Walk the user through an interactive interview, then create the repo, then optionally hand off to the `repo-branch-protection` skill.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status`). If not, instruct the user to run `gh auth login` and stop.

## Interview

Ask each question in order. If the user has already provided an answer in their initial message, skip that question.

1. **Repo name** — required. Optionally collect a short description.

2. **Owner** — "Should this repo be created under your personal account or an organization?"
   - If **organization**: ask for the organization URL or name (e.g., `https://github.com/acme` or just `acme`). Parse the trailing path segment as the org slug.
   - If **personal**: use the authenticated user (`gh api user --jq .login`).

3. **Visibility** — "Public or private?"

4. **Local init** — "Create a local clone and push an initial commit, or remote-only?"
   - If local: create the repo with `--clone`, add a minimal README if the directory is empty, commit, and push.
   - If remote-only: just create the repo on GitHub.

## Create

Run:

```bash
gh repo create <owner>/<name> \
  --public|--private \
  [--description "..."] \
  [--clone]
```

For local init after `--clone`, `cd` into the new directory; if no README exists, write one with the repo name as the H1 and the description as the first line, then `git add . && git commit -m "chore: initial commit" && git push -u origin main`.

## Hand-off

After successful creation, ask: **"Set up branch protection on the default branch now?"**

If yes, invoke the `repo-branch-protection` skill. Pass the new `<owner>/<name>` as the target repo so it doesn't need to ask again.

If no, print the repo URL (`gh repo view <owner>/<name> --json url --jq .url`) and stop.

## Notes

- Do not configure teams, collaborators, topics, or other org settings. Keep it minimal.
- If `gh repo create` fails because the name already exists, surface the error and ask the user how to proceed (different name? different owner?). Do not retry blindly.
