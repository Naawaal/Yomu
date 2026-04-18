import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/library_remote_datasource.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/entities/library_entry.dart';
import '../../domain/repositories/i_library_repository.dart';
import '../../domain/usecases/get_library_history_usecase.dart';
import '../../domain/usecases/sync_reader_progress_usecase.dart';

const int _defaultPageSize = 20;

/// Provides the library remote datasource implementation.
final libraryRemoteDataSourceProvider = Provider<LibraryRemoteDataSource>((
  Ref ref,
) {
  return MockLibraryRemoteDataSource();
});

/// Provides the library repository implementation.
final libraryRepositoryProvider = Provider<ILibraryRepository>((Ref ref) {
  return LibraryRepositoryImpl(ref.watch(libraryRemoteDataSourceProvider));
});

/// Provides use case for reading library history.
final getLibraryHistoryUseCaseProvider = Provider<GetLibraryHistoryUseCase>((
  Ref ref,
) {
  return GetLibraryHistoryUseCase(ref.watch(libraryRepositoryProvider));
});

/// Provides use case for syncing reader progress.
final syncReaderProgressUseCaseProvider = Provider<SyncReaderProgressUseCase>((
  Ref ref,
) {
  return SyncReaderProgressUseCase(ref.watch(libraryRepositoryProvider));
});

/// Async notifier for loading and syncing library history.
class LibraryNotifier extends AsyncNotifier<List<LibraryEntry>> {
  int _page = 1;
  bool _hasMore = true;

  @override
  Future<List<LibraryEntry>> build() async {
    return const <LibraryEntry>[];
  }

  /// Loads the first history page.
  Future<void> fetchHistory() async {
    _page = 1;
    _hasMore = true;
    state = const AsyncLoading<List<LibraryEntry>>();

    final GetLibraryHistoryUseCase useCase = ref.read(
      getLibraryHistoryUseCaseProvider,
    );
    final result = await useCase(page: _page, pageSize: _defaultPageSize);

    state = result.fold(
      (failure) => AsyncError<List<LibraryEntry>>(
        StateError(failure.message),
        StackTrace.current,
      ),
      (List<LibraryEntry> entries) {
        _hasMore = entries.length >= _defaultPageSize;
        _page = 2;
        return AsyncData<List<LibraryEntry>>(entries);
      },
    );
  }

  /// Loads the next history page when available.
  Future<void> loadMore() async {
    if (!_hasMore) {
      return;
    }

    final List<LibraryEntry> current =
        state.valueOrNull ?? const <LibraryEntry>[];
    final GetLibraryHistoryUseCase useCase = ref.read(
      getLibraryHistoryUseCaseProvider,
    );
    final result = await useCase(page: _page, pageSize: _defaultPageSize);

    state = result.fold(
      (failure) => AsyncError<List<LibraryEntry>>(
        StateError(failure.message),
        StackTrace.current,
      ),
      (List<LibraryEntry> nextPageEntries) {
        _hasMore = nextPageEntries.length >= _defaultPageSize;
        _page = _page + 1;
        return AsyncData<List<LibraryEntry>>(<LibraryEntry>[
          ...current,
          ...nextPageEntries,
        ]);
      },
    );
  }

  /// Syncs one entry and updates in-memory state if already loaded.
  Future<void> syncEntryProgress(LibraryEntry entry) async {
    final SyncReaderProgressUseCase useCase = ref.read(
      syncReaderProgressUseCaseProvider,
    );
    final result = await useCase(entry);

    result.fold(
      (failure) {
        state = AsyncError<List<LibraryEntry>>(
          StateError(failure.message),
          StackTrace.current,
        );
      },
      (_) {
        final List<LibraryEntry> current =
            state.valueOrNull ?? const <LibraryEntry>[];
        final int index = current.indexWhere(
          (LibraryEntry currentEntry) => currentEntry.id == entry.id,
        );

        if (index < 0) {
          state = AsyncData<List<LibraryEntry>>(<LibraryEntry>[
            entry,
            ...current,
          ]);
          return;
        }

        final List<LibraryEntry> updated = List<LibraryEntry>.from(current);
        updated[index] = entry;
        state = AsyncData<List<LibraryEntry>>(updated);
      },
    );
  }
}

/// Provides LibraryNotifier for presentation consumers.
final libraryNotifierProvider =
    AsyncNotifierProvider<LibraryNotifier, List<LibraryEntry>>(
      LibraryNotifier.new,
    );
