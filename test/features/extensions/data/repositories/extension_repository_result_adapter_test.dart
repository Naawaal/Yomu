import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/failure.dart';
import 'package:yomu/features/extensions/data/repositories/bridge_extension_repository.dart';
import 'package:yomu/features/extensions/data/repositories/extension_repository_result_adapter.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';

class _FakeExtensionRepository implements ExtensionRepository {
  _FakeExtensionRepository({
    this.availableExtensions = const <ExtensionItem>[],
    this.trustError,
    this.installError,
  });

  final List<ExtensionItem> availableExtensions;
  final Object? trustError;
  final Object? installError;

  bool getAvailableExtensionsCalled = false;
  bool trustCalled = false;
  bool installCalled = false;
  String? lastTrustedPackage;
  String? lastInstalledPackage;
  String? lastInstallArtifact;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async {
    getAvailableExtensionsCalled = true;
    return availableExtensions;
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {
    installCalled = true;
    lastInstalledPackage = packageName;
    lastInstallArtifact = installArtifact;
    if (installError != null) {
      throw installError!;
    }
  }

  @override
  Future<void> trust(String packageName) async {
    trustCalled = true;
    lastTrustedPackage = packageName;
    if (trustError != null) {
      throw trustError!;
    }
  }
}

void main() {
  group('ExtensionRepositoryResultAdapter', () {
    test('returns Right when getAvailableExtensions succeeds', () async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository(
        availableExtensions: const <ExtensionItem>[
          ExtensionItem(
            name: 'MangaDex',
            packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
            language: 'all',
            versionName: '1.0.0',
            isInstalled: true,
            hasUpdate: false,
            isNsfw: false,
            trustStatus: ExtensionTrustStatus.trusted,
          ),
        ],
      );
      final ExtensionRepositoryResultAdapter adapter =
          ExtensionRepositoryResultAdapter(repository);

      final Either<Failure, List<ExtensionItem>> result = await adapter
          .getAvailableExtensions();

      expect(result.isRight(), isTrue);
      expect(repository.getAvailableExtensionsCalled, isTrue);
      expect(
        result.fold((_) => const <ExtensionItem>[], (items) => items),
        hasLength(1),
      );
    });

    test(
      'maps MissingPluginException from getAvailableExtensions to failure',
      () async {
        final _FakeExtensionRepository repository = _FakeExtensionRepository(
          trustError: null,
        );
        final ExtensionRepositoryResultAdapter adapter =
            ExtensionRepositoryResultAdapter(
              _MissingPluginGetAvailableRepository(repository),
            );

        final Either<Failure, List<ExtensionItem>> result = await adapter
            .getAvailableExtensions();

        expect(result.isLeft(), isTrue);
        result.fold((Failure failure) {
          expect(failure, isA<ServerFailure>());
          expect(
            failure.message,
            'Extension discovery is unavailable on this platform.',
          );
        }, (_) => fail('Expected Left failure result'));
      },
    );

    test('returns Right when trust succeeds', () async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository();
      final ExtensionRepositoryResultAdapter adapter =
          ExtensionRepositoryResultAdapter(repository);

      final Either<Failure, Unit> result = await adapter.trust(
        'eu.kanade.tachiyomi.extension.all.mangadex',
      );

      expect(result.isRight(), isTrue);
      expect(repository.trustCalled, isTrue);
      expect(
        repository.lastTrustedPackage,
        'eu.kanade.tachiyomi.extension.all.mangadex',
      );
    });

    test('maps ExtensionTrustException to failure', () async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository(
        trustError: const ExtensionTrustException(
          code: 'TRUST_DENIED',
          message: 'Signer not allowed',
        ),
      );
      final ExtensionRepositoryResultAdapter adapter =
          ExtensionRepositoryResultAdapter(repository);

      final Either<Failure, Unit> result = await adapter.trust(
        'eu.kanade.tachiyomi.extension.all.mangadex',
      );

      expect(result.isLeft(), isTrue);
      result.fold((Failure failure) {
        expect(failure, isA<ServerFailure>());
        expect(
          failure.message,
          'Extension trust failed (TRUST_DENIED): Signer not allowed',
        );
      }, (_) => fail('Expected Left failure result'));
    });

    test('returns Right when install succeeds', () async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository();
      final ExtensionRepositoryResultAdapter adapter =
          ExtensionRepositoryResultAdapter(repository);

      final Either<Failure, Unit> result = await adapter.install(
        'eu.kanade.tachiyomi.extension.all.mangadex',
        installArtifact: 'content://install/mangadex.apk',
      );

      expect(result.isRight(), isTrue);
      expect(repository.installCalled, isTrue);
      expect(
        repository.lastInstalledPackage,
        'eu.kanade.tachiyomi.extension.all.mangadex',
      );
      expect(repository.lastInstallArtifact, 'content://install/mangadex.apk');
    });

    test('maps PlatformException from install to failure', () async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository(
        installError: PlatformException(
          code: ExtensionInstallErrorCode.requiresUserAction,
          message: 'User confirmation required',
        ),
      );
      final ExtensionRepositoryResultAdapter adapter =
          ExtensionRepositoryResultAdapter(repository);

      final Either<Failure, Unit> result = await adapter.install(
        'eu.kanade.tachiyomi.extension.all.mangadex',
        installArtifact: 'content://install/mangadex.apk',
      );

      expect(result.isLeft(), isTrue);
      result.fold((Failure failure) {
        expect(failure, isA<ServerFailure>());
        expect(
          failure.message,
          'Extension install failed (REQUIRES_USER_ACTION): User confirmation required',
        );
      }, (_) => fail('Expected Left failure result'));
    });
  });
}

class _MissingPluginGetAvailableRepository implements ExtensionRepository {
  const _MissingPluginGetAvailableRepository(this.delegate);

  final ExtensionRepository delegate;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() {
    throw MissingPluginException('no plugin');
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) {
    return delegate.install(packageName, installArtifact: installArtifact);
  }

  @override
  Future<void> trust(String packageName) {
    return delegate.trust(packageName);
  }
}
