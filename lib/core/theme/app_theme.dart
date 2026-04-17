import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

import 'app_colors.dart';
import 'app_colors_extension.dart';
import 'app_text_styles.dart';

/// Theme factory for application-wide styling.
///
/// Registers [MoonTheme] as a [ThemeExtension] so Moon Design widgets
/// automatically pick up the customised token set. The Material 3 seed
/// color is kept in sync with Moon's primary (piccolo) color.
abstract final class AppTheme {
  /// Primary brand color — drives both [ColorScheme.fromSeed] and
  /// [MoonColors.piccolo] so Material and Moon surfaces stay aligned.
  static const Color _seedColor = AppColors.seed;

  /// Builds the light application [ThemeData] with [MoonTheme] registered.
  static ThemeData light() {
    final MoonTokens tokens = MoonTokens.light.copyWith(
      colors: MoonColors.light.copyWith(piccolo: _seedColor),
    );
    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      textTheme: AppTextStyles.resolve(Brightness.light),
      extensions: <ThemeExtension<dynamic>>[
        MoonTheme(tokens: tokens),
        AppColorsExtension.light(),
      ],
    );
  }

  /// Builds the dark application [ThemeData] with [MoonTheme] registered.
  static ThemeData dark() {
    final MoonTokens tokens = MoonTokens.dark.copyWith(
      colors: MoonColors.dark.copyWith(piccolo: _seedColor),
    );
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      textTheme: AppTextStyles.resolve(Brightness.dark),
      extensions: <ThemeExtension<dynamic>>[
        MoonTheme(tokens: tokens),
        AppColorsExtension.dark(),
      ],
    );
  }
}
