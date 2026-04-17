# UI Guidelines

## Design Direction

- Style: minimal, modern, clean, high usability
- Tone: structured calm
- Seed color: #005E7A

## Typography

- Display font: Sora
- Body font: Plus Jakarta Sans
- Use Theme text roles only; do not create ad hoc text styles in widgets.

## Icons

- Use Ionicons as the single icon system.
- Prefer semantic aliases from design_system.json.

## Color Usage

- Use Theme.of(context).colorScheme roles.
- Semantic status colors (success/warning/info) must come from AppColorsExtension.

## Tokens

- Spacing: 4, 8, 12, 16, 24, 32, 48, 64
- Radius: 4, 8, 12, 16, 24, 999

## Components

- PrimaryButton: AppButton (filled)
- SecondaryButton: AppButton.outlined
- DestructiveButton: AppButton.destructive
- AppTextField: AppTextInput
- ContentCard: AppCard (tonal elevation, no drop shadow)
- AppNavBar: NavigationBar wrapper
- LoadingShimmer: shape-matched shimmer skeletons
- EmptyState: icon + copy + optional action
- ErrorState: icon + copy + retry action

## State Patterns

- Loading: shimmer for content screens
- Empty: informative message and recovery action when possible
- Error: safe message + retry control
- Success: concise, non-blocking feedback

## Constraints

- No Color(...) or Colors.\* in widget trees (except Colors.transparent)
- No TextStyle(...) outside app_text_styles.dart
- No BottomNavigationBar
- No spinner-only full-screen loading patterns
