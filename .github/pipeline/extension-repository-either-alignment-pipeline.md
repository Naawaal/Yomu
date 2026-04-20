# Pipeline: Extension Repository Either Alignment

**Status**: BUILDING
**Created**: 2026-04-20
**Last Updated**: 2026-04-20 by Code Agent

## Context Block

**Task Summary**: Introduce a non-breaking Either-based adapter for the extension repository so callers can opt into typed failures without changing the current interface.
**Architecture Pattern**: Clean Architecture + Riverpod provider graph
**Reference Feature**: lib/features/extensions/
**Key Constraints**:

- Keep the existing ExtensionRepository interface stable during migration
- Preserve bridge fallback behavior and current exception-based callers
- Avoid UI changes until the typed adapter path is stable

## Decisions Log

| Decision                                                        | Rationale                                                              | Agent | Date       |
| --------------------------------------------------------------- | ---------------------------------------------------------------------- | ----- | ---------- |
| Add a typed adapter instead of swapping the repository contract | Lowest-risk path for a broad consumer surface                          | Code  | 2026-04-20 |
| Use the existing Failure hierarchy for the first adapter pass   | Keeps the migration non-breaking and avoids a parallel exception model | Code  | 2026-04-20 |

## TODO Pipeline

| ID       | Task                                                    | Status  | File                                                                               | Agent | Notes                                                                                                |
| -------- | ------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------- | ----- | ---------------------------------------------------------------------------------------------------- |
| TODO-001 | Add Either adapter wrapper for extension repository ops | ✅ DONE | lib/features/extensions/data/repositories/extension_repository_result_adapter.dart | Code  | Non-breaking typed result surface for list, trust, and install                                       |
| TODO-002 | Add adapter regression tests                            | ✅ DONE | test/features/extensions/data/repositories/                                        | Code  | Added 6 passing regression tests for success paths and exception mapping                             |
| TODO-003 | Normalize extension failure mapping                     | ✅ DONE | lib/features/extensions/data/mappers/                                              | Code  | Added extension failure mapper and 4 passing mapper tests with user-action install context preserved |
| TODO-004 | Migrate controllers to opt into adapter                 | ✅ DONE | lib/features/extensions/presentation/controllers/                                  | Code  | List controller now reads through the typed adapter; legacy action path remains stable               |
| TODO-005 | Validate migration with targeted tests                  | ✅ DONE | test/features/extensions/                                                          | Code  | Added controller coverage for adapter-backed list loading and verified with flutter test/analyze     |
