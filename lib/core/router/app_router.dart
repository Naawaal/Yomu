import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';

import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/extensions/presentation/screens/extension_details_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/main/presentation/screens/main_shell_screen.dart';
import '../../features/main/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Global router used by the app shell.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: LaunchRoute.path,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return fadeThroughPage(state, const OnboardingGateScreen());
      },
    ),
    GoRoute(
      path: OnboardingRoute.path,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return sharedAxisHorizontalPage(state, const OnboardingScreen());
      },
    ),
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) {
            return MainShellScreen(navigationShell: navigationShell);
          },
      branches: <StatefulShellBranch>[
        // Home tab
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: HomeRoute.path,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return fadeThroughPage(state, const HomeScreen());
              },
            ),
          ],
        ),
        // Feed tab
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: DiscoverRoute.path,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return fadeThroughPage(state, const DiscoverScreen());
              },
              routes: <RouteBase>[
                GoRoute(
                  path: ':${ExtensionDetailsRoute.paramPackageName}',
                  pageBuilder: (BuildContext context, GoRouterState state) {
                    final String packageName =
                        state.pathParameters[ExtensionDetailsRoute
                            .paramPackageName] ??
                        '';
                    return sharedAxisHorizontalPage(
                      state,
                      ExtensionDetailsScreen(packageName: packageName),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Library tab
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: SettingsRoute.path,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return fadeThroughPage(state, const SettingsScreen());
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: FeedRoute.path,
      redirect: (BuildContext context, GoRouterState state) {
        return HomeRoute.path;
      },
    ),
  ],
);

/// Builds a [CustomTransitionPage] using [FadeThroughTransition] (250 ms).
///
/// Visible for testing — prefer using [appRouter] in production code.
@visibleForTesting
CustomTransitionPage<void> fadeThroughPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
  );
}

/// Builds a [CustomTransitionPage] using a horizontal [SharedAxisTransition] (320 ms).
///
/// Visible for testing — prefer using [appRouter] in production code.
@visibleForTesting
CustomTransitionPage<void> sharedAxisHorizontalPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
  );
}

/// Typed route helper for app launch (outside the shell).
abstract final class LaunchRoute {
  /// Route path used to determine the initial destination.
  static const String path = '/';

  /// Navigates to the app launch route.
  static void go(BuildContext context) {
    context.go(path);
  }
}

/// Typed route helper for onboarding (outside the shell).
abstract final class OnboardingRoute {
  /// Route path for onboarding.
  static const String path = '/onboarding';

  /// Navigates to onboarding.
  static void go(BuildContext context) {
    context.go(path);
  }
}

/// Typed route helper for the Feed tab.
abstract final class FeedRoute {
  /// Route path for the feed tab.
  static const String path = '/feed';

  /// Navigates to the feed tab.
  static void go(BuildContext context) {
    context.go(path);
  }
}

/// Typed route helper for the Home tab.
abstract final class HomeRoute {
  /// Route path for the home tab.
  static const String path = '/home';

  /// Navigates to the home tab.
  static void go(BuildContext context) {
    context.go(path);
  }
}

/// Typed route helper for the extensions tab.
abstract final class DiscoverRoute {
  /// Route path for the extensions tab.
  static const String path = '/extensions';

  /// Navigates to the extensions tab.
  static void go(BuildContext context) {
    context.go(path);
  }
}

/// Typed route helper for the Settings tab.
abstract final class SettingsRoute {
  /// Route path for the settings tab.
  static const String path = '/settings';

  /// Navigates to the settings tab.
  static void go(BuildContext context) {
    context.go(path);
  }
}

/// Typed route helper for the extension store route.
abstract final class ExtensionsStoreRoute {
  /// URL segment for the extension route.
  static const String segment = 'extensions';

  /// Full route path for the extensions store.
  static const String path = DiscoverRoute.path;

  /// Navigates to the extensions store.
  static void go(BuildContext context) {
    context.go(path);
  }
}

/// Typed route helper for extension details (nested under extensions store).
abstract final class ExtensionDetailsRoute {
  /// Path parameter key for package name.
  static const String paramPackageName = 'packageName';

  /// Builds the full route location from a package name.
  static String location(String packageName) {
    return '${ExtensionsStoreRoute.path}/$packageName';
  }

  /// Pushes the extension details route.
  static Future<T?> push<T>(BuildContext context, String packageName) {
    return context.push<T>(location(packageName));
  }
}
