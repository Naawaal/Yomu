---
name: flutter-task-pipeline
description: >
  Shared TODO pipeline and context persistence for multi-agent Flutter development. 
  Use this skill to initialize a task pipeline, read current pipeline status, update 
  task states, or pass context between Planner/Researcher/Builder agents. Always load 
  this skill when starting a new Flutter feature or resuming work in progress.
argument-hint: "[feature name or 'status' to check current pipeline]"
---

# Flutter Task Pipeline Skill

This skill defines how the TODO pipeline is structured, stored, and shared between agents.

## Pipeline File Location

Each feature gets a pipeline file at:
```
.github/
└── pipeline/
    └── [feature-slug]-pipeline.md
```

Never delete pipeline files until the feature is merged. They are the single source of truth for task state.

## Pipeline File Format

Create this file when the Planner completes. All agents read and update this file.

```markdown
# Pipeline: [Feature Name]
**Status**: PLANNING | RESEARCH | BUILDING | REVIEW | COMPLETE
**Created**: [date]
**Last Updated**: [date by agent name]

## Context Block
**Task Summary**: [1-2 sentence description]
**Architecture Pattern**: [Riverpod / BLoC / which version]
**Reference Feature**: [path to similar existing feature]
**Key Constraints**: 
- [constraint 1]
- [constraint 2]

## Decisions Log
| Decision | Rationale | Agent | Date |
|----------|-----------|-------|------|
| Use Riverpod AsyncNotifier | Existing app uses Riverpod v2 | Planner | [date] |
| Offline-first cache | Business requirement | Researcher | [date] |

## Research Findings
**Validated Packages**: [package list with versions]
**Flagged Issues**: [any issues found]
**UI Specification**: [link or inline M3 spec]
**Pattern Reference**: [code pattern location]

## TODO Pipeline

### Phase 1: Domain Layer
| ID | Task | Status | File | Agent | Notes |
|----|------|--------|------|-------|-------|
| TODO-001 | Create [Entity] entity | ⬜ PENDING | lib/features/[f]/domain/entities/ | Builder | |
| TODO-002 | Define [Repo] repository interface | ⬜ PENDING | lib/features/[f]/domain/repositories/ | Builder | |
| TODO-003 | Create [UseCase] | ⬜ PENDING | lib/features/[f]/domain/usecases/ | Builder | |

### Phase 2: Data Layer
| ID | Task | Status | File | Agent | Notes |
|----|------|--------|------|-------|-------|
| TODO-004 | Create [Model] model | ⬜ PENDING | lib/features/[f]/data/models/ | Builder | |
| TODO-005 | Implement [DataSource] | ⬜ PENDING | lib/features/[f]/data/datasources/ | Builder | |
| TODO-006 | Implement [Repo] implementation | ⬜ PENDING | lib/features/[f]/data/repositories/ | Builder | |

### Phase 3: Presentation Layer
| ID | Task | Status | File | Agent | Notes |
|----|------|--------|------|-------|-------|
| TODO-007 | Create [Provider/Cubit] | ⬜ PENDING | lib/features/[f]/presentation/providers/ | Builder | |
| TODO-008 | Build [Page] screen | ⬜ PENDING | lib/features/[f]/presentation/pages/ | Builder | |
| TODO-009 | Build [Widget] components | ⬜ PENDING | lib/features/[f]/presentation/widgets/ | Builder | |

### Phase 4: Integration
| ID | Task | Status | File | Agent | Notes |
|----|------|--------|------|-------|-------|
| TODO-010 | Register DI in injection_container | ⬜ PENDING | lib/injection_container.dart | Builder | |
| TODO-011 | Add routes to app_router | ⬜ PENDING | lib/app_router.dart | Builder | |
| TODO-012 | UI polish (M3 tokens, animations) | ⬜ PENDING | Multiple | Builder | |

### Phase 5: Tests
| ID | Task | Status | File | Agent | Notes |
|----|------|--------|------|-------|-------|
| TODO-013 | Unit tests for use case | ⬜ PENDING | test/features/[f]/domain/ | Builder | |
| TODO-014 | Widget tests for page | ⬜ PENDING | test/features/[f]/presentation/ | Builder | |

## Status Key
- ⬜ PENDING — not started
- 🔄 IN PROGRESS — currently being worked on
- ✅ DONE — complete and verified (flutter analyze: 0 warnings)
- ⛔ BLOCKED — blocked by an issue (see Notes)
- ⏭️ SKIPPED — intentionally skipped with reason in Notes
```

## How Agents Use the Pipeline

### Planner Agent
1. Creates the pipeline file with all TODOs in PENDING state
2. Fills in Context Block and Decisions Log
3. Leaves Research Findings empty — for the Researcher to fill

### Researcher Agent
1. Reads the pipeline file to understand the full scope
2. Fills in Research Findings section
3. Updates the Decisions Log with validated/overridden decisions
4. Changes pipeline Status from PLANNING → RESEARCH → BUILDING

### Builder Agent
1. **Before starting any task**: reads the pipeline file
2. **Picks up** the first TODO with ⬜ PENDING status
3. **Changes status** to 🔄 IN PROGRESS before writing code
4. **Changes status** to ✅ DONE after `flutter analyze` passes
5. **Adds notes** if the task revealed additional subtasks
6. **Updates** the pipeline file after every completed task

### Reviewer Agent
1. Reads pipeline to understand what was just built
2. Adds review notes to the relevant TODO row
3. If revision needed: changes status back to ⬜ PENDING with detailed notes

## Context Persistence Between Sessions

When resuming work after a break, always start with:
```
Read .github/pipeline/[feature]-pipeline.md

Find all tasks with 🔄 IN PROGRESS status (these were interrupted).
Find the first ⬜ PENDING task.
Summarize the current state and ask: "Continue from TODO-[N]?"
```

## Pipeline Initialization Command

When the Planner produces a plan, immediately create the pipeline file. Do not start building until the pipeline file exists.

Template for Planner to fill:
```bash
# Create pipeline directory
mkdir -p .github/pipeline

# Create pipeline file
touch .github/pipeline/[feature-slug]-pipeline.md
```

## Subtask Injection

If the Builder discovers during implementation that a TODO needs to be split:
```
TODO-008 has been split into:
  TODO-008a: Build ProductListPage scaffold
  TODO-008b: Build ProductCard widget  
  TODO-008c: Build ProductSearchBar widget
  
Original TODO-008 is now a parent task — mark as IN PROGRESS when any child is in progress,
DONE only when all children are DONE.
```
