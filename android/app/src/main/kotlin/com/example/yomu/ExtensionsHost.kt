package com.example.yomu

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Bundle
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Handles the Android side of the extensions MethodChannel bridge. */
class ExtensionsHost(
  private val activity: Activity,
  private val trustStorage: ExtensionTrustStorage,
) {
  private val packageManager: PackageManager
    get() = activity.packageManager

  private val installManager = ExtensionInstallManager(activity)
  private val signatureVerifier = ExtensionSignatureVerifier(
    packageManager = packageManager,
    hostPackageName = activity.packageName,
  )
  private val scanner = InstalledExtensionScanner(
    packageManager = packageManager,
    signatureVerifier = signatureVerifier,
    trustStorage = trustStorage,
  )

  /** Routes Flutter MethodChannel calls to the appropriate host handler. */
  fun handle(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      BridgeMethod.getRuntimeInfo -> handleGetRuntimeInfo(result)
      BridgeMethod.listAvailableExtensions -> handleListAvailableExtensions(result)
      BridgeMethod.trustExtension -> handleTrustExtension(call, result)
      BridgeMethod.installExtension -> handleInstallExtension(call, result)
      else -> result.notImplemented()
    }
  }

  private fun handleGetRuntimeInfo(result: MethodChannel.Result) {
    try {
      result.success(
        mapOf(
          "schemaVersion" to BRIDGE_SCHEMA_VERSION,
          "capabilities" to ExtensionsHostCapabilities.all,
        )
      )
    } catch (exception: Exception) {
      result.error("GET_RUNTIME_INFO_FAILED", exception.message, null)
    }
  }

  private fun handleListAvailableExtensions(result: MethodChannel.Result) {
    try {
      result.success(scanner.listAvailableExtensions())
    } catch (exception: Exception) {
      result.error("LIST_EXTENSIONS_FAILED", exception.message, null)
    }
  }

  private fun handleTrustExtension(
    call: MethodCall,
    result: MethodChannel.Result,
  ) {
    val packageName = call.argument<String>(ARG_PACKAGE_NAME)
    if (packageName.isNullOrBlank()) {
      result.error("INVALID_ARGS", "packageName is required", null)
      return
    }

    try {
      packageManager.getPackageInfo(packageName, 0)
      val verification = signatureVerifier.verifyInstalledPackage(packageName)
      if (!verification.isTrusted) {
        result.error(
          "SIGNATURE_VERIFICATION_FAILED",
          verification.message,
          mapOf("signers" to verification.signerDigests.toList()),
        )
        return
      }

      trustStorage.trust(packageName)
      result.success(null)
    } catch (_: PackageManager.NameNotFoundException) {
      result.error("PACKAGE_NOT_FOUND", "Extension package not found: $packageName", null)
    } catch (exception: Exception) {
      result.error("TRUST_EXTENSION_FAILED", exception.message, null)
    }
  }

  private fun handleInstallExtension(
    call: MethodCall,
    result: MethodChannel.Result,
  ) {
    val packageName = call.argument<String>(ARG_PACKAGE_NAME)
    val installArtifact = call.argument<String>(ARG_INSTALL_ARTIFACT)

    if (packageName.isNullOrBlank()) {
      result.error("INVALID_ARGS", "packageName is required", null)
      return
    }
    if (installArtifact.isNullOrBlank()) {
      result.error("INVALID_ARGS", "installArtifact is required", null)
      return
    }

    try {
      try {
        packageManager.getPackageInfo(packageName, 0)
        result.error(
          "PACKAGE_ALREADY_INSTALLED",
          "Extension already installed: $packageName",
          null,
        )
        return
      } catch (_: PackageManager.NameNotFoundException) {
        // Package not found, proceed with install-source checks.
      }

      if (!installManager.canRequestPackageInstalls()) {
        try {
          installManager.openInstallSourceSettings()
          result.success(
            mapOf(
              "state" to InstallStateValues.requiresUserAction,
              "sessionId" to null,
              "message" to "User needs to enable installation from unknown sources",
            )
          )
        } catch (exception: Exception) {
          result.error(
            "INSTALL_SOURCE_SETTING_UNAVAILABLE",
            "Could not open install source settings: ${exception.message}",
            null,
          )
        }
        return
      }

      val installResult = installManager.installExtensionFromArtifact(installArtifact)
      result.success(installResult.toMap())
    } catch (exception: ExtensionInstallException) {
      result.error(exception.code, exception.message, null)
    } catch (exception: Exception) {
      result.error("INSTALL_EXTENSION_FAILED", exception.message, null)
    }
  }

  private companion object {
    const val ARG_PACKAGE_NAME = "packageName"
    const val ARG_INSTALL_ARTIFACT = "installArtifact"
    const val BRIDGE_SCHEMA_VERSION = 1
  }
}

/** Central capability identifiers exposed by the native extension host. */
object ExtensionsHostCapabilities {
  const val list = "extensions.list"
  const val trust = "extensions.trust"
  const val install = "extensions.install"

  val all: List<String> = listOf(list, trust, install)
}

private object BridgeMethod {
  const val getRuntimeInfo = "getRuntimeInfo"
  const val listAvailableExtensions = "listAvailableExtensions"
  const val trustExtension = "trustExtension"
  const val installExtension = "installExtension"
}

/** Encapsulates the current package-scan based extension discovery logic. */
private class InstalledExtensionScanner(
  private val packageManager: PackageManager,
  private val signatureVerifier: ExtensionSignatureVerifier,
  private val trustStorage: ExtensionTrustStorage,
) {
  fun listAvailableExtensions(): List<Map<String, Any?>> {
    return queryTargetedExtensionPackages()
      .asSequence()
      .mapNotNull { packageInfo ->
        packageInfo.toExtensionPayload(
          packageManager = packageManager,
          signatureVerifier = signatureVerifier,
          trustStorage = trustStorage,
        )
      }
      .toList()
  }

  private fun queryTargetedExtensionPackages(): List<PackageInfo> {
    val targetedPackages = queryPackagesFromDiscoveryAction()
    if (targetedPackages.isNotEmpty()) {
      return targetedPackages
    }

    // Fallback scan preserves behavior for extension packages that have not yet
    // adopted the targeted discovery action.
    return packageManager.getInstalledPackages(PackageManager.GET_META_DATA)
  }

  private fun queryPackagesFromDiscoveryAction(): List<PackageInfo> {
    val queryIntent = Intent(ExtensionPackageContract.discoverAction)
    val packageNames = resolveDiscoveryIntentPackages(queryIntent)
    return packageNames
      .asSequence()
      .mapNotNull { packageName ->
        runCatching {
          packageManager.getPackageInfo(packageName, PackageManager.GET_META_DATA)
        }.getOrNull()
      }
      .toList()
  }

  private fun resolveDiscoveryIntentPackages(queryIntent: Intent): Set<String> {
    val resolveInfos = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
      packageManager.queryIntentActivities(
        queryIntent,
        PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()),
      )
    } else {
      @Suppress("DEPRECATION")
      packageManager.queryIntentActivities(queryIntent, PackageManager.MATCH_DEFAULT_ONLY)
    }

    return resolveInfos
      .asSequence()
      .mapNotNull { resolveInfo: ResolveInfo -> resolveInfo.activityInfo?.packageName }
      .toSet()
  }
}

private fun PackageInfo.toExtensionPayload(
  packageManager: PackageManager,
  signatureVerifier: ExtensionSignatureVerifier,
  trustStorage: ExtensionTrustStorage,
): Map<String, Any?>? {
  val metadata = applicationInfo?.metaData ?: return null
  if (!metadata.isRecognizedExtension()) {
    return null
  }

  val applicationLabel = applicationInfo?.let { appInfo ->
    packageManager.getApplicationLabel(appInfo)
  } ?: "Unknown"
  val displayName = metadata.getTrimmedString(ExtensionPackageContract.metadataDisplayName)
    ?: applicationLabel.toString()
  val language = metadata.getTrimmedString(ExtensionPackageContract.metadataLanguage)
    ?: ExtensionPackageContract.defaultLanguage

  val isVerifiedSigner = signatureVerifier.verifyInstalledPackage(packageName).isTrusted

  return mapOf(
    "name" to displayName,
    "packageName" to packageName,
    "language" to language,
    "versionName" to versionName,
    "hasUpdate" to false,
    "isNsfw" to metadata.getBoolean(ExtensionPackageContract.metadataNsfw, false),
    "installArtifact" to metadata.getTrimmedString(ExtensionPackageContract.metadataInstallArtifact),
    "isTrusted" to (trustStorage.isTrusted(packageName) && isVerifiedSigner),
  )
}

private fun Bundle.isRecognizedExtension(): Boolean {
  val schemaVersion = getInt(
    ExtensionPackageContract.metadataSchemaVersion,
    ExtensionPackageContract.unspecifiedSchemaVersion,
  )
  if (schemaVersion != ExtensionPackageContract.schemaVersion) {
    return false
  }

  return getBoolean(ExtensionPackageContract.metadataEnabled, false)
}

private fun Bundle.getTrimmedString(key: String): String? {
  return getString(key)?.trim()?.takeIf { value -> value.isNotEmpty() }
}
