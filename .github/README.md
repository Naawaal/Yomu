# Flutter Multi-Agent System for GitHub Copilot

A structured multi-agent system built with VS Code custom agents and skills to produce consistently high-quality Flutter output. Solves the three core problems of vibe coding: shallow task understanding, poor UI/UX quality, and unstructured code generation.

---

## System Architecture

```
User Request
     │
     ▼
┌─────────────┐     handoff      ┌──────────────┐     handoff      ┌─────────────┐     handoff      ┌───────────┐
│   Research  │ ──────────────▶  │   Planning   │ ──────────────▶  │    UIUX     │ ──────────────▶  │   Code    │
│    Agent    │                  │    Agent     │                  │    Agent    │                  │   Agent   │
└─────────────┘                  └──────────────┘                  └─────────────┘                  └───────────┘
     │                                  │                                 │                               │
  Read-only                         Read-only                         Read-only                       Edit files
  web + search                      search only                       web + search                    run terminal
```

---

## File Structure

```
.github/
  agents/
    research.agent.md     ← Research Agent
    planning.agent.md     ← Planning Agent
    uiux.agent.md         ← UI/UX Agent
    code.agent.md         ← Code Agent
  skills/
    flutter-research/
      SKILL.md            ← Codebase analysis + approach evaluation
    flutter-planning/
      SKILL.md            ← Phase structure + TODO template
    flutter-uiux/
      SKILL.md            ← Material 3 tokens, spacing, component guide
    flutter-todo/
      SKILL.md            ← Cross-agent TODO tracking protocol
  instructions/
    flutter-standards.instructions.md  ← Global rules for all agents
```

---

## How to Use

### Starting a New Feature

1. Open GitHub Copilot Chat in VS Code
2. Select **Research** from the agents dropdown
3. Describe your task: `"I need to build a user profile screen with avatar, edit form, and settings list"`
4. Research Agent analyzes your codebase and outputs a Research Summary
5. Click the **"→ Plan This Feature"** handoff button
6. Planning Agent creates the phased TODO pipeline
7. Click **"→ Design the UI/UX"** handoff button
8. UIUX Agent produces a Material 3 design spec
9. Click **"→ Implement This UI"** handoff button
10. Code Agent implements production-ready Flutter code

### Switching Agents Manually

In the Chat input, use the agent picker to switch directly:

- Type a task → switch to `Research` first
- Have research? → switch to `Planning`
- Have a plan + UI task? → switch to `UIUX`
- Have approved design? → switch to `Code`

### Checking TODO Status

Type `/flutter-todo` in any agent to get a current pipeline status report.

---

## Agent Reference

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| Research | Claude Opus 4.6 | web, codebase search | Problem analysis, pattern discovery |
| Planning | Claude Opus 4.6 | codebase search | Task decomposition, phase planning |
| UIUX | Claude Opus 4.6 | web, codebase search | Material 3 design spec |
| Code | Claude Sonnet 4.6 | edit, terminal, search | Implementation |

---

## Skills Reference

| Skill | Slash Command | Auto-loaded | Purpose |
|-------|---------------|-------------|---------|
| flutter-research | `/flutter-research` | Yes | Codebase analysis patterns |
| flutter-planning | `/flutter-planning` | Yes | Phase structure, TODO format |
| flutter-uiux | `/flutter-uiux` | Yes | M3 tokens, component guide |
| flutter-todo | `/flutter-todo` | Yes | Cross-agent TODO tracking |

---

## Design Principles

**Research before code** — no agent jumps to implementation without understanding the problem and codebase first.

**Structured handoffs** — each agent produces a structured output the next agent reads directly. No raw text dumps.

**UI/UX gate** — code is never written for a screen until a design spec is approved. This is the single biggest quality lever.

**TODO pipeline** — every task has an owner, dependency, and expected output. Nothing is vague.

**Material 3 enforcement** — the UIUX Agent and its skill enforce M3 standards at the design stage, not after code review.

---

## Setup

1. Copy the entire `.github/` folder into your Flutter project root
2. Open VS Code with GitHub Copilot installed
3. Open the Chat Customizations editor (`Ctrl+Shift+P` → `Chat: Open Chat Customizations`)
4. Confirm the 4 agents appear under the **Agents** tab
5. Confirm the 4 skills appear under the **Skills** tab
6. You're ready — start with the **Research** agent

> **Note**: Agents are stored in `.github/agents/` (VS Code format). Skills are in `.github/skills/`. Both are automatically discovered by VS Code.
