package com.example.yomu

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private companion object {
    const val CHANNEL_NAME = "yomu/extensions"
  }

  private lateinit var trustStorage: ExtensionTrustStorage
  private lateinit var extensionsHost: ExtensionsHost

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    trustStorage = ExtensionTrustStorage(this)
    extensionsHost = ExtensionsHost(
      activity = this,
      trustStorage = trustStorage,
    )

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_NAME
    ).setMethodCallHandler { call, result ->
      extensionsHost.handle(call, result)
    }
  }
}
