import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/extensions/data/repositories/mock_extension_repository.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';

void main() {
  group('MockExtensionRepository (Singleton)', () {
    // Reset state before each test for isolation
    setUp(MockExtensionRepository.resetForTesting);

    // Verify singleton instance returns same object
    test('returns same instance on multiple accesses', () {
      final instance1 = MockExtensionRepository.instance;
      final instance2 = MockExtensionRepository.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    // Verify trust state persists across multiple accesses
    test('persists trust state across instance accesses', () async {
      final repo = MockExtensionRepository.instance;
      const targetPackage = 'eu.kanade.tachiyomi.extension.en.mangadex';

      // Verify initial state is trusted
      final initialList = await repo.getAvailableExtensions();
      final initialMangaDex = initialList.firstWhere(
        (e) => e.packageName == targetPackage,
      );
      expect(initialMangaDex.trustStatus, ExtensionTrustStatus.trusted);

      // Get fresh reference to singleton and access untrusted extension
      const untrustedPackage = 'eu.kanade.tachiyomi.extension.all.nekoscans';
      final untrustedItem = initialList.firstWhere(
        (e) => e.packageName == untrustedPackage,
      );
      expect(untrustedItem.trustStatus, ExtensionTrustStatus.untrusted);

      // Trust the untrusted extension
      await repo.trust(untrustedPackage);

      // Get fresh reference and verify trust persists
      final freshRepo = MockExtensionRepository.instance;
      final refreshedList = await freshRepo.getAvailableExtensions();
      final trustedItem = refreshedList.firstWhere(
        (e) => e.packageName == untrustedPackage,
      );

      // Trust status should now be trusted
      expect(trustedItem.trustStatus, ExtensionTrustStatus.trusted);
    });

    // Verify that multiple trust calls work correctly
    test('handles multiple trust() calls on different packages', () async {
      final repo = MockExtensionRepository.instance;
      const pkg1 = 'eu.kanade.tachiyomi.extension.en.mangadex';
      const pkg2 = 'eu.kanade.tachiyomi.extension.all.nekoscans';

      // Initial states
      var list = await repo.getAvailableExtensions();
      var pkg1Item = list.firstWhere((e) => e.packageName == pkg1);
      var pkg2Item = list.firstWhere((e) => e.packageName == pkg2);

      expect(pkg1Item.trustStatus, ExtensionTrustStatus.trusted);
      expect(pkg2Item.trustStatus, ExtensionTrustStatus.untrusted);

      // Trust the second package
      await repo.trust(pkg2);

      // Verify both are trusted
      final freshRepo = MockExtensionRepository.instance;
      list = await freshRepo.getAvailableExtensions();
      pkg1Item = list.firstWhere((e) => e.packageName == pkg1);
      pkg2Item = list.firstWhere((e) => e.packageName == pkg2);

      expect(pkg1Item.trustStatus, ExtensionTrustStatus.trusted);
      expect(pkg2Item.trustStatus, ExtensionTrustStatus.trusted);
    });

    // Verify that trusting a non-existent package is safe
    test('handles trust() on non-existent package gracefully', () async {
      final repo = MockExtensionRepository.instance;
      const nonExistentPackage = 'com.unknown.extension';

      // Should not throw
      await expectLater(repo.trust(nonExistentPackage), completes);

      // Existing items should remain unchanged
      final list = await repo.getAvailableExtensions();
      expect(list.length, 2);
    });
  });
}
