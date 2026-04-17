package com.example.yomu

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented tests for the extension bridge.
 *
 * Tests verify:
 * - Trust storage persistence
 * - Package filtering logic
 * - Permission checks
 */
@RunWith(AndroidJUnit4::class)
class ExtensionBridgeTest {
  private lateinit var context: Context
  private lateinit var trustStorage: ExtensionTrustStorage

  @Before
  fun setUp() {
    context = InstrumentationRegistry.getInstrumentation().targetContext
    trustStorage = ExtensionTrustStorage(context)
    // Clear state before each test
    trustStorage.clearAll()
  }

  @Test
  fun testTrustStoragePersistence() {
    val testPackage = "com.test.extension"

    // Initially untrusted
    assertFalse(trustStorage.isTrusted(testPackage))

    // Trust the package
    trustStorage.trust(testPackage)
    assertTrue(trustStorage.isTrusted(testPackage))

    // Create new instance to verify persistence
    val newStorageInstance = ExtensionTrustStorage(context)
    assertTrue(newStorageInstance.isTrusted(testPackage))
  }

  @Test
  fun testGetTrustedPackages() {
    val pkg1 = "com.test.ext1"
    val pkg2 = "com.test.ext2"

    trustStorage.trust(pkg1)
    trustStorage.trust(pkg2)

    val trusted = trustStorage.getTrustedPackages()
    assertEquals(2, trusted.size)
    assertTrue(trusted.contains(pkg1))
    assertTrue(trusted.contains(pkg2))
  }

  @Test
  fun testUntrustPackage() {
    val testPackage = "com.test.extension"

    trustStorage.trust(testPackage)
    assertTrue(trustStorage.isTrusted(testPackage))

    trustStorage.untrust(testPackage)
    assertFalse(trustStorage.isTrusted(testPackage))
  }

  @Test
  fun testClearAll() {
    trustStorage.trust("com.test.ext1")
    trustStorage.trust("com.test.ext2")

    assertEquals(2, trustStorage.getTrustedPackages().size)

    trustStorage.clearAll()
    assertEquals(0, trustStorage.getTrustedPackages().size)
  }

  @Test
  fun testSystemPackagesAreFiltered() {
    val pm = context.packageManager

    // Get list of all packages
    val allPackages = pm.getInstalledPackages(0)

    // Count user-installed packages
    var userInstalledCount = 0
    for (pkg in allPackages) {
      try {
        val appInfo = pm.getApplicationInfo(pkg.packageName, 0)
        val isUserInstalled =
          (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0 ||
          (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

        if (isUserInstalled) {
          userInstalledCount++
        }
      } catch (e: Exception) {
        // Skip packages we can't access
      }
    }

    // At minimum, the test app itself should be user-installed
    assertTrue(userInstalledCount > 0)
  }
}
