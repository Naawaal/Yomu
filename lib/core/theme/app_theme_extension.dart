import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

/// App-level semantic colour aliases that Moon's own vocabulary
/// does not name directly (success, warning, etc.).
///
/// Register this alongside [MoonTheme] in [ThemeData.extensions] and
/// access it via [BuildContext.appTheme].
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  /// Creates an [AppThemeExtension].
  const AppThemeExtension({
    required this.successColor,
    required this.onSuccessColor,
    required this.successContainerColor,
    required this.warningColor,
    required this.onWarningColor,
    required this.warningContainerColor,
    required this.contentSurface,
    required this.onContentSurface,
  });

  /// Builds the light variant, backed by [MoonColors.light].
  factory AppThemeExtension.light() {
    final MoonColors c = MoonColors.light;
    return AppThemeExtension(
      successColor: c.roshi,
      onSuccessColor: c.goten,
      successContainerColor: c.roshi10,
      warningColor: c.krillin,
      onWarningColor: c.bulma,
      warningContainerColor: c.krillin10,
      contentSurface: c.gohan,
      onContentSurface: c.bulma,
    );
  }

  /// Builds the dark variant, backed by [MoonColors.dark].
  factory AppThemeExtension.dark() {
    final MoonColors c = MoonColors.dark;
    return AppThemeExtension(
      successColor: c.roshi,
      onSuccessColor: c.goten,
      successContainerColor: c.roshi10,
      warningColor: c.krillin,
      onWarningColor: c.bulma,
      warningContainerColor: c.krillin10,
      contentSurface: c.gohan,
      onContentSurface: c.bulma,
    );
  }

  /// Success action / status colour (maps to Moon `roshi`).
  final Color successColor;

  /// Text/icon colour on a success-coloured surface.
  final Color onSuccessColor;

  /// Low-emphasis success container (maps to Moon `roshi10`).
  final Color successContainerColor;

  /// Warning action / status colour (maps to Moon `krillin`).
  final Color warningColor;

  /// Text/icon colour on a warning-coloured surface.
  final Color onWarningColor;

  /// Low-emphasis warning container (maps to Moon `krillin10`).
  final Color warningContainerColor;

  /// Default card / content surface colour (maps to Moon `gohan`).
  final Color contentSurface;

  /// Primary text colour on [contentSurface] (maps to Moon `bulma`).
  final Color onContentSurface;

  @override
  AppThemeExtension copyWith({
    Color? successColor,
    Color? onSuccessColor,
    Color? successContainerColor,
    Color? warningColor,
    Color? onWarningColor,
    Color? warningContainerColor,
    Color? contentSurface,
    Color? onContentSurface,
  }) {
    return AppThemeExtension(
      successColor: successColor ?? this.successColor,
      onSuccessColor: onSuccessColor ?? this.onSuccessColor,
      successContainerColor:
          successContainerColor ?? this.successContainerColor,
      warningColor: warningColor ?? this.warningColor,
      onWarningColor: onWarningColor ?? this.onWarningColor,
      warningContainerColor:
          warningContainerColor ?? this.warningContainerColor,
      contentSurface: contentSurface ?? this.contentSurface,
      onContentSurface: onContentSurface ?? this.onContentSurface,
    );
  }

  @override
  AppThemeExtension lerp(
    covariant AppThemeExtension? other,
    double t,
  ) {
    if (other == null) return this;
    return AppThemeExtension(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      onSuccessColor: Color.lerp(onSuccessColor, other.onSuccessColor, t)!,
      successContainerColor: Color.lerp(
        successContainerColor,
        other.successContainerColor,
        t,
      )!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      onWarningColor: Color.lerp(onWarningColor, other.onWarningColor, t)!,
      warningContainerColor: Color.lerp(
        warningContainerColor,
        other.warningContainerColor,
        t,
      )!,
      contentSurface: Color.lerp(contentSurface, other.contentSurface, t)!,
      onContentSurface:
          Color.lerp(onContentSurface, other.onContentSurface, t)!,
    );
  }
}
