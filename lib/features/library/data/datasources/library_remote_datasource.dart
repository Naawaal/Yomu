import '../models/library_entry_model.dart';
import '../../domain/entities/library_entry.dart';

/// Abstracts remote data operations for library/history.
abstract class LibraryRemoteDataSource {
  /// Loads paged library entries.
  Future<List<LibraryEntryModel>> getLibraryHistory({
    int page = 1,
    int pageSize = 20,
  });

  /// Synchronizes a single library entry update.
  Future<void> syncReaderProgress(LibraryEntryModel entry);
}

/// In-memory mock implementation for library datasource.
class MockLibraryRemoteDataSource implements LibraryRemoteDataSource {
  MockLibraryRemoteDataSource()
    : _entries = <LibraryEntryModel>[
        LibraryEntryModel(
          id: 'lib-001',
          title: 'One Piece',
          coverImageUrl: '',
          currentChapter: 1129,
          latestChapter: 1150,
          progress: 0.74,
          lastReadAt: DateTime.now().subtract(const Duration(hours: 3)),
          status: LibraryEntryStatus.reading,
        ),
        LibraryEntryModel(
          id: 'lib-002',
          title: 'Kaiju No. 8',
          coverImageUrl: '',
          currentChapter: 121,
          latestChapter: 122,
          progress: 0.97,
          lastReadAt: DateTime.now().subtract(const Duration(hours: 9)),
          status: LibraryEntryStatus.reading,
        ),
        LibraryEntryModel(
          id: 'lib-003',
          title: 'Dungeon Meshi',
          coverImageUrl: '',
          currentChapter: 97,
          latestChapter: 97,
          progress: 1,
          lastReadAt: DateTime.now().subtract(const Duration(days: 2)),
          status: LibraryEntryStatus.completed,
        ),
      ];

  final List<LibraryEntryModel> _entries;

  @override
  Future<List<LibraryEntryModel>> getLibraryHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final int safePage = page < 1 ? 1 : page;
    final int safePageSize = pageSize < 1 ? 20 : pageSize;
    final int start = (safePage - 1) * safePageSize;

    if (start >= _entries.length) {
      return const <LibraryEntryModel>[];
    }

    final int end = (start + safePageSize).clamp(0, _entries.length);
    return _entries.sublist(start, end);
  }

  @override
  Future<void> syncReaderProgress(LibraryEntryModel entry) async {
    final int index = _entries.indexWhere(
      (LibraryEntryModel current) => current.id == entry.id,
    );

    if (index >= 0) {
      _entries[index] = entry;
      return;
    }

    _entries.insert(0, entry);
  }
}
