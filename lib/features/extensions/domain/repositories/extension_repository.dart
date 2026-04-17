import '../entities/extension_item.dart';

/// Repository for extension lifecycle and listing.
abstract class ExtensionRepository {
  /// Returns all available extension entries.
  Future<List<ExtensionItem>> getAvailableExtensions();

  /// Marks extension package as trusted.
  Future<void> trust(String packageName);

  /// Installs extension package.
  Future<void> install(String packageName, {String? installArtifact});
}
