import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../extensions/domain/entities/extension_item.dart';
import '../../../extensions/presentation/controllers/extensions_controllers.dart';
import '../providers/home_feed_provider.dart';

/// Provider to get installed extensions for the shelf.
final _installedExtensionsProvider =
    FutureProvider.autoDispose<List<ExtensionItem>>((ref) async {
      final repo = ref.watch(extensionRepositoryProvider);
      final all = await repo.getAvailableExtensions();
      return all.where((item) => item.isInstalled).toList(growable: false);
    });

/// Widget that displays all installed sources with toggle controls.
///
/// Only shown when multiple sources are installed. Single-source scenarios
/// auto-select and don't need UI control.
class InstalledSourcesShelf extends ConsumerWidget {
  /// Creates the installed sources shelf widget.
  const InstalledSourcesShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedExtensionsAsync = ref.watch(_installedExtensionsProvider);
    final selectedSources = ref.watch(selectedSourceIdsProvider);

    return installedExtensionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) => const SizedBox.shrink(),
      data: (List<ExtensionItem> installedItems) {
        // Only show if multiple sources installed
        if (installedItems.length <= 1) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Sources', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final ExtensionItem source in installedItems)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _SourceToggleChip(
                          source: source,
                          isSelected: selectedSources.contains(
                            source.packageName,
                          ),
                          onToggle: (_) {
                            final selectedNotifier = ref.read(
                              selectedSourceIdsProvider.notifier,
                            );
                            selectedNotifier.toggleSource(source.packageName);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual source toggle chip with icon and label.
class _SourceToggleChip extends StatelessWidget {
  /// Creates a source toggle chip.
  const _SourceToggleChip({
    required this.source,
    required this.isSelected,
    required this.onToggle,
  });

  /// The source item to display.
  final ExtensionItem source;

  /// Whether this source is currently selected.
  final bool isSelected;

  /// Called when user toggles this source.
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return FilterChip(
      selected: isSelected,
      onSelected: onToggle,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (source.iconUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: SizedBox.square(
                dimension: 16,
                child: Image.network(
                  source.iconUrl!,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) => Icon(
                        Ionicons.cube_outline,
                        size: 16,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          Text(source.name, style: textTheme.labelMedium),
        ],
      ),
      backgroundColor: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainer,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: textTheme.labelMedium?.copyWith(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
