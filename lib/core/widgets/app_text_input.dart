import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// App-standard text input built on Material [TextField].
///
/// Enforces design-system borders, spacing, and typography through
/// shared theme tokens.
///
/// ```dart
/// AppTextInput(
///   controller: _emailController,
///   label: 'Email',
///   hint: 'you@example.com',
///   keyboardType: TextInputType.emailAddress,
/// )
/// ```
class AppTextInput extends StatelessWidget {
  /// Creates an [AppTextInput].
  const AppTextInput({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.leadingIcon,
    this.trailingWidget,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.maxLength,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// The focus node for this input.
  final FocusNode? focusNode;

  /// Label rendered above the input field.
  final String? label;

  /// Placeholder text shown when the field is empty.
  final String? hint;

  /// Supporting helper text rendered below the field.
  final String? helper;

  /// When non-null, the field enters error state and shows this text.
  final String? errorText;

  /// Optional leading icon inside the input.
  final Widget? leadingIcon;

  /// Optional trailing widget inside the input (e.g. clear button).
  final Widget? trailingWidget;

  /// The keyboard type to use for this input.
  final TextInputType? keyboardType;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Optional list of input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Called every time the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Whether to hide the text — use for passwords.
  final bool obscureText;

  /// Whether the field is interactive.
  final bool enabled;

  /// When `true`, the field displays text but is not editable.
  final bool readOnly;

  /// Whether autocorrect is enabled.
  final bool autocorrect;

  /// Maximum number of lines. Defaults to 1 (single-line).
  final int? maxLines;

  /// Maximum character length. `null` means unlimited.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final OutlineInputBorder defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: colorScheme.outline, width: 1),
    );
    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    );
    final OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: colorScheme.error, width: 2),
    );

    final Widget input = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autocorrect: autocorrect,
      maxLines: maxLines,
      maxLength: maxLength,
      style: textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: errorText,
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall,
        prefixIcon: leadingIcon,
        suffixIcon: trailingWidget,
        border: defaultBorder,
        enabledBorder: defaultBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        fillColor: colorScheme.surface,
        filled: true,
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
      child: input,
    );
  }
}
