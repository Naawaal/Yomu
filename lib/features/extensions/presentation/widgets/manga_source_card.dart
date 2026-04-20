import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extensions_controllers.dart';

/// Cover-dominant discovery card for manga and manhwa sources.
class MangaSourceCard extends ConsumerWidget {
  /// Creates a manga source card.
  const MangaSourceCard({
    super.key,
    required this.item,
    required this.onPressed,
    this.genres = const <String>[],
    this.compact = false,
  });

  /// Extension item to render.
  final ExtensionItem item;

  /// Callback for opening the extension details screen.
  final VoidCallback onPressed;

  /// Optional genre tags shown beneath the title.
  final List<String> genres;

  /// Renders the card as a compact discovery card.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> actionState = ref.watch(
      extensionActionControllerProvider,
    );

    final bool isTrusted = item.trustStatus == ExtensionTrustStatus.trusted;
    final bool isBusy = actionState.isLoading;
    final _SourceActionDecision actionDecision = _SourceActionDecision.fromItem(
      item,
    );

    return AppCard.featured(
      onTap: onPressed,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: compact
          ? _CompactSourceRow(
              item: item,
              actionDecision: actionDecision,
              isBusy: isBusy,
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
              onManage: onPressed,
            )
          : item.isInstalled
          ? _InstalledSourceRow(
              item: item,
              actionDecision: actionDecision,
              isBusy: isBusy,
              onManage: onPressed,
              onUpdate: () {
                ref
                    .read(extensionActionControllerProvider.notifier)
                    .install(
                      item.packageName,
                      installArtifact: item.installArtifact,
                    );
              },
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SourceCoverArt(name: item.name, imageUrl: item.iconUrl),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MangaSourceCardBody(
                    item: item,
                    genres: genres,
                    actionDecision: actionDecision,
                    isBusy: isBusy,
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
                    onManage: onPressed,
                  ),
                ),
              ],
            ),
    );
  }
}

class _InstalledSourceRow extends StatelessWidget {
  const _InstalledSourceRow({
    required this.item,
    required this.actionDecision,
    required this.isBusy,
    required this.onManage,
    required this.onUpdate,
  });

  final ExtensionItem item;
  final _SourceActionDecision actionDecision;
  final bool isBusy;
  final VoidCallback onManage;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SourceCoverArt(name: item.name, imageUrl: item.iconUrl, size: 72),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppTag(
                    label: actionDecision.kind == _SourceActionKind.update
                        ? AppStrings.updateAvailable
                        : AppStrings.installed,
                    variant: actionDecision.kind == _SourceActionKind.update
                        ? AppTagVariant.warning
                        : AppTagVariant.success,
                    leadingIcon: Icon(
                      actionDecision.kind == _SourceActionKind.update
                          ? Ionicons.refresh_outline
                          : Ionicons.checkmark_done_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.packageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  AppTag(label: item.language.toUpperCase()),
                  AppTag(label: item.versionName),
                  if (item.isNsfw)
                    const AppTag(
                      label: AppStrings.nsfw,
                      variant: AppTagVariant.warning,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onManage,
                    icon: const Icon(Ionicons.settings_outline),
                    label: const Text(AppStrings.manage),
                  ),
                  if (actionDecision.kind == _SourceActionKind.update)
                    FilledButton.icon(
                      onPressed: isBusy ? null : onUpdate,
                      icon: const Icon(Ionicons.refresh_outline),
                      label: const Text(AppStrings.update),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactSourceRow extends StatelessWidget {
  const _CompactSourceRow({
    required this.item,
    required this.actionDecision,
    required this.isBusy,
    required this.onTrust,
    required this.onInstall,
    required this.onManage,
  });

  final ExtensionItem item;
  final _SourceActionDecision actionDecision;
  final bool isBusy;
  final VoidCallback onTrust;
  final VoidCallback onInstall;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final _CompactSourceRowState state = _CompactSourceRowState.fromItem(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SourceCoverArt(name: item.name, imageUrl: item.iconUrl),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppTag(
                    label: actionDecision.kind == _SourceActionKind.update
                        ? AppStrings.updateAvailable
                        : state.statusLabel,
                    variant: actionDecision.kind == _SourceActionKind.update
                        ? AppTagVariant.warning
                        : state.statusVariant,
                    leadingIcon: Icon(
                      actionDecision.kind == _SourceActionKind.update
                          ? Ionicons.refresh_outline
                          : state.statusIcon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.packageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  AppTag(label: item.language.toUpperCase()),
                  AppTag(label: item.versionName),
                  if (item.isNsfw)
                    const AppTag(
                      label: AppStrings.nsfw,
                      variant: AppTagVariant.warning,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  const Spacer(),
                  _SourcePrimaryActionButton(
                    actionDecision: actionDecision,
                    isBusy: isBusy,
                    onPressed: _resolveActionHandler(actionDecision.kind),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  VoidCallback _resolveActionHandler(_SourceActionKind kind) {
    return switch (kind) {
      _SourceActionKind.manage => onManage,
      _SourceActionKind.update => onInstall,
      _SourceActionKind.install => onInstall,
      _SourceActionKind.trust => onTrust,
    };
  }
}

class _SourcePrimaryActionButton extends StatelessWidget {
  const _SourcePrimaryActionButton({
    required this.actionDecision,
    required this.isBusy,
    required this.onPressed,
  });

  final _SourceActionDecision actionDecision;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(actionDecision.icon, size: 16);
    final Widget label = Text(actionDecision.label);

    if (actionDecision.kind == _SourceActionKind.manage) {
      return OutlinedButton.icon(
        onPressed: isBusy ? null : onPressed,
        icon: icon,
        label: label,
      );
    }

    return FilledButton.tonalIcon(
      onPressed: isBusy ? null : onPressed,
      icon: icon,
      label: label,
    );
  }
}

class _CompactSourceRowState {
  const _CompactSourceRowState({
    required this.statusLabel,
    required this.statusVariant,
    required this.statusIcon,
  });

  final String statusLabel;
  final AppTagVariant statusVariant;
  final IconData statusIcon;

  factory _CompactSourceRowState.fromItem(ExtensionItem item) {
    if (item.isInstalled && !item.hasUpdate) {
      return const _CompactSourceRowState(
        statusLabel: AppStrings.installed,
        statusVariant: AppTagVariant.success,
        statusIcon: Ionicons.checkmark_done_outline,
      );
    }

    if (item.hasUpdate) {
      return const _CompactSourceRowState(
        statusLabel: AppStrings.updateAvailable,
        statusVariant: AppTagVariant.warning,
        statusIcon: Ionicons.refresh_outline,
      );
    }

    if (item.trustStatus == ExtensionTrustStatus.trusted) {
      return const _CompactSourceRowState(
        statusLabel: AppStrings.trusted,
        statusVariant: AppTagVariant.success,
        statusIcon: Ionicons.shield_checkmark_outline,
      );
    }

    return const _CompactSourceRowState(
      statusLabel: AppStrings.untrusted,
      statusVariant: AppTagVariant.warning,
      statusIcon: Ionicons.alert_circle_outline,
    );
  }
}

class _MangaSourceCardBody extends StatelessWidget {
  const _MangaSourceCardBody({
    required this.item,
    required this.genres,
    required this.actionDecision,
    required this.isBusy,
    required this.onTrust,
    required this.onInstall,
    required this.onManage,
  });

  final ExtensionItem item;
  final List<String> genres;
  final _SourceActionDecision actionDecision;
  final bool isBusy;
  final VoidCallback onTrust;
  final VoidCallback onInstall;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isTrusted = item.trustStatus == ExtensionTrustStatus.trusted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TrustMark(
              isTrusted: isTrusted,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _GenreTag(label: item.language.toUpperCase()),
            _GenreTag(label: item.versionName),
            ...genres.take(1).map((String genre) => _GenreTag(label: genre)),
            if (item.isNsfw)
              const _GenreTag(
                label: AppStrings.nsfw,
                variant: AppTagVariant.warning,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _SubtleStatusText(actionDecision: actionDecision),
            if (actionDecision.kind == _SourceActionKind.manage)
              Chip(
                label: Text(AppStrings.installed),
                avatar: const Icon(Ionicons.checkmark_done_outline, size: 16),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )
            else
              TextButton.icon(
                onPressed: isBusy
                    ? null
                    : _resolveActionHandler(actionDecision.kind),
                icon: Icon(actionDecision.icon),
                label: Text(actionDecision.label),
              ),
          ],
        ),
      ],
    );
  }

  VoidCallback _resolveActionHandler(_SourceActionKind kind) {
    return switch (kind) {
      _SourceActionKind.manage => onManage,
      _SourceActionKind.update => onInstall,
      _SourceActionKind.install => onInstall,
      _SourceActionKind.trust => onTrust,
    };
  }
}

enum _SourceActionKind { manage, update, install, trust }

class _SourceActionDecision {
  const _SourceActionDecision({required this.kind});

  final _SourceActionKind kind;

  String get label {
    return switch (kind) {
      _SourceActionKind.manage => AppStrings.manage,
      _SourceActionKind.update => AppStrings.update,
      _SourceActionKind.install => AppStrings.install,
      _SourceActionKind.trust => AppStrings.trustAndEnable,
    };
  }

  IconData get icon {
    return switch (kind) {
      _SourceActionKind.manage => Ionicons.settings_outline,
      _SourceActionKind.update => Ionicons.refresh_outline,
      _SourceActionKind.install => Ionicons.download_outline,
      _SourceActionKind.trust => Ionicons.shield_checkmark_outline,
    };
  }

  factory _SourceActionDecision.fromItem(ExtensionItem item) {
    final bool hasInstallArtifact = item.installArtifact?.isNotEmpty ?? false;

    if (item.isInstalled && !item.hasUpdate) {
      return const _SourceActionDecision(kind: _SourceActionKind.manage);
    }

    if (item.hasUpdate) {
      return const _SourceActionDecision(kind: _SourceActionKind.update);
    }

    if (item.trustStatus != ExtensionTrustStatus.trusted &&
        !hasInstallArtifact) {
      return const _SourceActionDecision(kind: _SourceActionKind.trust);
    }

    return const _SourceActionDecision(kind: _SourceActionKind.install);
  }
}

class _SourceCoverArt extends StatelessWidget {
  const _SourceCoverArt({
    required this.name,
    required this.imageUrl,
    this.size = 64,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null || imageUrl!.isEmpty
            ? ColoredBox(
                color: colorScheme.primaryContainer,
                child: _FallbackCover(name: name),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return ColoredBox(
                        color: colorScheme.primaryContainer,
                        child: _FallbackCover(name: name),
                      );
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

                      return ColoredBox(
                        color: colorScheme.primaryContainer,
                        child: _FallbackCover(name: name),
                      );
                    },
              ),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Text(
        _initial(name),
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  String _initial(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _GenreTag extends StatelessWidget {
  const _GenreTag({required this.label, this.variant = AppTagVariant.neutral});

  final String label;
  final AppTagVariant variant;

  @override
  Widget build(BuildContext context) {
    return AppTag(label: label, variant: variant);
  }
}

class _TrustMark extends StatelessWidget {
  const _TrustMark({
    required this.isTrusted,
    required this.colorScheme,
    required this.textTheme,
  });

  final bool isTrusted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isTrusted
                ? Ionicons.shield_checkmark
                : Ionicons.alert_circle_outline,
            size: 12,
            color: isTrusted ? colorScheme.primary : colorScheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            isTrusted ? AppStrings.trusted : AppStrings.untrusted,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtleStatusText extends StatelessWidget {
  const _SubtleStatusText({required this.actionDecision});

  final _SourceActionDecision actionDecision;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String statusText = switch (actionDecision.kind) {
      _SourceActionKind.manage => AppStrings.installed,
      _SourceActionKind.update => AppStrings.updateAvailable,
      _SourceActionKind.install => AppStrings.install,
      _SourceActionKind.trust => AppStrings.trustAndEnable,
    };

    return Text(
      statusText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
