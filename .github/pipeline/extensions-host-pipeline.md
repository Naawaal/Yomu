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

## Status Key

- ⬜ PENDING — not started
- 🔄 IN PROGRESS — currently being worked on
- ✅ DONE — complete and verified
- ⛔ BLOCKED — blocked by an issue
- ⏭️ SKIPPED — intentionally skipped with reason in Notes
