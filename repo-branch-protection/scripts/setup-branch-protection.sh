#!/usr/bin/env bash
# Apply branch protection rules to a GitHub repo's branch via gh CLI.
# All options are passed as flags so the skill can drive it non-interactively.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO=""
BRANCH=""
ENFORCE_ADMINS="false"
APPROVALS="1"
DISMISS_STALE="true"
CODE_OWNER_REVIEWS="false"
REQUIRED_CHECKS=""
STRICT_CHECKS="true"
ALLOW_FORCE_PUSH="false"
ALLOW_DELETIONS="false"
ACTIONS_CAN_APPROVE="true"

usage() {
  cat <<EOF
Usage: $0 --repo <owner/name> [options]

Required:
  --repo <owner/name>             Target repository

Options (with defaults):
  --branch <name>                 Branch to protect (default: repo's default branch)
  --enforce-admins <true|false>   Apply rules to admins too (default: false = admins bypass)
  --approvals <N>                 Required approving reviews (default: 1)
  --dismiss-stale <true|false>    Dismiss stale reviews on new commits (default: true)
  --code-owner-reviews <bool>     Require CODEOWNERS approval (default: false)
  --required-checks <a,b,c>       Comma-separated required status check contexts (default: none)
  --strict-checks <true|false>    Require branch up-to-date before merge (default: true)
  --allow-force-push <bool>       Allow force pushes (default: false)
  --allow-deletions <bool>        Allow branch deletion (default: false)
  --actions-can-approve <bool>    Let GH Actions create/approve PRs (default: true)
  -h, --help                      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --enforce-admins) ENFORCE_ADMINS="$2"; shift 2 ;;
    --approvals) APPROVALS="$2"; shift 2 ;;
    --dismiss-stale) DISMISS_STALE="$2"; shift 2 ;;
    --code-owner-reviews) CODE_OWNER_REVIEWS="$2"; shift 2 ;;
    --required-checks) REQUIRED_CHECKS="$2"; shift 2 ;;
    --strict-checks) STRICT_CHECKS="$2"; shift 2 ;;
    --allow-force-push) ALLOW_FORCE_PUSH="$2"; shift 2 ;;
    --allow-deletions) ALLOW_DELETIONS="$2"; shift 2 ;;
    --actions-can-approve) ACTIONS_CAN_APPROVE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo -e "${RED}Unknown flag: $1${NC}" >&2; usage; exit 1 ;;
  esac
done

if ! command -v gh &> /dev/null; then
  echo -e "${RED}gh CLI not installed. See https://cli.github.com/${NC}" >&2
  exit 1
fi

if ! gh auth status &> /dev/null; then
  echo -e "${RED}Not authenticated. Run: gh auth login${NC}" >&2
  exit 1
fi

if [[ -z "$REPO" ]]; then
  echo -e "${RED}--repo is required${NC}" >&2
  usage
  exit 1
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH=$(gh api "repos/${REPO}" --jq '.default_branch')
fi

echo -e "${YELLOW}Repository: ${REPO}${NC}"
echo -e "${YELLOW}Branch: ${BRANCH}${NC}"

# Build contexts JSON array from comma-separated input
CONTEXTS_JSON="[]"
if [[ -n "$REQUIRED_CHECKS" ]]; then
  CONTEXTS_JSON=$(echo "$REQUIRED_CHECKS" | awk -F',' '{
    printf "[";
    for (i=1; i<=NF; i++) {
      gsub(/^ +| +$/, "", $i);
      printf "%s\"%s\"", (i>1?",":""), $i;
    }
    printf "]";
  }')
fi

PAYLOAD=$(cat <<EOF
{
  "required_status_checks": {
    "strict": ${STRICT_CHECKS},
    "contexts": ${CONTEXTS_JSON}
  },
  "enforce_admins": ${ENFORCE_ADMINS},
  "required_pull_request_reviews": {
    "required_approving_review_count": ${APPROVALS},
    "dismiss_stale_reviews": ${DISMISS_STALE},
    "require_code_owner_reviews": ${CODE_OWNER_REVIEWS}
  },
  "restrictions": null,
  "allow_force_pushes": ${ALLOW_FORCE_PUSH},
  "allow_deletions": ${ALLOW_DELETIONS}
}
EOF
)

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT
echo "$PAYLOAD" > "$TMP_FILE"

echo -e "${YELLOW}Applying branch protection...${NC}"
gh api "repos/${REPO}/branches/${BRANCH}/protection" \
  --method PUT \
  --input "$TMP_FILE" > /dev/null

echo -e "${GREEN}Branch protection applied.${NC}"

echo -e "${YELLOW}Configuring GitHub Actions workflow permissions...${NC}"
gh api "repos/${REPO}/actions/permissions/workflow" \
  --method PUT \
  --field "can_approve_pull_request_reviews=${ACTIONS_CAN_APPROVE}" > /dev/null

echo -e "${GREEN}Actions permissions configured.${NC}"

echo
echo -e "${GREEN}Done. Applied to ${REPO}@${BRANCH}:${NC}"
echo "  enforce_admins:           ${ENFORCE_ADMINS}"
echo "  approvals:                ${APPROVALS}"
echo "  dismiss_stale_reviews:    ${DISMISS_STALE}"
echo "  code_owner_reviews:       ${CODE_OWNER_REVIEWS}"
echo "  required_checks:          ${REQUIRED_CHECKS:-(none)}"
echo "  strict_checks:            ${STRICT_CHECKS}"
echo "  allow_force_pushes:       ${ALLOW_FORCE_PUSH}"
echo "  allow_deletions:          ${ALLOW_DELETIONS}"
echo "  actions_can_approve_prs:  ${ACTIONS_CAN_APPROVE}"
