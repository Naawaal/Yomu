import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

import '../theme/tokens.dart';

/// Visual variants for [AppButton].
enum AppButtonVariant {
  /// Primary filled button — use for the main call-to-action.
  filled,

  /// Secondary outlined button — use for secondary actions.
  outlined,

  /// Destructive filled button — use for irreversible actions.
  destructive,
}

/// Size variants for [AppButton].
enum AppButtonSize {
  /// Small button (Moon `xs`).
  sm,

  /// Medium button (Moon `sm`) — default.
  md,

  /// Large button (Moon `md`).
  lg,
}

/// App-standard button built on the design system.
///
/// Wraps [MoonFilledButton], [MoonOutlinedButton], or a destructive
/// [FilledButton] variant depending on [variant].
///
/// ```dart
/// AppButton(
///   label: 'Install',
///   onPressed: handleInstall,
/// )
///
/// AppButton.outlined(
///   label: 'Cancel',
///   onPressed: Navigator.of(context).pop,
/// )
///
/// AppButton.destructive(
///   label: 'Delete',
///   onPressed: onDelete,
/// )
/// ```
class AppButton extends StatelessWidget {
  /// Creates a filled [AppButton].
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  /// Creates an outlined [AppButton].
  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.outlined;

  /// Creates a destructive [AppButton].
  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.destructive;

  /// The text label displayed inside the button.
  final String label;

  /// Called when the button is tapped. Pass `null` to disable.
  final VoidCallback? onPressed;

  /// Visual style — filled, outlined, or ghost.
  final AppButtonVariant variant;

  /// Size — sm, md (default), or lg.
  final AppButtonSize size;

  /// Optional leading icon widget.
  final Widget? leadingIcon;

  /// Optional trailing icon widget.
  final Widget? trailingIcon;

  /// When `true` the button expands to fill available horizontal space.
  final bool isFullWidth;

  /// When `true` the button shows a [MoonCircularLoader] instead of the label.
  final bool isLoading;

  static const double _destructiveMinWidth = 64;

  MoonButtonSize get _moonButtonSize => switch (size) {
    AppButtonSize.sm => MoonButtonSize.xs,
    AppButtonSize.md => MoonButtonSize.sm,
    AppButtonSize.lg => MoonButtonSize.md,
  };

  Widget get _loadingIndicator =>
      const MoonCircularLoader(circularLoaderSize: MoonCircularLoaderSize.xs);

  Widget _resolvedLabel(BuildContext context) {
    if (isLoading) {
      return _loadingIndicator;
    }
    return Text(label, style: Theme.of(context).textTheme.labelLarge);
  }

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final Widget resolvedLabel = _resolvedLabel(context);

    return switch (variant) {
      AppButtonVariant.filled => MoonFilledButton(
        onTap: effectiveOnPressed,
        buttonSize: _moonButtonSize,
        isFullWidth: isFullWidth,
        showPulseEffect: false,
        leading: leadingIcon,
        trailing: trailingIcon,
        label: resolvedLabel,
      ),
      AppButtonVariant.outlined => MoonOutlinedButton(
        onTap: effectiveOnPressed,
        buttonSize: _moonButtonSize,
        isFullWidth: isFullWidth,
        showPulseEffect: false,
        leading: leadingIcon,
        trailing: trailingIcon,
        label: resolvedLabel,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(_destructiveMinWidth, AppSpacing.xxl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: resolvedLabel,
      ),
    };
  }
}
