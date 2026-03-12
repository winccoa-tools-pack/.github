# Reusable Workflows – Caller Reference

> Phase 1 deliverable for [Issue #43](https://github.com/winccoa-tools-pack/.github/issues/43).
> These centralised workflows replace duplicated per-repo workflow logic.

---

## Overview

| Reusable Workflow | Purpose | Replaces (per-repo) |
|---|---|---|
| `reusable-ci-cd.yml` | Lint, format, test, integration-test pipeline | `ci-cd.yml` |
| `reusable-prerelease.yml` | Version bump + pre-release packaging | `prerelease-reusable.yml` |
| `reusable-release.yml` | Tag + publish final release | `release-reusable.yml` |
| `reusable-create-release-branch.yml` | Create release/hotfix branch + PR | `create-release-branch.yml` |

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
    types: [opened, synchronize, reopened, ready_for_review]
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
    types: [opened, synchronize, reopened, ready_for_review]
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
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
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
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
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
