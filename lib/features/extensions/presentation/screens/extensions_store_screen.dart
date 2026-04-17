import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extensions_controllers.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/extension_tile.dart';

/// Screen that lists available extensions.
class ExtensionsStoreScreen extends ConsumerWidget {
  /// Creates extensions store screen.
  const ExtensionsStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ExtensionItem>> asyncExtensions = ref.watch(
      extensionsListControllerProvider,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isExpanded =
              constraints.maxWidth >= ScreenBreakpoints.medium;
          final int crossAxisCount = isExpanded ? 2 : 1;

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar.large(
                title: const Text(AppStrings.extensionsTitle),
                actions: <Widget>[
                  IconButton(
                    onPressed: () {
                      ref
                          .read(extensionsListControllerProvider.notifier)
                          .refresh();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              SliverPadding(
                padding: InsetsTokens.page,
                sliver: asyncExtensions.when(
                  loading: () => SliverToBoxAdapter(
                    child: _LoadingGrid(crossAxisCount: crossAxisCount),
                  ),
                  error: (Object error, StackTrace stackTrace) =>
                      SliverToBoxAdapter(
                        child: _ErrorCard(
                          message: error.toString(),
                          onRetry: () {
                            ref
                                .read(extensionsListControllerProvider.notifier)
                                .refresh();
                          },
                        ),
                      ),
                  data: (List<ExtensionItem> items) {
                    if (items.isEmpty) {
                      return const SliverToBoxAdapter(child: EmptyStateCard());
                    }

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: SpacingTokens.md,
                        mainAxisSpacing: SpacingTokens.md,
                        childAspectRatio: isExpanded ? 2.2 : 1.9,
                      ),
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        final ExtensionItem item = items[index];

                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 180 + (index * 25)),
                          builder:
                              (
                                BuildContext context,
                                double value,
                                Widget? child,
                              ) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      (1 - value) * SpacingTokens.md,
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                          child: ExtensionTile(
                            item: item,
                            onPressed: () {
                              ExtensionDetailsRoute.push(
                                context,
                                item.packageName,
                              );
                            },
                          ),
                        );
                      }, childCount: items.length),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid({required this.crossAxisCount});

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: SpacingTokens.md,
        mainAxisSpacing: SpacingTokens.md,
        childAspectRatio: 2.0,
      ),
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(SpacingTokens.xs),
          ),
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: InsetsTokens.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: SpacingTokens.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
