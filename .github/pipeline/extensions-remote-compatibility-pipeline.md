# Pipeline: Extensions Remote Compatibility

**Status**: BUILDING
**Created**: 2026-04-18
**Last Updated**: 2026-04-18 by Code Agent (compatibility core + tests)

## Context Block

**Task Summary**: Add compatibility for Tachiyomi-style remote repository indexes so supported repositories populate the Extensions page without changing existing domain behavior.
**Architecture Pattern**: Riverpod + clean feature layering
**Reference Feature**: lib/features/extensions/
**Key Constraints**:

- Preserve existing domain contracts for extension listing and remote loading
- Keep compatibility work in the data layer unless presentation diagnostics are explicitly added
- Canonical object-schema repositories must keep working unchanged
- Install artifacts may require repository-aware path resolution

## Decisions Log

| Decision                                               | Rationale                                                                    | Agent      | Date       |
| ------------------------------------------------------ | ---------------------------------------------------------------------------- | ---------- | ---------- |
| Keep `ExtensionRepository` unchanged                   | Listing, trust, and install semantics already match the feature goal         | Code Agent | 2026-04-18 |
| Keep `LoadRemoteExtensionsUseCase` unchanged           | Remote compatibility is a data parsing concern, not a domain behavior change | Code Agent | 2026-04-18 |
| Normalize Tachiyomi feeds into existing internal shape | Avoids ripple changes across controllers, composite repository, and UI       | Code Agent | 2026-04-18 |
| Diagnostics in Settings only (Option B)                | Power-user feedback at point of action; Extensions page stays clean          | Code Agent | 2026-04-18 |

## Research Findings

**Validated Packages**: none needed
**Flagged Issues**: Provided repository URL serves a bare JSON array with `pkg`, `version`, and `apk` aliases instead of the canonical object schema.
**UI Specification**: Not required for TODO-001 or TODO-002; diagnostics UX remains optional later in the pipeline.
**Pattern Reference**: lib/features/extensions/data/models/remote_extension_index_model.dart and lib/features/extensions/data/datasources/remote_extension_index_datasource.dart
**Normalization Rules**:

- Accept canonical object-root repositories unchanged: `schemaVersion`, `extensions`, optional `repositoryName`
- Accept Tachiyomi-style array-root repositories as a second supported format
- For Tachiyomi entries, map `pkg` -> `packageName`, `version` -> `versionName`, `lang` -> `language`, and `apk` -> `installArtifact`
- Coerce `nsfw` values from integer or boolean into the existing boolean `isNsfw` field
- Ignore Tachiyomi-only metadata that the app does not currently consume, including `code` and `sources`
- Preserve remote listing/trust/install behavior by normalizing both formats into the existing `RemoteExtensionEntryModel` shape
- Resolve non-absolute Tachiyomi `apk` filenames relative to repository-aware rules, with `apk/` under the repository root as the primary convention to implement next

## TODO Pipeline

### Phase 1: Domain/Contract Stability

| ID       | Task                                                                            | Status  | File                                 | Agent      | Notes                                                                            |
| -------- | ------------------------------------------------------------------------------- | ------- | ------------------------------------ | ---------- | -------------------------------------------------------------------------------- |
| TODO-001 | Preserve existing ExtensionRepository and LoadRemoteExtensionsUseCase contracts | ✅ DONE | lib/features/extensions/domain/      | Code Agent | Verified no domain contract changes are needed for compatibility support         |
| TODO-002 | Define normalization rules for Tachiyomi array feeds                            | ✅ DONE | lib/features/extensions/data/models/ | Code Agent | Dual root-shape support and alias mapping rules are now fixed for implementation |

### Phase 2: Data Layer

| ID       | Task                                                        | Status  | File                                      | Agent      | Notes                                                                                                           |
| -------- | ----------------------------------------------------------- | ------- | ----------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------- |
| TODO-003 | Add Tachiyomi compatibility model for array-root entries    | ✅ DONE | lib/features/extensions/data/models/      | Code Agent | Added `tachiyomi_repository_index_model.dart` to normalize alias-based entries into `RemoteExtensionEntryModel` |
| TODO-004 | Update datasource to detect canonical and Tachiyomi schemas | ✅ DONE | lib/features/extensions/data/datasources/ | Code Agent | Datasource now accepts object-root and array-root repository payloads                                           |
| TODO-005 | Resolve apk filenames into absolute install artifacts       | ✅ DONE | lib/features/extensions/data/models/      | Code Agent | Bare Tachiyomi filenames now resolve against the repository root `apk/` convention                              |
| TODO-006 | Normalize Tachiyomi feeds into the existing internal shape  | ✅ DONE | lib/features/extensions/data/             | Code Agent | Array-root entries normalize into existing `RemoteExtensionIndexModel` and `RemoteExtensionEntryModel` shapes   |

### Phase 3: Presentation Layer

| ID       | Task                                                            | Status  | File                                            | Agent      | Notes                                                                                          |
| -------- | --------------------------------------------------------------- | ------- | ----------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------- |
| TODO-007 | Update settings validation for compatible Tachiyomi feeds       | ✅ DONE | lib/features/settings/presentation/controllers/ | Code Agent | Existing validation path now accepts compatible array-root feeds through the shared datasource |
| TODO-008 | Decide whether skipped-repository diagnostics should be exposed | ✅ DONE | lib/features/extensions/data/repositories/      | Code Agent | Option B: Settings-only diagnostics (health status in Settings; Extensions page stays clean)   |
| TODO-009 | Surface repository health status in Settings UI                 | ✅ DONE | lib/features/main/presentation/screens/         | Code Agent | Validation now fetches and parses index; health status icon + label shown in repository list   |
| TODO-010 | Add copy for repository health states                           | ✅ DONE | lib/core/constants/                             | Code Agent | Added: "Healthy", "Unavailable", "Not validated" status labels to AppStrings                   |

### Phase 4: Integration

| ID       | Task                                                         | Status     | File                                       | Agent      | Notes |
| -------- | ------------------------------------------------------------ | ---------- | ------------------------------------------ | ---------- | ----- |
| TODO-011 | Verify composite merge behavior remains correct              | ⬜ PENDING | lib/features/extensions/data/repositories/ | Code Agent |       |
| TODO-012 | Verify install flow receives resolved installArtifact values | ⬜ PENDING | lib/features/extensions/data/repositories/ | Code Agent |       |

### Phase 5: Tests

| ID       | Task                                                           | Status     | File                                             | Agent      | Notes                                                                            |
| -------- | -------------------------------------------------------------- | ---------- | ------------------------------------------------ | ---------- | -------------------------------------------------------------------------------- |
| TODO-013 | Test canonical schema parsing still works                      | ✅ DONE    | test/features/extensions/data/                   | Code Agent | Added and updated focused datasource/model tests                                 |
| TODO-014 | Test Tachiyomi schema parsing into extension items             | ✅ DONE    | test/features/extensions/data/                   | Code Agent | Added Tachiyomi normalization model and datasource coverage                      |
| TODO-015 | Test install artifact resolution rules                         | ✅ DONE    | test/features/extensions/data/                   | Code Agent | Added direct fetch-rule coverage for repository-aware APK resolution             |
| TODO-016 | Test mixed repository partial-success behavior                 | ✅ DONE    | test/features/extensions/data/                   | Code Agent | Added repository test proving invalid repositories do not suppress valid entries |
| TODO-017 | Test settings validation for the provided repository URL shape | ✅ DONE    | test/features/settings/presentation/controllers/ | Code Agent | Validation controller tests now use the provided direct-json repository URL      |
| TODO-018 | Test compatibility warning UI if diagnostics are added         | ⬜ PENDING | test/features/extensions/presentation/           | Code Agent | Optional                                                                         |

## Status Key

- ⬜ PENDING — not started
- 🔄 IN PROGRESS — currently being worked on
- ✅ DONE — complete and verified
- ⛔ BLOCKED — blocked by an issue (see Notes)
- ⏭️ SKIPPED — intentionally skipped with reason in Notes
