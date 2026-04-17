import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

/// Visual variants for [AppButton].
enum AppButtonVariant {
  /// Primary filled button — use for the main call-to-action.
  filled,

  /// Secondary outlined button — use for secondary actions.
  outlined,

  /// Ghost text-only button — use for tertiary / low-emphasis actions.
  ghost,
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

/// App-standard button built on the Moon Design System.
///
/// Wraps [MoonFilledButton], [MoonOutlinedButton], or [MoonTextButton]
/// depending on [variant]. All sizing, colour, and shape come from the
/// registered [MoonTheme] — no hardcoded values.
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

  /// Creates a ghost (text-only) [AppButton].
  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.ghost;

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

  MoonButtonSize get _moonButtonSize => switch (size) {
        AppButtonSize.sm => MoonButtonSize.xs,
        AppButtonSize.md => MoonButtonSize.sm,
        AppButtonSize.lg => MoonButtonSize.md,
      };

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(this.label);

    return switch (variant) {
      AppButtonVariant.filled => MoonFilledButton(
          onTap: onPressed,
          buttonSize: _moonButtonSize,
          isFullWidth: isFullWidth,
          showPulseEffect: false,
          leading: leadingIcon,
          trailing: trailingIcon,
          label: isLoading
              ? const MoonCircularLoader(
                circularLoaderSize: MoonCircularLoaderSize.xs,
                )
              : label,
        ),
      AppButtonVariant.outlined => MoonOutlinedButton(
          onTap: onPressed,
          buttonSize: _moonButtonSize,
          isFullWidth: isFullWidth,
          showPulseEffect: false,
          leading: leadingIcon,
          trailing: trailingIcon,
          label: isLoading
              ? const MoonCircularLoader(
                circularLoaderSize: MoonCircularLoaderSize.xs,
                )
              : label,
        ),
      AppButtonVariant.ghost => MoonTextButton(
          onTap: onPressed,
          buttonSize: _moonButtonSize,
          isFullWidth: isFullWidth,
          showPulseEffect: false,
          leading: leadingIcon,
          trailing: trailingIcon,
          label: isLoading
              ? const MoonCircularLoader(
                circularLoaderSize: MoonCircularLoaderSize.xs,
                )
              : label,
        ),
    };
  }
}
