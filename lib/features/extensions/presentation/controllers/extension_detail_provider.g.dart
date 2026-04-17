// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extension_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$extensionDetailHash() => r'80036a26bf2d1da5ea42e01c07dee74729bd17ec';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Resolves a single extension by package name from the loaded extension list.
///
/// Copied from [extensionDetail].
@ProviderFor(extensionDetail)
const extensionDetailProvider = ExtensionDetailFamily();

/// Resolves a single extension by package name from the loaded extension list.
///
/// Copied from [extensionDetail].
class ExtensionDetailFamily extends Family<AsyncValue<ExtensionItem?>> {
  /// Resolves a single extension by package name from the loaded extension list.
  ///
  /// Copied from [extensionDetail].
  const ExtensionDetailFamily();

  /// Resolves a single extension by package name from the loaded extension list.
  ///
  /// Copied from [extensionDetail].
  ExtensionDetailProvider call(String packageName) {
    return ExtensionDetailProvider(packageName);
  }

  @override
  ExtensionDetailProvider getProviderOverride(
    covariant ExtensionDetailProvider provider,
  ) {
    return call(provider.packageName);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'extensionDetailProvider';
}

/// Resolves a single extension by package name from the loaded extension list.
///
/// Copied from [extensionDetail].
class ExtensionDetailProvider
    extends AutoDisposeProvider<AsyncValue<ExtensionItem?>> {
  /// Resolves a single extension by package name from the loaded extension list.
  ///
  /// Copied from [extensionDetail].
  ExtensionDetailProvider(String packageName)
    : this._internal(
        (ref) => extensionDetail(ref as ExtensionDetailRef, packageName),
        from: extensionDetailProvider,
        name: r'extensionDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$extensionDetailHash,
        dependencies: ExtensionDetailFamily._dependencies,
        allTransitiveDependencies:
            ExtensionDetailFamily._allTransitiveDependencies,
        packageName: packageName,
      );

  ExtensionDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.packageName,
  }) : super.internal();

  final String packageName;

  @override
  Override overrideWith(
    AsyncValue<ExtensionItem?> Function(ExtensionDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExtensionDetailProvider._internal(
        (ref) => create(ref as ExtensionDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        packageName: packageName,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<AsyncValue<ExtensionItem?>> createElement() {
    return _ExtensionDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExtensionDetailProvider && other.packageName == packageName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, packageName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExtensionDetailRef on AutoDisposeProviderRef<AsyncValue<ExtensionItem?>> {
  /// The parameter `packageName` of this provider.
  String get packageName;
}

class _ExtensionDetailProviderElement
    extends AutoDisposeProviderElement<AsyncValue<ExtensionItem?>>
    with ExtensionDetailRef {
  _ExtensionDetailProviderElement(super.provider);

  @override
  String get packageName => (origin as ExtensionDetailProvider).packageName;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
