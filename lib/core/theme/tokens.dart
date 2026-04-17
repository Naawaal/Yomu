import 'package:flutter/widgets.dart';

/// Spacing scale used throughout the app.
abstract final class SpacingTokens {
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
  static const EdgeInsets page = EdgeInsets.all(SpacingTokens.md);

  /// Default card insets.
  static const EdgeInsets card = EdgeInsets.all(SpacingTokens.md);
}
