import 'package:flutter/material.dart';

/// Size variants for [AppLoader].
enum AppLoaderSize {
  /// Small spinner — 16 dp diameter.
  sm,

  /// Medium spinner — 24 dp diameter (default).
  md,

  /// Large spinner — 36 dp diameter.
  lg,
}

/// App-standard inline loading indicator.
///
/// Uses [colorScheme.primary] — no hardcoded colors or sizes.
/// For full-screen loading, use [LoadingShimmer] instead.
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
  const AppLoader({super.key, this.size = AppLoaderSize.md});

  /// Controls the diameter of the spinner.
  final AppLoaderSize size;

  double get _dimension => switch (size) {
    AppLoaderSize.sm => 16.0,
    AppLoaderSize.md => 24.0,
    AppLoaderSize.lg => 36.0,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
