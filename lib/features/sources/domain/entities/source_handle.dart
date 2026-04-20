import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Identifies one executable source runtime target.
@immutable
class SourceHandle extends Equatable {
  const SourceHandle({
    required this.sourceId,
    required this.packageName,
    required this.displayName,
    required this.language,
    required this.isTrusted,
  });

  final String sourceId;
  final String packageName;
  final String displayName;
  final String language;
  final bool isTrusted;

  @override
  List<Object?> get props => <Object?>[
    sourceId,
    packageName,
    displayName,
    language,
    isTrusted,
  ];
}
