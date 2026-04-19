import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography mapping for the application design system.
abstract final class AppTextStyles {
  /// Builds the complete text theme for the provided [brightness].
  static TextTheme resolve(Brightness brightness) {
    final TextTheme base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;

    return base.copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 57,
        fontWeight: FontWeight.w600,
        height: 1.12,
        letterSpacing: 0,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.50,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Manga-specific typography helpers used by discovery and reading surfaces.
extension MangaTextTheme on TextTheme {
  /// Chapter and title-style headings for manga cards and hero banners.
  TextStyle? get mangaChapterTitle => headlineSmall;

  /// Source names and package labels in dense discovery layouts.
  TextStyle? get mangaSourceName => titleSmall?.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  /// Low-emphasis metadata labels for install status, language, and chips.
  TextStyle? get mangaMetadataLabel => labelSmall;
}
