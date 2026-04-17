# Extensions Contract

This feature now supports Android-native extension discovery, trust, and install flows through the `yomu/extensions` MethodChannel.

## Extension Package Requirements

Android extension packages should expose Yomu metadata in their manifest application block.

Required metadata keys:

- `com.example.yomu.extension.ENABLED=true`
- `com.example.yomu.extension.SCHEMA_VERSION=1`

Optional metadata keys:

- `com.example.yomu.extension.NAME`
- `com.example.yomu.extension.LANGUAGE`
- `com.example.yomu.extension.NSFW`
- `com.example.yomu.extension.INSTALL_ARTIFACT`

These values are defined in [android/app/src/main/kotlin/com/example/yomu/ExtensionPackageContract.kt](android/app/src/main/kotlin/com/example/yomu/ExtensionPackageContract.kt).

## Discovery Contract

Yomu now prefers visibility-aware extension discovery.

Extension packages should expose an activity that responds to the discovery action:

- `com.example.yomu.extension.DISCOVER`

The host app declares a matching `<queries>` entry in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) and resolves packages through that action before falling back to a broader installed-package scan for backward compatibility.

## Trust Behavior

An extension is only treated as trusted in Flutter when both conditions are true:

- the package has been explicitly trusted by the user
- native signer verification still passes

Native trust verification currently accepts:

- packages signed with the same signer as the host app
- packages whose signer digest appears in the allowlist in [android/app/src/main/kotlin/com/example/yomu/ExtensionSignatureVerifier.kt](android/app/src/main/kotlin/com/example/yomu/ExtensionSignatureVerifier.kt)

Signer verification failures now surface into Flutter as typed trust failures instead of silently falling back to mock trust behavior.

## Install Contract

Install requests require an explicit install artifact string. The current bridge accepts values such as:

- `content://...`
- `file://...`
- absolute file paths

The artifact is threaded through:

- [lib/core/bridge/extensions_host_client.dart](lib/core/bridge/extensions_host_client.dart)
- [lib/features/extensions/data/repositories/bridge_extension_repository.dart](lib/features/extensions/data/repositories/bridge_extension_repository.dart)
- [android/app/src/main/kotlin/com/example/yomu/ExtensionsHost.kt](android/app/src/main/kotlin/com/example/yomu/ExtensionsHost.kt)
- [android/app/src/main/kotlin/com/example/yomu/ExtensionInstallManager.kt](android/app/src/main/kotlin/com/example/yomu/ExtensionInstallManager.kt)

On Android, install uses a `PackageInstaller` session and can return structured states such as committed or requires-user-action.

## Flutter Mapping

Flutter currently maps native extension payloads into the presentation model in [lib/features/extensions/data/repositories/bridge_extension_repository.dart](lib/features/extensions/data/repositories/bridge_extension_repository.dart).

Relevant behaviors:

- native trusted payloads map to `ExtensionTrustStatus.trusted`
- native untrusted payloads map to `ExtensionTrustStatus.untrusted`
- native trust verification failures raise `ExtensionTrustException`
- native install failures raise `ExtensionInstallException`

Fallback behavior is still preserved for unsupported capabilities and missing-plugin/runtime cases.
