package com.example.yomu

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.yomu.source.RuntimeExecutionRequest
import com.example.yomu.source.RuntimeExecutionException
import com.example.yomu.source.RuntimeOperation
import com.example.yomu.source.SourceBridgePayloadMapper
import com.example.yomu.source.SourceRuntimeExecutor
import java.io.ByteArrayOutputStream

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
  private val runtimeExecutor = SourceRuntimeExecutor()
  private val runtimePayloadMapper = SourceBridgePayloadMapper()

  /** Routes Flutter MethodChannel calls to the appropriate host handler. */
  fun handle(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      BridgeMethod.getRuntimeInfo -> handleGetRuntimeInfo(result)
      BridgeMethod.listAvailableExtensions -> handleListAvailableExtensions(result)
      BridgeMethod.trustExtension -> handleTrustExtension(call, result)
      BridgeMethod.installExtension -> handleInstallExtension(call, result)
      BridgeMethod.executeLatest -> handleExecuteRuntime(call, result, RuntimeOperation.latest)
      BridgeMethod.executePopular -> handleExecuteRuntime(call, result, RuntimeOperation.popular)
      BridgeMethod.executeSearch -> handleExecuteRuntime(call, result, RuntimeOperation.search)
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
      result.error(
        "GET_RUNTIME_INFO_FAILED",
        exception.toDetailedMessage("Failed to load extension host runtime info"),
        null,
      )
    }
  }

  private fun handleListAvailableExtensions(result: MethodChannel.Result) {
    try {
      result.success(scanner.listAvailableExtensions())
    } catch (exception: Exception) {
      result.error(
        "LIST_EXTENSIONS_FAILED",
        exception.toDetailedMessage("Failed to list available extensions"),
        null,
      )
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
      result.error(
        "TRUST_EXTENSION_FAILED",
        exception.toDetailedMessage("Failed to trust extension: $packageName"),
        null,
      )
    }
  }

  private fun handleInstallExtension(
    call: MethodCall,
    result: MethodChannel.Result,
  ) {
    val packageName = call.argument<String>(ARG_PACKAGE_NAME)
    val installArtifact = call.argument<String>(ARG_INSTALL_ARTIFACT)

    if (packageName.isNullOrBlank()) {
      result.error("INVALID_ARGS", "packageName is required for installExtension", null)
      return
    }
    if (installArtifact.isNullOrBlank()) {
      result.error(
        "INVALID_ARGS",
        "installArtifact is required for package: $packageName",
        null,
      )
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
      result.error(
        "INSTALL_EXTENSION_FAILED",
        exception.toDetailedMessage("Install failed for package: $packageName"),
        null,
      )
    }
  }

  private fun handleExecuteRuntime(
    call: MethodCall,
    result: MethodChannel.Result,
    operation: RuntimeOperation,
  ) {
    val sourceId = call.argument<String>(ARG_SOURCE_ID)
    if (sourceId.isNullOrBlank()) {
      result.error("INVALID_ARGS", "sourceId is required", null)
      return
    }

    val page = call.argument<Int>(ARG_PAGE)?.takeIf { value -> value > 0 } ?: 1
    val pageSize = call.argument<Int>(ARG_PAGE_SIZE)?.takeIf { value -> value > 0 } ?: 20
    val query = call.argument<String>(ARG_QUERY)?.trim().orEmpty()

    if (operation == RuntimeOperation.search && query.isBlank()) {
      result.error("INVALID_ARGS", "query is required for executeSearch", null)
      return
    }

    try {
      val trustedExtension = scanner.findTrustedBySourceId(sourceId)
      if (trustedExtension == null) {
        result.error(
          "SOURCE_NOT_TRUSTED",
          "Source is not installed and trusted: $sourceId",
          null,
        )
        return
      }

      val executionResult = runtimeExecutor.execute(
        RuntimeExecutionRequest(
          sourceId = sourceId,
          operation = operation,
          page = page,
          pageSize = pageSize,
          query = if (operation == RuntimeOperation.search) query else null,
        )
      )
      result.success(runtimePayloadMapper.toRuntimePagePayload(executionResult))
    } catch (exception: RuntimeExecutionException) {
      result.error(exception.code, exception.message, null)
    } catch (exception: Exception) {
      result.error(
        "EXECUTE_RUNTIME_FAILED",
        exception.toDetailedMessage("Failed to execute ${operation.value} for source: $sourceId"),
        null,
      )
    }
  }

  private companion object {
    const val ARG_PACKAGE_NAME = "packageName"
    const val ARG_INSTALL_ARTIFACT = "installArtifact"
    const val ARG_SOURCE_ID = "sourceId"
    const val ARG_QUERY = "query"
    const val ARG_PAGE = "page"
    const val ARG_PAGE_SIZE = "pageSize"
    const val BRIDGE_SCHEMA_VERSION = 1
  }
}

/** Central capability identifiers exposed by the native extension host. */
object ExtensionsHostCapabilities {
  const val list = "extensions.list"
  const val trust = "extensions.trust"
  const val install = "extensions.install"
  const val executeLatest = "extensions.execute.latest"
  const val executePopular = "extensions.execute.popular"
  const val executeSearch = "extensions.execute.search"

  val all: List<String> = listOf(
    list,
    trust,
    install,
    executeLatest,
    executePopular,
    executeSearch,
  )
}

private object BridgeMethod {
  const val getRuntimeInfo = "getRuntimeInfo"
  const val listAvailableExtensions = "listAvailableExtensions"
  const val trustExtension = "trustExtension"
  const val installExtension = "installExtension"
  const val executeLatest = "executeLatest"
  const val executePopular = "executePopular"
  const val executeSearch = "executeSearch"
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

  fun findTrustedBySourceId(sourceId: String): Map<String, Any?>? {
    return listAvailableExtensions().firstOrNull { payload ->
      val packageName = payload["packageName"] as? String
      val trusted = payload["isTrusted"] as? Boolean ?: false
      packageName == sourceId && trusted
    }
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
    val packageNames = ExtensionPackageContract.discoverActions
      .asSequence()
      .flatMap { action ->
        resolveDiscoveryIntentPackages(Intent(action)).asSequence()
      }
      .toSet()

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
  val metadata = applicationInfo?.metaData
  val hasYomuContractMetadata = metadata?.isRecognizedExtension() == true
  val isCompatibilityPackage = packageName.isKnownCompatibilityExtensionPackage()
  if (!hasYomuContractMetadata && !isCompatibilityPackage) {
    return null
  }

  val applicationLabel = applicationInfo?.let { appInfo ->
    packageManager.getApplicationLabel(appInfo)
  } ?: "Unknown"
  val displayName = if (hasYomuContractMetadata) {
    metadata?.getTrimmedString(ExtensionPackageContract.metadataDisplayName)
      ?: applicationLabel.toString()
  } else {
    applicationLabel.toString()
  }

  val language = if (hasYomuContractMetadata) {
    metadata?.getTrimmedString(ExtensionPackageContract.metadataLanguage)
      ?: ExtensionPackageContract.defaultLanguage
  } else {
    packageName.inferCompatibilityLanguage()
  }

  val iconPayload = metadata?.getTrimmedString(ExtensionPackageContract.metadataIconUrl)
    ?: packageManager.resolveInstalledIconDataUri(packageName)

  val isVerifiedSigner = signatureVerifier.verifyInstalledPackage(packageName).isTrusted

  return mapOf(
    "name" to displayName,
    "packageName" to packageName,
    "language" to language,
    "versionName" to versionName,
    "hasUpdate" to false,
    "isNsfw" to if (hasYomuContractMetadata) {
      metadata?.getBoolean(ExtensionPackageContract.metadataNsfw, false) ?: false
    } else {
      false
    },
    "installArtifact" to if (hasYomuContractMetadata) {
      metadata?.getTrimmedString(ExtensionPackageContract.metadataInstallArtifact)
    } else {
      null
    },
    "iconUrl" to iconPayload,
    "isTrusted" to (trustStorage.isTrusted(packageName) && isVerifiedSigner),
  )
}

private fun String.isKnownCompatibilityExtensionPackage(): Boolean {
  return startsWith(ExtensionPackageContract.tachiyomiPackagePrefix) ||
    startsWith(ExtensionPackageContract.mihonPackagePrefix)
}

private fun String.inferCompatibilityLanguage(): String {
  val segments = split('.')
  val extensionSegmentIndex = segments.indexOf("extension")
  if (extensionSegmentIndex >= 0 && extensionSegmentIndex + 1 < segments.size) {
    val candidate = segments[extensionSegmentIndex + 1].lowercase()
    if (candidate == "all") {
      return candidate
    }
    if (candidate.matches(Regex("^[a-z]{2,5}$"))) {
      return candidate
    }
  }

  return ExtensionPackageContract.defaultLanguage
}

private fun PackageManager.resolveInstalledIconDataUri(packageName: String): String? {
  val drawable = runCatching { getApplicationIcon(packageName) }.getOrNull() ?: return null
  return drawable.toPngDataUri()
}

private fun Drawable.toPngDataUri(): String? {
  val bitmap = toBitmapOrNull() ?: return null
  val bytes = ByteArrayOutputStream().use { stream ->
    val didWrite = bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
    if (!didWrite) {
      return null
    }
    stream.toByteArray()
  }

  return "data:image/png;base64,${Base64.encodeToString(bytes, Base64.NO_WRAP)}"
}

private fun Drawable.toBitmapOrNull(): Bitmap? {
  if (this is BitmapDrawable) {
    val drawableBitmap = bitmap
    if (drawableBitmap != null) {
      return drawableBitmap
    }
  }

  val width = intrinsicWidth.takeIf { value -> value > 0 } ?: DEFAULT_ICON_SIZE_PX
  val height = intrinsicHeight.takeIf { value -> value > 0 } ?: DEFAULT_ICON_SIZE_PX
  val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
  val canvas = Canvas(bitmap)
  setBounds(0, 0, canvas.width, canvas.height)
  draw(canvas)
  return bitmap
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

private fun Throwable.toDetailedMessage(context: String): String {
  val trimmed = message?.trim()
  if (!trimmed.isNullOrEmpty()) {
    return "$context: $trimmed"
  }

  return "$context (${this::class.java.simpleName})"
}

private const val DEFAULT_ICON_SIZE_PX = 128
