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
  # Create a JSON payload file to preserve types (booleans, nulls)
  TMPFILE=$(mktemp)
  cat > "$TMPFILE" <<EOF
{
  "required_status_checks": { "strict": true, "contexts": ["${REQUIRED_CONTEXTS[0]}", "${REQUIRED_CONTEXTS[1]}"] },
  "enforce_admins": ${ALLOW_ADMINS_BYPASS:+false},
  "required_pull_request_reviews": { "dismiss_stale_reviews": true, "required_approving_review_count": 1 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

  gh api --method PUT "/repos/$OWNER/$REPO/branches/$BR/protection" --input "$TMPFILE" || true
  rm -f "$TMPFILE"
done

# Ensure the develop branch exists and set it as the default branch
echo "Setting default branch to 'develop' for $OWNER/$REPO"
if ! gh api "/repos/$OWNER/$REPO/git/ref/heads/develop" -q .ref >/dev/null 2>&1; then
  echo "Remote branch 'develop' not found; creating from main"
  main_sha=$(gh api "/repos/$OWNER/$REPO/git/ref/heads/main" -q .object.sha)
  if [ -n "$main_sha" ]; then
    gh api --method POST "/repos/$OWNER/$REPO/git/refs" -f ref=refs/heads/develop -f sha="$main_sha" || true
    echo "Created develop from main ($main_sha)"
  else
    echo "Unable to find main SHA; create develop manually and re-run this script"
  fi
fi

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
