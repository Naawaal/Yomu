---
name: flutter-architecture
description: >
  Clean architecture patterns for Flutter. Use this skill when planning a new Flutter 
  feature, deciding on folder structure, setting up dependency injection, or when 
  implementing domain/data/presentation layers. Covers entities, use cases, repositories, 
  models, and Riverpod/BLoC patterns.
---

# Flutter Clean Architecture Skill

## Canonical Folder Structure

```
lib/
├── core/
│   ├── error/
│   │   ├── failures.dart          # Sealed class of all Failure types
│   │   └── exceptions.dart        # Custom exception types
│   ├── usecases/
│   │   └── usecase.dart           # Abstract UseCase<T, Params> base class
│   ├── network/
│   │   └── network_info.dart
│   └── utils/
│       └── either.dart            # Or use dartz/fpdart package
│
├── features/
│   └── [feature_name]/
│       ├── domain/
│       │   ├── entities/          # Pure Dart, Equatable, immutable
│       │   ├── repositories/      # Abstract contracts only
│       │   └── usecases/          # One class per use case
│       ├── data/
│       │   ├── models/            # Extends entity, adds JSON serialization
│       │   ├── datasources/       # remote_datasource, local_datasource
│       │   └── repositories/     # Implements domain repository contract
│       └── presentation/
│           ├── providers/         # (Riverpod) or bloc/ (BLoC)
│           ├── pages/             # One file per screen
│           └── widgets/           # Feature-specific extracted widgets
│
├── shared/
│   ├── widgets/                   # App-wide reusable widgets
│   └── theme/
│       ├── app_theme.dart
│       └── app_colors.dart        # ONLY color seed — not raw colors
│
└── injection_container.dart       # GetIt registrations
```

## Entity Pattern
```dart
// domain/entities/product.dart
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, price, imageUrl];
}
```

## Repository Contract Pattern
```dart
// domain/repositories/product_repository.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, Unit>> createProduct(Product product);
}
```

## UseCase Pattern
```dart
// domain/usecases/get_products.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProducts implements UseCase<List<Product>, NoParams> {
  const GetProducts(this.repository);
  final ProductRepository repository;

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) {
    return repository.getProducts();
  }
}
```

## Model Pattern
```dart
// data/models/product_model.dart
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
```

## Repository Implementation Pattern
```dart
// data/repositories/product_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../datasources/product_local_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getProducts();
        await localDataSource.cacheProducts(products);
        return Right(products);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cached = await localDataSource.getCachedProducts();
        return Right(cached);
      } on CacheException {
        return const Left(CacheFailure('No cached data available'));
      }
    }
  }
}
```

## Failure Types
```dart
// core/error/failures.dart
import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure([this.message = 'An unexpected error occurred']);
  final String message;
  
  @override
  List<Object> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}
```

## Riverpod Provider Pattern
```dart
// presentation/providers/products_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';
import '../../../../injection_container.dart';

part 'products_provider.g.dart';

@riverpod
class ProductsNotifier extends _$ProductsNotifier {
  @override
  FutureOr<List<Product>> build() async {
    return _loadProducts();
  }

  Future<List<Product>> _loadProducts() async {
    final getProducts = ref.read(getProductsProvider);
    final result = await getProducts(const NoParams());
    return result.fold(
      (failure) => throw Exception(failure.message),
      (products) => products,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

## BLoC Pattern
```dart
// presentation/bloc/products_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';

part 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._getProducts) : super(ProductsInitial());
  
  final GetProducts _getProducts;

  Future<void> loadProducts() async {
    emit(ProductsLoading());
    final result = await _getProducts(const NoParams());
    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }
}

// State
part of 'products_cubit.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object> get props => [];
}
class ProductsInitial extends ProductsState {}
class ProductsLoading extends ProductsState {}
class ProductsLoaded extends ProductsState {
  const ProductsLoaded(this.products);
  final List<Product> products;
  @override List<Object> get props => [products];
}
class ProductsError extends ProductsState {
  const ProductsError(this.message);
  final String message;
  @override List<Object> get props => [message];
}
```

## Dependency Injection (GetIt)
```dart
// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features — Products
  // Providers/BLoC
  sl.registerFactory(() => ProductsCubit(sl()));
  
  // Use Cases
  sl.registerLazySingleton(() => GetProducts(sl()));
  
  // Repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  
  // Data Sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(sharedPreferences: sl()),
  );
  
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
```

## Core Packages (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management (choose one)
  flutter_bloc: ^8.1.6         # BLoC pattern
  # riverpod: ^2.5.1           # Riverpod pattern
  # riverpod_annotation: ^2.3.5
  
  # Functional Programming
  dartz: ^0.10.1               # Either, Option types
  # fpdart: ^1.1.0             # Modern alternative to dartz
  
  # DI
  get_it: ^7.7.0
  injectable: ^2.4.4
  
  # Networking
  dio: ^5.6.0
  
  # Local Storage
  shared_preferences: ^2.3.2
  hive_flutter: ^1.1.0
  
  # Utilities
  equatable: ^2.0.5
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  
  # UI
  animations: ^2.0.11          # M3 transitions
  shimmer: ^3.0.0              # Loading states
  cached_network_image: ^3.3.1
  go_router: ^14.2.7

dev_dependencies:
  build_runner: ^2.4.12
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  injectable_generator: ^2.6.2
  riverpod_generator: ^2.4.3   # If using Riverpod
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  bloc_test: ^9.1.7
```
