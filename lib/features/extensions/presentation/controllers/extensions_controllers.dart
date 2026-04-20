import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/bridge/extensions_host_client.dart';
import '../../../../core/failure.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/datasources/remote_extension_index_datasource.dart';
import '../../data/repositories/extension_repository_result_adapter.dart';
import '../../data/repositories/bridge_extension_repository.dart';
import '../../data/repositories/composite_extension_repository.dart';
import '../../data/repositories/mock_extension_repository.dart';
import '../../data/repositories/remote_extension_catalog_repository_impl.dart';
import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/extension_repository.dart';
import '../../domain/repositories/remote_extension_catalog_repository.dart';
import '../../domain/usecases/load_remote_extensions_usecase.dart';

part 'extensions_controllers.g.dart';

/// Provides HTTP client implementation for remote extension index fetch.
final Provider<RemoteExtensionIndexHttpClient>
remoteExtensionIndexHttpClientProvider =
    Provider<RemoteExtensionIndexHttpClient>(
      (Ref ref) => const DartIoRemoteExtensionIndexHttpClient(),
    );

/// Provides datasource implementation for remote extension index fetch.
final Provider<RemoteExtensionIndexDataSource>
remoteExtensionIndexDataSourceProvider =
    Provider<RemoteExtensionIndexDataSource>((Ref ref) {
      return RemoteExtensionIndexHttpDataSource(
        httpClient: ref.watch(remoteExtensionIndexHttpClientProvider),
      );
    });

/// Provides remote-catalog repository implementation.
final Provider<RemoteExtensionCatalogRepository>
remoteExtensionCatalogRepositoryProvider =
    Provider<RemoteExtensionCatalogRepository>((Ref ref) {
      return RemoteExtensionCatalogRepositoryImpl(
        settingsRepository: ref.watch(settingsRepositoryProvider),
        dataSource: ref.watch(remoteExtensionIndexDataSourceProvider),
      );
    });

/// Provides use case for loading remote extension entries.
final Provider<LoadRemoteExtensionsUseCase>
loadRemoteExtensionsUseCaseProvider = Provider<LoadRemoteExtensionsUseCase>((
  Ref ref,
) {
  return LoadRemoteExtensionsUseCase(
    ref.watch(remoteExtensionCatalogRepositoryProvider),
  );
});

/// Provides the composed extension repository implementation.
@riverpod
ExtensionRepository extensionRepository(Ref ref) {
  final ExtensionRepository bridgeRepository = BridgeExtensionRepository(
    hostClient: MethodChannelExtensionsHostClient(),
    fallbackRepository: MockExtensionRepository.instance,
  );

  return CompositeExtensionRepository(
    primaryRepository: bridgeRepository,
    loadRemoteExtensions: ref.watch(loadRemoteExtensionsUseCaseProvider),
  );
}

/// Provides typed Either-based operations for extension repository flows.
final Provider<ExtensionRepositoryResultAdapter>
extensionRepositoryResultAdapterProvider =
    Provider<ExtensionRepositoryResultAdapter>((Ref ref) {
      return ExtensionRepositoryResultAdapter(
        ref.watch(extensionRepositoryProvider),
      );
    });

/// Loads extension list state.
@riverpod
class ExtensionsListController extends _$ExtensionsListController {
  @override
  Future<List<ExtensionItem>> build() {
    final ExtensionRepositoryResultAdapter adapter = ref.watch(
      extensionRepositoryResultAdapterProvider,
    );

    return adapter.getAvailableExtensions().then((
      Either<Failure, List<ExtensionItem>> result,
    ) {
      return result.fold(
        (Failure failure) => throw failure,
        (List<ExtensionItem> items) => items,
      );
    });
  }

  /// Reloads extension list from repository.
  Future<void> refresh() async {
    state = const AsyncValue<List<ExtensionItem>>.loading();
    state = await AsyncValue.guard(build);
  }
}

/// Derives installed extension entries from the loaded extensions list state.
final Provider<AsyncValue<List<ExtensionItem>>> installedSourcesProvider =
    Provider<AsyncValue<List<ExtensionItem>>>((Ref ref) {
      final AsyncValue<List<ExtensionItem>> asyncExtensions = ref.watch(
        extensionsListControllerProvider,
      );

      return asyncExtensions.whenData((List<ExtensionItem> items) {
        return items
            .where((ExtensionItem item) => item.isInstalled)
            .toList(growable: false);
      });
    });

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
    if (installArtifact == null || installArtifact.trim().isEmpty) {
      throw Exception(AppStrings.extensionsInstallArtifactMissing);
    }

    final ExtensionRepository repository = ref.read(
      extensionRepositoryProvider,
    );
    state = const AsyncLoading<void>();
    final AsyncValue<void> installState = await AsyncValue.guard(
      () => repository.install(packageName, installArtifact: installArtifact),
    );

    state = installState;

    final bool requiresUserAction =
        installState.hasError &&
        installState.error is ExtensionInstallException &&
        (installState.error as ExtensionInstallException).code ==
            ExtensionInstallErrorCode.requiresUserAction;

    if (!installState.hasError || requiresUserAction) {
      await ref.read(extensionsListControllerProvider.notifier).refresh();
    }

    if (requiresUserAction) {
      final List<ExtensionItem> refreshedItems =
          ref.read(extensionsListControllerProvider).valueOrNull ??
          const <ExtensionItem>[];
      final bool nowInstalled = refreshedItems.any(
        (ExtensionItem item) =>
            item.packageName == packageName && item.isInstalled,
      );

      if (nowInstalled) {
        state = const AsyncData<void>(null);
      }
    }
  }
}
