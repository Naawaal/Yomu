# Settings Redesign Pipeline

**Status**: IN PROGRESS
**Feature**: Settings Page Redesign (Theme, Backup, Repository Management)
**Architecture**: Presentation Layer Only (Domain/Data unchanged)
**Design System**: Material 3 (colorScheme roles, textTheme scales, AppSpacing, AppRadius tokens)

## Context Block

**Task Summary**: Refine the settings presentation so section state, layout, semantics, and tests align with the app's Material 3 design system.
**Reference Feature**: lib/features/main/presentation/screens/settings_screen.dart
**Key Constraints**:
- Keep domain and data layers unchanged
- Use AppStrings for visible UI copy
- Use design tokens for spacing, radius, and colors
- Preserve the existing settings snapshot flow

## Decisions Log

| Decision | Rationale | Agent | Date |
| --- | --- | --- | --- |
| Parent screen owns section card chrome | Keeps section widgets content-only and reusable | Code | 2026-04-20 |
| Track operation state separately from snapshot state | Enables per-section loading/error without partial data models | Code | 2026-04-20 |
| Keep the settings controller on full snapshot reloads | Avoids stale state and reduces merge complexity | Code | 2026-04-20 |

## Completed TODOs (12/14)

### ✅ TODO-SET-001: Section hierarchy & spacing contract

Section order and page rhythm documented; section card styling standardized.

### ✅ TODO-SET-002: Section-scoped state behavior model

Added `SettingsSectionOperation`, `SectionOperationState`, and `sectionOperationStateProvider`.

### ✅ TODO-SET-003: Theme section card widget

Theme section now renders content only and uses the shared card wrapper.

### ✅ TODO-SET-004: Backup section card widget

Backup section now renders content only and uses the shared card wrapper.

### ✅ TODO-SET-005: Repository section card widget

Repository section now renders content only and uses the shared card wrapper.

### ✅ TODO-SET-006: Accessibility attributes and focus

Semantic labels and container context added for interactive settings content.

### ✅ TODO-SET-007: Responsive layout adjustments

Layout behavior now scales across mobile, tablet, and desktop widths.

### ✅ TODO-SET-008: Motion and transitions

Shimmer loading, header motion, and navigation transitions are in place.

### ✅ TODO-SET-009: String constants validation

All visible settings copy is AppStrings-backed.

### ✅ TODO-SET-010: Settings controller state refinement

Controller methods now update `sectionOperationStateProvider` during theme, backup, and repository operations.

### ✅ TODO-SET-011: Settings screen integration

`SettingsScreen` now consumes the section operation state overlay for per-section loading and error feedback.

### ✅ TODO-SET-012: Widget and behavior tests

Widget tests for the settings sections and screen coverage now pass cleanly.

## Pending TODOs (2/14)

### ⏳ TODO-SET-013: Accessibility and responsive tests

Add widget tests for semantic labels, focus management, and responsive breakpoints.

### ⏳ TODO-SET-014: Manual QA and validation

Manual testing on device/emulator; verify UX against design specs.

## Architecture Decisions

### 1. Section Card Ownership (TODO-SET-001)

Parent screen owns card chrome, title, and padding. Section widgets render content only.

### 2. Section-Scoped State (TODO-SET-002)

Maintain full snapshot state and track operation type separately for UI feedback.

### 3. Design Token Compliance (TODO-SET-001+)

Use design tokens for all colors, text styles, spacing, and radius. Zero exceptions.

### 4. Accessibility First (TODO-SET-006)

Provide semantic labels on all containers and interactive controls.

## File Changes Summary

| File | Status | Notes |
| --- | --- | --- |
| [lib/features/main/presentation/screens/settings_screen.dart](../../lib/features/main/presentation/screens/settings_screen.dart) | Complete | Section overlays and card structure |
| [lib/features/settings/presentation/controllers/settings_controller.dart](../../lib/features/settings/presentation/controllers/settings_controller.dart) | Complete | Section operation state updates |
| [lib/features/settings/presentation/widgets/theme_settings_section_widget.dart](../../lib/features/settings/presentation/widgets/theme_settings_section_widget.dart) | Complete | Content-only theme selector |
| [lib/features/settings/presentation/widgets/backup_settings_section_widget.dart](../../lib/features/settings/presentation/widgets/backup_settings_section_widget.dart) | Complete | Content-only backup controls |
| [lib/features/settings/presentation/widgets/repository_settings_section_widget.dart](../../lib/features/settings/presentation/widgets/repository_settings_section_widget.dart) | Complete | Content-only repository controls |
| [test/features/settings/presentation/widgets/theme_settings_section_widget_test.dart](../../test/features/settings/presentation/widgets/theme_settings_section_widget_test.dart) | Complete | Theme selector coverage |
| [test/features/settings/presentation/widgets/backup_settings_section_widget_test.dart](../../test/features/settings/presentation/widgets/backup_settings_section_widget_test.dart) | Complete | Backup action coverage |
| [test/features/settings/presentation/widgets/repository_settings_section_widget_test.dart](../../test/features/settings/presentation/widgets/repository_settings_section_widget_test.dart) | Complete | Repository action coverage |
| [test/features/main/presentation/screens/settings_screen_test.dart](../../test/features/main/presentation/screens/settings_screen_test.dart) | Complete | Screen layout and loading coverage |

## Validation

- `flutter test` on settings presentation tests: passing
- `flutter analyze`: passing

## Next Steps

1. TODO-SET-013: accessibility and responsive test coverage
2. TODO-SET-014: manual QA and validation
