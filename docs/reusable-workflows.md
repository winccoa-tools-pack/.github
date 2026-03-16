# Reusable Workflows – Caller Reference

> Phase 1 deliverable for [Issue #43](https://github.com/winccoa-tools-pack/.github/issues/43).
> These centralised workflows replace duplicated per-repo workflow logic.

---

## Secret Management

All callers use **`secrets: inherit`**. GitHub resolves secrets with automatic
priority:

1. **Repository-level secret** — set per repo when a custom token is needed
2. **Organization-level secret** — shared fallback for the whole org

| Secret | Used by | Purpose |
|---|---|---|
| `VSCE_PAT` | `reusable-release.yml` | VS Code Marketplace publish token |
| `NPM_TOKEN` | `reusable-prerelease.yml`, `reusable-release.yml` | npm registry publish token |
| `DOCKER_USER` | `reusable-ci-cd.yml` | Docker Hub username (integration tests) |
| `DOCKER_PASSWORD` | `reusable-ci-cd.yml` | Docker Hub password (integration tests) |
| `REPO_ADMIN_TOKEN` | `reusable-create-release-branch.yml`, `reusable-apply-settings-and-rulesets.yml` | Token with admin access (push to protected branches, manage rulesets) |

> **Setup**: Define `VSCE_PAT` and `NPM_TOKEN` as **org-level secrets** (Settings →
> Secrets → Actions) so every repo gets them automatically. When a specific repo
> needs its own token (e.g. different marketplace publisher), add a **repo-level
> secret** with the same name — it overrides the org secret.

---

## Overview

| Reusable Workflow | Purpose | Replaces (per-repo) |
|---|---|---|
| `reusable-ci-cd.yml` | Lint, format, test, integration-test, Git Flow validation | `ci-cd.yml` + `gitflow-validation.yml` |
| `reusable-prerelease.yml` | Version bump + pre-release packaging | `prerelease-reusable.yml` |
| `reusable-release.yml` | Tag + publish final release | `release-reusable.yml` |
| `reusable-create-release-branch.yml` | Create release/hotfix branch + PR | `create-release-branch.yml` |
| `reusable-apply-settings-and-rulesets.yml` | Apply repo settings & branch rulesets via API | `apply-settings-and-rulesets.yml` + `generate_settings_payloads.py` |
| `reusable-gitflow-upmerge.yml` | Upmerge main → develop via PR after release | `gitflow.yml` |

All workflows live in `.github/workflows/` of this organisation repo and are called
with `uses: winccoa-tools-pack/.github/.github/workflows/<file>@main`.

---

## 1. CI/CD Pipeline – `reusable-ci-cd.yml`

### Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `build_command` | string | `npm run build` | Build command to execute |
| `enable_coverage` | boolean | `false` | Collect coverage on one matrix cell |
| `coverage_node_version` | string | `25.x` | Node version for coverage |
| `enable_xvfb` | boolean | `false` | Set up Xvfb on Linux (VS Code extensions) |
| `enable_integration_tests` | boolean | `true` | Run WinCC OA Docker integration tests |
| `integration_test_command` | string | _(empty)_ | Command inside Docker container |
| `fixture_config_path` | string | `./test/fixtures/…/config` | Host-side fixture check path |
| `docker_image_name` | string | `mpokornyetm/…:npm-winccoa-core` | Docker image for integration tests |

### Jobs

The CI/CD pipeline now includes **8 jobs**:

1. **changelog** — Verify CHANGELOG.md for release/hotfix PRs
2. **lint** — ESLint + markdown lint
3. **format** — Prettier format check
4. **test** — Unit tests (2 OS × 4 Node versions matrix)
5. **integration-winccoa** — WinCC OA Docker integration tests
6. **gitflow-validation** — Git Flow branch naming + Conventional Commits (PR only)
7. **remind-branch-deletion** — Comment reminder on merged PRs (PR closed + merged)
8. **required** — Gate job for branch protection

> **Note**: Jobs 6–7 replace the per-repo `gitflow-validation.yml` workflow. The
> caller’s `on:` trigger must include `pull_request` with `types: [opened,
> synchronize, reopened, edited, ready_for_review, closed]` for validation to run.

### Secrets

`DOCKER_USER`, `DOCKER_PASSWORD` – optional, for Docker Hub auth.

### Caller – VS Code extension

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop, "release/**", "hotfix/**"]
  pull_request:
    branches: [main, develop]
    types: [opened, synchronize, reopened, edited, ready_for_review, closed]
  workflow_dispatch:
    inputs:
      confirmed_local_tests:
        description: "I confirm that I have run all integration tests locally and they passed"
        required: true
        type: boolean
        default: false

jobs:
  ci-cd:
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-ci-cd.yml@main
    with:
      build_command: "npm run compile:tsc"
      enable_coverage: true
      enable_xvfb: true
      integration_test_command: "xvfb-run -a npx --no-install vscode-test --label integrationTests"
      fixture_config_path: "./src/test/fixtures/projects/runnable/config/config"
    secrets: inherit
```

### Caller – npm library

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop, "release/**", "hotfix/**"]
  pull_request:
    branches: [main, develop]
    types: [opened, synchronize, reopened, edited, ready_for_review, closed]
  workflow_dispatch:
    inputs:
      confirmed_local_tests:
        description: "I confirm that I have run all integration tests locally and they passed"
        required: true
        type: boolean
        default: false

jobs:
  ci-cd:
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-ci-cd.yml@main
    with:
      integration_test_command: 'xvfb-run -s "-screen 0 1280x1024x24" node --import tsx scripts/run-node-tests.ts test/integration'
    secrets: inherit
```

---

## 2. Pre-release – `reusable-prerelease.yml`

### Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `target_branch` | string | _(required)_ | Branch to version/package |
| `validate_release_branch` | boolean | `true` | Require `release/` or `hotfix/` prefix |
| `project_type` | string | _(required)_ | `vscode` or `npm` |
| `publish_to_npm` | boolean | `false` | Publish to npm with `next` tag (npm only) |

### Secrets

`NPM_TOKEN` – optional, required when `publish_to_npm: true`.

### Caller – VS Code extension (from `pre-release-develop.yml`)

```yaml
name: "Pre-Release (develop)"

on:
  workflow_run:
    workflows: ["CI/CD Pipeline"]
    branches: [develop]
    types: [completed]

jobs:
  pre-release:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-prerelease.yml@main
    with:
      target_branch: ${{ github.event.workflow_run.head_branch || github.ref_name }}
      validate_release_branch: false
      project_type: vscode
    secrets: inherit
```

### Caller – npm library (from `pre-release-develop.yml`)

```yaml
name: "Pre-Release (develop)"

on:
  workflow_run:
    workflows: ["CI/CD Pipeline"]
    branches: [develop]
    types: [completed]

jobs:
  pre-release:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-prerelease.yml@main
    with:
      target_branch: ${{ github.event.workflow_run.head_branch || github.ref_name }}
      validate_release_branch: false
      project_type: npm
      publish_to_npm: false
    secrets: inherit
```

---

## 3. Release – `reusable-release.yml`

### Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `target_branch` | string | _(required)_ | Branch to release from |
| `project_type` | string | _(required)_ | `vscode` or `npm` |

### Secrets

- `VSCE_PAT` – optional, required for `project_type: vscode` (VS Marketplace publish).
- `NPM_TOKEN` – optional, required for `project_type: npm`.

### Caller – VS Code extension

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      target_branch:
        description: "Branch to release"
        required: true
        default: "main"
        type: string

jobs:
  release:
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-release.yml@main
    with:
      target_branch: ${{ inputs.target_branch || 'main' }}
      project_type: vscode
    secrets: inherit
```

### Caller – npm library

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      target_branch:
        description: "Branch to release"
        required: true
        default: "main"
        type: string

jobs:
  release:
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-release.yml@main
    with:
      target_branch: ${{ inputs.target_branch || 'main' }}
      project_type: npm
    secrets: inherit
```

---

## 4. Create Release Branch – `reusable-create-release-branch.yml`

### Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `kind` | string | _(required)_ | `release` or `hotfix` |
| `version` | string | _(required)_ | SemVer (e.g. `1.2.3`) |
| `base_branch` | string | `develop` | Source branch |
| `target_branch` | string | `main` | PR target branch |
| `draft` | boolean | `false` | Create PR as draft |
| `labels` | string | `chore,release` | Comma-separated labels |
| `project_type` | string | _(required)_ | `vscode` or `npm` |

### Secrets

`REPO_ADMIN_TOKEN` – optional, for repos with branch protection rules.

### Caller (identical for both project types, only `project_type` differs)

```yaml
name: Create Release Branch + PR

on:
  workflow_dispatch:
    inputs:
      kind:
        description: "Branch type to create"
        required: true
        default: "release"
        type: choice
        options:
          - release
          - hotfix
      version:
        description: "Release version (SemVer, e.g. 1.2.3)"
        required: true
        type: string
      base_branch:
        description: "Base branch (release: develop, hotfix: main)"
        required: true
        default: "develop"
        type: string
      target_branch:
        description: "PR target branch (typically main)"
        required: true
        default: "main"
        type: string
      draft:
        description: "Create PR as draft"
        required: true
        default: false
        type: boolean
      labels:
        description: "Comma-separated labels to apply (optional)"
        required: false
        default: "chore,release"
        type: string

jobs:
  create:
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-create-release-branch.yml@main
    with:
      kind: ${{ inputs.kind }}
      version: ${{ inputs.version }}
      base_branch: ${{ inputs.base_branch }}
      target_branch: ${{ inputs.target_branch }}
      draft: ${{ inputs.draft }}
      labels: ${{ inputs.labels }}
      project_type: npm   # or: vscode
    secrets: inherit
```

---

## 5. Apply Settings & Rulesets – `reusable-apply-settings-and-rulesets.yml`

Applies `.github/repository.settings.yml` and `.github/rulesets/*.yml` to the
repository via the GitHub REST API. The Python helper script
(`generate_settings_payloads.py`) lives in this org repo — consumer repos do
**not** need a local copy of the script.

### Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `mode` | string | `apply` | `dry-run` prints payloads; `apply` updates the repo |

### Secrets

`REPO_ADMIN_TOKEN` — PAT with admin access. Repo-level overrides org-level.

### Caller (identical for all repos)

```yaml
name: Apply Repo Settings & Rulesets

on:
  push:
    branches: [develop, main]
    paths:
      - ".github/repository.settings.yml"
      - ".github/rulesets/**"
  workflow_dispatch:
    inputs:
      mode:
        description: "dry-run prints payloads; apply updates repo settings/rulesets"
        required: true
        default: "apply"
        type: choice
        options:
          - dry-run
          - apply

jobs:
  apply:
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-apply-settings-and-rulesets.yml@main
    with:
      mode: ${{ inputs.mode || 'apply' }}
    secrets: inherit
```

> **Note**: Once migrated, the per-repo copies of `apply-settings-and-rulesets.yml`
> and `.github/scripts/generate_settings_payloads.py` can be deleted.

---

## 6. GitFlow Upmerge – `reusable-gitflow-upmerge.yml`

After a push to main (typically a release merge), creates or updates a PR that
merges main back into develop — the standard GitFlow upmerge step.

### Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `source_branch` | string | `main` | Branch to merge FROM |
| `target_branch` | string | `develop` | Branch to merge INTO |
| `upmerge_branch` | string | `feature/upmerge-main-to-develop` | Intermediate PR branch |
| `auto_merge_method` | string | `SQUASH` | Auto-merge method (`SQUASH`, `MERGE`, `REBASE`, or empty) |

### Secrets

`REPO_ADMIN_TOKEN` — PAT with repo access. Required so the push/PR triggers
downstream workflows (CI/CD, Git Flow Validation). Falls back to `GITHUB_TOKEN`.

### Caller (identical for all repos)

```yaml
name: GitFlow (Upmerge main → develop via PR)

on:
  push:
    branches: [main]
  workflow_dispatch: {}

jobs:
  upmerge:
    uses: winccoa-tools-pack/.github/.github/workflows/reusable-gitflow-upmerge.yml@main
    secrets: inherit
```

> **Note**: Once migrated, the per-repo copies of `gitflow.yml` can be deleted.
> The 3 repos still using the legacy `Logerfo/gitflow-action@0.0.5`
> (vscode-winccoa-ctrllang, githbut-ci-workflow-build-winccoa-docker-image,
> vscode-winccoa-tests) should be migrated to this reusable workflow.

---

## Migration Notes

### Phase 2 – Template Updates (not yet done)
1. Replace per-repo workflow bodies with thin callers shown above.
2. Update branch protection required status checks — reusable workflow job
   names appear as `<caller_job> / <reusable_job>` (e.g. `ci-cd / lint`).
3. The npm template's `pre-release.yml` still uses the legacy `standard-version`
   flow (289 lines). It should be modernised to match the VS Code template's
   pattern (wait → changelog-preview → call reusable-prerelease → cleanup).
4. Identical simple workflows (dependabot-auto-merge, stale, sync-labels, etc.)
   are already handled by `template-sync-reusable.yml` and were not included here.
5. **Org secrets**: Ensure `VSCE_PAT` and `NPM_TOKEN` are configured as org-level
   secrets so every repo inherits them automatically. Repos that need custom tokens
   can override with a repo-level secret of the same name.
