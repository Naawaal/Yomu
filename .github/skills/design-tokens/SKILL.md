---
name: design-tokens
description: "Design system tokens for this Flutter app: ColorScheme roles, TextTheme typescale, spacing values (xs/sm/md/lg/xl/xxl), border radius tokens, elevation levels, icon system, and component contracts. Auto-load when writing any Flutter widget, page, or UI component."
user-invocable: false
disable-model-invocation: false
---

# Design Tokens Reference

Complete design system for this Flutter app. Use these exact values in all UI code.
Full JSON spec: [design_system.json](./design_system.json)

## Non-negotiable rules

1. Every color → `colorScheme.[role]` — zero exceptions
2. Every text style → `textTheme.[scale]` — zero exceptions
3. All spacing → `AppSpacing.[token]` constant — no magic numbers
4. All radius → `AppRadius.[token]` constant — no magic numbers
5. Elevation → tonal color (surfaceTintColor = primary), NOT drop shadows

## Color Roles (from design_system.json)

Access: `Theme.of(context).colorScheme.[role]`

```dart
// Backgrounds and surfaces (4-level hierarchy)
colorScheme.background               // page background
colorScheme.surface                  // card/sheet surface
colorScheme.surfaceContainer         // secondary surface
colorScheme.surfaceContainerHighest  // highest contrast surface

// Primary actions
colorScheme.primary                  // primary buttons, active icons
colorScheme.onPrimary                // text/icons on primary
colorScheme.primaryContainer         // featured cards, chips selected
colorScheme.onPrimaryContainer       // text/icons on primaryContainer

// Secondary
colorScheme.secondary                // secondary actions
colorScheme.secondaryContainer       // nav indicator, filter chips
colorScheme.onSecondaryContainer     // text on secondaryContainer

// Text and icons
colorScheme.onSurface                // primary text
colorScheme.onSurfaceVariant         // secondary text, default icons

// Borders
colorScheme.outline                  // input borders, dividers (stronger)
colorScheme.outlineVariant           // card borders, dividers (subtle)

// Semantic (via ThemeExtension — NOT colorScheme)
Theme.of(context).extension<AppColorsExtension>()!.success
Theme.of(context).extension<AppColorsExtension>()!.warning
Theme.of(context).extension<AppColorsExtension>()!.info
```

## Typography Scale

Access: `Theme.of(context).textTheme.[scale]`

```dart
textTheme.displayLarge    // 57px — splash screens only
textTheme.headlineLarge   // 32px — screen hero text (display font)
textTheme.headlineMedium  // 28px — section heroes (display font)
textTheme.headlineSmall   // 24px — card titles (display font)
textTheme.titleLarge      // 22px — app bar titles
textTheme.titleMedium     // 16px w500 — list item titles
textTheme.titleSmall      // 14px w500 — section headers
textTheme.bodyLarge       // 16px — primary body text
textTheme.bodyMedium      // 14px — secondary body, list subtitles
textTheme.bodySmall       // 12px — captions, metadata
textTheme.labelLarge      // 14px w500 — buttons (auto-applied by M3)
textTheme.labelMedium     // 12px w500 — chips, tags
textTheme.labelSmall      // 11px w500 — badges, tiny labels
```

## Spacing Tokens

```dart
AppSpacing.xs  = 4   // tight internal (icon gaps, chip internal)
AppSpacing.sm  = 8   // compact (list item internal, small cards)
AppSpacing.md  = 16  // standard (screen horizontal margin, card padding)
AppSpacing.lg  = 24  // generous (section gaps, modal padding)
AppSpacing.xl  = 32  // section separators
AppSpacing.xxl = 48  // hero/onboarding spacing
```

## Border Radius Tokens

```dart
AppRadius.xs   = 4   // tags, badges
AppRadius.sm   = 8   // buttons, inputs, small cards
AppRadius.md   = 12  // standard cards
AppRadius.lg   = 16  // bottom sheets, dialogs
AppRadius.xl   = 24  // hero cards, featured content
AppRadius.full = 999 // pills, avatars, FABs
```

## Component Quick Reference

```dart
// PRIMARY BUTTON
FilledButton(
  style: FilledButton.styleFrom(
    minimumSize: const Size(64, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
  ),
  onPressed: ...,
  child: Text('Action', style: textTheme.labelLarge),
)

// CONTENT CARD
Card(
  elevation: 0,
  color: colorScheme.surfaceContainerLow,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    side: BorderSide(color: colorScheme.outlineVariant),
  ),
  child: Padding(padding: EdgeInsets.all(AppSpacing.md), ...),
)

// LOADING (shimmer — never CircularProgressIndicator on full screen)
Shimmer.fromColors(
  baseColor: colorScheme.surfaceContainerHighest,
  highlightColor: colorScheme.surfaceContainerHigh,
  child: [skeleton matching content shape],
)

// NAVIGATION BAR (never BottomNavigationBar)
NavigationBar(
  indicatorColor: colorScheme.secondaryContainer,
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  ...
)
```

## Forbidden Patterns

These are never valid regardless of context:

- `Color(0x...)` or `Colors.*` (except `Colors.transparent`)
- `TextStyle(fontSize: ...)` or any TextStyle construction outside `app_text_styles.dart`
- `BottomNavigationBar` (use `NavigationBar`)
- `CircularProgressIndicator` as sole full-screen loader (use shimmer skeleton)
- Elevation > 0 on cards (use tonal color: `surfaceContainerLow`)
- Drop shadows on cards or surfaces (M3 uses tonal elevation)
