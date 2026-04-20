# Pipeline: Extensions Host

**Status**: COMPLETE
**Created**: 2026-04-17
**Last Updated**: 2026-04-17 by GitHub Copilot

## Context Block

**Task Summary**: Build the Android/Flutter extension host workflows for discovery, trust, and install handling, starting with host-side architecture extraction.
**Architecture Pattern**: Riverpod generator + MethodChannel bridge + Android host managers
**Reference Feature**: lib/features/settings/presentation/controllers/settings_controller.dart
**Key Constraints**:

- Keep current MethodChannel contract unless richer typed transport becomes necessary
- Do not rely on heuristic package scans as the long-term extension identity model
- Add signer/trust workflow before treating extensions as trusted
- Preserve Material 3 and theme token usage in Flutter UI

## Decisions Log

| Decision                                                                   | Rationale                                                               | Agent      | Date       |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ---------- | ---------- |
| Keep MethodChannel for this phase                                          | Current bridge surface is still small and validated in research         | Researcher | 2026-04-17 |
| Split Android host logic out of MainActivity first                         | Session install and signer validation should not accumulate in activity | Researcher | 2026-04-17 |
| Use explicit extension identification, not broad user-installed heuristics | Required for Android 11+ visibility and secure trust model              | Researcher | 2026-04-17 |
| Verify signers before trust acceptance                                     | User trust without signer checks is not sufficient                      | Researcher | 2026-04-17 |

## Research Findings

**Validated Packages**: flutter_riverpod 2.6.1, riverpod_annotation 2.6.1, go_router 16.2.0, shared_preferences 2.5.5, moon_design 1.1.0
**Flagged Issues**: MainActivity is overloaded; package visibility and signing workflows are incomplete; install flow is only stubbed
**UI Specification**: Existing extensions store/details screens remain the presentation baseline; host install flow is primarily native/system UI
**Pattern Reference**: lib/features/settings/presentation/controllers/settings_controller.dart; lib/features/extensions/data/repositories/bridge_extension_repository.dart

## TODO Pipeline

### Phase 1: Android Host Foundation

| ID       | Task                                                             | Status  | File                                          | Agent   | Notes                                                                                                                        |
| -------- | ---------------------------------------------------------------- | ------- | --------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------- |
| TODO-001 | Extract Android extension host manager classes from MainActivity | ✅ DONE | android/app/src/main/kotlin/com/example/yomu/ | Builder | MainActivity now delegates to ExtensionsHost and ExtensionInstallManager; flutter analyze and :app:compileDebugKotlin passed |
| TODO-002 | Define explicit extension identity contract                      | ✅ DONE | android/app/src/main/kotlin/com/example/yomu/ | Builder | Discovery now requires ExtensionPackageContract manifest metadata; flutter analyze and :app:compileDebugKotlin passed        |
| TODO-003 | Add signer verification workflow                                 | ✅ DONE | android/app/src/main/kotlin/com/example/yomu/ | Builder | Trust now requires verified installed package signers; persisted trust only counts when verification still passes            |

### Phase 2: Install Flow

| ID       | Task                                            | Status  | File                                                               | Agent   | Notes                                                                                                                                                                                                                               |
| -------- | ----------------------------------------------- | ------- | ------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TODO-004 | Implement PackageInstaller session install flow | ✅ DONE | android/app/src/main/kotlin/com/example/yomu/                      | Builder | Added installArtifact contract end-to-end and PackageInstaller session commit flow (artifact streaming + pending user action launch); flutter analyze and :app:compileDebugKotlin passed                                            |
| TODO-005 | Expose structured install state to Flutter      | ✅ DONE | lib/core/bridge/ and android/app/src/main/kotlin/com/example/yomu/ | Builder | Native install returns structured state map (committed/requires_user_action), bridge parses HostInstallResult, repository maps native errors to typed ExtensionInstallException; flutter analyze and :app:compileDebugKotlin passed |

### Phase 3: Discovery and Trust Integration

| ID       | Task                                                    | Status  | File                                                            | Agent   | Notes                                                                                                                                                                                                       |
| -------- | ------------------------------------------------------- | ------- | --------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TODO-006 | Refine extension discovery with visibility-aware lookup | ✅ DONE | android/app/src/main/AndroidManifest.xml and android host files | Builder | Added targeted discovery action query in manifest and host query-first discovery with fallback scan; flutter analyze and :app:compileDebugKotlin passed                                                     |
| TODO-007 | Integrate verified trust into Flutter repository flow   | ✅ DONE | lib/features/extensions/                                        | Builder | Native trust verification failures now surface as typed ExtensionTrustException while missing plugin/runtime and unsupported capability still fall back; flutter analyze and :app:compileDebugKotlin passed |

### Phase 4: Approved Bugfix Pipeline (2026-04-19)

| ID       | Task                                                                                                          | Status  | File                                                                                                                                                          | Agent   | Notes                                                                                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TODO-008 | Android extension scanner compatibility fallback so non-Yomu Tachiyomi/Mihon packages can appear installed    | ✅ DONE | android/app/src/main/kotlin/com/example/yomu/ and android/app/src/main/AndroidManifest.xml                                                                    | Builder | Added compatibility discovery actions + package-prefix fallback mapping while keeping Yomu metadata contract path preferred                                                  |
| TODO-009 | Include icon payload for installed extension entries from native host where possible                          | ✅ DONE | android/app/src/main/kotlin/com/example/yomu/ExtensionsHost.kt and lib/core/bridge/extensions_host_client.dart                                                | Builder | Host now emits iconUrl payload via metadata override or generated PNG data URI from installed app icon; Dart payload mapping already supports icon aliases                   |
| TODO-010 | Normalize/handle GitHub repo page URLs for extension index fetch and fail clearly for HTML/non-JSON           | ✅ DONE | lib/features/extensions/data/models/remote_extension_index_model.dart and lib/features/extensions/data/datasources/                                           | Builder | Added GitHub tree/blob normalization to raw index URL when feasible and explicit HTML/non-JSON invalid-format errors with raw URL guidance                                   |
| TODO-011 | Preserve partial-success remote fetch but attach actionable per-repository failure reasons for empty catalogs | ✅ DONE | lib/features/extensions/data/repositories/remote_extension_catalog_repository_impl.dart and composite_extension_repository                                    | Builder | Added aggregated per-repository failure diagnostics and rethrow behavior only when remote fails and no installed sources are available                                       |
| TODO-012 | Ensure post-install refresh path reflects installed status promptly or pending-user-action explicitly         | ✅ DONE | lib/features/extensions/data/repositories/bridge_extension_repository.dart and lib/features/extensions/presentation/controllers/extensions_controllers.dart   | Builder | Pending user action now surfaced explicitly, refresh is attempted for pending outcomes, and action state is auto-cleared if refreshed list already reflects installed status |
| TODO-013 | Add/adjust tests for URL normalization and invalid non-JSON handling                                          | ✅ DONE | test/features/extensions/data/models/remote_extension_index_model_test.dart and test/features/extensions/data/datasources/                                    | Builder | Added GitHub normalization coverage and clear HTML/non-JSON failure assertions                                                                                               |
| TODO-014 | Add/adjust tests ensuring home feed is non-empty when installed sources exist                                 | ✅ DONE | test/features/home/presentation/providers/home_feed_provider_test.dart and test/features/extensions/presentation/controllers/extensions_controllers_test.dart | Builder | Added compatibility-source installed feed test and install pending refresh-path tests                                                                                        |

## Status Key

- ⬜ PENDING — not started
- 🔄 IN PROGRESS — currently being worked on
- ✅ DONE — complete and verified
- ⛔ BLOCKED — blocked by an issue
- ⏭️ SKIPPED — intentionally skipped with reason in Notes
