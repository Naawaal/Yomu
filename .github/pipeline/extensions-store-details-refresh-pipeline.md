# Pipeline: Extensions Store + Details Refresh

**Status**: BUILDING
**Created**: 2026-04-20
**Last Updated**: 2026-04-20 by Builder

## Context Block

**Task Summary**: Modernize Extensions Store and Extension Details presentation while preserving behavior, routing, and data contracts.
**Architecture Pattern**: Clean Architecture + Riverpod
**Reference Feature**: lib/features/home/presentation/screens/home_screen.dart
**Key Constraints**:

- Use Material 3 roles and app tokens only (no hardcoded colors/styles/spacing/radius)
- Keep existing provider/controller and route-helper contracts unchanged
- Add extension page gradient backdrop analogous to Home feed pattern

## Decisions Log

| Decision                              | Rationale                                                                         | Agent              | Date       |
| ------------------------------------- | --------------------------------------------------------------------------------- | ------------------ | ---------- |
| Keep domain/data layers unchanged     | Request is presentation-focused and current contracts already support required UX | PlanResearch Agent | 2026-04-20 |
| Keep typed GoRouter helpers unchanged | Avoid behavioral regressions and preserve navigation consistency                  | PlanResearch Agent | 2026-04-20 |
| Reuse Home backdrop language          | Existing visual treatment already aligned with design system                      | PlanResearch Agent | 2026-04-20 |

## Research Findings

**Validated Packages**: None needed
**Flagged Issues**: Store has stacked pinned controls causing compact feel; compact More Sources rows are too dense
**UI Specification**: Plan from chat (TODO-009 onward)
**Pattern Reference**: lib/features/extensions/presentation/screens/extensions_store_screen.dart

## TODO Pipeline

### Phase 1: Domain/Data Safety

| ID       | Task                                             | Status  | File                                         | Agent              | Notes                                           |
| -------- | ------------------------------------------------ | ------- | -------------------------------------------- | ------------------ | ----------------------------------------------- |
| TODO-001 | Validate no domain changes needed                | ✅ DONE | lib/features/extensions/domain/              | PlanResearch Agent | Entity + use case contracts already sufficient  |
| TODO-002 | Validate no repository contract changes needed   | ✅ DONE | lib/features/extensions/domain/repositories/ | PlanResearch Agent | Existing repository verbs cover UI actions      |
| TODO-003 | Validate no data model/datasource changes needed | ✅ DONE | lib/features/extensions/data/                | PlanResearch Agent | Data layer can remain untouched for UI redesign |

### Phase 2: Presentation Refactor Prep

| ID       | Task                                                   | Status  | File                                  | Agent              | Notes                                                         |
| -------- | ------------------------------------------------------ | ------- | ------------------------------------- | ------------------ | ------------------------------------------------------------- |
| TODO-004 | Prepare store/details presentation refactor boundaries | ✅ DONE | lib/features/extensions/presentation/ | PlanResearch Agent | Refactor boundaries and constraints validated before UI edits |

### Phase 3: Presentation UI

| ID       | Task                                               | Status  | File                                                                       | Agent   | Notes                                                               |
| -------- | -------------------------------------------------- | ------- | -------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------- |
| TODO-005 | Restructure Extensions Store hierarchy             | ✅ DONE | lib/features/extensions/presentation/screens/extensions_store_screen.dart  | Builder | Unified controls header and increased section rhythm                |
| TODO-006 | Redesign More Sources compact card density         | ✅ DONE | lib/features/extensions/presentation/widgets/manga_source_card.dart        | Builder | Larger artwork and roomier compact row spacing                      |
| TODO-007 | Modernize Extension Details hierarchy              | ✅ DONE | lib/features/extensions/presentation/screens/extension_details_screen.dart | Builder | Increased hero/metadata spacing and clearer hierarchy               |
| TODO-008 | Apply extension page gradient backdrop             | ✅ DONE | lib/features/extensions/presentation/screens/extensions_store_screen.dart  | Builder | Added light-mode gradient + radial accents layer                    |
| TODO-009 | Align loading/empty/error geometry with new layout | ✅ DONE | lib/features/extensions/presentation/screens/                              | Builder | Unified state surfaces and sliver geometry validated in tests       |
| TODO-010 | Responsive tuning for compact/expanded layouts     | ✅ DONE | lib/features/extensions/presentation/screens/                              | Builder | Adaptive controls header and expanded details composition validated |

### Phase 4: Validation

| ID       | Task                        | Status     | File                                                                             | Agent   | Notes                                                 |
| -------- | --------------------------- | ---------- | -------------------------------------------------------------------------------- | ------- | ----------------------------------------------------- |
| TODO-011 | Update store widget tests   | ⬜ PENDING | test/features/extensions/presentation/screens/extensions_store_screen_test.dart  | Builder | Assert redesigned hierarchy while preserving behavior |
| TODO-012 | Update details widget tests | ⬜ PENDING | test/features/extensions/presentation/screens/extension_details_screen_test.dart | Builder | Validate loading/error/not-found/data parity          |
