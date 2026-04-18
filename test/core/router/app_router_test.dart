import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yomu/core/router/app_router.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/onboarding/presentation/controllers/onboarding_controller.dart';

// ---------------------------------------------------------------------------
// Fake controller — avoids SharedPreferences in tests
// ---------------------------------------------------------------------------

/// Fake [OnboardingController] that always returns [false] (not completed).
class _FakeOnboardingController extends OnboardingController {
  @override
  Future<bool> build() async => false;
}

// ---------------------------------------------------------------------------
// Test router factory
//
// Creates a fresh GoRouter per test using the production [fadeThroughPage] and
// [sharedAxisHorizontalPage] helpers. Using a local router (rather than the
// global [appRouter]) prevents route state from leaking between tests.
// ---------------------------------------------------------------------------

GoRouter _buildTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            fadeThroughPage(state, const Text('Home')),
        routes: <RouteBase>[
          GoRoute(
            path: 'details',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                sharedAxisHorizontalPage(state, const Text('Details')),
          ),
        ],
      ),
    ],
  );
}

/// Wraps [child] in a bare [MaterialApp] so GoRouter can resolve
/// [MediaQuery] and [Overlay] without a full theme.
Widget _buildApp(GoRouter router) {
  return MaterialApp.router(theme: AppTheme.light(), routerConfig: router);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. Route path constants
  // ─────────────────────────────────────────────────────────────────────────

  group('Route path constants', () {
    test('LaunchRoute.path == "/"', () {
      expect(LaunchRoute.path, equals('/'));
    });

    test('OnboardingRoute.path == "/onboarding"', () {
      expect(OnboardingRoute.path, equals('/onboarding'));
    });

    test('FeedRoute.path == "/feed"', () {
      expect(FeedRoute.path, equals('/feed'));
    });

    test('DiscoverRoute.path == "/extensions"', () {
      expect(DiscoverRoute.path, equals('/extensions'));
    });

    test('SettingsRoute.path == "/settings"', () {
      expect(SettingsRoute.path, equals('/settings'));
    });

    test('ExtensionsStoreRoute.path == "/extensions"', () {
      expect(ExtensionsStoreRoute.path, equals('/extensions'));
    });

    test('ExtensionDetailsRoute.location builds correct path', () {
      expect(
        ExtensionDetailsRoute.location('com.example.pkg'),
        equals('/extensions/com.example.pkg'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Derived path helpers
  // ─────────────────────────────────────────────────────────────────────────

  group('Derived path helpers', () {
    test('ExtensionsStoreRoute.path matches discover route path', () {
      expect(ExtensionsStoreRoute.path, equals(DiscoverRoute.path));
    });

    test(
      'ExtensionDetailsRoute.location appends packageName to store path',
      () {
        const String pkg = 'com.repo.extension';
        expect(
          ExtensionDetailsRoute.location(pkg),
          equals('${ExtensionsStoreRoute.path}/$pkg'),
        );
      },
    );

    test('ExtensionDetailsRoute.paramPackageName key is non-empty', () {
      expect(ExtensionDetailsRoute.paramPackageName, isNotEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Transition policy — page builder output
  //
  // Uses test-local GoRouters with the production fadeThroughPage /
  // sharedAxisHorizontalPage helpers so state never leaks between tests.
  // ─────────────────────────────────────────────────────────────────────────

  group('Transition policy — page builder output', () {
    testWidgets(
      'fadeThroughPage produces CustomTransitionPage with 250 ms duration',
      (WidgetTester tester) async {
        final GoRouter router = _buildTestRouter();
        await tester.pumpWidget(_buildApp(router));
        await tester.pump();

        final Navigator nav = tester.widget<Navigator>(
          find.byType(Navigator).first,
        );
        final Page<Object?> page = nav.pages.first;

        expect(page, isA<CustomTransitionPage<void>>());
        expect(
          (page as CustomTransitionPage<void>).transitionDuration,
          const Duration(milliseconds: 250),
        );
        expect(
          page.reverseTransitionDuration,
          const Duration(milliseconds: 240),
        );
      },
    );

    testWidgets(
      'sharedAxisHorizontalPage produces CustomTransitionPage with 320 ms duration',
      (WidgetTester tester) async {
        final GoRouter router = _buildTestRouter(initialLocation: '/details');
        await tester.pumpWidget(_buildApp(router));
        await tester.pump();

        final Navigator nav = tester.widget<Navigator>(
          find.byType(Navigator).first,
        );
        final Page<Object?> page = nav.pages.last;

        expect(page, isA<CustomTransitionPage<void>>());
        expect(
          (page as CustomTransitionPage<void>).transitionDuration,
          const Duration(milliseconds: 320),
        );
        expect(
          page.reverseTransitionDuration,
          const Duration(milliseconds: 240),
        );
      },
    );

    testWidgets(
      'FadeThroughTransition widget appears in tree at initial route',
      (WidgetTester tester) async {
        final GoRouter router = _buildTestRouter();
        await tester.pumpWidget(_buildApp(router));
        // First animation frame — transitionsBuilder has been called.
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(FadeThroughTransition), findsWidgets);
      },
    );

    testWidgets(
      'forward navigation to child route produces 320 ms shared-axis page',
      (WidgetTester tester) async {
        final GoRouter router = _buildTestRouter();
        await tester.pumpWidget(_buildApp(router));
        await tester.pumpAndSettle();

        // Navigate forward — GoRouter pushes the child route on the stack.
        router.go('/details');
        await tester.pump();

        final Navigator nav = tester.widget<Navigator>(
          find.byType(Navigator).first,
        );
        final Page<Object?> topPage = nav.pages.last;

        expect(topPage, isA<CustomTransitionPage<void>>());
        expect(
          (topPage as CustomTransitionPage<void>).transitionDuration,
          const Duration(milliseconds: 320),
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Smoke test — appRouter mounts without provider crashes
  //
  // OnboardingGateScreen watches onboardingControllerProvider (SharedPrefs).
  // Override with a fake that returns false synchronously.
  // ─────────────────────────────────────────────────────────────────────────

  group('AppRouter smoke test', () {
    testWidgets('appRouter renders initial route without crashing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            onboardingControllerProvider.overrideWith(
              _FakeOnboardingController.new,
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: appRouter,
          ),
        ),
      );
      await tester.pump();

      // The route at '/' should be a CustomTransitionPage (fade-through).
      final Navigator nav = tester.widget<Navigator>(
        find.byType(Navigator).first,
      );
      final Page<Object?> page = nav.pages.first;

      expect(page, isA<CustomTransitionPage<void>>());
      expect(
        (page as CustomTransitionPage<void>).transitionDuration,
        const Duration(milliseconds: 250),
      );
    });
  });
}
