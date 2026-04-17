import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../domain/entities/extension_item.dart';

/// Primary extension action button set.
class ExtensionActionButtons extends StatelessWidget {
  /// Creates action buttons for extension trust/install/update flow.
  const ExtensionActionButtons({
    super.key,
    required this.item,
    required this.isLoading,
    required this.onTrust,
    required this.onInstall,
    this.fullWidth = false,
    this.showInstallWhenUpToDate = true,
  });

  /// Source item represented by this action cluster.
  final ExtensionItem item;

  /// Whether an action is currently running.
  final bool isLoading;

  /// Callback for trusting an extension.
  final VoidCallback onTrust;

  /// Callback for install/update action.
  final VoidCallback onInstall;

  /// Expands button width to available horizontal space.
  final bool fullWidth;

  /// Shows install button for trusted extensions with no updates.
  final bool showInstallWhenUpToDate;

  @override
  Widget build(BuildContext context) {
    final bool isTrusted = item.trustStatus == ExtensionTrustStatus.trusted;
    final bool shouldShowInstall = item.hasUpdate || showInstallWhenUpToDate;

    if (!isTrusted) {
      final Widget button = FilledButton.tonal(
        onPressed: isLoading ? null : onTrust,
        child: const Text(AppStrings.trustAndEnable),
      );
      return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
    }

    if (!shouldShowInstall) {
      return const SizedBox.shrink();
    }

    final String label = item.hasUpdate ? AppStrings.update : AppStrings.install;
    final Widget button = FilledButton(
      onPressed: isLoading ? null : onInstall,
      child: Text(label),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
