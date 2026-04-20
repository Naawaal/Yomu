import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/failure.dart';
import 'package:yomu/features/extensions/data/repositories/bridge_extension_repository.dart';
import 'package:yomu/features/extensions/data/repositories/extension_repository_result_adapter.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';
import 'package:yomu/features/extensions/presentation/controllers/extensions_controllers.dart';

class _FakeExtensionRepository implements ExtensionRepository {
  _FakeExtensionRepository({required this.loader});

  final Future<List<ExtensionItem>> Function() loader;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() => loader();

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {}

  @override
  Future<void> trust(String packageName) async {}
}

class _ActionTestExtensionRepository implements ExtensionRepository {
  _ActionTestExtensionRepository({
    required this.items,
    required this.installBehavior,
  });

  List<ExtensionItem> items;
  final Future<void> Function(String packageName, String? installArtifact)
  installBehavior;
  int getAvailableCalls = 0;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async {
    getAvailableCalls += 1;
    return items;
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) {
    return installBehavior(packageName, installArtifact);
  }

  @override
  Future<void> trust(String packageName) async {}
}

class _FakeExtensionRepositoryResultAdapter
    extends ExtensionRepositoryResultAdapter {
  _FakeExtensionRepositoryResultAdapter({
    required ExtensionRepository repository,
    required this.result,
  }) : super(repository);

  final Either<Failure, List<ExtensionItem>> result;

  @override
  Future<Either<Failure, List<ExtensionItem>>> getAvailableExtensions() async {
    return result;
  }
}

void main() {
  group('installedSourcesProvider', () {
    test('returns only installed extensions from loaded list', () async {
      const ExtensionItem installed = ExtensionItem(
        name: 'MangaDex',
        packageName: 'pkg.installed',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );
      const ExtensionItem notInstalled = ExtensionItem(
        name: 'Remote Only',
        packageName: 'pkg.remote',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          extensionRepositoryProvider.overrideWithValue(
            _FakeExtensionRepository(
              loader: () async => const <ExtensionItem>[
                installed,
                notInstalled,
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(extensionsListControllerProvider.future);
      final AsyncValue<List<ExtensionItem>> installedAsync = container.read(
        installedSourcesProvider,
      );

      expect(installedAsync.hasValue, isTrue);
      expect(installedAsync.value, <ExtensionItem>[installed]);
    });

    test('uses adapter-backed list results in the controller layer', () async {
      const ExtensionItem installed = ExtensionItem(
        name: 'MangaDex',
        packageName: 'pkg.installed',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );
      const ExtensionItem notInstalled = ExtensionItem(
        name: 'Remote Only',
        packageName: 'pkg.remote',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          extensionRepositoryResultAdapterProvider.overrideWithValue(
            _FakeExtensionRepositoryResultAdapter(
              repository: _FakeExtensionRepository(
                loader: () async => const [],
              ),
              result: const Right<Failure, List<ExtensionItem>>(<ExtensionItem>[
                installed,
                notInstalled,
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(extensionsListControllerProvider.future);
      final AsyncValue<List<ExtensionItem>> installedAsync = container.read(
        installedSourcesProvider,
      );

      expect(installedAsync.hasValue, isTrue);
      expect(installedAsync.value, <ExtensionItem>[installed]);
    });

    test('reflects loading state while source list is unresolved', () {
      final Completer<List<ExtensionItem>> completer =
          Completer<List<ExtensionItem>>();

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          extensionRepositoryResultAdapterProvider.overrideWithValue(
            _FakeExtensionRepositoryResultAdapter(
              repository: _FakeExtensionRepository(
                loader: () => completer.future,
              ),
              result: const Right<Failure, List<ExtensionItem>>(
                <ExtensionItem>[],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final AsyncValue<List<ExtensionItem>> installedAsync = container.read(
        installedSourcesProvider,
      );

      expect(installedAsync.isLoading, isTrue);
    });

    test('propagates error state when source list loading fails', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          extensionRepositoryResultAdapterProvider.overrideWithValue(
            _FakeExtensionRepositoryResultAdapter(
              repository: _FakeExtensionRepository(
                loader: () async => const [],
              ),
              result: Left<Failure, List<ExtensionItem>>(
                ServerFailure('failed to load extensions'),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(extensionsListControllerProvider.future),
        throwsA(isA<ServerFailure>()),
      );

      final AsyncValue<List<ExtensionItem>> installedAsync = container.read(
        installedSourcesProvider,
      );

      expect(installedAsync.hasError, isTrue);
    });
  });

  group('ExtensionActionController.install', () {
    const ExtensionItem uninstalled = ExtensionItem(
      name: 'MangaDex',
      packageName: 'pkg.pending',
      language: 'en',
      versionName: '1.0.0',
      isInstalled: false,
      hasUpdate: false,
      isNsfw: false,
      trustStatus: ExtensionTrustStatus.untrusted,
      installArtifact: 'https://repo.example/pkg.pending.apk',
    );

    test(
      'keeps explicit pending error when refresh still shows not installed',
      () async {
        final _ActionTestExtensionRepository repository =
            _ActionTestExtensionRepository(
              items: <ExtensionItem>[uninstalled],
              installBehavior:
                  (String packageName, String? installArtifact) async {
                    expect(packageName, isNotEmpty);
                    expect(installArtifact, isNotNull);
                    throw const ExtensionInstallException(
                      code: ExtensionInstallErrorCode.requiresUserAction,
                      message: 'Enable unknown app sources to continue.',
                    );
                  },
            );

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            extensionRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        final ExtensionActionController controller = container.read(
          extensionActionControllerProvider.notifier,
        );

        await controller.install(
          uninstalled.packageName,
          installArtifact: uninstalled.installArtifact,
        );

        final AsyncValue<void> actionState = container.read(
          extensionActionControllerProvider,
        );

        expect(actionState.hasError, isTrue);
        expect(actionState.error, isA<ExtensionInstallException>());
        expect(repository.getAvailableCalls, greaterThan(0));
      },
    );

    test(
      'clears pending error after refresh when item is now installed',
      () async {
        late final _ActionTestExtensionRepository repository;
        repository = _ActionTestExtensionRepository(
          items: <ExtensionItem>[uninstalled],
          installBehavior: (String packageName, String? installArtifact) async {
            expect(packageName, isNotEmpty);
            expect(installArtifact, isNotNull);
            repository.items = <ExtensionItem>[
              const ExtensionItem(
                name: 'MangaDex',
                packageName: 'pkg.pending',
                language: 'en',
                versionName: '1.0.0',
                isInstalled: true,
                hasUpdate: false,
                isNsfw: false,
                trustStatus: ExtensionTrustStatus.trusted,
              ),
            ];

            throw const ExtensionInstallException(
              code: ExtensionInstallErrorCode.requiresUserAction,
              message: 'Install pending confirmation.',
            );
          },
        );

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            extensionRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        final ExtensionActionController controller = container.read(
          extensionActionControllerProvider.notifier,
        );

        await controller.install(
          uninstalled.packageName,
          installArtifact: uninstalled.installArtifact,
        );

        final AsyncValue<void> actionState = container.read(
          extensionActionControllerProvider,
        );

        expect(actionState.hasError, isFalse);
        expect(actionState.hasValue, isTrue);
      },
    );
  });
}
