import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme_extension.dart';
import '../../../../../core/theme/tokens.dart';
import '../controllers/onboarding_controller.dart';

const String _extensionsRoutePath = '/home';
const String _onboardingRoutePath = '/onboarding';

/// Premium onboarding flow for first launch and future logout resets.
class OnboardingScreen extends ConsumerWidget {
  /// Creates the onboarding screen.
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> onboardingState = ref.watch(
      onboardingControllerProvider,
    );

    ref.listen<AsyncValue<bool>>(onboardingControllerProvider, (
      _,
      AsyncValue<bool> next,
    ) {
      next.whenOrNull(
        data: (bool completed) {
          if (completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go(_extensionsRoutePath);
              }
            });
          }
        },
      );
    });

    return onboardingState.when(
      loading: () => const _LaunchLoadingScaffold(),
      error: (Object error, StackTrace _) => _LaunchErrorScaffold(
        message: error.toString(),
        onRetry: () => ref.invalidate(onboardingControllerProvider),
      ),
      data: (bool completed) {
        if (completed) {
          return const _LaunchLoadingScaffold();
        }

        return const Scaffold(body: SafeArea(child: _OnboardingPager()));
      },
    );
  }
}

/// Root launch gate that decides between onboarding and the extension manager.
class OnboardingGateScreen extends ConsumerWidget {
  /// Creates the onboarding gate screen.
  const OnboardingGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> onboardingState = ref.watch(
      onboardingControllerProvider,
    );

    return onboardingState.when(
      loading: () => const _LaunchLoadingScaffold(),
      error: (Object error, StackTrace _) => _LaunchErrorScaffold(
        message: error.toString(),
        onRetry: () => ref.invalidate(onboardingControllerProvider),
      ),
      data: (bool completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          context.go(completed ? _extensionsRoutePath : _onboardingRoutePath);
        });
        return const _LaunchLoadingScaffold();
      },
    );
  }
}

class _OnboardingPager extends StatefulWidget {
  const _OnboardingPager();

  @override
  State<_OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<_OnboardingPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      eyebrow: AppStrings.discover,
      title: AppStrings.onboardingDiscoverTitle,
      body: AppStrings.onboardingDiscoverBody,
      icon: Icons.auto_stories_rounded,
      heroTone: _OnboardingHeroTone.tertiary,
    ),
    _OnboardingPageData(
      eyebrow: AppStrings.extend,
      title: AppStrings.onboardingExtendTitle,
      body: AppStrings.onboardingExtendBody,
      icon: Icons.extension_rounded,
      heroTone: _OnboardingHeroTone.primary,
    ),
    _OnboardingPageData(
      eyebrow: AppStrings.readOffline,
      title: AppStrings.onboardingOfflineTitle,
      body: AppStrings.onboardingOfflineBody,
      icon: Icons.download_for_offline_rounded,
      heroTone: _OnboardingHeroTone.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: _OnboardingLayoutTokens.pageAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isMedium = constraints.maxWidth >= ScreenBreakpoints.compact;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMedium
                  ? _OnboardingLayoutTokens.maxContentWidth
                  : double.infinity,
            ),
            child: Padding(
              padding: InsetsTokens.page,
              child: Column(
                children: <Widget>[
                  _OnboardingTopBar(
                    currentPage: _currentPage,
                    pageCount: _pages.length,
                    onSkip: () => _goToPage(_pages.length - 1),
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (int index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return _OnboardingPage(
                          data: _pages[index],
                          pageIndex: index,
                          isMedium: isMedium,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  _OnboardingIndicatorRow(
                    currentPage: _currentPage,
                    pageCount: _pages.length,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  _OnboardingActionRow(
                    currentPage: _currentPage,
                    pageCount: _pages.length,
                    onBack: _currentPage == 0
                        ? null
                        : () => _goToPage(_currentPage - 1),
                    onNext: () => _goToPage(_currentPage + 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({
    required this.currentPage,
    required this.pageCount,
    required this.onSkip,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          AppStrings.onboarding,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        if (currentPage < pageCount - 1)
          TextButton(onPressed: onSkip, child: const Text(AppStrings.skip)),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.pageIndex,
    required this.isMedium,
  });

  final _OnboardingPageData data;
  final int pageIndex;
  final bool isMedium;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: isMedium ? 6 : 5,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: _OnboardingLayoutTokens.heroAnimationDuration,
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * SpacingTokens.lg),
                  child: child,
                ),
              );
            },
            child: _OnboardingHeroCard(data: data),
          ),
        ),
        const SizedBox(height: SpacingTokens.xl),
        _OnboardingCopyBlock(data: data, pageIndex: pageIndex),
      ],
    );
  }
}

class _OnboardingHeroCard extends StatelessWidget {
  const _OnboardingHeroCard({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeExtension appTheme = Theme.of(
      context,
    ).extension<AppThemeExtension>()!;
    final _OnboardingHeroPalette palette = _OnboardingHeroPalette.fromTone(
      context,
      data.heroTone,
      colorScheme,
      appTheme,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_OnboardingLayoutTokens.heroRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.background, palette.accent],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: _OnboardingLayoutTokens.orbOffset,
            right: _OnboardingLayoutTokens.orbOffset,
            child: _BlurOrb(color: palette.highlight),
          ),
          Positioned(
            bottom: _OnboardingLayoutTokens.secondaryOrbBottom,
            left: _OnboardingLayoutTokens.orbOffset,
            child: _BlurOrb(color: palette.background.withValues(alpha: 0.72)),
          ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: _OnboardingLayoutTokens.heroBadgeSize,
                  height: _OnboardingLayoutTokens.heroBadgeSize,
                  decoration: BoxDecoration(
                    color: palette.badge,
                    borderRadius: BorderRadius.circular(
                      _OnboardingLayoutTokens.heroBadgeRadius,
                    ),
                  ),
                  child: Icon(
                    data.icon,
                    color: palette.onBadge,
                    size: _OnboardingLayoutTokens.heroIconSize,
                  ),
                ),
                const Spacer(),
                _HeroStoryStrip(
                  icon: data.icon,
                  primaryColor: palette.badge,
                  onPrimaryColor: palette.onBadge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStoryStrip extends StatelessWidget {
  const _HeroStoryStrip({
    required this.icon,
    required this.primaryColor,
    required this.onPrimaryColor,
  });

  final IconData icon;
  final Color primaryColor;
  final Color onPrimaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _HeroStoryCard(
            icon: icon,
            rotation: -0.04,
            backgroundColor: primaryColor.withValues(alpha: 0.18),
            foregroundColor: onPrimaryColor,
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: _HeroStoryCard(
            icon: Icons.menu_book_rounded,
            rotation: 0.02,
            backgroundColor: primaryColor.withValues(alpha: 0.28),
            foregroundColor: onPrimaryColor,
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: _HeroStoryCard(
            icon: Icons.favorite_border_rounded,
            rotation: 0.06,
            backgroundColor: primaryColor.withValues(alpha: 0.14),
            foregroundColor: onPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _HeroStoryCard extends StatelessWidget {
  const _HeroStoryCard({
    required this.icon,
    required this.rotation,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final double rotation;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: AspectRatio(
        aspectRatio: _OnboardingLayoutTokens.storyCardAspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(
              _OnboardingLayoutTokens.storyCardRadius,
            ),
            border: Border.all(color: foregroundColor.withValues(alpha: 0.18)),
          ),
          child: Center(
            child: Icon(
              icon,
              size: _OnboardingLayoutTokens.storyIconSize,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _OnboardingLayoutTokens.orbBlurSigma,
          sigmaY: _OnboardingLayoutTokens.orbBlurSigma,
        ),
        child: Container(
          width: _OnboardingLayoutTokens.orbSize,
          height: _OnboardingLayoutTokens.orbSize,
          color: color,
        ),
      ),
    );
  }
}

class _OnboardingCopyBlock extends StatelessWidget {
  const _OnboardingCopyBlock({required this.data, required this.pageIndex});

  final _OnboardingPageData data;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          label: '${AppStrings.onboardingPage} ${pageIndex + 1}',
          child: Text(
            data.eyebrow,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(data.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          AppStrings.onboardingTagline,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(data.body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _OnboardingIndicatorRow extends StatelessWidget {
  const _OnboardingIndicatorRow({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(pageCount, (int index) {
        final bool isActive = index == currentPage;
        return Semantics(
          label: '${AppStrings.onboardingPage} ${index + 1} of $pageCount',
          child: AnimatedContainer(
            duration: _OnboardingLayoutTokens.indicatorAnimationDuration,
            curve: Curves.easeOutCubic,
            width: isActive
                ? _OnboardingLayoutTokens.activeIndicatorWidth
                : _OnboardingLayoutTokens.inactiveIndicatorWidth,
            height: _OnboardingLayoutTokens.indicatorHeight,
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxs),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(
                _OnboardingLayoutTokens.indicatorHeight,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingActionRow extends ConsumerWidget {
  const _OnboardingActionRow({
    required this.currentPage,
    required this.pageCount,
    required this.onBack,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLastPage = currentPage == pageCount - 1;

    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: onBack == null
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: onBack,
                    child: const Text(AppStrings.back),
                  ),
          ),
        ),
        Expanded(
          child: FilledButton(
            onPressed: () async {
              if (isLastPage) {
                await ref
                    .read(onboardingControllerProvider.notifier)
                    .complete();
                return;
              }
              onNext();
            },
            child: AnimatedSwitcher(
              duration: _OnboardingLayoutTokens.indicatorAnimationDuration,
              child: Text(
                isLastPage ? AppStrings.getStarted : AppStrings.next,
                key: ValueKey<bool>(isLastPage),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LaunchLoadingScaffold extends StatelessWidget {
  const _LaunchLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: InsetsTokens.page,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator.adaptive(),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  AppStrings.preparingLibrary,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchErrorScaffold extends StatelessWidget {
  const _LaunchErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: InsetsTokens.page,
            child: Card(
              child: Padding(
                padding: InsetsTokens.card,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.unableToLoadApp,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.heroTone,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final _OnboardingHeroTone heroTone;
}

enum _OnboardingHeroTone { tertiary, primary, success }

class _OnboardingHeroPalette {
  const _OnboardingHeroPalette({
    required this.background,
    required this.accent,
    required this.highlight,
    required this.badge,
    required this.onBadge,
  });

  factory _OnboardingHeroPalette.fromTone(
    BuildContext context,
    _OnboardingHeroTone tone,
    ColorScheme colorScheme,
    AppThemeExtension appTheme,
  ) {
    switch (tone) {
      case _OnboardingHeroTone.tertiary:
        return _OnboardingHeroPalette(
          background: colorScheme.surfaceContainerHighest,
          accent: colorScheme.tertiaryContainer,
          highlight: colorScheme.tertiary.withValues(alpha: 0.22),
          badge: colorScheme.tertiary,
          onBadge: colorScheme.onTertiary,
        );
      case _OnboardingHeroTone.primary:
        return _OnboardingHeroPalette(
          background: colorScheme.surfaceContainerHigh,
          accent: colorScheme.primaryContainer,
          highlight: colorScheme.primary.withValues(alpha: 0.22),
          badge: colorScheme.primary,
          onBadge: colorScheme.onPrimary,
        );
      case _OnboardingHeroTone.success:
        return _OnboardingHeroPalette(
          background: colorScheme.surfaceContainer,
          accent: appTheme.successContainerColor,
          highlight: appTheme.successColor.withValues(alpha: 0.22),
          badge: appTheme.successColor,
          onBadge: appTheme.onSuccessColor,
        );
    }
  }

  final Color background;
  final Color accent;
  final Color highlight;
  final Color badge;
  final Color onBadge;
}

abstract final class _OnboardingLayoutTokens {
  static const double maxContentWidth = 620;
  static const double heroRadius = 36;
  static const double heroBadgeSize = 72;
  static const double heroBadgeRadius = 24;
  static const double heroIconSize = 36;
  static const double orbSize = 120;
  static const double orbBlurSigma = 20;
  static const double orbOffset = 24;
  static const double secondaryOrbBottom = 56;
  static const double storyCardRadius = 28;
  static const double storyCardAspectRatio = 0.74;
  static const double storyIconSize = 34;
  static const double indicatorHeight = 8;
  static const double activeIndicatorWidth = 36;
  static const double inactiveIndicatorWidth = 12;
  static const Duration pageAnimationDuration = Duration(milliseconds: 420);
  static const Duration heroAnimationDuration = Duration(milliseconds: 520);
  static const Duration indicatorAnimationDuration = Duration(
    milliseconds: 220,
  );
}
