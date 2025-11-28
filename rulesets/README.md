# Branch protection rules

This folder contains recommended branch protection guidance and scripts to apply repository-level protections for common branches (`main`, `develop`). The scripts use the GitHub CLI (`gh`) to call the repository branch protection API.

Recommended settings applied by the scripts:

- Require pull request reviews (1 approving reviewer)
- Dismiss stale approvals when new commits are pushed
- Require passing status checks (CI) and up-to-date branches before merge
- Enforce for admins
- Disallow force pushes and branch deletions

Usage (Linux / macOS):

```bash
# install and authenticate gh: https://cli.github.com/manual/installation
gh auth login
./apply-rules.sh <owner> <repo>    # e.g. ./apply-rules.sh winccoa-tools-pack my-repo
```

Usage (Windows PowerShell):

```powershell
# install and authenticate gh: https://cli.github.com/manual/installation
gh auth login
.\apply-rules.ps1 -Owner winccoa-tools-pack -Repo my-repo
```

Notes:

- The scripts set required status check contexts to a conservative list (`ci`, `build`). Adjust the contexts to match your repository's workflow names.
- You must have `repo` scope permission for the GitHub token used by `gh`.
- These scripts are idempotent and safe to run multiple times.

Runbook:

- See `.github/RUNBOOK-SETUP-WORKFLOWS.md` for detailed instructions on the dispatchable setup workflows and their caveats.

Important branch name note:

- These scripts and workflows assume the primary long-lived branch is named `main`. If your repository still uses `master`, create a `main` branch or update the workflows/scripts to target `master` before running them.
