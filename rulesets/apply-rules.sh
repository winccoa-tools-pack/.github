#!/usr/bin/env bash
# Apply basic branch protection rules to a repository using gh CLI
set -euo pipefail
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <owner> <repo>"
  exit 2
fi
OWNER=$1
REPO=$2
BRANCHES=(main develop)
# Required status checks - update to match your workflow job names
REQUIRED_CONTEXTS=(ci build)

for BR in "${BRANCHES[@]}"; do
  echo "Applying rules to $OWNER/$REPO branch $BR"
  gh api --method PUT "/repos/$OWNER/$REPO/branches/$BR/protection" \
    -f required_status_checks.contexts="${REQUIRED_CONTEXTS[*]}" \
    -f required_status_checks.strict=true \
    -f enforce_admins=true \
    -f required_pull_request_reviews.dismiss_stale_reviews=true \
    -f required_pull_request_reviews.required_approving_review_count=1 \
    -F allow_force_pushes=false \
    -F allow_deletions=false
done

echo "Branch protection applied."
