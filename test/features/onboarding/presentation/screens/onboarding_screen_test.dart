import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/core/widgets/error_state.dart';
import 'package:yomu/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:yomu/features/onboarding/presentation/screens/onboarding_screen.dart';

class _LoadingOnboardingController extends OnboardingController {
  _LoadingOnboardingController(this._completer);

  final Completer<bool> _completer;

  @override
  Future<bool> build() => _completer.future;
}

class _ErrorOnboardingController extends OnboardingController {
  @override
  Future<bool> build() async {
    throw Exception('Launch failed');
  }
}

class _IncompleteOnboardingController extends OnboardingController {
  @override
  Future<bool> build() async => false;
}

Widget _buildApp(OnboardingController Function() createOverride) {
  return ProviderScope(
    overrides: <Override>[
      onboardingControllerProvider.overrideWith(createOverride),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const OnboardingScreen(),
    ),
  );
}

Widget _buildDarkApp(OnboardingController Function() createOverride) {
  return ProviderScope(
    overrides: <Override>[
      onboardingControllerProvider.overrideWith(createOverride),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const OnboardingScreen(),
    ),
  );
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('shows branded loading scaffold without spinner', (
      WidgetTester tester,
    ) async {
      final Completer<bool> completer = Completer<bool>();

      await tester.pumpWidget(
        _buildApp(() => _LoadingOnboardingController(completer)),
      );
      await tester.pump();

      expect(find.text(AppStrings.appTitle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows shared error state when launch fails', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp(() => _ErrorOnboardingController()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text(AppStrings.unableToLoadApp), findsOneWidget);
      expect(find.text('Exception: Launch failed'), findsOneWidget);
    });

    testWidgets('uses ionicons for onboarding page visuals', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(() => _IncompleteOnboardingController()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Ionicons.book_outline), findsWidgets);
      expect(find.byIcon(Icons.auto_stories_rounded), findsNothing);

      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();
      expect(find.byIcon(Ionicons.extension_puzzle_outline), findsWidgets);
      expect(find.byIcon(Icons.extension_rounded), findsNothing);

      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();
      expect(find.byIcon(Ionicons.cloud_download_outline), findsWidgets);
      expect(find.byIcon(Icons.download_for_offline_rounded), findsNothing);
    });

    testWidgets('renders onboarding flow correctly in dark theme', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildDarkApp(() => _IncompleteOnboardingController()),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.onboarding), findsOneWidget);
      expect(find.text(AppStrings.onboardingTagline), findsOneWidget);
    });

    testWidgets('exposes onboarding page semantics label', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildApp(() => _IncompleteOnboardingController()),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });
}
