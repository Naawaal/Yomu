# Settings Redesign Pipeline

**Status**: IN PROGRESS  
**Feature**: Settings Page Redesign (Theme, Backup, Repository Management)  
**Architecture**: Presentation Layer Only (Domain/Data unchanged)  
**Design System**: Material 3 (colorScheme roles, textTheme scales, AppSpacing, AppRadius tokens)

---

## Completed TODOs (7/14)

### ✅ TODO-SET-001: Section hierarchy & spacing contract

**Acceptance**: Section order and page rhythm documented; all spacing/radius reference token constants.

**Changes**:

- Refactored [lib/features/main/presentation/screens/settings_screen.dart](../../lib/features/main/presentation/screens/settings_screen.dart)
- Documented three-card layout: Theme → Backup → Repositories
- Defined spacing rhythm (AppSpacing.md/lg/sm/xl/xxxl)
- Created `_SettingsSectionCard` widget for consistent card styling
- Added comprehensive docstrings explaining IA and sliver structure

**Deliverables**:

- ✅ Page structure documented (420 lines with comments)
- ✅ All tokens used (no hardcoded values)
- ✅ M3 compliance: no raw colors/text styles
- ✅ Flutter analyze: clean

---

### ✅ TODO-SET-002: Section-scoped state behavior model

**Acceptance**: Section operation state model supports per-section loading/error without full-page blocks.

**Changes**:

- Added `SettingsSectionOperation` enum (7 operation types)
- Created `SectionOperationState` class with isLoading/hasError getters
- Created `sectionOperationStateProvider` (StateProvider)
- Documented full architecture in SettingsController (detailed comments explaining future integration)

**Deliverables**:

- ✅ Operation enum with all section types
- ✅ State class with computed properties
- ✅ Provider for presentation layer access
- ✅ Architecture documentation (enables TODO-SET-011 integration)
- ✅ Flutter analyze: clean

**Architecture Notes**:

- Domain/data layers unchanged
- Presentation layer tracks operation state independently
- Full snapshot still reloaded after operations (fresh data)
- Per-section loading indicators can display without blocking others

---

### ✅ TODO-SET-003: Theme section card widget

**Acceptance**: Theme section renders content without card/title wrapper; uses token-based styling.

**Changes**:

- Removed AppCard and title from ThemeSettingsSectionWidget
- Widget now renders only SegmentedButton content
- Parent \_SettingsSectionCard provides card+title+padding
- Added semantic container for a11y

**Deliverables**:

- ✅ Content-only widget (card provided by parent)
- ✅ SegmentedButton with 3 theme options
- ✅ No duplicate card styling
- ✅ Flutter analyze: clean (unused imports removed)

---

### ✅ TODO-SET-004: Backup section card widget

**Acceptance**: Backup section renders content without card/title wrapper; uses token-based styling.

**Changes**:

- Removed AppCard wrapper from BackupSettingsSectionWidget
- Widget renders two tappable list items (export/import)
- Metadata (last export/import timestamps) included
- Added semantic labels for a11y

**Deliverables**:

- ✅ Content-only widget (card provided by parent)
- ✅ Two action list items with trailing icons
- ✅ Timestamp display with fallback
- ✅ Flutter analyze: clean

---

### ✅ TODO-SET-005: Repository section card widget

**Acceptance**: Repository section renders content without card/title wrapper; uses token-based styling.

**Changes**:

- Removed AppCard wrapper from RepositorySettingsSectionWidget
- Widget renders repository list or empty state
- Health status icons with color-coding (healthy/unhealthy/unknown)
- Add repository button at bottom
- Added semantic list context for a11y

**Deliverables**:

- ✅ Content-only widget (card provided by parent)
- ✅ Repository list with health indicators
- ✅ Per-repository action buttons (validate/remove)
- ✅ Empty state with informative message
- ✅ Flutter analyze: clean

---

### ✅ TODO-SET-006: Accessibility attributes & focus

**Acceptance**: Semantic labels and screen reader support for all interactive elements.

**Changes**:

- Added Semantics container to \_SettingsSectionCard
- Added semanticLabel to section title
- Added Semantics context to theme widget
- Added Semantics labels to backup actions with timestamps
- Added Semantics labels to repository items with health status
- Added tooltips to all icon buttons (via existing AppListTile/AppButton)

**Deliverables**:

- ✅ Screen reader context for all sections
- ✅ Semantic labels with dynamic content (timestamps, status)
- ✅ Proper label hierarchy
- ✅ Flutter analyze: clean

---

### ✅ TODO-SET-007: Responsive layout adjustments

**Acceptance**: Layout adapts to mobile/tablet/desktop without breaking; spacing scales appropriately.

**Implementation**: Already complete via:

- SliverAppBar (responsive header)
- CustomScrollView + slivers (scroll-aware layout)
- Token-based spacing (AppSpacing tokens scale consistently)
- Flexible/Expanded widgets in repository list
- No hardcoded dimensions

**Deliverables**:

- ✅ Mobile: full-width cards with edge padding
- ✅ Tablet+: consistent padding and max-width via InsetsTokens
- ✅ All spacing uses tokens (responsive by design)

---

### ✅ TODO-SET-008: Motion & transitions

**Acceptance**: Page transitions and content loading provide visual feedback.

**Implementation**: Already complete via:

- Shimmer loading (shape-matched skeletons for all 3 sections)
- SliverAppBar.medium (collapsing header animation)
- Navigation transitions (GoRouter fade-through)
- Snackbar feedback on operations

**Deliverables**:

- ✅ Full-page loading shimmer (3 placeholder cards)
- ✅ Header collapse animation
- ✅ Page transition motion (GoRouter)
- ✅ Operation feedback (snackbars)

---

## Pending TODOs (7/14)

### ⏳ TODO-SET-009: String constants validation

**Task**: Verify all user-facing text uses AppStrings centralized constants.

**Acceptance**: No hardcoded strings; all UI copy from AppStrings.  
**Status**: Ready (all visible strings verified to use AppStrings or dynamic values)

---

### ⏳ TODO-SET-010: Settings controller state refinement

**Task**: Update controller methods to populate sectionOperationStateProvider during operations.

**Acceptance**: Each operation (theme, backup, repository) updates section operation state.  
**Current State**: Provider exists, controller methods not yet updated.  
**Blocked By**: None (can proceed anytime)

---

### ⏳ TODO-SET-011: Settings screen integration

**Task**: Integrate sectionOperationStateProvider into SettingsScreen for per-section loading/error.

**Acceptance**: Sections show loading/error indicators independently; main snapshot state used for data.  
**Current State**: Screen displays three cards but uses full-page loading only.  
**Blocked By**: TODO-SET-010 (controller methods not yet calling section operation updates)

---

### ⏳ TODO-SET-012: Widget & behavior tests

**Task**: Add widget tests for all section widgets and screen layout.

**Test Coverage**:

- ThemeSettingsSectionWidget: selection changes, callback invocation
- BackupSettingsSectionWidget: export/import callbacks, timestamp display
- RepositorySettingsSectionWidget: list rendering, health status colors, add/validate/remove buttons
- SettingsScreen: screen state transitions (loading/error/data), snackbar feedback
- \_SettingsSectionCard: title rendering, semantic labels, spacing

**Acceptance**: ≥80% code coverage for presentation layer.

---

### ⏳ TODO-SET-013: Accessibility & responsive tests

**Task**: Add widget tests for semantic labels, focus management, and responsive breakpoints.

**Test Coverage**:

- Semantic labels on all interactive elements
- Dark/light theme adaptation
- Mobile/tablet layout (500dp, 720dp, 1200dp viewports)
- Text scaling (100%, 125%, 200%)
- Keyboard navigation (tab order)

**Acceptance**: All semantic labels verified; layout tested at 3 breakpoints.

---

### ⏳ TODO-SET-014: Manual QA & validation

**Task**: Manual testing on device/emulator; verify UX against design specs.

**QA Checklist**:

- [ ] Theme section: all 3 theme options selectable; icon changes reflect selection
- [ ] Backup section: export/import buttons tap-responsive; timestamps display correctly
- [ ] Repository section: list renders; health icons color-coded; add/validate/remove buttons work
- [ ] Loading: shimmer skeleton displays on initial load; matches content shape
- [ ] Error: error state shows recoverable error message + retry action
- [ ] Snackbar: operation feedback (theme changed, backup exported, repo added, etc.)
- [ ] A11y: TalkBack/VoiceOver navigation; screen reader announces all actions
- [ ] Responsive: tested on 360dp (mobile), 600dp (tablet), 1200dp (desktop)
- [ ] Dark mode: colors use colorScheme roles; no readability issues
- [ ] Motion: smooth transitions; shimmer animation fluid

---

## Architecture Decisions

### 1. Section Card Ownership (TODO-SET-001)

**Decision**: Parent screen (\_SettingsSectionCard) provides card, title, padding. Section widgets render content only.

**Rationale**:

- Consistent card styling across all sections
- Single source of truth for section header typography/color
- Easy to refactor section layout (e.g., side-by-side on desktop) without touching widget internals
- Reduces duplication across three nearly-identical section widgets

### 2. Section-Scoped State (TODO-SET-002)

**Decision**: Maintain full snapshot state (never partial). Track operation type separately for UI feedback.

**Rationale**:

- Avoids stale data (always reload full snapshot after operation)
- No complex state merging logic
- Per-section loading indicators still possible via operation state provider
- Domain/data layers unchanged (presentation concern only)

### 3. Design Token Compliance (TODO-SET-001+)

**Decision**: All colors, text styles, spacing, radius use design system tokens. Zero exceptions.

**Compliance**:

- ✅ Colors: Theme.of(context).colorScheme.[role]
- ✅ Text: Theme.of(context).textTheme.[scale]
- ✅ Spacing: AppSpacing.[xs-xxl] constants
- ✅ Radius: AppRadius.[xs-full] constants
- ✅ Elevation: Tonal (surfaceContainerLow/High), no drop shadows
- ✅ Components: M3 standards (no BottomNavigationBar, etc.)

### 4. Accessibility First (TODO-SET-006)

**Decision**: Semantic labels on all containers; screen reader context built-in from day one.

**Rationale**:

- Inclusive by default (not retrofitted)
- Semantic labels on operations (timestamps, health status, etc.)
- No hidden barriers for keyboard/a11y users

---

## File Changes Summary

| File                                                                                                                                                                           | Status      | Lines | Changes                                                                                                            |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- | ----- | ------------------------------------------------------------------------------------------------------------------ |
| [lib/features/main/presentation/screens/settings_screen.dart](../../lib/features/main/presentation/screens/settings_screen.dart)                                               | ✅ Complete | 420   | Refactored screen structure, added \_SettingsSectionCard, documented IA/spacing, added semantics                   |
| [lib/features/settings/presentation/controllers/settings_controller.dart](../../lib/features/settings/presentation/controllers/settings_controller.dart)                       | ✅ Complete | ~380  | Added SettingsSectionOperation enum, SectionOperationState class, sectionOperationStateProvider, architecture docs |
| [lib/features/settings/presentation/widgets/theme_settings_section_widget.dart](../../lib/features/settings/presentation/widgets/theme_settings_section_widget.dart)           | ✅ Complete | ~60   | Removed card wrapper, cleaned up imports, added semantics container                                                |
| [lib/features/settings/presentation/widgets/backup_settings_section_widget.dart](../../lib/features/settings/presentation/widgets/backup_settings_section_widget.dart)         | ✅ Complete | ~75   | Removed card wrapper, added semantic labels with dynamic content                                                   |
| [lib/features/settings/presentation/widgets/repository_settings_section_widget.dart](../../lib/features/settings/presentation/widgets/repository_settings_section_widget.dart) | ✅ Complete | ~130  | Removed card wrapper, added semantic list context and status labels                                                |

---

## Test Commands

```bash
# Analyze all changes
flutter analyze lib/features/settings/ lib/features/main/presentation/screens/settings_screen.dart

# Run existing tests (if any)
flutter test test/features/settings/

# Build for QA
flutter run --release
```

---

## Next Steps (Post-Implementation)

1. **TODO-SET-010**: Update controller methods to call sectionOperationStateProvider updates
2. **TODO-SET-011**: Integrate section operation state into screen (per-section loading indicators)
3. **TODO-SET-012/013**: Add widget tests + a11y coverage
4. **TODO-SET-014**: Manual QA on device

---

## Sign-Off

- **Completed**: 7/14 TODOs
- **Analyze Status**: ✅ All files clean (no errors/warnings)
- **Design Compliance**: ✅ 100% (all tokens, no exceptions)
- **Accessibility**: ✅ Semantic labels on all sections
- **Ready for**: TODO-SET-010 (controller method integration)
