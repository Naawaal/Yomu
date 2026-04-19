package com.example.yomu

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Looper
import android.provider.Settings
import java.io.File
import java.io.FileNotFoundException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executors

/** Manages install-source permission checks for extension APK workflows. */
class ExtensionInstallManager(
  private val activity: Activity,
) {
  private val packageManager: PackageManager
    get() = activity.packageManager

  /** Returns true when the host is allowed to request package installs. */
  fun canRequestPackageInstalls(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      packageManager.canRequestPackageInstalls()
    } else {
      packageManager.checkPermission(
        REQUEST_INSTALL_PACKAGES_PERMISSION,
        activity.packageName,
      ) == PackageManager.PERMISSION_GRANTED
    }
  }

  /** Launches the system settings screen for enabling unknown-app-source installs. */
  fun openInstallSourceSettings() {
    val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
      data = Uri.parse("package:${activity.packageName}")
      addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    activity.startActivity(intent)
  }

  /** Installs an extension from a file/content artifact using a PackageInstaller session. */
  fun installExtensionFromArtifact(installArtifact: String): InstallOperationResult {
    val sourceUri = resolveSourceUri(installArtifact)
    val packageInstaller = packageManager.packageInstaller
    val sessionParams = PackageInstaller.SessionParams(
      PackageInstaller.SessionParams.MODE_FULL_INSTALL,
    ).apply {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        setPackageSource(PackageInstaller.PACKAGE_SOURCE_LOCAL_FILE)
      }
    }

    val sessionId = try {
      packageInstaller.createSession(sessionParams)
    } catch (exception: Exception) {
      throw ExtensionInstallException(
        code = "INSTALL_SESSION_CREATE_FAILED",
        message = exception.message ?: "Could not create install session.",
        cause = exception,
      )
    }

    try {
      registerStatusReceiver(sessionId)
      packageInstaller.openSession(sessionId).use { session ->
        writeArtifactToSession(session = session, sourceUri = sourceUri)
        val statusReceiver = createStatusPendingIntent(sessionId)
        session.commit(statusReceiver.intentSender)
      }
      return InstallOperationResult.committed(sessionId)
    } catch (exception: Exception) {
      unregisterStatusReceiver(sessionId)
      runCatching { packageInstaller.abandonSession(sessionId) }
      throw ExtensionInstallException(
        code = "INSTALL_SESSION_FAILED",
        message = exception.message ?: "Could not commit install session.",
        cause = exception,
      )
    }
  }

  private fun writeArtifactToSession(
    session: PackageInstaller.Session,
    sourceUri: Uri,
  ) {
    val input = activity.contentResolver.openInputStream(sourceUri)
      ?: throw FileNotFoundException("Could not open install artifact: $sourceUri")

    input.use { source ->
      session.openWrite(INSTALL_ENTRY_BASE_APK, 0, -1).use { target ->
        source.copyTo(target)
        session.fsync(target)
      }
    }
  }

  private fun registerStatusReceiver(sessionId: Int) {
    val receiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(
          PackageInstaller.EXTRA_STATUS,
          PackageInstaller.STATUS_FAILURE,
        )

        when (status) {
          PackageInstaller.STATUS_PENDING_USER_ACTION -> {
            val confirmIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
              intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
            } else {
              @Suppress("DEPRECATION")
              intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
            }

            if (confirmIntent != null) {
              confirmIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              activity.startActivity(confirmIntent)
            }
          }

          PackageInstaller.STATUS_SUCCESS,
          PackageInstaller.STATUS_FAILURE,
          PackageInstaller.STATUS_FAILURE_ABORTED,
          PackageInstaller.STATUS_FAILURE_BLOCKED,
          PackageInstaller.STATUS_FAILURE_CONFLICT,
          PackageInstaller.STATUS_FAILURE_INCOMPATIBLE,
          PackageInstaller.STATUS_FAILURE_INVALID,
          PackageInstaller.STATUS_FAILURE_STORAGE,
          PackageInstaller.STATUS_FAILURE_TIMEOUT,
          -> unregisterStatusReceiver(sessionId)
        }
      }
    }

    activeReceivers[sessionId] = receiver
    val filter = IntentFilter(sessionStatusAction(sessionId))
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      activity.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
    } else {
      @Suppress("DEPRECATION")
      activity.registerReceiver(receiver, filter)
    }
  }

  private fun unregisterStatusReceiver(sessionId: Int) {
    val receiver = activeReceivers.remove(sessionId) ?: return
    runCatching { activity.unregisterReceiver(receiver) }
  }

  private fun createStatusPendingIntent(sessionId: Int): PendingIntent {
    val intent = Intent(sessionStatusAction(sessionId)).apply {
      setPackage(activity.packageName)
    }
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
    return PendingIntent.getBroadcast(activity, sessionId, intent, flags)
  }

  private fun sessionStatusAction(sessionId: Int): String {
    return "${activity.packageName}.EXTENSION_INSTALL_STATUS.$sessionId"
  }

  private fun resolveSourceUri(installArtifact: String): Uri {
    val trimmed = installArtifact.trim()
    return when {
      trimmed.startsWith(CONTENT_URI_PREFIX) -> Uri.parse(trimmed)
      trimmed.startsWith(FILE_URI_PREFIX) -> Uri.parse(trimmed)
      trimmed.startsWith(HTTP_URI_PREFIX, ignoreCase = true) ||
        trimmed.startsWith(HTTPS_URI_PREFIX, ignoreCase = true) ->
        downloadRemoteArtifactToCacheOffMainThread(trimmed)
      else -> Uri.fromFile(File(trimmed))
    }
  }

  private fun downloadRemoteArtifactToCacheOffMainThread(artifactUrl: String): Uri {
    if (Looper.myLooper() != Looper.getMainLooper()) {
      return downloadRemoteArtifactToCache(artifactUrl)
    }

    val future = networkExecutor.submit<Uri> { downloadRemoteArtifactToCache(artifactUrl) }
    return try {
      future.get()
    } catch (exception: ExecutionException) {
      val cause = exception.cause
      if (cause is Exception) {
        throw cause
      }
      throw exception
    }
  }

  private fun downloadRemoteArtifactToCache(artifactUrl: String): Uri {
    val tempFile = File.createTempFile(REMOTE_APK_PREFIX, REMOTE_APK_SUFFIX, activity.cacheDir)
    val connection = URL(artifactUrl).openConnection() as HttpURLConnection

    try {
      connection.instanceFollowRedirects = true
      connection.connectTimeout = NETWORK_CONNECT_TIMEOUT_MS
      connection.readTimeout = NETWORK_READ_TIMEOUT_MS
      connection.connect()

      if (connection.responseCode !in HTTP_OK_MIN..HTTP_OK_MAX) {
        throw FileNotFoundException(
          "Could not download install artifact (HTTP ${connection.responseCode}).",
        )
      }

      connection.inputStream.use { source ->
        tempFile.outputStream().use { target ->
          source.copyTo(target)
        }
      }

      return Uri.fromFile(tempFile)
    } catch (exception: Exception) {
      // Ensure no partial APK remains in cache if download fails.
      runCatching { tempFile.delete() }
      throw exception
    } finally {
      connection.disconnect()
    }
  }

  private companion object {
    const val REQUEST_INSTALL_PACKAGES_PERMISSION =
      "android.permission.REQUEST_INSTALL_PACKAGES"
    const val INSTALL_ENTRY_BASE_APK = "base.apk"
    const val CONTENT_URI_PREFIX = "content://"
    const val FILE_URI_PREFIX = "file://"
    const val HTTP_URI_PREFIX = "http://"
    const val HTTPS_URI_PREFIX = "https://"
    const val REMOTE_APK_PREFIX = "extension_install_"
    const val REMOTE_APK_SUFFIX = ".apk"
    const val NETWORK_CONNECT_TIMEOUT_MS = 15_000
    const val NETWORK_READ_TIMEOUT_MS = 30_000
    const val HTTP_OK_MIN = 200
    const val HTTP_OK_MAX = 299
    val networkExecutor = Executors.newSingleThreadExecutor()
  }

  private val activeReceivers = mutableMapOf<Int, BroadcastReceiver>()
}

/** Exception thrown when extension install session setup or commit fails. */
class ExtensionInstallException(
  val code: String,
  override val message: String,
  override val cause: Throwable? = null,
) : RuntimeException(message, cause)

/** Structured install operation result returned over the Flutter bridge. */
data class InstallOperationResult(
  val state: String,
  val sessionId: Int?,
  val message: String,
) {
  companion object {
    fun committed(sessionId: Int): InstallOperationResult {
      return InstallOperationResult(
        state = InstallStateValues.committed,
        sessionId = sessionId,
        message = "Install session committed.",
      )
    }
  }

  fun toMap(): Map<String, Any?> {
    return mapOf(
      "state" to state,
      "sessionId" to sessionId,
      "message" to message,
    )
  }
}

/** Canonical install state values exchanged across the native bridge. */
object InstallStateValues {
  const val committed = "committed"
  const val requiresUserAction = "requires_user_action"
}