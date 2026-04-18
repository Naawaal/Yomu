import '../../domain/entities/library_entry.dart';

/// Data model for LibraryEntry, with JSON serialization.
class LibraryEntryModel extends LibraryEntry {
  const LibraryEntryModel({
    required super.id,
    required super.title,
    required super.coverImageUrl,
    required super.currentChapter,
    required super.latestChapter,
    required super.progress,
    required super.lastReadAt,
    super.status = LibraryEntryStatus.reading,
  });

  factory LibraryEntryModel.fromJson(Map<String, dynamic> json) {
    return LibraryEntryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      coverImageUrl: json['coverImageUrl'] as String,
      currentChapter: json['currentChapter'] as int,
      latestChapter: json['latestChapter'] as int,
      progress: (json['progress'] as num).toDouble(),
      lastReadAt:
          DateTime.tryParse(json['lastReadAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _statusFromJson(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'coverImageUrl': coverImageUrl,
    'currentChapter': currentChapter,
    'latestChapter': latestChapter,
    'progress': progress,
    'lastReadAt': lastReadAt.toIso8601String(),
    'status': status.name,
  };

  static LibraryEntryStatus _statusFromJson(String? status) {
    return LibraryEntryStatus.values.firstWhere(
      (LibraryEntryStatus value) => value.name == status,
      orElse: () => LibraryEntryStatus.reading,
    );
  }
}
