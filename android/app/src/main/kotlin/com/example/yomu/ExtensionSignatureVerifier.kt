package com.example.yomu

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import java.security.MessageDigest
import java.util.Locale

/** Verifies whether an installed extension package is signed by an allowed signer. */
class ExtensionSignatureVerifier(
  private val packageManager: PackageManager,
  private val hostPackageName: String,
) {
  /** Verifies an installed package against the host signer or an allowlisted signer digest. */
  fun verifyInstalledPackage(packageName: String): ExtensionSignatureVerification {
    return try {
      if (packageManager.checkSignatures(hostPackageName, packageName) == PackageManager.SIGNATURE_MATCH) {
        ExtensionSignatureVerification.trusted(
          signerDigests = readSignerDigests(packageName),
          message = "Package signer matches the host application signer.",
        )
      } else {
        val signerDigests = readSignerDigests(packageName)
        if (signerDigests.any { digest -> digest in ExtensionSignaturePolicy.trustedSignerDigests }) {
          ExtensionSignatureVerification.trusted(
            signerDigests = signerDigests,
            message = "Package signer matches the configured signer allowlist.",
          )
        } else {
          ExtensionSignatureVerification.untrusted(
            signerDigests = signerDigests,
            message = "Package signer does not match the host signer or configured signer allowlist.",
          )
        }
      }
    } catch (_: PackageManager.NameNotFoundException) {
      ExtensionSignatureVerification.untrusted(
        signerDigests = emptySet(),
        message = "Package was not found for signer verification.",
      )
    }
  }

  private fun readSignerDigests(packageName: String): Set<String> {
    val packageInfo = loadPackageInfo(packageName)
    val signatures = packageInfo.readSignatures()
    return signatures
      .asSequence()
      .map { signature -> signature.toSha256Digest() }
      .toSet()
  }

  private fun loadPackageInfo(packageName: String): PackageInfo {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      packageManager.getPackageInfo(
        packageName,
        PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong()),
      )
    } else {
      @Suppress("DEPRECATION")
      packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
    }
  }
}

/** Result of verifying an extension package signer against the active trust policy. */
data class ExtensionSignatureVerification(
  val isTrusted: Boolean,
  val signerDigests: Set<String>,
  val message: String,
) {
  companion object {
    fun trusted(
      signerDigests: Set<String>,
      message: String,
    ): ExtensionSignatureVerification {
      return ExtensionSignatureVerification(
        isTrusted = true,
        signerDigests = signerDigests,
        message = message,
      )
    }

    fun untrusted(
      signerDigests: Set<String>,
      message: String,
    ): ExtensionSignatureVerification {
      return ExtensionSignatureVerification(
        isTrusted = false,
        signerDigests = signerDigests,
        message = message,
      )
    }
  }
}

/** Secure default signer policy for extension verification. */
object ExtensionSignaturePolicy {
  /** Additional trusted signer digests encoded as uppercase SHA-256 hex strings. */
  val trustedSignerDigests: Set<String> = emptySet()
}

private fun PackageInfo.readSignatures(): Array<Signature> {
  return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
    val signingInfo = signingInfo ?: return emptyArray()
    if (signingInfo.hasMultipleSigners()) {
      signingInfo.apkContentsSigners
    } else {
      signingInfo.signingCertificateHistory ?: signingInfo.apkContentsSigners
    }
  } else {
    @Suppress("DEPRECATION")
    signatures ?: emptyArray()
  }
}

private fun Signature.toSha256Digest(): String {
  val digest = MessageDigest.getInstance("SHA-256").digest(toByteArray())
  return digest.joinToString(separator = "") { byte ->
    String.format(Locale.US, "%02X", byte)
  }
}