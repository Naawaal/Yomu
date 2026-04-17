import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/bridge/extensions_host_client.dart';
import '../../data/repositories/bridge_extension_repository.dart';
import '../../data/repositories/mock_extension_repository.dart';
import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/extension_repository.dart';

part 'extensions_controllers.g.dart';

/// Provides the extension repository implementation.
@riverpod
ExtensionRepository extensionRepository(Ref ref) {
  return BridgeExtensionRepository(
    hostClient: MethodChannelExtensionsHostClient(),
    fallbackRepository: MockExtensionRepository(),
  );
}

/// Loads extension list state.
@riverpod
class ExtensionsListController extends _$ExtensionsListController {
  @override
  Future<List<ExtensionItem>> build() {
    final ExtensionRepository repository = ref.watch(
      extensionRepositoryProvider,
    );
    return repository.getAvailableExtensions();
  }

  /// Reloads extension list from repository.
  Future<void> refresh() async {
    state = const AsyncValue<List<ExtensionItem>>.loading();
    state = await AsyncValue.guard(build);
  }
}

/// Handles mutating extension actions.
@riverpod
class ExtensionActionController extends _$ExtensionActionController {
  @override
  Future<void> build() async {}

  /// Trusts the extension package.
  Future<void> trust(String packageName) async {
    final ExtensionRepository repository = ref.read(
      extensionRepositoryProvider,
    );
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() => repository.trust(packageName));
    await ref.read(extensionsListControllerProvider.notifier).refresh();
  }

  /// Installs the extension package.
  Future<void> install(String packageName, {String? installArtifact}) async {
    final ExtensionRepository repository = ref.read(
      extensionRepositoryProvider,
    );
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(
      () => repository.install(packageName, installArtifact: installArtifact),
    );
  }
}
