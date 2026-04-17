/// Health status for a managed content repository.
enum RepositoryHealthStatus {
  /// Health has not been checked yet.
  unknown,

  /// Repository endpoint is reachable and valid.
  healthy,

  /// Repository endpoint is unreachable or invalid.
  unhealthy,
}

/// Immutable repository configuration managed from settings.
class RepositoryConfig {
  /// Creates repository configuration.
  const RepositoryConfig({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.isEnabled,
    required this.healthStatus,
    this.lastValidatedAt,
  });

  /// Stable identifier for persistence and updates.
  final String id;

  /// Human-friendly repository name shown in UI.
  final String displayName;

  /// Base URL for repository operations.
  final String baseUrl;

  /// Whether this repository is currently active.
  final bool isEnabled;

  /// Last known health state.
  final RepositoryHealthStatus healthStatus;

  /// Timestamp of latest validation, if available.
  final DateTime? lastValidatedAt;
}
