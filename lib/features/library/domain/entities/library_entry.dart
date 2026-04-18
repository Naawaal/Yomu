import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Reading lifecycle state for a library entry.
enum LibraryEntryStatus { reading, completed, onHold }

/// Immutable domain entity representing one item in the user's library/history.
@immutable
class LibraryEntry extends Equatable {
  /// Creates a library entry used by Home Library surfaces.
  const LibraryEntry({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.currentChapter,
    required this.latestChapter,
    required this.progress,
    required this.lastReadAt,
    this.status = LibraryEntryStatus.reading,
  }) : assert(currentChapter >= 0, 'currentChapter must be >= 0'),
       assert(latestChapter >= 0, 'latestChapter must be >= 0'),
       assert(
         progress >= 0 && progress <= 1,
         'progress must be between 0 and 1',
       );

  /// Stable identifier for manga/manhwa title.
  final String id;

  /// Display title.
  final String title;

  /// Cover image URL.
  final String coverImageUrl;

  /// Last chapter the user reached.
  final int currentChapter;

  /// Latest chapter available from active sources.
  final int latestChapter;

  /// Reading progress in range 0.0..1.0.
  final double progress;

  /// Timestamp of the most recent read interaction.
  final DateTime lastReadAt;

  /// Current reading lifecycle status.
  final LibraryEntryStatus status;

  /// Returns a copy with updated values.
  LibraryEntry copyWith({
    String? id,
    String? title,
    String? coverImageUrl,
    int? currentChapter,
    int? latestChapter,
    double? progress,
    DateTime? lastReadAt,
    LibraryEntryStatus? status,
  }) {
    return LibraryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      currentChapter: currentChapter ?? this.currentChapter,
      latestChapter: latestChapter ?? this.latestChapter,
      progress: progress ?? this.progress,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    coverImageUrl,
    currentChapter,
    latestChapter,
    progress,
    lastReadAt,
    status,
  ];
}
