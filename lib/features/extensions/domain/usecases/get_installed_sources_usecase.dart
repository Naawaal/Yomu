import '../entities/extension_item.dart';
import '../repositories/extension_repository.dart';

/// Resolves the installed extension sources from the extension repository.
class GetInstalledSourcesUseCase {
  /// Creates the installed sources use case.
  const GetInstalledSourcesUseCase(this._repository);

  final ExtensionRepository _repository;

  /// Returns only installed extension entries, preserving repository order.
  Future<List<ExtensionItem>> call() async {
    final List<ExtensionItem> items = await _repository
        .getAvailableExtensions();
    return items
        .where((ExtensionItem item) => item.isInstalled)
        .toList(growable: false);
  }
}
