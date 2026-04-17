import 'package:flutter/material.dart';

import 'app_colors_extension.dart';
import 'app_theme_extension.dart';

/// Convenience accessors on [BuildContext] for design-system tokens.
///
/// For Moon primitive tokens, use the [BuildContextX] extension provided
/// by `moon_design` directly:
/// ```dart
/// context.moonTheme?.colors.piccolo
/// context.moonTheme?.borders.interactiveSm
/// context.moonTheme?.sizes.sm
/// ```
///
/// For app-level semantic aliases:
/// ```dart
/// context.appTheme.successColor
/// context.appTheme.contentSurface
/// ```
extension AppThemeContext on BuildContext {
  /// The app-level semantic color extension.
  ///
  /// Throws if [AppColorsExtension] was not registered in [ThemeData].
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;

  /// The app-level semantic token aliases.
  ///
  /// Throws if [AppThemeExtension] was not registered in [ThemeData].
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
