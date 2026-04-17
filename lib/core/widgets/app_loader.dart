import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

/// Size variants for [AppLoader].
enum AppLoaderSize {
  /// Small spinner (Moon `xs`).
  sm,

  /// Medium spinner (Moon `sm`) — default.
  md,

  /// Large spinner (Moon `md`).
  lg,
}

/// App-standard circular loading indicator built on [MoonCircularLoader].
///
/// Uses the primary colour from the registered [MoonTheme] — no
/// hardcoded colours or sizes.
///
/// ```dart
/// // Inline usage:
/// const AppLoader()
///
/// // Full-screen centred:
/// const Center(child: AppLoader(size: AppLoaderSize.lg))
/// ```
class AppLoader extends StatelessWidget {
  /// Creates an [AppLoader].
  const AppLoader({
    super.key,
    this.size = AppLoaderSize.md,
  });

  /// Controls the diameter of the spinner.
  final AppLoaderSize size;

  MoonCircularLoaderSize get _moonSize => switch (size) {
        AppLoaderSize.sm => MoonCircularLoaderSize.xs,
        AppLoaderSize.md => MoonCircularLoaderSize.sm,
        AppLoaderSize.lg => MoonCircularLoaderSize.md,
      };

  @override
  Widget build(BuildContext context) {
    return MoonCircularLoader(circularLoaderSize: _moonSize);
  }
}
