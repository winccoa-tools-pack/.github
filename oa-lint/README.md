# 🌐 OALint – WinCC OA Linter

![OALint Logo](logo.jfif)

## 🎯 Purpose

OALint is the **static code quality gate for WinCC OA projects**.  
It enforces consistent coding standards, detects issues early, and provides actionable feedback across all environments — from developer workstations to enterprise CI/CD pipelines.

Our mission is simple:  
**Make WinCC OA code reliable, maintainable, and future proof through automated quality checks.**

---

## 🏗️ Architecture

OALint is designed as a **modular ecosystem**:

- **oalint-npm** → Core NPM package with rules and validators  
- **oalint-for-azure** → Azure DevOps runner  
- **oalint-for-jenkins** → Jenkins plugin/shared library  
- **oalint-for-github** → GitHub Action runner  
- **oalint-for-vscode** → VS Code extension for inline diagnostics  
- **oalint-tool-ctrlppcheck** → Integration with `ctrlppcheck` for C++ static analysis  
- **oalint-tool-lizard** → Integration with `lizard` for complexity analysis  
- **oalint-tool-sonarqube** → Exporter for SonarQube Generic Issue Data format  
- **oalint-examples** → Showcase integrations (e.g., Jenkins → Azure PR feedback)  

---

## 🔄 Workflow

1. **Rules defined** in `oalint-npm` (YAML/JSON + TypeScript validators)  
2. **Runners** import the shared library and execute rules in their environment  
3. **Violations detected** → reported in:
   - PR comments (GitHub, Azure)  
   - Build logs (Jenkins)  
   - Inline editor diagnostics (VS Code)  
4. **SonarQube JSON output** → unified dashboards  
5. **MCP binding** → AI assistants consume violations + recommendations, generate fixes  

---

## 🛡️ Key Features

- **Consistency**: Same rules enforced across GitHub, Jenkins, Azure, VS Code, and local CLI  
- **Scalability**: Easy to extend with new runners and tools  
- **Developer Experience**: Inline feedback in editors and PRs  
- **Enterprise Ready**: SonarQube integration for compliance dashboards  
- **AI Enhanced**: MCP binding allows Copilot/AI to suggest fixes automatically  

---

## 🚀 Vision

OALint is more than a linter — it’s a **quality ecosystem**.  
By combining static analysis, CI/CD integration, SonarQube dashboards, and AI powered recommendations, OALint ensures WinCC OA projects meet the highest standards of reliability and maintainability.

Our vision is to make **quality gates invisible yet powerful**: developers focus on building, while OALint quietly ensures every line of code meets the checklist.

---

## 📌 Next Steps

- Expand rule coverage for WinCC OA projects  
- Strengthen integrations with SonarQube and MCP  
- Build community driven rule sets for shared best practices  
- Provide ready to use examples for all major CI/CD platforms  

---

## 📎 Links

- Organisation: [winccoa-tools-pack](https://github.com/winccoa-tools-pack)  
- Core Package: `oalint-npm`  
- Runners: `oalint-for-azure`, `oalint-for-jenkins`, `oalint-for-github`, `oalint-for-vscode`  
- Tools: `oalint-tool-ctrlppcheck`, `oalint-tool-lizard`, `oalint-tool-sonarqube`  
- Examples: `oalint-examples`  

---

<center>Made with ❤️ for and by the WinCC OA community</center>
