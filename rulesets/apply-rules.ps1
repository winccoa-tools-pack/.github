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

  # Build strongly-typed JSON payload to avoid form-encoding type coercion issues
  $payload = [ordered]@{
    required_status_checks = [ordered]@{
      strict = $true
      contexts = $requiredContexts
    }
    enforce_admins = -not $AllowAdminsBypass
    required_pull_request_reviews = [ordered]@{
      dismiss_stale_reviews = $true
      required_approving_review_count = 1
    }
    restrictions = $null
    allow_force_pushes = $false
    allow_deletions = $false
  }

  $tmp = [System.IO.Path]::GetTempFileName()
  $json = $payload | ConvertTo-Json -Depth 6
  Set-Content -Path $tmp -Value $json -Encoding utf8

  gh api --method PUT "/repos/$Owner/$Repo/branches/$b/protection" --input $tmp
  Remove-Item -Path $tmp -ErrorAction SilentlyContinue
}

# Ensure the develop branch exists and set it as the default branch before applying protections
try {
  $ref = gh api "/repos/$Owner/$Repo/git/ref/heads/develop" -q .ref 2>$null
} catch {
  Write-Host "Remote branch 'develop' not found, creating from 'main'"
  $mainSha = gh api "/repos/$Owner/$Repo/git/ref/heads/main" -q .object.sha
  if ($mainSha) {
    gh api --method POST "/repos/$Owner/$Repo/git/refs" -f "ref=refs/heads/develop" -f "sha=$mainSha" | Out-Null
    Write-Host "Created 'develop' from main ($mainSha)"
  } else {
    Write-Host "Unable to determine main SHA; please create 'develop' branch manually."
  }
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
