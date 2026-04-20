import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/settings/domain/entities/repository_config.dart';
import 'package:yomu/features/settings/presentation/widgets/repository_settings_section_widget.dart';

Widget _buildWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  testWidgets('renders repositories, add action, and management callbacks', (
    WidgetTester tester,
  ) async {
    String? validatedRepositoryId;
    String? removedRepositoryId;
    bool addTapped = false;

    await tester.pumpWidget(
      _buildWidget(
        RepositorySettingsSectionWidget(
          repositories: const <RepositoryConfig>[
            RepositoryConfig(
              id: 'repo-1',
              displayName: 'Primary Repo',
              baseUrl: 'https://repo.example',
              isEnabled: true,
              healthStatus: RepositoryHealthStatus.healthy,
            ),
            RepositoryConfig(
              id: 'repo-2',
              displayName: 'Mirror Repo',
              baseUrl: 'https://mirror.example',
              isEnabled: true,
              healthStatus: RepositoryHealthStatus.unknown,
            ),
          ],
          onAddRepository: () {
            addTapped = true;
          },
          onValidateRepository: (String repositoryId) {
            validatedRepositoryId = repositoryId;
          },
          onRemoveRepository: (String repositoryId) {
            removedRepositoryId = repositoryId;
          },
        ),
      ),
    );

    expect(find.text('Primary Repo'), findsOneWidget);
    expect(find.text('Mirror Repo'), findsOneWidget);
    expect(find.text(AppStrings.settingsRepositoryHealthyLabel), findsOneWidget);
    expect(find.text(AppStrings.settingsRepositoryUnknownLabel), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.settingsRepositoryValidate).first);
    await tester.pump();
    await tester.tap(find.byTooltip(AppStrings.settingsRepositoryRemove).first);
    await tester.pump();
    await tester.tap(find.text(AppStrings.settingsRepositoryAdd));
    await tester.pump();

    expect(validatedRepositoryId, 'repo-1');
    expect(removedRepositoryId, 'repo-1');
    expect(addTapped, isTrue);
  });

  testWidgets('shows empty state when no repositories exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildWidget(
        RepositorySettingsSectionWidget(
          repositories: const <RepositoryConfig>[],
          onAddRepository: () {},
          onValidateRepository: (_) {},
          onRemoveRepository: (_) {},
        ),
      ),
    );

    expect(find.text(AppStrings.settingsRepositoriesEmpty), findsOneWidget);
    expect(find.text(AppStrings.settingsRepositoryAdd), findsOneWidget);
  });
}
