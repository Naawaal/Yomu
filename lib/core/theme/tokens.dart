import 'package:flutter/widgets.dart';

/// Spacing scale used throughout the app.
abstract final class AppSpacing {
  /// 4 dp spacing.
  static const double xxs = 4;

  /// 8 dp spacing.
  static const double xs = 8;

  /// 12 dp spacing.
  static const double sm = 12;

  /// 16 dp spacing.
  static const double md = 16;

  /// 24 dp spacing.
  static const double lg = 24;

  /// 32 dp spacing.
  static const double xl = 32;

  /// 48 dp spacing.
  static const double xxl = 48;

  /// 64 dp spacing.
  static const double xxxl = 64;
}

/// Spacing scale used throughout the app.
abstract final class SpacingTokens {
  /// 4 dp spacing.
  static const double xxs = AppSpacing.xxs;

  /// 8 dp spacing.
  static const double xs = AppSpacing.xs;

  /// 12 dp spacing.
  static const double sm = AppSpacing.sm;

  /// 16 dp spacing.
  static const double md = AppSpacing.md;

  /// 24 dp spacing.
  static const double lg = AppSpacing.lg;

  /// 32 dp spacing.
  static const double xl = AppSpacing.xl;

  /// 48 dp spacing.
  static const double xxl = AppSpacing.xxl;

  /// 64 dp spacing.
  static const double xxxl = AppSpacing.xxxl;
}

/// Border radius tokens used throughout the app.
abstract final class AppRadius {
  /// Extra-small radius used for tags and badges.
  static const double xs = 4;

  /// Small radius used for buttons and text fields.
  static const double sm = 8;

  /// Medium radius used for standard cards.
  static const double md = 12;

  /// Large radius used for dialogs and sheets.
  static const double lg = 16;

  /// Extra-large radius used for featured cards.
  static const double xl = 24;

  /// Fully rounded radius used for pills.
  static const double full = 999;
}

/// Breakpoints used for responsive layouts.
abstract final class ScreenBreakpoints {
  /// Compact width upper bound.
  static const double compact = 600;

  /// Medium width upper bound.
  static const double medium = 840;
}

/// Common inset tokens.
abstract final class InsetsTokens {
  /// Default page insets.
  static const EdgeInsets page = EdgeInsets.all(AppSpacing.md);

  /// Default card insets.
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.md);
}
