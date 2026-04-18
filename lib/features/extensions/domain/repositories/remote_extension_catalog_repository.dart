import '../entities/extension_item.dart';

/// Domain contract for reading remote extension catalog entries.
abstract class RemoteExtensionCatalogRepository {
  /// Returns extension entries resolved from configured remote repositories.
  Future<List<ExtensionItem>> getRemoteExtensions();
}
