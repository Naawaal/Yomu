import 'package:flutter/material.dart';

/// Centralized color constants used by the app theme.
abstract final class AppColors {
  /// Global seed color used to generate Material 3 color schemes.
  static const Color seed = Color(0xFF005E7A);

  /// Semantic success color.
  static const Color success = Color(0xFF2E7D32);

  /// Foreground color on [success].
  static const Color onSuccess = Color(0xFFFFFFFF);

  /// Tonal success container color.
  static const Color successContainer = Color(0xFFC8E6C9);

  /// Foreground color on [successContainer].
  static const Color onSuccessContainer = Color(0xFF0F2E12);

  /// Semantic warning color.
  static const Color warning = Color(0xFFB26A00);

  /// Foreground color on [warning].
  static const Color onWarning = Color(0xFFFFFFFF);

  /// Tonal warning container color.
  static const Color warningContainer = Color(0xFFFFE0B2);

  /// Foreground color on [warningContainer].
  static const Color onWarningContainer = Color(0xFF3D2400);

  /// Semantic info color.
  static const Color info = Color(0xFF1565C0);

  /// Foreground color on [info].
  static const Color onInfo = Color(0xFFFFFFFF);

  /// Tonal info container color.
  static const Color infoContainer = Color(0xFFD6E9FF);

  /// Foreground color on [infoContainer].
  static const Color onInfoContainer = Color(0xFF032244);
}
