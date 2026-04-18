import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extensions_controllers.dart';
import '../widgets/extension_tile.dart';

final _extensionsSearchQueryProvider = StateProvider.autoDispose<String>(
  (Ref ref) => '',
);

final _extensionsLanguageFilterProvider = StateProvider.autoDispose<String?>(
  (Ref ref) => null,
);

const double _extensionsSearchHeaderHeight = AppSpacing.xxxl;
const double _extensionsFilterHeaderHeight = AppSpacing.xxxl;

/// Screen that lists available extensions.
class ExtensionsStoreScreen extends ConsumerWidget {
  /// Creates extensions store screen.
  const ExtensionsStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ExtensionItem>> asyncExtensions = ref.watch(
      extensionsListControllerProvider,
    );
    final String searchQuery = ref.watch(_extensionsSearchQueryProvider);
    final String normalizedQuery = searchQuery.trim().toLowerCase();
    final String? selectedLanguage = ref.watch(
      _extensionsLanguageFilterProvider,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isExpanded =
              constraints.maxWidth >= ScreenBreakpoints.medium;
          final int crossAxisCount = isExpanded ? 2 : 1;

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar.medium(
                title: const Text(AppStrings.extensionsTitle),
                actions: <Widget>[
                  IconButton(
                    onPressed: () {
                      ref
                          .read(extensionsListControllerProvider.notifier)
                          .refresh();
                    },
                    icon: const Icon(Ionicons.refresh_outline),
                  ),
                ],
              ),
              const SliverPersistentHeader(
                pinned: true,
                delegate: _ExtensionsPinnedHeaderDelegate(
                  height: _extensionsSearchHeaderHeight,
                  child: _ExtensionsSearchHeader(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ExtensionsPinnedHeaderDelegate(
                  height: _extensionsFilterHeaderHeight,
                  child: _ExtensionsLanguageFilters(
                    languages: asyncExtensions.maybeWhen(
                      data: _extractLanguages,
                      orElse: () => const <String>[],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: InsetsTokens.page,
                sliver: asyncExtensions.when(
                  loading: () => SliverToBoxAdapter(
                    child: _LoadingGrid(crossAxisCount: crossAxisCount),
                  ),
                  error: (Object error, StackTrace stackTrace) =>
                      SliverToBoxAdapter(
                        child: ErrorState(
                          title: AppStrings.unableToLoadApp,
                          message: error.toString(),
                          retryLabel: AppStrings.retry,
                          onRetry: () {
                            ref
                                .read(extensionsListControllerProvider.notifier)
                                .refresh();
                          },
                        ),
                      ),
                  data: (List<ExtensionItem> items) {
                    final List<ExtensionItem> filteredItems = items
                        .where((ExtensionItem item) {
                          final bool matchesLanguage =
                              selectedLanguage == null ||
                              item.language == selectedLanguage;
                          final bool matchesQuery =
                              normalizedQuery.isEmpty ||
                              item.name.toLowerCase().contains(
                                normalizedQuery,
                              ) ||
                              item.packageName.toLowerCase().contains(
                                normalizedQuery,
                              ) ||
                              item.language.toLowerCase().contains(
                                normalizedQuery,
                              );

                          return matchesLanguage && matchesQuery;
                        })
                        .toList(growable: false);

                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: EmptyState(
                          title: AppStrings.noExtensionsTitle,
                          description: AppStrings.noExtensionsBody,
                          actionLabel: AppStrings.retry,
                          onAction: () {
                            ref
                                .read(extensionsListControllerProvider.notifier)
                                .refresh();
                          },
                          icon: Ionicons.search_outline,
                        ),
                      );
                    }

                    if (filteredItems.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyState(
                          title: AppStrings.noExtensionsTitle,
                          description: AppStrings.noExtensionsBody,
                          icon: Ionicons.search_outline,
                        ),
                      );
                    }

                    return _AnimatedExtensionsGrid(
                      items: filteredItems,
                      crossAxisCount: crossAxisCount,
                      isExpanded: isExpanded,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
      ),
    );
  }
}

List<String> _extractLanguages(List<ExtensionItem> items) {
  final List<String> languages =
      items
          .map((ExtensionItem item) => item.language)
          .toSet()
          .toList(growable: false)
        ..sort();
  return languages;
}

class _ExtensionsSearchHeader extends ConsumerStatefulWidget {
  const _ExtensionsSearchHeader();

  @override
  ConsumerState<_ExtensionsSearchHeader> createState() =>
      _ExtensionsSearchHeaderState();
}

class _ExtensionsSearchHeaderState
    extends ConsumerState<_ExtensionsSearchHeader> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(_extensionsSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(_extensionsSearchQueryProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AppTextInput(
      controller: _controller,
      hint: AppStrings.extensionsSearchHint,
      leadingIcon: Icon(
        Ionicons.search_outline,
        color: colorScheme.onSurfaceVariant,
      ),
      trailingWidget: query.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                _controller.clear();
                ref.read(_extensionsSearchQueryProvider.notifier).state = '';
              },
              icon: Icon(
                Ionicons.close_circle_outline,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      onChanged: (String value) {
        ref.read(_extensionsSearchQueryProvider.notifier).state = value;
      },
    );
  }
}

class _ExtensionsLanguageFilters extends ConsumerWidget {
  const _ExtensionsLanguageFilters({required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? selectedLanguage = ref.watch(
      _extensionsLanguageFilterProvider,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          FilterChip(
            label: const Text(AppStrings.extensionsAllLanguages),
            selected: selectedLanguage == null,
            onSelected: (_) {
              ref.read(_extensionsLanguageFilterProvider.notifier).state = null;
            },
          ),
          for (final String language in languages) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            FilterChip(
              label: Text(language.toUpperCase()),
              selected: selectedLanguage == language,
              onSelected: (bool isSelected) {
                ref.read(_extensionsLanguageFilterProvider.notifier).state =
                    isSelected ? language : null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtensionsPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ExtensionsPinnedHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final Color backgroundColor = Theme.of(context).colorScheme.surface;

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ExtensionsPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _AnimatedExtensionsGrid extends StatefulWidget {
  const _AnimatedExtensionsGrid({
    required this.items,
    required this.crossAxisCount,
    required this.isExpanded,
  });

  final List<ExtensionItem> items;
  final int crossAxisCount;
  final bool isExpanded;

  @override
  State<_AnimatedExtensionsGrid> createState() =>
      _AnimatedExtensionsGridState();
}

class _AnimatedExtensionsGridState extends State<_AnimatedExtensionsGrid> {
  bool _animationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _animationsEnabled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: widget.isExpanded ? 2.2 : 1.9,
      ),
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        final ExtensionItem item = widget.items[index];

        final Widget tile = ExtensionTile(
          key: ValueKey<String>(item.packageName),
          item: item,
          onPressed: () {
            ExtensionDetailsRoute.push(context, item.packageName);
          },
        );

        if (!_animationsEnabled) {
          return tile;
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 180 + (index * 25)),
          builder: (BuildContext context, double value, Widget? child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * AppSpacing.md),
                child: child,
              ),
            );
          },
          child: tile,
        );
      }, childCount: widget.items.length),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid({required this.crossAxisCount});

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final Color skeletonColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

    return LoadingShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: 6,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.0,
        ),
        itemBuilder: (BuildContext context, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          );
        },
      ),
    );
  }
}
