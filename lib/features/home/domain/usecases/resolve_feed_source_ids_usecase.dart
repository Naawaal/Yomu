/// Resolves the source IDs that should be used for Home feed queries.
///
/// Resolution priority:
/// 1. Explicit user selections that are still installed.
/// 2. Requested query source IDs that are still installed.
/// 3. Auto-selection based on installed sources (single source or all).
class ResolveFeedSourceIdsUseCase {
  /// Creates a source ID resolver for Home feed queries.
  const ResolveFeedSourceIdsUseCase();

  /// Returns a deterministic ordered list of source IDs for query execution.
  List<String> call({
    required List<String> installedSourceIds,
    Set<String> selectedSourceIds = const <String>{},
    List<String> requestedSourceIds = const <String>[],
  }) {
    final List<String> installed = _dedupePreservingOrder(installedSourceIds);
    if (installed.isEmpty) {
      return const <String>[];
    }

    final Set<String> installedSet = installed.toSet();

    final List<String> selected = installed
        .where(selectedSourceIds.contains)
        .toList(growable: false);
    if (selected.isNotEmpty) {
      return selected;
    }

    final List<String> requested = _dedupePreservingOrder(
      requestedSourceIds.where(installedSet.contains).toList(growable: false),
    );
    if (requested.isNotEmpty) {
      return requested;
    }

    if (installed.length == 1) {
      return <String>[installed.first];
    }

    return installed;
  }

  List<String> _dedupePreservingOrder(List<String> sourceIds) {
    final Set<String> seen = <String>{};
    final List<String> unique = <String>[];

    for (final String sourceId in sourceIds) {
      if (sourceId.isEmpty || seen.contains(sourceId)) {
        continue;
      }

      seen.add(sourceId);
      unique.add(sourceId);
    }

    return unique;
  }
}
