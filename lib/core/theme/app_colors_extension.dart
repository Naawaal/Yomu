import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-level semantic color aliases not represented by [ColorScheme].
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  /// Creates an [AppColorsExtension].
  const AppColorsExtension({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// Builds the light semantic extension.
  factory AppColorsExtension.light() {
    return const AppColorsExtension(
      success: AppColors.success,
      onSuccess: AppColors.onSuccess,
      successContainer: AppColors.successContainer,
      onSuccessContainer: AppColors.onSuccessContainer,
      warning: AppColors.warning,
      onWarning: AppColors.onWarning,
      warningContainer: AppColors.warningContainer,
      onWarningContainer: AppColors.onWarningContainer,
      info: AppColors.info,
      onInfo: AppColors.onInfo,
      infoContainer: AppColors.infoContainer,
      onInfoContainer: AppColors.onInfoContainer,
    );
  }

  /// Builds the dark semantic extension.
  factory AppColorsExtension.dark() {
    return const AppColorsExtension(
      success: AppColors.success,
      onSuccess: AppColors.onSuccess,
      successContainer: AppColors.successContainer,
      onSuccessContainer: AppColors.onSuccessContainer,
      warning: AppColors.warning,
      onWarning: AppColors.onWarning,
      warningContainer: AppColors.warningContainer,
      onWarningContainer: AppColors.onWarningContainer,
      info: AppColors.info,
      onInfo: AppColors.onInfo,
      infoContainer: AppColors.infoContainer,
      onInfoContainer: AppColors.onInfoContainer,
    );
  }

  /// Semantic success color.
  final Color success;

  /// Foreground color on [success].
  final Color onSuccess;

  /// Tonal success container.
  final Color successContainer;

  /// Foreground color on [successContainer].
  final Color onSuccessContainer;

  /// Semantic warning color.
  final Color warning;

  /// Foreground color on [warning].
  final Color onWarning;

  /// Tonal warning container.
  final Color warningContainer;

  /// Foreground color on [warningContainer].
  final Color onWarningContainer;

  /// Semantic info color.
  final Color info;

  /// Foreground color on [info].
  final Color onInfo;

  /// Tonal info container.
  final Color infoContainer;

  /// Foreground color on [infoContainer].
  final Color onInfoContainer;

  /// Backward-compatible alias for [success].
  Color get successColor => success;

  /// Backward-compatible alias for [onSuccess].
  Color get onSuccessColor => onSuccess;

  /// Backward-compatible alias for [successContainer].
  Color get successContainerColor => successContainer;

  /// Backward-compatible alias for [warning].
  Color get warningColor => warning;

  /// Backward-compatible alias for [onWarning].
  Color get onWarningColor => onWarning;

  /// Backward-compatible alias for [warningContainer].
  Color get warningContainerColor => warningContainer;

  @override
  AppColorsExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  AppColorsExtension lerp(covariant AppColorsExtension? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}
