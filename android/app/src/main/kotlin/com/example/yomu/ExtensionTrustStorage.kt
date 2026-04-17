package com.example.yomu

import android.content.Context
import android.content.SharedPreferences

/**
 * Manages trusted extension packages using SharedPreferences.
 *
 * Provides persistence for extension trust state across app sessions.
 */
class ExtensionTrustStorage(context: Context) {
  private companion object {
    const val PREFS_NAME = "extension_trust_storage"
    const val TRUSTED_PACKAGES_KEY = "trusted_packages_set"
  }

  private val prefs: SharedPreferences =
    context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

  /**
   * Checks if an extension package is marked as trusted.
   *
   * @param packageName The package name to check.
   * @return True if trusted, false otherwise.
   */
  fun isTrusted(packageName: String): Boolean {
    val trusted = prefs.getStringSet(TRUSTED_PACKAGES_KEY, emptySet()) ?: emptySet()
    return trusted.contains(packageName)
  }

  /**
   * Marks an extension package as trusted.
   *
   * @param packageName The package name to trust.
   */
  fun trust(packageName: String) {
    val trusted = prefs.getStringSet(TRUSTED_PACKAGES_KEY, mutableSetOf())?.toMutableSet()
      ?: mutableSetOf()
    trusted.add(packageName)
    prefs.edit().putStringSet(TRUSTED_PACKAGES_KEY, trusted).apply()
  }

  /**
   * Removes trust from an extension package.
   *
   * @param packageName The package name to untrust.
   */
  fun untrust(packageName: String) {
    val trusted = prefs.getStringSet(TRUSTED_PACKAGES_KEY, mutableSetOf())?.toMutableSet()
      ?: mutableSetOf()
    trusted.remove(packageName)
    prefs.edit().putStringSet(TRUSTED_PACKAGES_KEY, trusted).apply()
  }

  /**
   * Retrieves all trusted extension packages.
   *
   * @return Set of trusted package names.
   */
  fun getTrustedPackages(): Set<String> {
    return prefs.getStringSet(TRUSTED_PACKAGES_KEY, emptySet()) ?: emptySet()
  }

  /**
   * Clears all trusted extensions.
   */
  fun clearAll() {
    prefs.edit().remove(TRUSTED_PACKAGES_KEY).apply()
  }
}
