import 'package:flutter/material.dart';

/// Centralized color constants used by the app theme.
abstract final class AppColors {
  /// Global seed color used to generate Material 3 color schemes.
  static const Color seed = Color(0xFF2A6A5A);

  /// Semantic success color.
  static const Color success = Color(0xFF4CA36A);

  /// Foreground color on [success].
  static const Color onSuccess = Color(0xFFF4FFF6);

  /// Tonal success container color.
  static const Color successContainer = Color(0xFF183525);

  /// Foreground color on [successContainer].
  static const Color onSuccessContainer = Color(0xFFD5F7E2);

  /// Semantic warning color.
  static const Color warning = Color(0xFFC58B31);

  /// Foreground color on [warning].
  static const Color onWarning = Color(0xFF271500);

  /// Tonal warning container color.
  static const Color warningContainer = Color(0xFF39250C);

  /// Foreground color on [warningContainer].
  static const Color onWarningContainer = Color(0xFFFFE6B8);

  /// Semantic info color.
  static const Color info = Color(0xFF4C86C9);

  /// Foreground color on [info].
  static const Color onInfo = Color(0xFF06192C);

  /// Tonal info container color.
  static const Color infoContainer = Color(0xFF1A304D);

  /// Foreground color on [infoContainer].
  static const Color onInfoContainer = Color(0xFFD8E8FF);
}
