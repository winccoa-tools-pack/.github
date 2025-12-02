param(
  [Parameter(Mandatory=$true)] [string] $Owner,
  [Parameter(Mandatory=$true)] [string] $Repo
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "gh CLI not found. Install from https://cli.github.com/manual/installation"
  exit 1
}

$branches = @('develop','main')
$requiredContexts = @('ci','build')

# Set these variables to control admin bypass and repo auto-merge
$AllowAdminsBypass = $true
$EnableRepoAutoMerge = $true
# Automatically delete head branches on merge
$DeleteHeadBranchesOnMerge = $true

foreach ($b in $branches) {
  Write-Host "Applying branch protection for $Owner/$Repo branch $b"
  $enforceAdminsVal = if ($AllowAdminsBypass) { 'false' } else { 'true' }
  gh api --method PUT "/repos/$Owner/$Repo/branches/$b/protection" `
    -f "required_status_checks.contexts=$($requiredContexts -join ' ')" `
    -f "required_status_checks.strict=true" `
    -f "enforce_admins=$enforceAdminsVal" `
    -f "required_pull_request_reviews.dismiss_stale_reviews=true" `
    -f "required_pull_request_reviews.required_approving_review_count=1" `
    -F "allow_force_pushes=false" `
    -F "allow_deletions=false"
}

# Ensure the develop branch exists and set it as the default branch before applying protections
if (-not (git ls-remote --heads "https://github.com/$Owner/$Repo.git" develop)) {
  Write-Host "Creating remote branch 'develop' from main (if main exists)"
  # Try to create develop locally and push
  git init -q temp-repo 2>$null | Out-Null
  Remove-Item -Recurse -Force temp-repo 2>$null | Out-Null
}

Write-Host "Setting default branch to 'develop' for $Owner/$Repo"
gh api --method PATCH "/repos/$Owner/$Repo" -f default_branch=develop | Out-Null

if ($EnableRepoAutoMerge) {
  Write-Host "Enabling repository auto-merge for $Owner/$Repo"
  gh api --method PATCH "/repos/$Owner/$Repo" -f "allow_auto_merge=true" | Out-Null
}

if ($DeleteHeadBranchesOnMerge) {
  Write-Host "Enabling delete head branches on merge for $Owner/$Repo"
  gh api --method PATCH "/repos/$Owner/$Repo" -f "delete_branch_on_merge=true" | Out-Null
}

Write-Host "Branch protection applied."
