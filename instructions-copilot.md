

💡 Architecture Summary – Modular Node.js Setup for VS Code + GitHub Actions

1. Core Concept
💡 Keep heavy logic in Node.js Shared Libraries  
- Written in TypeScript, published as npm packages.  
- Provides reusable functions (log(), validateConfig(), getExtensions()).  
- Used by both VS Code Extensions and GitHub Actions.  

---

2. Repository Structure


`
 winccoa-tools-pack/
 ├─ .github ← Organisation repository (this repo holds organization-level settings, workflows, and templates)
 ├─ npm-shared-library/ ←  'core-utils' - Shared npm library (TypeScript)
 ├─ github-action-project-register/ ← GitHub Action using core-utils to register WinCC OA project
 ├─ github-action-project-create/ ← GitHub Action using core-utils to create WinCC OA project
 ├─ github-action-project-start/ ← GitHub Action using core-utils to start WinCC OA project
 ├─ github-action-project-stop/ ← GitHub Action using core-utils ti stop WinCC OA project
 ├─ github-action-project-restart/ ← GitHub Action using core-utils to restart WinCC OA project
 ├─ github-action-log-analazyer/ ← GitHub Action using core-utils to analyze WinCC OA logs
 ├─ github-action-test-dynamic/ ← GitHub Action using core-utils to execute and validate OaTest based tests
 ├─ github-action-test-static/ ← GitHub Action using core-utils to execute and validate static analysis (inspired by https://github.com/siemens/CtrlppCheck)
 ├─ github-action-test-framework/ ← GitHub Action using core-utils to execute and validate tests by WinCC OA Testframework
 ├─ github-ci-workflows/ ← Reusable GitHub Workflows (TBD)
 ├─ vs-code-tools-pack/ ← VS Code Extension Package to group all helpfull packages
 ├─ vs-code-projectAdmin/ ← VS Code Extension (client) to administarte WinCC OA projects
 ├─ vs-code-logViewer/ ← VS Code Extension (client) for WInCC OA logs
 ├─ vs-code-scriptsActions/ ← VS Code Extension (client) to provide several script actions like start / stop.
 ├─ vs-code-ctrlLang/ ← VS Code Extension (client) to support WinCC OA ctrl lang (extended version of https://github.com/LukasSchopp/vscode-ctrlpptools)
 ├─ vs-code-test/ ← VS Code base Extension for WinCC OA tests
 ├─ vs-code-test-dynamic/ ← VS Code Extension for dynamic WinCC OA tests based on vs-code-test
 ├─ vs-code-test-static/ ← VS Code Extension  WinCC OA tests for static analysis based on vs-code-test
 └─ vs-code-test-framework/ ← VS Code Extension to execute and validate WinCc OA TestFramework tests
`

💡 Separation of concerns:  
- Library = logic.  
- Actions = automation.  
- Workflows = pipelines.  
- Extension = UI + client.

---

3. GitHub Action Example
action.yml
`yaml
name: "WinCC OA Core Utils Action"
description: "Use shared library functions in workflows"
runs:
  using: "node16"
  main: "dist/index.js"
`

src/index.ts
`ts
import * as core from "@actions/core";
import { log } from "@winccoa-tools-pack/core-utils";

async function run() {
  const message = core.getInput("message");
  log(Action received: ${message});
}

run();
`

💡 Prebuild & commit dist/ → no compile step for users.

---

4. VS Code Extension Example
`ts
import { getExtensions } from "@winccoa-tools-pack/core-utils";
import * as vscode from "vscode";

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.commands.registerCommand("martin.showExtensions", async () => {
      const extensions = await getExtensions();
      vscode.window.showInformationMessage(
        Available: ${extensions.map(e => e.name).join(", ")}
      );
    })
  );
}
`

💡 Extension stays lightweight → only calls shared library.

---

5. CI/CD Workflow Example
ci-workflows/build.yml
`yaml
name: Build and Test

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm run build
      - run: npm test
`

💡 Reusable workflows → centralize CI/CD logic.

---

6. Key Principles
- 💡 Modularity: Each piece in its own repo.  
- 💡 Reusability: Shared library imported everywhere.  
- 💡 Performance: Node.js only, no Python runtime overhead.  
- 💡 Maintainability: Versioned npm packages + tagged Actions.  
- 💡 Scalability: Easy to add new Actions or Extensions.  
  
=====

Here’s the architecture diagram in text form so you (and GitHub Copilot) can visualize the flow.  

---

💡 Modular Node.js Architecture Diagram

`
          ┌─────────────────────┐
          │ VS Code Extension │
          │ (UI + Commands) │
          └─────────┬───────────┘
                    │ calls
                    ▼
          ┌─────────────────────┐
          │ Shared npm Library│
          │ (@winccoa-tools-pack/core-utils) 
          │ - log()
          │ - validateConfig()
          │ - getExtensions() │
          └─────────┬───────────┘
                    │ imported by
   ┌────────────────┴─────────────────┐
   │ │
   ▼ ▼
┌───────────────┐ ┌────────────────┐
│ GitHub Action │ │ Reusable CI/CD │
│ (logger, │ │ Workflows │
│ validator) │ │ (build, test, │
│ uses core-utils│ │ publish) │
└───────────────┘ └────────────────┘
`

---

🔑 Flow Explanation
- 💡 VS Code Extension → lightweight, only UI + commands.  
- 💡 Shared npm Library → central logic, reusable everywhere.  
- 💡 GitHub Actions → automation tasks, import the library.  
- 💡 Reusable Workflows → orchestrate pipelines, call Actions.  

---

🚀 Key Principles
- Modularity: Each component in its own repo.  
- Reusability: Library imported by both Extension and Actions.  
- Performance: Node.js only, no external runtime overhead.  
- Maintainability: Versioned npm packages + tagged Actions.  
- Scalability: Easy to add new Actions or Extensions.  

---

👉 With this diagram, Copilot will understand the roles and connections clearly. Tomorrow, you can ask it to scaffold new modules by saying things like:  
- “Generate a GitHub Action that imports @winccoa-tools-pack/core-utils and runs validateConfig.”  
- “Add a VS Code command that calls getExtensions from the shared library.”  

====


– here’s a step by step Copilot prompt script you can save and paste tomorrow. It’s written in an architecture driven format so GitHub Copilot will understand the roles and generate boilerplate code in the right places.

---

💡 Copilot Prompt Script – Modular Node.js Architecture

Templates
`templates/` contains starter templates for the components described above.
- `templates/npm-shared-library/` — shared library starter (use to create `@winccoa-tools-pack/core-utils`)
- `templates/github-action/` — generic GitHub Action template (copy and customize for specific actions)
- `templates/github-ci-workflows/` — reusable GitHub workflow `build.yml` (call via `workflow_call`)
- `templates/vscode-extension/` — minimal VS Code extension scaffold


1. Create Shared Library (core-utils)
`

Copilot, generate a TypeScript npm library called @winccoa-tools-pack/core-utils.

It should export functions like:

- log(message: string): void

- validateConfig(config: object): boolean

- getExtensions(): Promise<{name: string, description: string}[]>

Include package.json, tsconfig.json, and a build script.
`

---

2. Create GitHub Action (action-logger)
`

Copilot, scaffold a GitHub Action in a new repo called action-logger.

It should:

- Import @winccoa-tools-pack/core-utils

- Use log() to print an input message

- Include action.yml, package.json, src/index.ts, and dist/index.js

- Prebuild dist/ and commit it so users don’t need to compile.
`

---

3. Create GitHub Action (action-validator)
`

Copilot, scaffold another GitHub Action in a repo called action-validator.

It should:

- Import @winccoa-tools-pack/core-utils

- Use validateConfig() on a JSON input

- Fail the workflow if validation returns false

- Include action.yml, package.json, src/index.ts, and dist/index.js
`

---

4. Create Reusable Workflow (ci-workflows)
`

Copilot, generate a reusable GitHub workflow in a repo called ci-workflows.

It should:

- Build and test Node.js projects

- Run npm install, npm run build, npm test

- Be reusable via uses: martin-org/ci-workflows/.github/workflows/build.yml@v1
`

---

5. Create VS Code Extension (vscode-extension)
`

Copilot, scaffold a VS Code extension in a repo called vscode-extension.

It should:

- Import @winccoa-tools-pack/core-utils

- Add a command "martin.showExtensions"

- Call getExtensions() and show results in vscode.window.showInformationMessage

- Include package.json, extension.ts, and activation logic.
`

---

6. Architecture Diagram (for Copilot context)
`
VS Code Extension → Shared npm Library → GitHub Actions → Reusable Workflows
`

---

🔑 Key Instructions for Copilot
- 💡 Always separate repos: library, actions, workflows, extension.  
- 💡 Use @winccoa-tools-pack/core-utils everywhere as the shared dependency.  
- 💡 Prebuild dist/ for Actions so users don’t need to compile.  
- 💡 Keep Extension lightweight: only UI + calls to library.  
- 💡 Workflows orchestrate Actions, not raw scripts.  

---

👉 With this script, you can guide Copilot tomorrow to generate boilerplate repos exactly in the modular Node.js architecture we designed.  

====

---

📑 Summary – MCP Server & Shared Libraries

Goal:  
Build a modular ecosystem of VS Code extensions with shared libraries and an MCP server that Copilot (or other AI clients) can connect to.

Steps:
1. Multiple Repositories  
   - Each extension in its own repo → easier maintenance & versioning.  
   - Shared utilities in a separate repo as npm package (@winccoa-tools-pack/core-utils).  

2. Shared Libraries  
   - Create a Node/TypeScript library with reusable functions.  
   - Publish via npm or GitHub Packages.  
   - Import into extensions and MCP server.  

3. MCP Server  
   - Runs on WebSocket (ws://localhost:8080 or wss://yourdomain).  
   - Provides methods like ping, getExtensions, getProjectInfo.  
   - Uses JSON request/response format.  

4. Copilot Configuration  
   - Define a config file (copilot-mcp.json) with server URL and optional auth token.  
   - Example:
     `json
     {
       "servers": {
         "martin-mcp": {
           "url": "ws://localhost:8080",
           "description": "Local MCP Server",
           "auth": { "type": "token", "token": "XYZ123" }
         }
       }
     }
     `

5. Documentation  
   - Provide API.md in English.  
   - Each method documented with description, request, response, and examples.  
   - Follow semantic versioning for stability.  

---

👉 Damit hast du eine klare Roadmap: Extensions modularisieren, Shared Library bauen, MCP Server bereitstellen, Copilot konfigurieren, und API dokumentieren.  
