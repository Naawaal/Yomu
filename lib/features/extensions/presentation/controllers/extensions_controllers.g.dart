// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extensions_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$extensionRepositoryHash() =>
    r'1c594ac6cd1c690485d71190a2245bf25b00ea79';

/// Provides the composed extension repository implementation.
///
/// Copied from [extensionRepository].
@ProviderFor(extensionRepository)
final extensionRepositoryProvider =
    AutoDisposeProvider<ExtensionRepository>.internal(
      extensionRepository,
      name: r'extensionRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$extensionRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExtensionRepositoryRef = AutoDisposeProviderRef<ExtensionRepository>;
String _$extensionsListControllerHash() =>
    r'93b00f6bb8684f19a178366e1384d0b8790b9dea';

/// Loads extension list state.
///
/// Copied from [ExtensionsListController].
@ProviderFor(ExtensionsListController)
final extensionsListControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      ExtensionsListController,
      List<ExtensionItem>
    >.internal(
      ExtensionsListController.new,
      name: r'extensionsListControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$extensionsListControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ExtensionsListController =
    AutoDisposeAsyncNotifier<List<ExtensionItem>>;
String _$extensionActionControllerHash() =>
    r'75b7894eb70da463569f2554231749687d77a171';

/// Handles mutating extension actions.
///
/// Copied from [ExtensionActionController].
@ProviderFor(ExtensionActionController)
final extensionActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExtensionActionController, void>.internal(
      ExtensionActionController.new,
      name: r'extensionActionControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$extensionActionControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ExtensionActionController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
