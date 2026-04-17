import '../entities/settings_snapshot.dart';
import '../repositories/settings_repository.dart';

/// Parameters for updating the app theme preference.
class UpdateThemeModeParams {
  /// Creates immutable parameters for [UpdateThemeModeUseCase].
  const UpdateThemeModeParams({required this.preference});

  /// Theme preference to persist.
  final AppThemePreference preference;
}

/// Persists the selected app theme preference.
class UpdateThemeModeUseCase {
  /// Creates a use case for theme preference updates.
  const UpdateThemeModeUseCase(this._repository);

  final SettingsRepository _repository;

  /// Executes the use case.
  Future<void> call(UpdateThemeModeParams params) {
    return _repository.setThemePreference(params.preference);
  }
}
