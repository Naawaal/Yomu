# Pipeline: Source Runtime Parser Adapter

**Status**: BUILDING
**Created**: 2026-04-20
**Last Updated**: 2026-04-20 by Code Agent

## Context Block

**Task Summary**: Introduce a parser contract and default adapter in sources runtime data flow to isolate host payload mapping.
**Architecture Pattern**: Clean Architecture + Riverpod provider graph
**Reference Feature**: lib/features/sources/
**Key Constraints**:

- No presentation/UI changes in TODO-001
- Keep repository and provider public APIs unchanged
- Preserve existing runtime capability and exception behavior

## Decisions Log

| Decision                                                 | Rationale                            | Agent        | Date       |
| -------------------------------------------------------- | ------------------------------------ | ------------ | ---------- |
| Insert parser boundary at datasource mapping point       | Lowest-risk seam with no UI coupling | PlanResearch | 2026-04-20 |
| Keep constructor backward-compatible with default parser | Avoid call-site churn                | Code         | 2026-04-20 |

## TODO Pipeline

| ID       | Task                                                             | Status  | File                                                                                                            | Agent | Notes                                                                                                          |
| -------- | ---------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------- | ----- | -------------------------------------------------------------------------------------------------------------- |
| TODO-001 | Add source runtime parser contract + adapter and wire datasource | ✅ DONE | lib/features/sources/data/parsers/, lib/features/sources/data/datasources/source_runtime_bridge_datasource.dart | Code  | Implemented with backward-compatible datasource constructor and clean analysis on touched files                |
| TODO-002 | Add parser adapter unit tests                                    | ✅ DONE | test/features/sources/data/parsers/                                                                             | Code  | Added 3 passing tests for mapping, fallback, and empty payload handling                                        |
| TODO-003 | Add datasource behavior tests (capability + bridge errors)       | ✅ DONE | test/features/sources/data/datasources/                                                                         | Code  | Added 5 passing tests for dispatch, parser delegation, unsupported capability, and exception translation       |
| TODO-004 | Normalize bridge error code mapping constants                    | ✅ DONE | lib/features/sources/data/datasources/                                                                          | Code  | Datasource now uses SourceFailureCode constants; datasource tests updated and passing                          |
| TODO-005 | Tighten repository failure mapping for parser format issues      | ✅ DONE | lib/features/sources/data/repositories/                                                                         | Code  | Added deterministic ParseFailure normalization for FormatException payloads and 4 passing repository tests     |
| TODO-006 | Add repository regression tests for Either mapping               | ✅ DONE | test/features/sources/data/repositories/                                                                        | Code  | Added 6 passing regression tests covering Either success/failure mapping paths                                 |
| TODO-007 | Document parser boundary in sources data layer                   | ✅ DONE | lib/features/sources/data/                                                                                      | Code  | Added [lib/features/sources/data/README.md] documenting parser boundary, responsibilities, and extension rules |
| TODO-008 | Optional follow-up: extension repository Either alignment plan   | ✅ DONE | docs/planning                                                                                                   | Code  | Added [docs/planning/extension-repository-either-alignment-plan.md] as a separate follow-up plan               |
