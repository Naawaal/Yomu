# Yomu Agent Instructions

Purpose: help coding agents become productive quickly in this repo without duplicating existing docs.

## Start Here

- Project-level workflow and agent system: [.github/README.md](.github/README.md)
- UI/token rules and component contracts: [lib/core/theme/UI_GUIDELINES.md](lib/core/theme/UI_GUIDELINES.md)
- Design token source of truth: [lib/core/theme/design_system.json](lib/core/theme/design_system.json)
- Router and route helpers: [lib/core/router/app_router.dart](lib/core/router/app_router.dart)
- Shared component barrel: [lib/core/widgets/widgets.dart](lib/core/widgets/widgets.dart)
- UI strings source: [lib/core/constants/app_strings.dart](lib/core/constants/app_strings.dart)
- Error model baseline: [lib/core/failure.dart](lib/core/failure.dart)

## Required Standards

- Use Material 3 theming only: colorScheme roles for colors, textTheme roles for typography.
- Do not use hardcoded widget colors or raw TextStyle in widgets.
- Use AppSpacing and AppRadius tokens from the theme system.
- Loading for screens must be shape-matched shimmer, not spinner-only full-screen loading.
- Navigation must use NavigationBar patterns and route helpers from app_router.
- UI copy must come from AppStrings constants.
- Prefer Riverpod patterns already used in feature controllers.

## Architecture Guardrails

- Follow feature layering under lib/features/{feature}: domain, data, presentation.
- Domain stays pure Dart; repository contracts live in domain.
- Data repositories map exceptions into Failure/Either flows.
- Presentation controllers own business logic; widgets render state.
- When adding a feature, mirror the closest existing feature first.

## Commands Agents Should Use

- Get deps: flutter pub get
- Regenerate Riverpod/build files when needed: dart run build_runner build --delete-conflicting-outputs
- Analyze: flutter analyze
- Tests: flutter test

## Hook Behavior (Important)

- After Dart file writes, PostToolUse runs automatic checks via [.github/scripts/flutter-quality.ps1](.github/scripts/flutter-quality.ps1).
- The hook runs best-effort dart fix, then flutter analyze for changed Dart files.
- Fix reported warnings/errors before marking work complete.

## Common Pitfalls To Avoid

- Do not introduce new shared-state setState flows; use established controller/provider patterns.
- Do not add new raw Exception propagation in repositories; map to Failure.
- Do not bypass extension trust/signature checks in bridge-related work.
- Do not duplicate provider names across feature modules.

## Working Style

- Link to existing docs/files instead of embedding long duplicated guidance.
- Make the smallest safe change that matches local patterns.
- Validate with analyze/tests for touched areas before completion.
