# github-ci-workflows (template)

Reusable workflow that builds and tests Node.js projects. Call via `uses:` from other repos.

## 🏆 Recognition

Special thanks to all our [contributors](https://github.com/orgs/winccoa-tools-pack/people) who make this project possible!

### Key Contributors

- **Martin Pokorny** ([@mPokornyETM](https://github.com/mPokornyETM)) - Creator & Lead Developer
- And many more amazing contributors!

---

## 📜 License

This project is basically licensed under the **MIT License** - see the [LICENSE](https://github.com/winccoa-tools-pack/.github/blob/main/LICENSE) file for details.

It might happens, that the partial repositories contains third party SW which are using other license models.

---

## ⚠️ Disclaimer

**WinCC OA** and **Siemens** are trademarks of Siemens AG. This project is not affiliated with, endorsed by, or sponsored by Siemens AG. This is a community-driven open source project created to enhance the development experience for WinCC OA developers.

---

## 🎉 Thank You

Thank you for using WinCC OA tools package! We're excited to be part of your development journey.

**Happy Coding! 🚀**

---

**Quick Links**

- [📦 VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=mPokornyETM.wincc-oa-projects)

*Made with ❤️ for and by the WinCC OA community*

---

## 🔐 Required Secrets (placeholders)

The workflows included in this template may require the following repository secrets to be set in each repository using the template. Add these under Settings → Secrets → Actions.

- `GITHUB_TOKEN` (automatically provided by GitHub Actions) — used for tagging and pushing.
- `VSCE_PAT` — personal access token for publishing to the VS Code Marketplace (optional).
- `GHCR_TOKEN` — optional token if you publish container images or use registries.

If a secret is not present, the workflow will attempt to skip the corresponding publish steps and continue.

## 🧩 Publish secrets and behavior

- **Default behavior:** The provided workflows are defensive: publish steps check for the presence of repository secrets (for example `VSCE_PAT`) and will skip publishing when secrets are not defined. This lets you use the CI and release automation without exposing credentials in forks or test repositories.
- **If you want strict enforcement:** To require publishing secrets be present and fail the workflow when missing, add an explicit pre-check in the workflow or enable a required status check that validates secret presence via a small validation job. Example snippet you can add at the top of your `release` job:

```yaml
  - name: Ensure required secrets
    shell: bash
    run: |
      if [ -z "${{ secrets.VSCE_PAT }}" ]; then
        echo "Required secret VSCE_PAT is missing. Set repository secret 'VSCE_PAT' to enable publishing.";
        exit 1;
      fi
```

- **Recommended:** Keep the template workflows defensive by default and opt into strict secret enforcement only for repositories that intentionally publish to the Marketplace.

## 🔁 Dependency updates (Dependabot)

This template includes a Dependabot configuration that opens weekly pull requests to update:

- `npm` dependencies found in `package.json`
- `GitHub Actions` workflow versions used under `.github/workflows`

Dependabot config is included both at the org repo root (`.github/dependabot.yml`) and inside this template so repositories created from the template will inherit the same weekly schedule. Review and approve Dependabot PRs to keep dependencies up to date. You can customize the schedule and package-ecosystems as needed.

## ⚙️ How to enable and use

1. Ensure Actions are enabled for the repository.
2. Add any required secrets under Settings → Secrets → Actions.
3. Optionally enable branch protection rules to require the validation workflows and CI checks before merging.
4. Customize the workflows as needed (e.g., the `release.yml` expects `VSCE_PAT` to publish to the Marketplace).

If you prefer the workflows to be defensive (skip publish steps when secrets are missing), see the template implementation for examples and adjust as required.
