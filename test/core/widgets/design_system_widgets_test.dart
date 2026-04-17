import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/core/widgets/app_nav_bar.dart';
import 'package:yomu/core/widgets/empty_state.dart';
import 'package:yomu/core/widgets/error_state.dart';

void main() {
  group('Design system widgets', () {
    testWidgets('EmptyState renders and triggers optional action', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: EmptyState(
              title: 'No data',
              description: 'Try again later',
              actionLabel: 'Reload',
              onAction: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No data'), findsOneWidget);
      expect(find.text('Try again later'), findsOneWidget);
      expect(find.text('Reload'), findsOneWidget);

      await tester.tap(find.text('Reload'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('ErrorState renders and triggers retry callback', (
      WidgetTester tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ErrorState(
              title: 'Failed',
              message: 'Something went wrong',
              retryLabel: 'Retry',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Ionicons.close_circle_outline), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('AppNavBar dispatches selected destination index', (
      WidgetTester tester,
    ) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            bottomNavigationBar: AppNavBar(
              selectedIndex: 0,
              onDestinationSelected: (int index) {
                selectedIndex = index;
              },
              destinations: const <AppNavDestination>[
                AppNavDestination(
                  icon: Icon(Ionicons.home_outline),
                  selectedIcon: Icon(Ionicons.home),
                  label: 'Home',
                ),
                AppNavDestination(
                  icon: Icon(Ionicons.settings_outline),
                  selectedIcon: Icon(Ionicons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
    });
  });
}
