🤖 AI Prompt Plan for OALint

🎯 Purpose
This document defines how AI assistants (e.g., Copilot, MCP bound tools) interact with OALint.  
The goal is to provide consistent prompts that generate explanations, recommendations, and auto fixes for WinCC OA code quality violations.

---

🧩 Prompt Categories

1. Rule Explanation
Explain why a violation matters and how it impacts code quality.

Template:
`
You are a code quality assistant.
Explain why the following violation matters:

Rule: {{ruleId}}
Violation: {{message}} in {{filePath}} line {{line}}

Provide a concise explanation and a recommended fix.
`

---

2. Auto Fix Suggestion
Generate code snippets or configuration changes to resolve violations.

Template:
`
You are an AI code fixer.
Given this violation:

Rule: {{ruleId}}
Violation: {{message}} in {{filePath}}

Generate a corrected code snippet or configuration change.
`

---

3. SonarQube JSON Conversion
Convert violations into SonarQube Generic Issue Data format.

Template:
`
You are an AI integration assistant.
Convert the following rule violations into SonarQube Generic Issue Data JSON format
with recommendations included.

Violations:
{{violations}}
`

---

4. Checklist Expansion
Suggest new rules based on best practices for WinCC OA projects.

Template:
`
You are a code standards advisor.
Given the current checklist:

{{rules}}

Suggest 3 new rules that would improve maintainability and reliability
for WinCC OA projects.
`

---

5. Developer Coaching
Provide human friendly guidance for developers in PRs or VS Code.

Template:
`
You are a developer coach.
Explain the following violation in simple terms:

Rule: {{ruleId}}
Violation: {{message}}

Provide a short, encouraging message with a clear next step.
`

---

🔄 Workflow Integration
- Runners (Azure, Jenkins, GitHub, VS Code) call these prompts when violations are detected.  
- AI assistants return explanations, fixes, or JSON outputs.  
- SonarQube dashboards aggregate results for enterprise visibility.  
- MCP binding allows AI to act as a “code detective assistant,” guiding developers directly.

---

🚀 Next Steps
- Implement prompt templates in oalint-npm.  
- Add AI prompt execution in oalint-for-vscode for inline coaching.  
- Extend oalint-tool-sonarqube to use JSON conversion prompts.  
- Document usage examples in oalint-examples.

---


---

<center>Made with ❤️ for and by the WinCC OA community</center>