/// Extension trust state shown in UI.
enum ExtensionTrustStatus {
  /// Trusted and loadable extension.
  trusted,

  /// Installed but requires user trust.
  untrusted,
}

/// Presentation-focused extension item.
class ExtensionItem {
  /// Creates a single extension item.
  const ExtensionItem({
    required this.name,
    required this.packageName,
    required this.language,
    required this.versionName,
    required this.hasUpdate,
    required this.isNsfw,
    required this.trustStatus,
    this.installArtifact,
    this.iconUrl,
  });

  /// Display name.
  final String name;

  /// Android package name.
  final String packageName;

  /// Source language code.
  final String language;

  /// Version name.
  final String versionName;

  /// Whether an update is available.
  final bool hasUpdate;

  /// Whether source is NSFW.
  final bool isNsfw;

  /// Trust state of extension.
  final ExtensionTrustStatus trustStatus;

  /// Install artifact hint used by native install flow (content/file URI or file path).
  final String? installArtifact;

  /// URL to extension icon image (optional, for display in UI).
  final String? iconUrl;
}
