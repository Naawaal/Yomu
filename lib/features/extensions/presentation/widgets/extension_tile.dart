import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extensions_controllers.dart';
import 'extension_action_buttons.dart';
import 'extension_trust_chip.dart';

/// Card widget for a single extension item.
class ExtensionTile extends ConsumerWidget {
  /// Creates an extension tile.
  const ExtensionTile({super.key, required this.item, required this.onPressed});

  /// Extension item to render.
  final ExtensionItem item;

  /// Callback for opening details.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isTrusted = item.trustStatus == ExtensionTrustStatus.trusted;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AsyncValue<void> actionState = ref.watch(
      extensionActionControllerProvider,
    );

    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SpacingTokens.xs),
        child: Padding(
          padding: InsetsTokens.card,
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.extension_rounded,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      '${item.language.toUpperCase()}  ${item.versionName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    ExtensionTrustChip(trusted: isTrusted),
                  ],
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              ExtensionActionButtons(
                item: item,
                isLoading: actionState.isLoading,
                onTrust: () {
                  ref
                      .read(extensionActionControllerProvider.notifier)
                      .trust(item.packageName);
                },
                onInstall: () {
                  ref
                      .read(extensionActionControllerProvider.notifier)
                      .install(
                        item.packageName,
                        installArtifact: item.installArtifact,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
