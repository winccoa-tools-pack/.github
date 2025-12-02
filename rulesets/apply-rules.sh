#!/usr/bin/env bash
# Apply basic branch protection rules to a repository using gh CLI
set -euo pipefail
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <owner> <repo>"
  exit 2
fi
OWNER=$1
REPO=$2
# Apply protections to develop first, then main
BRANCHES=(develop main)
# Required status checks - update to match your workflow job names
REQUIRED_CONTEXTS=(ci build)

# Set these flags to control admin bypass and repo auto-merge
ALLOW_ADMINS_BYPASS=true
ENABLE_REPO_AUTO_MERGE=true
ENABLE_DELETE_HEAD_BRANCHES=true

for BR in "${BRANCHES[@]}"; do
  echo "Applying rules to $OWNER/$REPO branch $BR"
  gh api --method PUT "/repos/$OWNER/$REPO/branches/$BR/protection" \
    -f required_status_checks.contexts="${REQUIRED_CONTEXTS[*]}" \
    -f required_status_checks.strict=true \
    -f enforce_admins=${ALLOW_ADMINS_BYPASS} \
    -f required_pull_request_reviews.dismiss_stale_reviews=true \
    -f required_pull_request_reviews.required_approving_review_count=1 \
    -F allow_force_pushes=false \
    -F allow_deletions=false
done

# Ensure the develop branch exists and set it as the default branch
echo "Setting default branch to 'develop' for $OWNER/$REPO"
gh api --method PATCH "/repos/$OWNER/$REPO" -f default_branch=develop || true

if [ "$ENABLE_REPO_AUTO_MERGE" = true ] ; then
  echo "Enabling repository auto-merge for $OWNER/$REPO"
  gh api --method PATCH "/repos/$OWNER/$REPO" -f allow_auto_merge=true || true
fi

if [ "$ENABLE_DELETE_HEAD_BRANCHES" = true ] ; then
  echo "Enabling automatic delete of head branches for $OWNER/$REPO"
  gh api --method PATCH "/repos/$OWNER/$REPO" -f delete_branch_on_merge=true || true
fi

echo "Branch protection applied."
