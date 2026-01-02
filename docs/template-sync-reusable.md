# Template → Child Repository Sync (Reusable Workflow)

Keep all your shared files (e.g., **issue templates**, **workflows**, **CODEOWNERS**, **editor config**) in a **single template repository** and have each child repository **periodically sync** and receive a **Pull Request** with any changes.  
This is implemented using a **reusable workflow** defined in the org DevOps repository.

---

## ✨ What you get

- **Central governance**: define once, reuse everywhere via `workflow_call`.
- **Safe rollout**: changes arrive to each child repository as a **PR** for review/merge.
- **Granular scope**: sync only what you want (`paths` globs).
- **Two modes**:  
  - `update` → copy/overwrite files but keep local extras  
  - `mirror` → enforce exact parity (delete extras under selected subtrees)
- **No PAT required** in child repos (uses their `GITHUB_TOKEN` by default).  
  You can pass a PAT if you need special triggering or identity.

---

## 🧱 Repository structure

```

.github/
workflows/
template-sync-reusable.yml    # <— Reusable workflow (in org DevOps repo)
docs/
template-sync-reusable.md        # <— This guide

````

> Consumers (child repos) add a tiny **caller workflow** that points to the reusable one.

---

## ⚙️ Reusable workflow reference

**Location (in this repo):**  
`.github/workflows/template-sync-reusable.yml`

**Trigger:** `workflow_call` (the workflow is invoked by other workflows)

### Inputs

| Input | Type | Required | Default | Description |
|---|---|:---:|---|---|
| `template_repo` | string | ✓ | — | Template repo in `owner/repo` format. |
| `template_ref` | string |  | `main` | Branch or tag in the template repo. |
| `paths` | string (multiline) | ✓ | — | Newline-separated **globs** (relative to template) to sync. |
| `sync_mode` | string |  | `update` | `update` or `mirror`. |
| `pr_title` | string |  | `chore(template): sync from template repository` | PR title. |
| `pr_body` | string |  | `Automated sync from template.` | PR body/description. |
| `pr_labels` | string |  | `sync, automated` | Comma-separated labels. |
| `pr_reviewers` | string |  | *(empty)* | Comma-separated users and/or `org/team`. |
| `branch_prefix` | string |  | `chore/template-sync` | Prefix for temporary sync branch. |

### Secrets

| Secret | Required | Notes |
|---|:---:|---|
| `token` | ✗ | Optional **fine-grained PAT**. If not supplied, the caller repo’s `GITHUB_TOKEN` is used. |

### Required permissions (executed in the caller repo context):
```yaml
permissions:
  contents: write
  pull-requests: write
````

---

## ▶️ How to use in a child repository

Create a **caller** workflow in the child repo:

**`.github/workflows/use-template-sync.yml`**

```yaml
name: Use reusable template sync
on:
  schedule:
    - cron: "15 6 * * 1-5"     # weekdays 06:15 UTC
  workflow_dispatch:

jobs:
  sync:
    uses: your-org/your-org-github/.github/workflows/template-sync-reusable.yml@v1
    with:
      template_repo: "your-org/templates"
      template_ref:  "main"
      sync_mode:     "update"   # or "mirror"
      paths: |
        .github/ISSUE_TEMPLATE/**/*.yml
        .github/ISSUE_TEMPLATE/**/*.yaml
      pr_title:  "chore(template): sync issue templates"
      pr_body:   "Automated sync from org template repository."
      pr_labels: "sync, automated"
      pr_reviewers: "your-user, your-org/team"
      branch_prefix: "chore/template-sync"
    secrets: inherit
```

> Replace `your-org/your-org-github` with the **org DevOps repo** that hosts the reusable workflow, and pin `@v1` to a **tag** you create in that repo.

---

## 🧪 Common configurations

### 1) Issue templates only (recommended first rollout)

```yaml
paths: |
  .github/ISSUE_TEMPLATE/**/*.yml
  .github/ISSUE_TEMPLATE/**/*.yaml
sync_mode: update
```

### 2) Governance & docs

```yaml
paths: |
  CODEOWNERS
  .editorconfig
  .github/*.md
  .github/workflows/shared-*.yml
sync_mode: update
```

### 3) Strict enforcement (mirror mode)

```yaml
paths: |
  .github/ISSUE_TEMPLATE/**
  .github/workflows/shared-ci.yml
sync_mode: mirror
```

> `mirror` will **delete** files under listed subtrees that are not present in the template. Use after you’re confident.

---

## 🔐 Permissions & security model

* The reusable workflow **runs in the caller (child) repo context**. That means:
  * It uses the child repo’s **`GITHUB_TOKEN`** unless a **PAT** is passed as `secrets.token`.
  * It needs `contents: write` and `pull-requests: write` in the caller workflow/job to push a branch and open PRs.
* For private orgs, confirm that **Actions access policies** allow the child repo to use workflows from the org DevOps repo (the one hosting this reusable workflow).
* If you require PRs to **trigger additional workflows** or need a specific identity, pass a **fine‑grained PAT** via `secrets.token` (scoped to the **child repo**).

---

## 🔄 Versioning & rollout strategy

* **Tag** the reusable workflow in the org DevOps repo (`v1`, `v1.1`, …).
* Child repos should reference the tag:  
    `uses: your-org/your-org-github/.github/workflows/template-sync-reusable.yml@v1`
* When you ship changes, bump to `v1.1` and increment callers gradually (or provide a PR sweep).

---

## 🛠️ Troubleshooting

**No PR created**

* Check the run log for “No changes to commit” (the repo already matches the template).
* Ensure the **paths globs** actually match files in the template repo.
* In `mirror` mode, verify that the top-level folders derived from globs exist (the workflow computes subtrees from your globs for deletion).

**Push failed / permission denied**

* Ensure the caller job has:

    ```yaml
    permissions:
      contents: write
      pull-requests: write
    ```

* If your org enforces restricted permissions, use a **fine‑grained PAT** via `secrets: token`.

**Reviewers not assigned**

* The users/teams must have access to the repo. For teams, use `org/team` syntax.

**We need different reviewers per repo**

* Add a small wrapper workflow in each child that passes repo‑specific `pr_reviewers` (and labels).  
    Alternatively, create a tiny config file (e.g., `.github/template-sync.yml`) read by a pre‑step in the caller to build inputs.

---

## 🧩 Advanced usage ideas

* **Multiple sync calls**: run several jobs calling the same reusable workflow with different `paths` (e.g., one for issue templates, one for workflows).
* **Policy checks**: insert additional steps in the caller (before or after) to lint synced files.
* **Dry‑run**: add a “preview changes” step in the caller (list changed files without committing) for experimentation.

---

## 🧭 Governance recommendations

* Keep the **template repo** the single source of truth.
* Start with `sync_mode: update` and **monitor PRs**.
* After 2–3 cycles, switch certain areas to `mirror` to ensure conformance.
* Announce tag updates in your engineering channel and create a short “what changed” note.

---

## 📌 Example: Minimal caller for issue templates

```yaml
name: Template sync (issue templates)
on:
  schedule: [{ cron: "0 7 * * 1" }]
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  sync-issues:
    uses: your-org/your-org-github/.github/workflows/template-sync-reusable.yml@v1
    with:
      template_repo: "your-org/templates"
      paths: |
        .github/ISSUE_TEMPLATE/**/*.yml
        .github/ISSUE_TEMPLATE/**/*.yaml
      pr_title: "chore(template): sync issue templates"
      pr_labels: "sync, automated"
    secrets: inherit
```

---

## ❓FAQ

**Q: Can we restrict which repos may run the reusable workflow?**  
A: Yes. Adjust **Actions access policies** in the org DevOps repo to allow only specific repositories. (In private setups, access must be explicitly configured.)

**Q: Do PRs created by `GITHUB_TOKEN` trigger other workflows?**  
A: `pull_request` workflows in the same repo are triggered. If you need to trigger `push` workflows from the bot branch or require a distinct identity, use a **PAT**.

**Q: Can we sync binary files or large directories?**  
A: Yes—globs are generic. Consider repository size and checkout time; for large assets, prefer package registries or releases.

---

## ✅ Change log (example)

* **v1.0.0** – Initial release: update/mirror modes, PR labels/reviewers, arbitrary globs.
* **v1.1.0** – Improved subtree detection for `mirror`, better diagnostics, safer branch naming.

---

## 📣 Contact / Ownership

* **Owners:** DevOps / Platform Engineering
* **Escalation:** `#devops` Slack / MS Teams channel
* **Maintenance window:** Wednesdays, 13:00–15:00 CET

---

<center>Made with ❤️ for and by the WinCC OA community</center>
