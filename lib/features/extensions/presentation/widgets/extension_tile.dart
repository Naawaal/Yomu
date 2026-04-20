import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extensions_controllers.dart';
import 'extension_action_buttons.dart';

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
    final AsyncValue<void> actionState = ref.watch(
      extensionActionControllerProvider,
    );

    return AppCard(
      onTap: onPressed,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ExtensionArtwork(name: item.name, iconUrl: item.iconUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _ExtensionTileBody(item: item)),
          const SizedBox(width: AppSpacing.sm),
          Align(
            alignment: Alignment.center,
            child: ExtensionActionButtons(
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
          ),
        ],
      ),
    );
  }
}

class _ExtensionArtwork extends StatelessWidget {
  const _ExtensionArtwork({required this.name, required this.iconUrl});

  final String name;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: _buildIconContent(colorScheme, textTheme),
    );
  }

  Widget _buildIconContent(ColorScheme colorScheme, TextTheme textTheme) {
    // Display network image if icon URL available
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return Image.network(
        iconUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              // Fallback to initials on image load error
              return _buildInitialsFallback(colorScheme, textTheme);
            },
        loadingBuilder:
            (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }
              // Keep icon rendering parity with other extension cards.
              return _buildInitialsFallback(colorScheme, textTheme);
            },
      );
    }

    // Fallback to initials
    return _buildInitialsFallback(colorScheme, textTheme);
  }

  Widget _buildInitialsFallback(ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      _initials(name),
      style: textTheme.titleMedium?.copyWith(
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  String _initials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _ExtensionTileBody extends StatelessWidget {
  const _ExtensionTileBody({required this.item});

  final ExtensionItem item;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.name,
          style: textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.packageName,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            AppTag(label: item.language.toUpperCase()),
            AppTag(label: item.versionName),
            AppTag(
              label: item.trustStatus == ExtensionTrustStatus.trusted
                  ? AppStrings.trusted
                  : AppStrings.untrusted,
              variant: item.trustStatus == ExtensionTrustStatus.trusted
                  ? AppTagVariant.success
                  : AppTagVariant.warning,
            ),
            if (item.isNsfw)
              const AppTag(
                label: AppStrings.nsfw,
                variant: AppTagVariant.error,
              ),
          ],
        ),
      ],
    );
  }
}
