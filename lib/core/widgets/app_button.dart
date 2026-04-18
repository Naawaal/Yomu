import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Visual variants for [AppButton].
enum AppButtonVariant {
  /// Primary filled button — use for the main call-to-action.
  filled,

  /// Secondary outlined button — use for secondary actions.
  outlined,

  /// Tonal button — use for soft secondary actions.
  tonal,

  /// Destructive filled button — use for irreversible actions.
  destructive,
}

/// Size variants for [AppButton].
enum AppButtonSize {
  /// Small button — 40 dp height.
  sm,

  /// Medium button — 48 dp height (default).
  md,

  /// Large button — 56 dp height.
  lg,
}

/// App-standard button built on Material 3 primitives.
///
/// Uses [FilledButton], [OutlinedButton], or [FilledButton.tonal] depending
/// on [variant]. All colors derive from [ColorScheme] — no hardcoded values.
///
/// ```dart
/// AppButton(label: 'Install', onPressed: handleInstall)
/// AppButton.outlined(label: 'Cancel', onPressed: Navigator.of(context).pop)
/// AppButton.tonal(label: 'Save Draft', onPressed: handleSave)
/// AppButton.destructive(label: 'Delete', onPressed: handleDelete)
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

  /// Creates a tonal [AppButton].
  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isFullWidth = false,
    this.isLoading = false,
  }) : variant = AppButtonVariant.tonal;

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

  /// Visual style — filled, outlined, tonal, or destructive.
  final AppButtonVariant variant;

  /// Size — sm, md (default), or lg.
  final AppButtonSize size;

  /// Optional leading icon widget.
  final Widget? leadingIcon;

  /// Optional trailing icon widget.
  final Widget? trailingIcon;

  /// When `true` the button expands to fill available horizontal space.
  final bool isFullWidth;

  /// When `true` the button shows a loading spinner instead of the label.
  /// The button footprint (height/width) does not change during loading.
  final bool isLoading;

  double get _height => switch (size) {
    AppButtonSize.sm => 40.0,
    AppButtonSize.md => 48.0,
    AppButtonSize.lg => 56.0,
  };

  double get _spinnerSize => switch (size) {
    AppButtonSize.sm => 16.0,
    AppButtonSize.md => 20.0,
    AppButtonSize.lg => 22.0,
  };

  /// Base [ButtonStyle] enforcing the correct height and optional full width.
  ButtonStyle _baseStyle() {
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(isFullWidth ? double.infinity : 64.0, _height),
      ),
    );
  }

  Widget _spinner(Color color) {
    return SizedBox(
      width: _spinnerSize,
      height: _spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _child(Widget spinner) {
    if (isLoading) return spinner;
    if (leadingIcon == null && trailingIcon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (leadingIcon != null) ...<Widget>[
          leadingIcon!,
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label),
        if (trailingIcon != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          trailingIcon!,
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    return switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: effectiveOnPressed,
        style: _baseStyle(),
        child: _child(_spinner(cs.onPrimary)),
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: _baseStyle(),
        child: _child(_spinner(cs.primary)),
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: effectiveOnPressed,
        style: _baseStyle(),
        child: _child(_spinner(cs.onSecondaryContainer)),
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        style: _baseStyle().copyWith(
          backgroundColor: WidgetStatePropertyAll<Color>(cs.error),
          foregroundColor: WidgetStatePropertyAll<Color>(cs.onError),
          overlayColor: WidgetStatePropertyAll<Color>(
            cs.onError.withValues(alpha: 0.12),
          ),
        ),
        child: _child(_spinner(cs.onError)),
      ),
    };
  }
}
