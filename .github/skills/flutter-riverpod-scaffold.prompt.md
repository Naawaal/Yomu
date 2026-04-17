---
name: flutter-riverpod-scaffold
description: Generate a complete Riverpod v2 controller, state class, and provider wiring for a feature. Use when you need the presentation logic layer scaffolded fast.
---

# Flutter Riverpod Scaffold Skill

Generate a **complete, production-ready Riverpod v2 presentation layer** for a feature.

## Required Input
1. Feature name (e.g., `audio_player`, `recording_session`)
2. What state the controller manages (list of fields + types)
3. What actions the controller exposes (method names + parameters)
4. Whether the state initializes async (requires data fetch on build)

## Output Structure

### 1. State Class (always Freezed)
```dart
// presentation/controllers/<feature>_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '<feature>_state.freezed.dart';

@freezed
class ${Feature}State with _$${Feature}State {
  const factory ${Feature}State({
    // List all state fields here — no booleans for loading, use AsyncValue for async fields
    @Default([]) List<${Entity}> items,
    ${Entity}? selectedItem,
    @Default(false) bool isProcessing,  // only for synchronous UI states
  }) = _${Feature}State;
}
```

### 2. Controller (AsyncNotifier for async init, Notifier for sync)

**Async init pattern** (when data is fetched on startup):
```dart
// presentation/controllers/<feature>_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '<feature>_controller.g.dart';

@riverpod
class ${Feature}Controller extends _$${Feature}Controller {
  @override
  FutureOr<${Feature}State> build() async {
    // One-time initialization
    final items = await ref.watch(${feature}RepositoryProvider).getItems();
    // Watch for changes and auto-rebuild on dependency change
    ref.listen(someStreamProvider, (_, next) {
      // handle stream update
    });
    return ${Feature}State(items: items);
  }

  Future<void> doAction(${Entity} item) async {
    // Don't set loading here for non-initial loads — use a separate isProcessing flag
    state = AsyncData(state.requireValue.copyWith(isProcessing: true));
    
    final result = await AsyncValue.guard(
      () => ref.read(${feature}RepositoryProvider).performAction(item),
    );
    
    result.when(
      data: (_) => state = AsyncData(
        state.requireValue.copyWith(isProcessing: false, selectedItem: item),
      ),
      error: (e, st) => state = AsyncError(e, st),
      loading: () {},
    );
  }
}
```

**Sync pattern** (no async init):
```dart
@riverpod
class ${Feature}Controller extends _$${Feature}Controller {
  @override
  ${Feature}State build() => const ${Feature}State();

  void selectItem(${Entity} item) {
    state = state.copyWith(selectedItem: item);
  }

  Future<void> saveItem() async {
    state = state.copyWith(isProcessing: true);
    await ref.read(${feature}RepositoryProvider).save(state.selectedItem!);
    state = state.copyWith(isProcessing: false);
  }
}
```

### 3. Repository Provider Wiring
```dart
// Always show the full provider chain so wiring is unambiguous

@riverpod
${Feature}Repository ${feature}Repository(${Feature}RepositoryRef ref) {
  return ${Feature}RepositoryImpl(
    remoteDataSource: ref.watch(${feature}RemoteDataSourceProvider),
    localDataSource: ref.watch(${feature}LocalDataSourceProvider),
  );
}

@riverpod
${Feature}RemoteDataSource ${feature}RemoteDataSource(${Feature}RemoteDataSourceRef ref) {
  return ${Feature}RemoteDataSourceImpl(
    dioClient: ref.watch(dioClientProvider),
  );
}
```

### 4. Consumer Widget Usage Snippet
```dart
// How to use this controller in a screen
class ${Feature}Screen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(${feature}ControllerProvider);

    // Pattern: watch with select for granular rebuilds
    final selectedItem = ref.watch(
      ${feature}ControllerProvider.select((s) => s.valueOrNull?.selectedItem),
    );

    return switch (asyncState) {
      AsyncLoading() => const _LoadingSkeleton(),
      AsyncError(:final error) => _ErrorState(error: error),
      AsyncData(:final value) => _Content(
          state: value,
          onAction: (item) => ref
              .read(${feature}ControllerProvider.notifier)
              .doAction(item),
        ),
    };
  }
}
```
