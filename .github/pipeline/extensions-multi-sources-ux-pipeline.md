# Pipeline: Extensions Multi Sources UX Redesign

**Status**: BUILDING
**Created**: 2026-04-20
**Last Updated**: 2026-04-20 by Builder

## Context Block

**Task Summary**: Redesign Extensions page to a denser, upgraded multi-sources UX with a clear Installed section while preserving behavior contracts.
**Architecture Pattern**: Clean Architecture + Riverpod
**Reference Feature**: lib/features/home/presentation/screens/home_screen.dart
**Key Constraints**:

- Presentation-only redesign with existing controller/repository contracts
- Material 3 + token-only styling (colorScheme/textTheme/AppSpacing/AppRadius)
- Keep existing search/filter behavior and route helpers

## Decisions Log

| Decision                               | Rationale                                                                                   | Agent   | Date       |
| -------------------------------------- | ------------------------------------------------------------------------------------------- | ------- | ---------- |
| No domain-layer changes                | Existing `ExtensionItem` already contains all fields needed for installed/multi-source rows | Builder | 2026-04-20 |
| Preserve repository/use-case contracts | UX scope does not require new data verbs                                                    | Builder | 2026-04-20 |

## Research Findings

**Validated Packages**: None needed
**Flagged Issues**: Duplicate "All languages" chip semantics in current controls rail can be clarified during UI work
**UI Specification**: From approved plan in chat
**Pattern Reference**: lib/features/extensions/presentation/screens/extensions_store_screen.dart

## TODO Pipeline

### Phase 1: Domain/Data Safety

| ID       | Task                                         | Status  | File                            | Agent   | Notes                                                                                       |
| -------- | -------------------------------------------- | ------- | ------------------------------- | ------- | ------------------------------------------------------------------------------------------- |
| TODO-001 | Validate no domain changes required          | ✅ DONE | lib/features/extensions/domain/ | Builder | Entity fields already cover installed + multi-source UX needs                               |
| TODO-002 | Validate no data/repository changes required | ✅ DONE | lib/features/extensions/data/   | Builder | Composite merge, remote catalog, datasource, and adapter already support required UX states |

### Phase 2: Presentation State

| ID       | Task                                                            | Status  | File                                                                      | Agent   | Notes                                                                           |
| -------- | --------------------------------------------------------------- | ------- | ------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------- |
| TODO-003 | Normalize section derivation: Installed + Multi Sources         | ✅ DONE | lib/features/extensions/presentation/screens/extensions_store_screen.dart | Builder | Explicit installed/non-installed grouping with preserved filter/search behavior |
| TODO-004 | Define row action resolver matrix (trust/install/update/manage) | ✅ DONE | lib/features/extensions/presentation/widgets/manga_source_card.dart       | Builder | Centralized action decision model wired to CTA label/icon/handler selection     |

### Phase 3: Presentation UI

| ID       | Task                                                      | Status     | File                                                                      | Agent   | Notes                                                                              |
| -------- | --------------------------------------------------------- | ---------- | ------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------- |
| TODO-005 | Recompose slivers into Installed + Multi Sources sections | ✅ DONE    | lib/features/extensions/presentation/screens/extensions_store_screen.dart | Builder | Verified explicit Installed/Multi section slivers and passing screen tests         |
| TODO-006 | Redesign Installed row variant                            | ✅ DONE    | lib/features/extensions/presentation/widgets/manga_source_card.dart       | Builder | Dedicated installed row with Manage primary affordance and Update secondary action |
| TODO-007 | Redesign Multi Sources dense row variant                  | ✅ DONE    | lib/features/extensions/presentation/widgets/manga_source_card.dart       | Builder | Compact row upgraded with action-matrix-driven single primary CTA                  |
| TODO-008 | Refine pinned controls rail labels/layout                 | ⬜ PENDING | lib/features/extensions/presentation/screens/extensions_store_screen.dart | Builder |                                                                                    |
| TODO-009 | Align backdrop/chrome with feed style                     | ⬜ PENDING | lib/features/extensions/presentation/screens/extensions_store_screen.dart | Builder |                                                                                    |

### Phase 4: Validation

| ID       | Task                             | Status     | File                                                                            | Agent   | Notes                               |
| -------- | -------------------------------- | ---------- | ------------------------------------------------------------------------------- | ------- | ----------------------------------- |
| TODO-010 | Update/extend store screen tests | ⬜ PENDING | test/features/extensions/presentation/screens/extensions_store_screen_test.dart | Builder | Section order/count/action matrix   |
| TODO-011 | Update row widget tests          | ⬜ PENDING | test/features/extensions/presentation/widgets/manga_source_card_test.dart       | Builder | Row state and responsive assertions |
