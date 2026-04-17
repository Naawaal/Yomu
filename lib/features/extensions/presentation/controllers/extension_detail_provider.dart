import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/extension_item.dart';
import 'extensions_controllers.dart';

part 'extension_detail_provider.g.dart';

/// Resolves a single extension by package name from the loaded extension list.
@riverpod
AsyncValue<ExtensionItem?> extensionDetail(Ref ref, String packageName) {
  final AsyncValue<List<ExtensionItem>> asyncItems = ref.watch(
    extensionsListControllerProvider,
  );

  return asyncItems.whenData((List<ExtensionItem> items) {
    for (final ExtensionItem item in items) {
      if (item.packageName == packageName) {
        return item;
      }
    }
    return null;
  });
}
