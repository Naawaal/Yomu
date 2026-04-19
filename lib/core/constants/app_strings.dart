/// Centralized UI strings for the application.
abstract final class AppStrings {
  /// Application title.
  static const String appTitle = 'Yomu';

  /// Extensions screen title.
  static const String extensionsTitle = 'Extensions';

  /// Extension detail title.
  static const String extensionDetailsTitle = 'Extension Details';

  /// Onboarding screen title for the discover step.
  static const String onboardingDiscoverTitle = 'Find Your Next Obsession';

  /// Onboarding body for the discover step.
  static const String onboardingDiscoverBody =
      'Browse thousands of manga from your favorite sources.';

  /// Onboarding screen title for the extend step.
  static const String onboardingExtendTitle = 'Add Any Source';

  /// Onboarding body for the extend step.
  static const String onboardingExtendBody =
      'Install extensions from community repos. The library never ends.';

  /// Onboarding screen title for the offline step.
  static const String onboardingOfflineTitle = 'Read Anywhere';

  /// Onboarding body for the offline step.
  static const String onboardingOfflineBody =
      'Download chapters and read without internet. Your library travels with you.';

  /// Onboarding brand promise.
  static const String onboardingTagline = 'Discover, Extend, Read Offline';

  /// Primary action label for advancing onboarding.
  static const String next = 'Next';

  /// Secondary action label for returning to a previous onboarding page.
  static const String back = 'Back';

  /// Secondary action label for skipping onboarding.
  static const String skip = 'Skip';

  /// Primary action label for finishing onboarding.
  static const String getStarted = 'Get Started';

  /// Accessibility label prefix for onboarding page indicators.
  static const String onboardingPage = 'Page';

  /// Title shown while the app decides the initial launch route.
  static const String preparingLibrary = 'Preparing your library';

  /// Fallback title for launch gate failures.
  static const String unableToLoadApp = 'Unable to load app';

  /// Helper label for the onboarding pager top bar.
  static const String onboarding = 'Onboarding';

  /// Leading title for the manga source feature step.
  static const String discover = 'Discover';

  /// Leading title for the extension feature step.
  static const String extend = 'Extend';

  /// Leading title for the offline reading feature step.
  static const String readOffline = 'Read Offline';

  /// Label for trusted extensions.
  static const String trusted = 'Trusted';

  /// Label for untrusted extensions.
  static const String untrusted = 'Untrusted';

  /// Install action label.
  static const String install = 'Install';

  /// Update action label.
  static const String update = 'Update';

  /// Trust action label.
  static const String trustAndEnable = 'Trust and Enable';

  /// Label for extension package metadata.
  static const String packageLabel = 'Package';

  /// Label for extension language metadata.
  static const String languageLabel = 'Language';

  /// Label for extension version metadata.
  static const String versionLabel = 'Version';

  /// Banner heading shown when update is available.
  static const String updateAvailable = 'Update available';

  /// Banner heading shown for NSFW sources.
  static const String nsfwContent = 'NSFW content';

  /// Compact NSFW label used in tags.
  static const String nsfw = 'NSFW';

  /// Banner body shown for NSFW sources.
  static const String nsfwBody =
      'This source may include mature content. Review before installing.';

  /// Fallback message when a selected extension is not present.
  static const String extensionNotFound = 'Extension not found';

  /// Retry action label.
  static const String retry = 'Retry';

  /// Empty state heading.
  static const String noExtensionsTitle = 'No extensions found';

  /// Empty state body.
  static const String noExtensionsBody =
      'Try syncing repositories or changing filters.';

  /// Search hint for filtering the extensions list.
  static const String extensionsSearchHint = 'Search extensions';

  /// Filter label for showing all extension languages.
  static const String extensionsAllLanguages = 'All languages';

  /// Extensions section title for trusted recommendations.
  static const String extensionsTrustedRecommendations =
      'Trusted recommendations';

  /// Extensions section title for recently updated items.
  static const String extensionsRecentlyUpdated = 'Recently updated';

  /// Extensions section title for sources ready to install.
  static const String extensionsInstallReady = 'Ready to install';

    /// Error shown when install is requested without an install artifact.
    static const String extensionsInstallArtifactMissing =
            'Install artifact missing. Refresh extensions and try again.';

  /// Extensions section title for the remaining catalog.
  static const String extensionsMoreSources = 'More sources';

  // ── Main shell ──────────────────────────────────────────────────────────────

  /// Bottom navigation label for the Home tab.
  static const String home = 'Home';

  /// Bottom navigation label for the Feed tab.
  static const String feed = 'Feed';

  /// Bottom navigation label for the Library tab.
  static const String library = 'Library';

  /// Bottom navigation label for the Settings tab.
  static const String settings = 'Settings';

  /// Settings section header for content management.
  static const String settingsSectionContent = 'Content';

  /// Settings list tile subtitle for the Extension Manager entry.
  static const String settingsExtensionsSubtitle =
      'Browse and install manga sources';

  /// Feed empty-state headline.
  static const String feedEmptyTitle = 'Your feed is empty';

  /// Feed empty-state body copy.
  static const String feedEmptyBody =
      'Install extensions to see the latest updates here.';

  /// Feed empty-state button label directing to extensions.
  static const String feedBrowseExtensions = 'Browse Extensions';

  /// Feed sort option label for newest-first ordering.
  static const String feedSortNewest = 'Newest';

  /// Feed sort option label for oldest-first ordering.
  static const String feedSortOldest = 'Oldest';

  /// Feed filter label when read items are visible.
  static const String feedFilterIncludingRead = 'Including Read';

  /// Feed filter label when only unread items are visible.
  static const String feedFilterUnreadOnly = 'Unread Only';

  /// Feed pagination action label.
  static const String feedLoadMore = 'Load More';

  /// Feed error heading text.
  static const String feedLoadFailed = 'Unable to load feed';

  /// Feed status chip text for unread/live updates.
  static const String feedStatusLive = 'Live';

  /// Feed status chip text for read items.
  static const String feedStatusRead = 'Read';

  /// Feed hero chip text for featured content.
  static const String feedFeaturedNowLabel = 'Featured Now';

  /// Feed section label for the continue-watching rail.
  static const String feedContinueWatchingLabel = 'Continue Watching';

  /// Feed section label for the latest-content rail.
  static const String feedLatestFromSourcesLabel = 'Latest from Your Sources';

  /// Hero section label for spotlight feed item.
  static const String feedSpotlightLabel = 'Spotlight';

  /// Quick stat label for unread item count.
  static const String feedUnreadCountLabel = 'Unread updates';

  /// Quick stat label for last successful sync.
  static const String feedLastSyncLabel = 'Last sync';

  /// Fallback value when no last-sync timestamp is available.
  static const String feedLastSyncUnknown = 'Not available';

  /// Relative-time label for very recent updates.
  static const String feedTimeNow = 'Now';

  /// Relative-time suffix for minute-based labels.
  static const String feedMinutesAgoSuffix = 'm ago';

  /// Relative-time suffix for hour-based labels.
  static const String feedHoursAgoSuffix = 'h ago';

  /// Relative-time suffix for day-based labels.
  static const String feedDaysAgoSuffix = 'd ago';

  /// Library tab placeholder body copy.
  static const String libraryPlaceholderBody =
      'Your saved titles and progress will appear here.';

  /// Home feed error heading text.
  static const String homeFeedLoadFailed = 'Unable to load home feed';

  /// Home feed empty-state heading.
  static const String homeFeedEmptyTitle = 'No updates yet';

  /// Home feed empty-state body copy.
  static const String homeFeedEmptyBody =
      'Try refreshing or adjusting your feed preferences.';

  /// Home library error heading text.
  static const String homeLibraryLoadFailed = 'Unable to load library';

  /// Home library empty-state heading.
  static const String homeLibraryEmptyTitle = 'Your library is empty';

  /// Home library empty-state body copy.
  static const String homeLibraryEmptyBody =
      'Start reading and your recent titles will appear here.';

  /// Generic refresh action label used on Home tab states.
  static const String homeRefresh = 'Refresh';

  /// Continue-reading module label.
  static const String homeContinueReadingLabel = 'Continue Reading';

  /// Continue-reading subtitle fallback text.
  static const String homeContinueReadingFallback =
      'Pick up where you left off';

  /// Continue-reading progress fallback text.
  static const String homeProgressUnavailable = 'Progress unavailable';

  /// Continue-reading action label.
  static const String homeResume = 'Resume';

  /// Progress shelf section heading.
  static const String homeLibraryShelfTitle = 'Continue your library';

  /// Progress shelf section subheading.
  static const String homeLibraryShelfSubtitle =
      'Progress-first picks to resume right away.';

  /// Settings section title for theme controls.
  static const String settingsSectionTheme = 'Theme';

  /// Settings section title for backup controls.
  static const String settingsSectionBackup = 'Backup';

  /// Settings section title for repository management.
  static const String settingsSectionRepositories = 'Repositories';

  /// Theme mode label for system setting.
  static const String settingsThemeSystem = 'System';

  /// Theme mode label for light setting.
  static const String settingsThemeLight = 'Light';

  /// Theme mode label for dark setting.
  static const String settingsThemeDark = 'Dark';

  /// Backup action label for export operation.
  static const String settingsBackupExport = 'Export Backup';

  /// Backup action label for import operation.
  static const String settingsBackupImport = 'Import Backup';

  /// Backup metadata label for last export.
  static const String settingsBackupLastExport = 'Last export';

  /// Backup metadata label for last import.
  static const String settingsBackupLastImport = 'Last import';

  /// Placeholder label for unavailable metadata values.
  static const String settingsNotAvailable = 'Not available';

  /// Repository action label for creating entries.
  static const String settingsRepositoryAdd = 'Add';

  /// Repository action tooltip for validation.
  static const String settingsRepositoryValidate = 'Validate repository';

  /// Repository action tooltip for removal.
  static const String settingsRepositoryRemove = 'Remove repository';

  /// Empty-state message for repository list.
  static const String settingsRepositoriesEmpty =
      'No repositories configured yet.';

  /// Dialog title for adding a repository.
  static const String settingsAddRepositoryTitle = 'Add repository';

  /// Dialog field label for repository name.
  static const String settingsRepositoryNameLabel = 'Repository name';

  /// Dialog field label for repository URL.
  static const String settingsRepositoryUrlLabel = 'Repository URL';

  /// Dialog action label for cancelling.
  static const String settingsCancel = 'Cancel';

  /// Dialog action label for confirming add.
  static const String settingsAdd = 'Add';

  /// Dialog title for confirming repository removal.
  static const String settingsRemoveRepositoryTitle = 'Remove repository';

  /// Dialog body for confirming repository removal.
  static const String settingsRemoveRepositoryBody =
      'Are you sure you want to remove this repository?';

  /// Dialog action label for confirming removal.
  static const String settingsRemove = 'Remove';

  /// Error message shown when repository input is invalid.
  static const String settingsRepositoryInputInvalid =
      'Please provide both a name and URL.';

  /// Feedback shown when repository validation succeeds.
  static const String settingsRepositoryValidationSuccess =
      'Repository validated successfully.';

  /// Feedback shown when repository URL has an unsupported format.
  static const String settingsRepositoryValidationInvalidUrl =
      'Repository URL is invalid. Use a valid http/https URL.';

  /// Repository health status: successfully validated.
  static const String settingsRepositoryHealthyLabel = 'Healthy';

  /// Repository health status: validation failed.
  static const String settingsRepositoryUnhealthyLabel = 'Unavailable';

  /// Repository health status: not yet validated.
  static const String settingsRepositoryUnknownLabel = 'Not validated';

  /// Feedback shown when repository index cannot be reached.
  static const String settingsRepositoryValidationUnreachable =
      'Could not reach repository index. Check the URL and network.';

  /// Feedback shown when repository index payload is malformed.
  static const String settingsRepositoryValidationInvalidIndex =
      'Repository index format is invalid.';

  /// Generic operation success message.
  static const String settingsOperationCompleted = 'Settings updated.';
}
