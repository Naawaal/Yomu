---
name: flutter-builder
description: >
  Production Flutter code generation patterns and quality checklists. Use when implementing 
  any Flutter feature file — widgets, providers, repositories, use cases, or models. Contains 
  code templates, quality gates, and anti-pattern warnings specific to production Flutter development.
---

# Flutter Builder Skill

This skill provides concrete implementation patterns that the Builder agent must follow when generating Flutter code.

## Pre-Implementation Checklist

Before writing any file, answer these:
- [ ] Does a similar file already exist in the codebase? (`search/codebase`)
- [ ] What is the exact naming convention used in existing features?
- [ ] Which version of state management is this project using?
- [ ] Is there a barrel file (`index.dart`) to update?

## Widget Implementation Standards

### Page Template (Riverpod)
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  static const routePath = '/products';

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsNotifierProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Products'),
          ),
          productsAsync.when(
            loading: () => const SliverFillRemaining(
              child: _ProductsLoadingSkeleton(),
            ),
            error: (error, _) => SliverFillRemaining(
              child: ErrorStateWidget(
                message: error.toString(),
                onRetry: () => ref.invalidate(productsNotifierProvider),
              ),
            ),
            data: (products) => products.isEmpty
                ? const SliverFillRemaining(
                    child: EmptyStateWidget(
                      title: 'No Products',
                      description: 'Add your first product to get started.',
                      actionLabel: 'Add Product',
                    ),
                  )
                : SliverList.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) => ProductCard(
                      key: ValueKey(products[index].id),
                      product: products[index],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
```

### Page Template (BLoC)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsCubit>()..loadProducts(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          return switch (state) {
            ProductsLoading() => const _ProductsLoadingSkeleton(),
            ProductsError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<ProductsCubit>().loadProducts(),
              ),
            ProductsLoaded(:final products) when products.isEmpty =>
              const EmptyStateWidget(title: 'No Products', description: '...'),
            ProductsLoaded(:final products) => _ProductsList(products: products),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
```

### Widget Extraction Pattern
```dart
// ❌ WRONG — single massive build method
@override
Widget build(BuildContext context) {
  return Column(children: [
    // 200 lines of nested widgets
  ]);
}

// ✅ CORRECT — extracted private widgets
@override
Widget build(BuildContext context) {
  return Column(children: [
    _ProductHeader(product: product),
    const SizedBox(height: 16),
    _ProductPriceSection(price: product.price),
    const SizedBox(height: 24),
    _ProductActionButtons(onAddToCart: _handleAddToCart),
  ]);
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});
  final Product product;
  // ...
}
```

## Anti-Patterns to NEVER Use

```dart
// ❌ Hardcoded colors
Container(color: Colors.blue)
Container(color: Color(0xFF6750A4))

// ✅ Always use theme
Container(color: Theme.of(context).colorScheme.primary)

// ❌ Hardcoded text styles
Text('Title', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))

// ✅ Always use textTheme
Text('Title', style: Theme.of(context).textTheme.titleLarge)

// ❌ BuildContext after async gap
Future<void> submit() async {
  final result = await repository.save(data);
  Navigator.of(context).pop();  // ❌ context may be invalid
}

// ✅ Check mounted
Future<void> submit() async {
  final result = await repository.save(data);
  if (!mounted) return;  // ✅
  Navigator.of(context).pop();

// ❌ Business logic in widget
onPressed: () async {
  final products = await dio.get('/products');  // ❌
  setState(() => _products = products.data);
}

// ✅ Delegate to provider/cubit
onPressed: () => ref.read(productsNotifierProvider.notifier).loadProducts()

// ❌ Direct setState for shared state
onPressed: () => setState(() => _isLoading = true)  // ❌ if shared

// ✅ Riverpod or BLoC for shared state
onPressed: () => ref.read(loadingProvider.notifier).state = true

// ❌ Missing const constructors
Widget build(BuildContext context) {
  return Padding(  // ❌ should be const if no dynamic values
    padding: EdgeInsets.all(16),
    child: Text('Static text'),
  );
}

// ✅ Const everywhere possible
return const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Static text'),
)
```

## GoRouter Integration Pattern

```dart
// app_router.dart
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: ProductsPage.routePath,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProductsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          ),
      ),
    ),
    GoRoute(
      path: '${ProductDetailPage.routePath}/:id',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ProductDetailPage(id: state.pathParameters['id']!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      ),
    ),
  ],
);
```

## Test Templates

### Use Case Unit Test
```dart
// test/features/products/domain/usecases/get_products_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProducts useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProducts(mockRepository);
  });

  group('GetProducts', () {
    final tProducts = [
      const Product(id: '1', name: 'Test Product', price: 9.99),
    ];

    test('should return list of products from repository', () async {
      // Arrange
      when(() => mockRepository.getProducts())
          .thenAnswer((_) async => Right(tProducts));
      
      // Act
      final result = await useCase(const NoParams());
      
      // Assert
      expect(result, Right(tProducts));
      verify(() => mockRepository.getProducts()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      when(() => mockRepository.getProducts())
          .thenAnswer((_) async => const Left(ServerFailure()));
      
      // Act
      final result = await useCase(const NoParams());
      
      // Assert
      expect(result, const Left(ServerFailure()));
    });
  });
}
```

### Widget Test
```dart
// test/features/products/presentation/pages/products_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('ProductsPage', () {
    testWidgets('shows loading skeleton initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productsNotifierProvider.overrideWith(
              () => MockProductsNotifier(const AsyncLoading()),
            ),
          ],
          child: const MaterialApp(home: ProductsPage()),
        ),
      );
      
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('shows product list when loaded', (tester) async {
      final products = [
        const Product(id: '1', name: 'Product 1', price: 9.99),
      ];
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productsNotifierProvider.overrideWith(
              () => MockProductsNotifier(AsyncData(products)),
            ),
          ],
          child: const MaterialApp(home: ProductsPage()),
        ),
      );
      await tester.pump();
      
      expect(find.text('Product 1'), findsOneWidget);
    });

    testWidgets('shows error state and retry button on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productsNotifierProvider.overrideWith(
              () => MockProductsNotifier(
                AsyncError(Exception('Network error'), StackTrace.empty),
              ),
            ),
          ],
          child: const MaterialApp(home: ProductsPage()),
        ),
      );
      await tester.pump();
      
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
```

## Post-Build Verification Steps

After completing all TODOs, run:
```bash
# 1. Static analysis
flutter analyze

# 2. All tests pass
flutter test

# 3. Build compiles
flutter build apk --debug  # or ios/web depending on target

# 4. Format check
dart format --set-exit-if-changed lib/ test/
```

All four must pass before marking the pipeline as COMPLETE.
