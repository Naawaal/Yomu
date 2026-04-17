import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/extensions/presentation/screens/extension_details_screen.dart';
import '../../features/extensions/presentation/screens/extensions_store_screen.dart';
import '../../features/main/presentation/screens/home_screen.dart';
import '../../features/main/presentation/screens/main_shell_screen.dart';
import '../../features/main/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Global router used by the app shell.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: LaunchRoute.path,
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingGateScreen();
      },
    ),
    GoRoute(
      path: OnboardingRoute.path,
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingScreen();
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
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: HomeRoute.path,
              builder: (BuildContext context, GoRouterState state) {
                return const HomeScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: SettingsRoute.path,
              builder: (BuildContext context, GoRouterState state) {
                return const SettingsScreen();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: ExtensionsStoreRoute.segment,
                  builder: (BuildContext context, GoRouterState state) {
                    return const ExtensionsStoreScreen();
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: ':${ExtensionDetailsRoute.paramPackageName}',
                      builder: (BuildContext context, GoRouterState state) {
                        final String packageName =
                            state.pathParameters[ExtensionDetailsRoute
                                .paramPackageName] ??
                            '';
                        return ExtensionDetailsScreen(packageName: packageName);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

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

/// Typed route helper for the Home (Feed) tab.
abstract final class HomeRoute {
  /// Route path for the home/feed tab.
  static const String path = '/home';

  /// Navigates to the home tab.
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

/// Typed route helper for the extension store (nested under Settings).
abstract final class ExtensionsStoreRoute {
  /// URL segment appended to [SettingsRoute.path].
  static const String segment = 'extensions';

  /// Full route path for the extensions store.
  static const String path = '${SettingsRoute.path}/$segment';

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
