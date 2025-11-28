param(
  [Parameter(Mandatory=$true)] [string] $Owner,
  [Parameter(Mandatory=$true)] [string] $Repo
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "gh CLI not found. Install from https://cli.github.com/manual/installation"
  exit 1
}

$branches = @('main','develop')
$requiredContexts = @('ci','build')

foreach ($b in $branches) {
  Write-Host "Applying branch protection for $Owner/$Repo branch $b"
  gh api --method PUT "/repos/$Owner/$Repo/branches/$b/protection" `
    -f "required_status_checks.contexts=$($requiredContexts -join ' ')" `
    -f "required_status_checks.strict=true" `
    -f "enforce_admins=true" `
    -f "required_pull_request_reviews.dismiss_stale_reviews=true" `
    -f "required_pull_request_reviews.required_approving_review_count=1" `
    -F "allow_force_pushes=false" `
    -F "allow_deletions=false"
}

Write-Host "Branch protection applied."
