
# GitHub Labels Configuration

This document describes the **organization-wide label system** used for issues and pull requests, along with DevOps instructions for maintaining consistency across repositories.

---

## 🏷️ Label Categories

### **Priority Labels** (Red Spectrum)
- `priority/critical` – 🔴 Must have for milestone, blocks other work
- `priority/high` – 🟠 Important for milestone success
- `priority/medium` – 🟡 Nice to have, can be moved to next milestone
- `priority/low` – ⚫ Future consideration, not scheduled

### **Type Labels** (Blue Spectrum)
- `enhancement` – 🔵 New feature or improvement
- `bug` – 🔴 Something isn't working correctly
- `documentation` – 📚 Improvements or additions to documentation
- `question` – ❓ Further information is requested
- `duplicate` – ⚫ This issue or pull request already exists
- `wontfix` – ⚫ This will not be worked on
- `breaking-change` – ⚠️ Introduces breaking changes

### **Component Labels** (Green Spectrum)
- `core` – 🟢 Core library functionality
- `api` – 🔌 Public API and interfaces
- `testing` – 🧪 Testing framework and test cases
- `quality` – 🔍 Code quality and static analysis
- `configuration` – ⚙️ Configuration options
- `integration` – 🔗 Third-party integrations

### **Status Labels** (Purple Spectrum)
- `needs-triage` – 🟣 New issue that needs initial review
- `status/planning` – 📋 In planning and design phase
- `status/in-progress` – 🔄 Actively being worked on
- `status/review` – 👀 In code review or testing
- `status/blocked` – 🚫 Blocked by dependency or external factor
- `status/ready` – ✅ Ready for development to begin

### **Special Labels**
- `good-first-issue` – 🌱 Good for newcomers
- `help-wanted` – 🙋 Extra attention is needed
- `security` – 🔒 Security related issue
- `performance` – ⚡ Performance improvement
- `dependencies` – 📦 Updates to dependencies
- `size/small` – 🗏 Small change size
- `area/build` – 🛠️ Build system or CI/CD pipeline

---

## 📊 Label Usage Guidelines

### Issue Workflow
1. **Automatic Labels** via GitHub Actions:
   - `needs-triage` added to all new issues
   - Type labels added based on title prefix
   - Component labels added based on issue template selection

2. **Manual Triage**:
   - Review `needs-triage` issues within 2–3 business days
   - Add priority and component labels
   - Remove `needs-triage` and add `status/ready` or `status/planning`

3. **Development Workflow**:
   - Add `status/in-progress` when work begins
   - Add `status/review` when PR is created
   - Close issue when merged and tested

### Pull Request Labeling
- Match type and component labels to changes
- Add `breaking-change` for API changes
- Add `dependencies` for package updates
- Add priority labels for critical fixes

---

## 🔍 Useful Queries
```bash
# Ready for development
is:issue is:open label:"status/ready" label:"priority/high"

# Good first issues
is:issue is:open label:"good-first-issue" label:"priority/medium"

# Documentation needs
is:issue is:open label:documentation -label:"status/in-progress"

---

🛠️ DevOps Instructions for Label Management
1) Update Global Labels

Edit labels/labels.yml in the org .github repository.
Commit changes to develop or main.

2) Apply Changes to Repositories

All repos: Run “Fan-out labels to repositories” (or push changes to labels/labels.yml/repos.txt to auto-trigger).
Single repo: Run “Run single-target label sync” and set target-repo.


Start with dry-run: true to preview changes.
Use strict: true when you want to delete labels not present in the global file.

3) Repo-specific labels (optional)

If a repository needs extra labels, create .github/labels.yml in that repo and manage locally (Option 3 approach).
The org workflows are independent and don’t require this.

4) Verify

Check Issues → Labels in each repository and confirm changes.


CLI Examples (Optional quick fixes)
Shell# Create a labelgh label create "priority/critical" --color "B60205" --description "Must have for milestone"# Edit a labelgh label edit "needs-triage" --color "FBCA04" --description "New issue that needs initial review"# Bulk add priority label to enhancement issuesgh issue list --label "enhancement" --json number | jq -r '.[].number' | \xargs -I {} gh issue edit {} --add-label "priority/medium"Weitere Zeilen anzeigen

📈 Metrics

Triage Velocity: Time from needs-triage to status/ready
Development Velocity: Time from status/ready to closed
Priority Distribution: Balance of priority levels
Component Coverage: Issue distribution across components

---

## How to roll out (summary)

1. **Add files** to `winccoa-tools-pack/.github`:
   - `labels/labels.yml`
   - `repos.txt`
   - `docs/LABELS.md`

2. **Create org secret** `ORG_LABELS_PAT` (scope: `repo`).

3. **Test**:
   - Use the GitHub CLI or API to sync labels for a test repo.
   - Verify labels match `labels/labels.yml`.

---

<center>Made with ❤️ for and by the WinCC OA community</center>