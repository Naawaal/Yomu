import 'package:flutter/services.dart';

import '../../../../core/bridge/extensions_host_client.dart';
import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/extension_repository.dart';

/// Install failure surfaced from native host install results.
class ExtensionInstallException implements Exception {
  /// Creates a typed install exception.
  const ExtensionInstallException({required this.code, required this.message});

  /// Stable machine-readable failure code.
  final String code;

  /// Human-readable failure message.
  final String message;

  @override
  String toString() => message;
}

/// Stable error codes produced by extension install operations.
abstract final class ExtensionInstallErrorCode {
  /// Native host accepted install request but user action is still required.
  static const String requiresUserAction = 'REQUIRES_USER_ACTION';

  /// Native host reports package already installed.
  static const String packageAlreadyInstalled = 'PACKAGE_ALREADY_INSTALLED';
}

/// Trust failure surfaced from native host trust verification.
class ExtensionTrustException implements Exception {
  /// Creates a typed trust exception.
  const ExtensionTrustException({required this.code, required this.message});

  /// Stable machine-readable failure code.
  final String code;

  /// Human-readable failure message.
  final String message;

  @override
  String toString() => message;
}

/// Bridge-backed extension repository using native platform channels.
class BridgeExtensionRepository implements ExtensionRepository {
  /// Creates a bridge-backed extension repository.
  const BridgeExtensionRepository({
    required ExtensionsHostClient hostClient,
    required ExtensionRepository fallbackRepository,
  }) : _hostClient = hostClient,
       _fallbackRepository = fallbackRepository;

  final ExtensionsHostClient _hostClient;
  final ExtensionRepository _fallbackRepository;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async {
    try {
      final ExtensionsHostRuntimeInfo runtimeInfo = await _hostClient
          .getRuntimeInfo();

      if (!_supportsList(runtimeInfo.capabilities)) {
        return _fallbackRepository.getAvailableExtensions();
      }

      final List<HostExtensionPayload> payloads = await _hostClient
          .listAvailableExtensions();

      return payloads
          .map(
            (HostExtensionPayload payload) => ExtensionItem(
              name: payload.name,
              packageName: payload.packageName,
              language: payload.language,
              versionName: payload.versionName,
              isInstalled: true,
              hasUpdate: payload.hasUpdate,
              isNsfw: payload.isNsfw,
              trustStatus: payload.isTrusted
                  ? ExtensionTrustStatus.trusted
                  : ExtensionTrustStatus.untrusted,
              installArtifact: payload.installArtifact,
              iconUrl: payload.iconUrl,
            ),
          )
          .toList(growable: false);
    } on MissingPluginException {
      return _fallbackRepository.getAvailableExtensions();
    } on PlatformException {
      return _fallbackRepository.getAvailableExtensions();
    }
  }

  @override
  Future<void> trust(String packageName) async {
    try {
      final ExtensionsHostRuntimeInfo runtimeInfo = await _hostClient
          .getRuntimeInfo();
      if (!_supportsTrust(runtimeInfo.capabilities)) {
        return _fallbackRepository.trust(packageName);
      }
      await _hostClient.trustExtension(packageName);
    } on MissingPluginException {
      await _fallbackRepository.trust(packageName);
    } on PlatformException catch (exception) {
      throw ExtensionTrustException(
        code: exception.code,
        message: exception.message ?? 'Trust failed.',
      );
    }
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {
    try {
      final ExtensionsHostRuntimeInfo runtimeInfo = await _hostClient
          .getRuntimeInfo();
      if (!_supportsInstall(runtimeInfo.capabilities)) {
        return _fallbackRepository.install(
          packageName,
          installArtifact: installArtifact,
        );
      }
      final HostInstallResult installResult = await _hostClient
          .installExtension(packageName, installArtifact: installArtifact);
      switch (installResult.state) {
        case HostInstallState.committed:
          return;
        case HostInstallState.requiresUserAction:
          throw ExtensionInstallException(
            code: ExtensionInstallErrorCode.requiresUserAction,
            message: installResult.message,
          );
      }
    } on MissingPluginException {
      await _fallbackRepository.install(
        packageName,
        installArtifact: installArtifact,
      );
    } on PlatformException catch (exception) {
      if (exception.code == ExtensionInstallErrorCode.packageAlreadyInstalled) {
        return;
      }

      final String? platformMessage = exception.message?.trim();
      throw ExtensionInstallException(
        code: exception.code,
        message: platformMessage?.isNotEmpty == true
            ? platformMessage!
            : 'Install failed (${exception.code}).',
      );
    }
  }
}

bool _supportsList(Set<String> capabilities) {
  if (capabilities.isEmpty) {
    return true;
  }

  return capabilities.contains(ExtensionsHostCapabilities.listAvailable) ||
      capabilities.contains(ExtensionsHostCapabilities.legacyListAvailable) ||
      capabilities.contains(
        ExtensionsHostCapabilities.legacyListAvailableMethod,
      );
}

bool _supportsTrust(Set<String> capabilities) {
  if (capabilities.isEmpty) return true;
  return capabilities.contains(ExtensionsHostCapabilities.trust);
}

bool _supportsInstall(Set<String> capabilities) {
  if (capabilities.isEmpty) return true;
  return capabilities.contains(ExtensionsHostCapabilities.install);
}
