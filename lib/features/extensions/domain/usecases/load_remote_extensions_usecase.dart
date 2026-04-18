import '../entities/extension_item.dart';
import '../repositories/remote_extension_catalog_repository.dart';

/// Loads extension entries from configured remote repository catalogs.
class LoadRemoteExtensionsUseCase {
  /// Creates the remote extensions use case.
  const LoadRemoteExtensionsUseCase(this._repository);

  final RemoteExtensionCatalogRepository _repository;

  /// Resolves all remote extension entries.
  Future<List<ExtensionItem>> call() {
    return _repository.getRemoteExtensions();
  }
}
