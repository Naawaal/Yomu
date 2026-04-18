# Flutter Development Instructions

These instructions apply to all agents in this workspace.

> **For multi-step feature work**, see [AGENTS.md](AGENTS.md) for the complete agent workflow (Plan → Research → Build). Use the **Orchestrator Agent** as your single entry point.

> **For task coordination**, see the [flutter-task-pipeline skill](.github/skills/flutter-task-pipeline/SKILL.md) to view, update, or resume TODO pipeline state across agent runs.

## Project Standards

- **Language**: Dart 3.x — use null-safety, records, and pattern matching where appropriate
- **Flutter version**: Latest stable — use Material 3 (`useMaterial3: true`)
- **Target platforms**: Mobile (Android + iOS primary)

## Code Quality Rules (Enforced on Every Output)

1. No `dynamic` types. Use sealed classes or generics.
2. No `setState` in feature screens. Only allowed in isolated, self-contained UI widgets.
3. Every `AsyncValue` must handle `.loading`, `.error`, and `.data` — no silent failures.
4. No hardcoded colors, sizes, or strings in widget trees. All values from theme or constants.
5. Widgets must be < 150 lines. Extract to sub-widgets or dedicated files.
6. Every public method/class gets a brief doc comment.
7. `const` constructors wherever possible.

## Non-Negotiables

1. **No hardcoded colors** — use `Theme.of(context).colorScheme.*` only
2. **No hardcoded text styles** — use `Theme.of(context).textTheme.*` only
3. **No logic in `build()` methods** — extract to controllers, notifiers, or helpers
4. **No `print()` statements** — use `debugPrint()` or a logging package
5. **Always use `const`** for widgets that don't depend on runtime data

## Agent Workflow Order

For any non-trivial task, always follow this order (see [AGENTS.md](AGENTS.md) for detailed agent descriptions):

```
   1. PLAN first       → Decompose feature into TODO pipeline
   2. RESEARCH second  → Validate architecture against codebase
   3. BUILD third      → Implement one TODO at a time
   4. REVIEW optional  → Validate code quality & tests
```

**Use the Orchestrator Agent** as the single entry point — it automatically routes to the right agents in the correct order.

Skipping phases is allowed only for trivial changes (single-line fixes, typos, simple refactors).

## File Naming Conventions

| Type       | Convention                   | Example                   |
| ---------- | ---------------------------- | ------------------------- |
| Screen     | `snake_case_screen.dart`     | `profile_screen.dart`     |
| Widget     | `snake_case_widget.dart`     | `user_avatar_widget.dart` |
| Model      | `snake_case.dart`            | `user_model.dart`         |
| BLoC       | `snake_case_bloc.dart`       | `auth_bloc.dart`          |
| Notifier   | `snake_case_notifier.dart`   | `user_notifier.dart`      |
| Repository | `snake_case_repository.dart` | `user_repository.dart`    |

## Import Order

```dart
// 1. Dart core & async
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. External packages
import 'package:moon_design/moon_design.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// 4. Internal — core
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/core/router/app_router.dart';
import 'package:yomu/core/constants/app_strings.dart';

// 5. Internal — features
import 'package:yomu/features/feed/presentation/controllers/feed_controller.dart';
import 'package:yomu/features/feed/domain/repositories/feed_repository.dart';

// 6. Internal — shared
import 'package:yomu/core/widgets/loading_indicator.dart';

// 7. Code generation (if using Riverpod)
part 'file_name.g.dart';
```

## Flutter UI Design Standards

- Use `ThemeData` extensions for custom tokens; never inline `Color(0xFF...)` in widgets.
- Spacing: use a spacing scale (4, 8, 12, 16, 24, 32, 48, 64) — no arbitrary pixel values.
- Prefer `SliverAppBar`, `CustomScrollView` for scrollable screens; avoid `NestedScrollView` hacks.
- Animations: use `AnimationController` + `CurvedAnimation`; never `Future.delayed` for UI timing.
- All `Image` widgets need `errorBuilder` and `loadingBuilder`.
- Responsive: use `LayoutBuilder` + `ScreenType` breakpoints (compact < 600, medium < 840, expanded).

> 💡 **See also**: [flutter-ui-research skill](.github/skills/flutter-ui-research/SKILL.md) for Material 3 patterns, component selection, theming, animations, and responsive design.

## Folder Structure Reference

```
lib/
  core/
    bridge/             # Platform channels (native interop)
    constants/          # AppStrings, AppDimensions, route paths
    router/             # AppRouter, route definitions (GoRouter)
    theme/              # AppTheme (Material 3 + Moon Design), AppThemeExtension
    widgets/            # Shared atomic widgets (reusable UI components)
  features/
    <feature_name>/
      data/
        datasources/    # (local or remote data sources)
        models/         # Freezed DTOs + JSON serialization
        repositories/   # Repository implementations
      domain/
        entities/       # Pure Dart classes (sealed classes, immutable)
        repositories/   # Abstract repository contracts
        usecases/       # (if not using Riverpod providers)
      presentation/
        screens/        # Full-page widgets (e.g., home_screen.dart)
        widgets/        # Feature-local UI components
        controllers/    # Riverpod providers (@riverpod, @riverpod.watch)
  extensions/
    presentation/       # Extensions feature (app-specific example)
  main.dart            # Entry point
  app.dart             # Root MaterialApp.router
```

**Note on feature structure**: Not every feature needs `domain/`. For simple screens, data + presentation is sufficient. Use domain layer for complex business logic shared across features.

> 💡 **See also**: [flutter-architecture skill](.github/skills/flutter-architecture/SKILL.md) for clean layering patterns, dependency injection setup, and entity/repository examples.

## Riverpod Code Generation

This project uses `riverpod_generator` + `build_runner` for @riverpod annotations. When creating providers:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_controller.g.dart';

@riverpod
Future<List<Feed>> feedList(FeedListRef ref) async {
  // Implementation
}

@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  FutureOr<List<Feed>> build() async {
    // Implementation
  }
}
```

After adding or modifying a provider, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or for watch mode during development:

```bash
flutter pub run build_runner watch
```

**Important**: Always include the `part` statement at the top of files using `@riverpod`.

> 💡 **See also**: [flutter-builder skill](.github/skills/flutter-builder/SKILL.md) for production code generation patterns and quality checklists.

## Development Workflow

### Common Commands

```bash
# Analyze code for issues
flutter analyze

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Format code
dart format lib/

# Run the app
flutter run -v

# Run tests
flutter test
```

### Debugging Tips

- Use `debugPrint()` instead of `print()` — wraps lines and adds time stamps
- Enable DevTools: `flutter run --devtools`
- For Riverpod state inspection, use `flutter pub add flutter_riverpod_inspector`
- Check theme at runtime: `print(Theme.of(context).colorScheme.primary);`
- Validate widget tree: `flutter run --profile` to check for expensive rebuilds

### Testing Pattern

Tests follow standard unit/widget patterns:

```bash
# Run all tests
flutter test test/

# Run tests matching a pattern
flutter test -k "feed"
```

Test example:

```dart
void main() {
  group('FeedController', () {
    test('loads feed successfully', () async {
      // Arrange
      final container = ProviderContainer();

      // Act
      final result = await container.read(feedListProvider.future);

      // Assert
      expect(result, isNotEmpty);
    });
  });
}
```

## Theme & Design System

### Material 3 + Moon Design

Your app uses **Moon Design** (`moon_design` package) with **Material 3** for a cohesive design system:

- **Color scheme**: Seed-based from `AppTheme._seedColor` (primary piccolo color)
- **Theme tokens**: `MoonTokens` (light/dark) registered as `ThemeExtension`
- **Spacing scale**: Use Moon's token system — no hardcoded pixel values
- **Components**: Prefer Moon Design widgets (MoonButton, MoonCheckbox) over Material when available
- **Theme access**:
  ```dart
  Theme.of(context).colorScheme.primary          // Material color
  Theme.of(context).extension<MoonTheme>()!      // Moon tokens
  ```

### Adding Custom Theme Values

Extend `AppThemeExtension` in `core/theme/app_theme_extension.dart`:

```dart
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color customBrandColor;

  const AppThemeExtension({required this.customBrandColor});

  static AppThemeExtension light() => AppThemeExtension(
    customBrandColor: const Color(0xFF005E7A),
  );

  @override
  ThemeExtension<AppThemeExtension> copyWith({Color? customBrandColor}) {
    // Implementation
  }
}
```

## Extensions Feature Patterns

The `extensions` feature demonstrates native platform bridge integration with fallback patterns. Key conventions:

### State Persistence (Trust)

When a repository needs to persist state across multiple instances:

- Use **singleton pattern** with static instance and shared data
- Example: [MockExtensionRepository](../lib/features/extensions/data/repositories/mock_extension_repository.dart) uses `static _instance` + `static _items` list
- Provide `@visibleForTesting resetForTesting()` method for test isolation
- Unit tests must call `setUp(MockExtensionRepository.resetForTesting)` to reset state between tests

### Native Bridge Fallback

When implementing native interop with fallback:

- Centralize capability names in bridge code: [ExtensionsHostCapabilities](../lib/core/bridge/extensions_host_client.dart)
- Mirror capability constants in native runtime info
- Check capabilities before delegating to native; fall back to mock on unsupported capabilities
- Example: [BridgeExtensionRepository](../lib/features/extensions/data/repositories/bridge_extension_repository.dart) checks `capabilities` set before calling native methods

### Network Image Handling

When displaying remote images with fallback:

- Always provide `errorBuilder` and `loadingBuilder` to `Image.network()`
- Implement graceful fallback (e.g., initials avatar) when image unavailable or fails
- Example: [ExtensionTile.\_ExtensionArtwork](../lib/features/extensions/presentation/widgets/extension_tile.dart) shows network icon with initials fallback

### Error Mapping

Data layer repositories must catch all exceptions and map to typed domain errors:

- Example: [ExtensionTrustException](../lib/features/extensions/data/repositories/bridge_extension_repository.dart) + [ExtensionInstallException](../lib/features/extensions/data/repositories/bridge_extension_repository.dart) carry `code` (machine-readable) + `message` (user-readable)
- Never let platform exceptions surface to presentation layer uncaught
- See [test coverage](../test/features/extensions/data/repositories/bridge_extension_repository_test.dart) for exception mapping patterns

For contract details, see [Extensions Feature README](../lib/features/extensions/README.md).

---

## What Every Agent Must Never Do

- Never generate a complete app in a single file
- Never use `BuildContext` across async gaps without `mounted` checks
- Never suggest `flutter pub get` as a fix — diagnose the actual issue
- Never output placeholder comments like `// TODO: implement` — write the actual implementation or ask
- Never skip error states in UI

---

## Linked Resources

**Agents & Workflow**:

- [AGENTS.md](AGENTS.md) — Agent catalog, when to use each agent, workflow coordination
- [Orchestrator Agent](AGENTS.md#orchestrator-agent) — Use this for all non-trivial feature work
- [Code Agent](AGENTS.md#code-agent) — Implements from TODO pipeline
- [PlanResearch Agent](AGENTS.md#planresearch-agent) — Decomposes features into TODO list
- [Explore Agent](AGENTS.md#explore-agent) — Fast codebase Q&A

**Skills** (on-demand, bundled workflows):

- [flutter-task-pipeline](../github/skills/flutter-task-pipeline/SKILL.md) — View, update, resume TODO pipeline state
- [flutter-architecture](../github/skills/flutter-architecture/SKILL.md) — Clean layering, entity/repository patterns, DI setup
- [flutter-builder](../github/skills/flutter-builder/SKILL.md) — Production code generation patterns, quality gates
- [flutter-ui-research](../github/skills/flutter-ui-research/SKILL.md) — Material 3, component selection, theming, animations
- [design-tokens](../github/skills/design-tokens/SKILL.md) — Design system reference

**Project Documentation**:

- [Extensions Feature README](../lib/features/extensions/README.md) — Native bridge contract, platform patterns
- [UI Guidelines](../lib/core/theme/UI_GUIDELINES.md) — Design tokens, components, constraints
