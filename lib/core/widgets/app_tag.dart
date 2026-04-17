import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

import '../theme/context_extensions.dart';

/// Semantic colour variants for [AppTag].
enum AppTagVariant {
  /// Neutral/informational tag.
  neutral,

  /// Success / positive status tag.
  success,

  /// Warning / caution status tag.
  warning,

  /// Error / destructive status tag.
  error,
}

/// App-standard tag / badge built on [MoonTag].
///
/// Background and text colours are resolved from the registered
/// [MoonTheme] and [AppThemeExtension] — no hardcoded values.
///
/// ```dart
/// AppTag(label: 'Trusted', variant: AppTagVariant.success)
/// AppTag(label: 'Untrusted', variant: AppTagVariant.error)
/// ```
class AppTag extends StatelessWidget {
  /// Creates an [AppTag].
  const AppTag({
    super.key,
    required this.label,
    this.variant = AppTagVariant.neutral,
    this.leadingIcon,
  });

  /// The text displayed inside the tag.
  final String label;

  /// Semantic colour variant.
  final AppTagVariant variant;

  /// Optional leading icon displayed before the label.
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final MoonColors? colors = Theme.of(context).extension<MoonTheme>()?.tokens.colors;
    final appTheme = context.appTheme;

    final (Color bg, Color fg) = switch (variant) {
      AppTagVariant.neutral => (
          colors?.gohan ?? Colors.grey.shade200,
          colors?.bulma ?? Colors.black87,
        ),
      AppTagVariant.success => (
          appTheme.successContainerColor,
          appTheme.successColor,
        ),
      AppTagVariant.warning => (
          appTheme.warningContainerColor,
          appTheme.warningColor,
        ),
      AppTagVariant.error => (
          colors?.chichi10 ?? Colors.red.shade100,
          colors?.chichi ?? Colors.red,
        ),
    };

    return MoonTag(
      backgroundColor: bg,
      label: Text(
        label,
        style: TextStyle(color: fg),
      ),
      leading: leadingIcon,
    );
  }
}
