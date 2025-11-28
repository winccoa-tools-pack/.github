# Runbook: Setup Workflows

This runbook documents the dispatchable setup workflows included in the repository and how to use them to initialize a new repository created from the templates.

Workflows covered

- `.github/workflows/setup-labels.yml` — creates a standard set of issue labels (bug, enhancement, documentation, dependencies, chore, release).
- `.github/workflows/setup-gitflow.yml` — creates `develop` and a `release/template` branch if they do not already exist.
- `.github/workflows/setup-branch-protection.yml` — applies branch protection for `main` and `develop` with conservative settings (required status checks, required reviews, disallow force pushes/deletions).

How to run

1. Open the repository on GitHub.
2. Go to the Actions tab and select the desired workflow (e.g., `Setup Labels`).
3. Click "Run workflow" to execute the job. You must have repository admin permissions to modify labels, branches or protections.

Notes and caveats

- The scripts and workflows assume the default long-lived branches are named `main` and `develop`. If your repository uses `master` instead of `main`, create a `main` branch or edit the workflows to use your default branch name before running them.
- Branch protection will attempt to set required status check contexts `ci` and `build`. Update these contexts if your CI uses different job names.
- Running `setup-gitflow.yml` will push new branches (`develop`, `release/template`) to the repository; ensure that you want these branches created before running.

Security reporting and templates

- This organization includes a security issue form at `.github/ISSUE_TEMPLATE/security.yml` that guides reporters through responsible disclosure. If a security report is submitted via the issue form, maintainers will triage it and move sensitive details to private handling as needed.
- Reminder: The placeholder security contact email `<security@winccoa-tools-pack.example>` in `.github/SECURITY.md` and template `SECURITY.md` files must be replaced with your real security contact before publishing or using the templates in production.

If you need the automation to run automatically at repository creation time, consider adding a repository template hook or using an organization-level provisioning workflow.

Auto-setup for Discussions (optional)

You can automatically pre-populate Discussion categories when a repository is created by calling the `auto-setup-discussions` workflow using `repository_dispatch`. Two examples follow.

Using `gh`:

```bash
gh api repos/:owner/:repo/dispatches -f event_type='auto-setup-discussions' -f client_payload='{ "owner": "my-org", "repo": "my-repo" }'
```

Using `curl` (requires a PAT with `repo` and `discussions:write` scopes):

```bash
curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"auto-setup-discussions","client_payload":{"owner":"OWNER","repo":"REPO"}}'
```

Notes:

- The token used to call `repository_dispatch` must have `repo` and `discussions:write` permissions for the target repository.
- If you want this to happen automatically when a repository is created from a template, you can wire the `dispatch` call into your repository provisioning process (for example, in an org-level repository creation script or via a custom webhook).
