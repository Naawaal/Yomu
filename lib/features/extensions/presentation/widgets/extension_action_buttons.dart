import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/widgets.dart';
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
    final bool hasInstallArtifact = item.installArtifact?.isNotEmpty ?? false;
    final bool isInstalled = item.isInstalled;
    final bool shouldShowInstall =
        item.hasUpdate || (showInstallWhenUpToDate && hasInstallArtifact);

    // Show installed badge when extension is already installed and has no updates.
    // Installed state should win over trust state on the detail page.
    if (isInstalled && !item.hasUpdate) {
      final Widget badge = Chip(
        label: Text(isLoading ? AppStrings.installing : AppStrings.installed),
        avatar: isLoading
            ? const AppLoader(size: AppLoaderSize.sm)
            : const Icon(Ionicons.checkmark_done_outline, size: 16),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
      return fullWidth ? SizedBox(width: double.infinity, child: badge) : badge;
    }

    if (!isTrusted) {
      final Widget button = hasInstallArtifact
          ? AppButton(
              onPressed: isLoading ? null : onInstall,
              label: AppStrings.install,
              isLoading: isLoading,
            )
          : AppButton.outlined(
              onPressed: isLoading ? null : onTrust,
              label: AppStrings.trustAndEnable,
              isLoading: isLoading,
            );
      return fullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button;
    }

    if (!shouldShowInstall) {
      return const SizedBox.shrink();
    }

    final String label = item.hasUpdate
        ? AppStrings.update
        : AppStrings.install;
    final Widget button = AppButton(
      onPressed: isLoading || !hasInstallArtifact ? null : onInstall,
      label: label,
      isLoading: isLoading,
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
