package com.example.yomu

/** Manifest metadata contract for installed Yomu extension packages. */
object ExtensionPackageContract {
  const val schemaVersion = 1
  const val unspecifiedSchemaVersion = -1
  const val defaultLanguage = "all"

  const val metadataEnabled = "com.example.yomu.extension.ENABLED"
  const val metadataSchemaVersion = "com.example.yomu.extension.SCHEMA_VERSION"
  const val metadataDisplayName = "com.example.yomu.extension.NAME"
  const val metadataLanguage = "com.example.yomu.extension.LANGUAGE"
  const val metadataNsfw = "com.example.yomu.extension.NSFW"
  const val metadataInstallArtifact = "com.example.yomu.extension.INSTALL_ARTIFACT"
  const val metadataIconUrl = "com.example.yomu.extension.ICON_URL"

  const val discoverAction = "com.example.yomu.extension.DISCOVER"

  // Legacy ecosystem discovery actions used by Tachiyomi/Mihon extensions.
  const val tachiyomiDiscoverAction = "eu.kanade.tachiyomi.extension"
  const val mihonDiscoverAction = "app.mihon.extension"

  val discoverActions: List<String> = listOf(
    discoverAction,
    tachiyomiDiscoverAction,
    mihonDiscoverAction,
  )

  const val tachiyomiPackagePrefix = "eu.kanade.tachiyomi.extension."
  const val mihonPackagePrefix = "app.mihon.extension."
}