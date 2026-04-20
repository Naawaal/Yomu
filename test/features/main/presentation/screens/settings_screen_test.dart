import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/core/widgets/loading_shimmer.dart';
import 'package:yomu/features/main/presentation/screens/settings_screen.dart';
import 'package:yomu/features/settings/domain/entities/repository_config.dart';
import 'package:yomu/features/settings/domain/entities/settings_snapshot.dart';
import 'package:yomu/features/settings/domain/repositories/settings_repository.dart';
import 'package:yomu/features/settings/presentation/controllers/settings_controller.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({required this.loader});

  final Future<SettingsSnapshot> Function() loader;

  @override
  Future<SettingsSnapshot> getSettingsSnapshot() => loader();

  @override
  Future<List<RepositoryConfig>> addRepository(
    RepositoryConfig repository,
  ) async {
    return <RepositoryConfig>[repository];
  }

  @override
  Future<BackupSnapshot> exportBackup() async {
    return const BackupSnapshot(version: 1);
  }

  @override
  Future<List<RepositoryConfig>> getRepositories() async {
    return (await loader()).repositories;
  }

  @override
  Future<BackupSnapshot> importBackup() async {
    return const BackupSnapshot(version: 1);
  }

  @override
  Future<List<RepositoryConfig>> removeRepository(String repositoryId) async {
    return <RepositoryConfig>[];
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {}

  @override
  Future<List<RepositoryConfig>> updateRepository(
    RepositoryConfig repository,
  ) async {
    return <RepositoryConfig>[repository];
  }

  @override
  Future<RepositoryConfig> validateRepository(String repositoryId) async {
    return _repository;
  }
}

Widget _buildApp(SettingsRepository repository) {
  return ProviderScope(
    overrides: <Override>[
      settingsRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SettingsScreen(),
    ),
  );
}

Widget _buildDarkApp(SettingsRepository repository) {
  return ProviderScope(
    overrides: <Override>[
      settingsRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const SettingsScreen(),
    ),
  );
}

const RepositoryConfig _repository = RepositoryConfig(
  id: 'repo-1',
  displayName: 'Primary Repo',
  baseUrl: 'https://repo.example',
  isEnabled: true,
  healthStatus: RepositoryHealthStatus.healthy,
);

const SettingsSnapshot _snapshot = SettingsSnapshot(
  themePreference: AppThemePreference.system,
  backup: BackupSnapshot(version: 1),
  repositories: <RepositoryConfig>[_repository],
);

void main() {
  group('SettingsScreen', () {
    testWidgets('shows loading shimmer while settings are unresolved', (
      WidgetTester tester,
    ) async {
      final Completer<SettingsSnapshot> completer =
          Completer<SettingsSnapshot>();
      final SettingsRepository repository = _FakeSettingsRepository(
        loader: () => completer.future,
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pump();

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    testWidgets('shows section headers for settings groups', (
      WidgetTester tester,
    ) async {
      final SettingsRepository repository = _FakeSettingsRepository(
        loader: () async => _snapshot,
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settingsSectionTheme), findsWidgets);
      expect(find.text(AppStrings.settingsSectionBackup), findsWidgets);
      expect(find.text(AppStrings.settingsSectionRepositories), findsWidgets);
    });

    testWidgets('opens add repository dialog from repositories section', (
      WidgetTester tester,
    ) async {
      final SettingsRepository repository = _FakeSettingsRepository(
        loader: () async => _snapshot,
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.settingsRepositoryAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.settingsRepositoryAdd));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settingsAddRepositoryTitle), findsOneWidget);
      expect(find.text(AppStrings.settingsRepositoryNameLabel), findsOneWidget);
      expect(find.text(AppStrings.settingsRepositoryUrlLabel), findsOneWidget);
    });

    testWidgets('canceling add repository only closes the dialog', (
      WidgetTester tester,
    ) async {
      final SettingsRepository repository = _FakeSettingsRepository(
        loader: () async => _snapshot,
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.settingsRepositoryAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.settingsRepositoryAdd));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settingsAddRepositoryTitle), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Fresh Repo');
      await tester.enterText(
        find.byType(TextField).at(1),
        'https://fresh.example',
      );
      await tester.pump();

      await tester.tap(find.text(AppStrings.settingsCancel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settingsAddRepositoryTitle), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('opens remove repository confirmation dialog', (
      WidgetTester tester,
    ) async {
      final SettingsRepository repository = _FakeSettingsRepository(
        loader: () async => _snapshot,
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(_repository.displayName));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.settingsRepositoryRemove));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.settingsRemoveRepositoryTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.settingsRemoveRepositoryBody),
        findsOneWidget,
      );
    });

    testWidgets('renders settings screen correctly in dark theme', (
      WidgetTester tester,
    ) async {
      final SettingsRepository repository = _FakeSettingsRepository(
        loader: () async => _snapshot,
      );

      await tester.pumpWidget(_buildDarkApp(repository));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settings), findsWidgets);
      expect(find.text(AppStrings.settingsSectionTheme), findsWidgets);
    });

    testWidgets('repository action buttons expose accessibility tooltips', (
      WidgetTester tester,
    ) async {
      final SettingsRepository repository = _FakeSettingsRepository(
        loader: () async => _snapshot,
      );

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(_repository.displayName),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.byTooltip(AppStrings.settingsRepositoryValidate),
        findsOneWidget,
      );
      expect(
        find.byTooltip(AppStrings.settingsRepositoryRemove),
        findsOneWidget,
      );
    });
  });
}
