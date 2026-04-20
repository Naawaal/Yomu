import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../../../../core/failure.dart';
import '../mappers/extension_failure_mapper.dart';
import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/extension_repository.dart';
import 'bridge_extension_repository.dart';

/// Typed result adapter for extension repository operations.
///
/// This keeps the existing repository contract intact while offering an
/// Either-based path for callers that want typed failures.
class ExtensionRepositoryResultAdapter {
  /// Creates a typed result adapter around an existing repository.
  const ExtensionRepositoryResultAdapter(this._repository);

  final ExtensionRepository _repository;

  /// Returns available extensions as a typed result.
  Future<Either<Failure, List<ExtensionItem>>> getAvailableExtensions() async {
    try {
      final List<ExtensionItem> items = await _repository
          .getAvailableExtensions();
      return Right<Failure, List<ExtensionItem>>(items);
    } on MissingPluginException {
      return Left<Failure, List<ExtensionItem>>(
        ExtensionFailureMapper.mapDiscovery(
          MissingPluginException('missing plugin'),
        ),
      );
    } on PlatformException catch (exception) {
      return Left<Failure, List<ExtensionItem>>(
        ExtensionFailureMapper.mapDiscovery(exception),
      );
    } catch (error) {
      return Left<Failure, List<ExtensionItem>>(
        ExtensionFailureMapper.mapDiscovery(error),
      );
    }
  }

  /// Marks a package as trusted and returns a typed result.
  Future<Either<Failure, Unit>> trust(String packageName) async {
    try {
      await _repository.trust(packageName);
      return const Right<Failure, Unit>(unit);
    } on ExtensionTrustException catch (exception) {
      return Left<Failure, Unit>(ExtensionFailureMapper.mapTrust(exception));
    } on MissingPluginException {
      return Left<Failure, Unit>(
        ExtensionFailureMapper.mapTrust(
          MissingPluginException('missing plugin'),
        ),
      );
    } on PlatformException catch (exception) {
      return Left<Failure, Unit>(ExtensionFailureMapper.mapTrust(exception));
    } catch (error) {
      return Left<Failure, Unit>(ExtensionFailureMapper.mapTrust(error));
    }
  }

  /// Installs a package and returns a typed result.
  Future<Either<Failure, Unit>> install(
    String packageName, {
    String? installArtifact,
  }) async {
    try {
      await _repository.install(packageName, installArtifact: installArtifact);
      return const Right<Failure, Unit>(unit);
    } on ExtensionInstallException catch (exception) {
      return Left<Failure, Unit>(ExtensionFailureMapper.mapInstall(exception));
    } on MissingPluginException {
      return Left<Failure, Unit>(
        ExtensionFailureMapper.mapInstall(
          MissingPluginException('missing plugin'),
        ),
      );
    } on PlatformException catch (exception) {
      return Left<Failure, Unit>(ExtensionFailureMapper.mapInstall(exception));
    } catch (error) {
      return Left<Failure, Unit>(ExtensionFailureMapper.mapInstall(error));
    }
  }
}
