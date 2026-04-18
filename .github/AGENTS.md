# Yomu Agents & Workflow

This document describes the agents available for Flutter development in this workspace. Use this guide to understand when to invoke each agent and what to expect.

> **Quick Start**: For non-trivial feature work, use the **Orchestrator Agent** — it classifies the task and runs the right agents automatically in the correct order: Plan → Research → Build.

## Agent Workflow

For all non-trivial tasks, agents execute in this sequence:

```
1. PLAN first       → Decompose feature into TODO pipeline
2. RESEARCH second  → Validate architecture & codebase patterns
3. BUILD third      → Implement one TODO at a time
4. REVIEW optional  → Validate code quality & tests
```

**Skip phases only for trivial changes** (single-line fixes, typos, simple refactors).

---

## Agent Catalog

### Orchestrator Agent

**Purpose**: Single-entry point for all Flutter feature work.

**What it does**:

- Classifies the task (new feature, bugfix, refactor, UI design)
- Determines which agents to run and in what order
- Coordinates the Plan → Research → Build pipeline automatically

**When to use**:

- "Build a new feature"
- "Fix a bug in the extensions screen"
- "Implement user authentication"
- Any non-trivial work

**Example**:

```
You: I want to add a user profile screen with avatar, bio, and settings links.

Orchestrator:
  [Runs UI/UX Design Agent] ← Design the profile screen layout
  [Runs PlanResearch Agent] ← Break down into TODO pipeline
  [Awaits your approval]
  [Runs Code Agent] ← Implements each TODO one by one
```

---

### Code Agent

**Purpose**: Implements Flutter features from a validated TODO pipeline. Executes one TODO at a time.

**Prerequisites**:

- Plan & Research phases must be complete
- UI/UX Design must be complete (for presentation-layer TODOs)
- A structured TODO pipeline with clear acceptance criteria

**What it does**:

- Reads the current TODO pipeline
- Implements one TODO per invocation
- Runs `flutter analyze` after every file (injected via PostToolUse hook)
- Fixes any reported issues before proceeding
- Updates the pipeline status and shows next pending TODO
- Provides file paths, line counts, and test results for verification

**When to use**:

- After Plan & Research phases are approved
- When you have a clear TODO list to work through
- When resuming implementation after a break

**Workflow**:

1. Code Agent implements TODO-001
2. You review the result
3. You invoke Code Agent again with "next" or "TODO-002"
4. Repeat until build complete

**Example invocation**:

```
You: Next
Code Agent: [implements TODO-002, runs analyze, updates pipeline status]
```

---

### PlanResearch Agent

**Purpose**: Decomposes a Flutter task into a structured TODO pipeline AND validates architecture against the existing codebase in a single pass.

**Always runs before any code is written.**

**What it does**:

- Analyzes the feature request
- Reads relevant codebase files to understand patterns
- Validates against established architecture (clean layers, dependency injection, Riverpod providers)
- Breaks down the work into 5–15 granular, testable TODOs
- Produces a TODO pipeline ready for Code Agent consumption
- Suggests when to pause for UI/UX Design

**When to use**:

- At the start of any feature work
- After Orchestrator Agent routes to it
- When you need a breakdown before implementation

**Output**:

```
TODO-001: Create entity model
TODO-002: Create repository interface
TODO-003: Implement repository
TODO-004: Create provider
... (etc)

⏸️  PAUSED — UI/UX Design needed before presentation TODOs
```

---

### UI/UX Design Agent

**Purpose**: Defines the complete design system and per-screen UI specs BEFORE any widget code is written.

**Triggers when**:

- Project is new (no ThemeData exists)
- No existing design system documentation
- Screens use hardcoded colors/styles
- User explicitly requests design work

**What it does**:

- Analyzes Material 3 + Moon Design tokens
- Creates `design_system.json` with color roles, typography scale, spacing, radius
- Produces component contracts (layout, constraints, state handling)
- Generates per-screen wireframes / UI specs
- Outputs CSS-like design tokens ready for implementation

**When to use**:

- Before implementing any presentation-layer feature
- When building a new major screen
- When design guidelines are unclear

**Output**:

```json
{
  "colors": {...},
  "typography": {...},
  "spacing": {...},
  "screens": {
    "profile_screen": {
      "layout": "vertical stack",
      "components": [...]
    }
  }
}
```

Then Code Agent consumes these specs exactly — no flexibility on colors, spacing, or component types.

---

### Explore Agent

**Purpose**: Fast read-only codebase exploration and Q&A.

**What it does**:

- Searches the codebase for patterns, files, or answers
- Returns relevant code snippets, file lists, or architectural summaries
- Does NOT modify files or run commands

**When to use**:

- "What's the folder structure for a feature?"
- "Show me how the extensions feature uses Riverpod"
- "Are there any examples of network error handling?"
- When you need information quickly without clutter

**Efficiency**:

- Can run in parallel with other agents
- Use `thoroughness` parameter (quick/medium/thorough) to control depth
- Preferred over manually chaining semantic_search + file reads

**Example**:

```
You: Explore — show me the extensions feature data layer pattern (thorough)

Explore Agent:
  → Reads repository interface, mock impl, bridge impl
  → Reads entity models, error types
  → Returns summary of architecture + code snippets
```

---

## Quick Decision Table

| Scenario                                 | Use Agent                   | Why                                                        |
| ---------------------------------------- | --------------------------- | ---------------------------------------------------------- |
| "Build a login flow"                     | Orchestrator                | Automatic routing to Plan → Research → Build               |
| "I have a TODO list, implement TODO-003" | Code Agent                  | Direct implementation from TODO                            |
| "Analyze the folder structure"           | Explore                     | Fast read-only lookup                                      |
| "Fix a typo in button text"              | None (direct edit)          | Trivial, no agent needed                                   |
| "Refactor a single function"             | Code Agent (if non-trivial) | Use Code Agent only for medium+ complexity                 |
| "Should I use Riverpod or BLoC?"         | Explore or PlanResearch     | Explore for pattern lookup; PlanResearch for full analysis |

---

## Task Coordination

### From Orchestrator to Code Agent

When the Orchestrator hands off to Code Agent, it provides:

- ✅ Complete TODO pipeline (5–15 items)
- ✅ Each TODO with acceptance criteria
- ✅ Architecture decisions documented
- ✅ Design specs (if presentation layer)
- ✅ Links to existing examples in codebase

Code Agent then:

1. Implements one TODO
2. Runs analyze (injected hook)
3. Marks complete
4. Displays next TODO
5. Awaits next invocation

### From Code Agent Back to You

After each TODO, Code Agent reports:

```
✅ TODO-001 COMPLETE: Create entity model
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: lib/features/auth/domain/entities/user.dart | Lines: 42 | Analyze: ✅ clean

PIPELINE:
✅ TODO-001 — done
✅ TODO-002 — done
⏳ TODO-003 — just completed
⬜ TODO-004 — next
```

---

## Linked Resources

**Skills** (on-demand workflows with bundled assets):

- [**flutter-task-pipeline**](./../skills/flutter-task-pipeline/SKILL.md)  
  Shared TODO pipeline & context persistence for multi-agent Flutter work. Use to view/update task state or resume work.

- [**design-tokens**](./../skills/design-tokens/SKILL.md)  
  Design system tokens reference (colors, typography, spacing, radius). Auto-load when building any UI component.

- [**flutter-architecture**](./../skills/flutter-architecture/SKILL.md)  
  Clean architecture patterns & folder structure. Use when planning a new feature or deciding on dependency injection.

- [**flutter-builder**](./../skills/flutter-builder/SKILL.md)  
  Production Flutter code generation patterns & quality checklists. Use when implementing any feature file.

- [**flutter-ui-research**](./../skills/flutter-ui-research/SKILL.md)  
  Material 3 UI patterns, component selection, theming, animations, responsive design. Use when designing screens.

**Related Documentation**:

- [Copilot Instructions](./copilot-instructions.md) — Code quality rules, standards, and conventions
- [Extensions Feature README](../lib/features/extensions/README.md) — Native bridge contract & platform patterns
- [UI Guidelines](../lib/core/theme/UI_GUIDELINES.md) — Design tokens & component constraints

---

## Troubleshooting

**"Why is the agent doing X when I asked for Y?"**

- Check the agent description in your request — agents match keywords from task descriptions
- Clarify the task scope: "New feature", "Bugfix", "Refactor", "Design review"
- Use agent names directly if routing is ambiguous: "Run Code Agent for TODO-004"

**"The TODO pipeline is stuck or incomplete"**

- Run Explore Agent to review codebase patterns
- Run PlanResearch again to re-decompose the task
- Check the flutter-task-pipeline skill to view/update current state

**"I need to see what the last agent did"**

- Use Explore Agent to search recent changes
- Check the file paths + line counts provided by the agent after each task
