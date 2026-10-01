import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/providers/food_providers.dart';
import 'package:food_swap/providers/product_search_provider.dart';
import 'package:food_swap/repositories/food_repository.dart';
import 'package:food_swap/services/openfood_service.dart';

void main() {
  test('starts in the idle state', () {
    final container = createContainer(FakeFoodRepository((_) async => []));
    addTearDown(container.dispose);

    expect(container.read(productSearchProvider), isA<ProductSearchIdle>());
  });

  test('emits a successful state with products', () async {
    final product = createProduct('Granola');
    final container = createContainer(
      FakeFoodRepository((_) async => [product]),
    );
    addTearDown(container.dispose);

    container.read(productSearchProvider.notifier).searchProducts('granola');
    await waitForDebounce();

    final state = container.read(productSearchProvider);
    expect(state, isA<ProductSearchSuccess>());
    expect((state as ProductSearchSuccess).products, [product]);
  });

  test(
    'keeps an empty repository result as a successful empty state',
    () async {
      final container = createContainer(FakeFoodRepository((_) async => []));
      addTearDown(container.dispose);

      container.read(productSearchProvider.notifier).searchProducts('unknown');
      await waitForDebounce();

      final state = container.read(productSearchProvider);
      expect(state, isA<ProductSearchSuccess>());
      expect((state as ProductSearchSuccess).products, isEmpty);
    },
  );

  test('emits a user-friendly error when the repository fails', () async {
    final container = createContainer(
      FakeFoodRepository(
        (_) async => throw const FoodRepositoryException(
          'Food search is currently unavailable.',
        ),
      ),
    );
    addTearDown(container.dispose);

    container.read(productSearchProvider.notifier).searchProducts('food');
    await waitForDebounce();

    final state = container.read(productSearchProvider);
    expect(state, isA<ProductSearchError>());
    expect(
      (state as ProductSearchError).message,
      'Food search is currently unavailable.',
    );
  });

  test('only searches for the final query after rapid input', () async {
    final queries = <String>[];
    final container = createContainer(
      FakeFoodRepository((query) async {
        queries.add(query);
        return [];
      }),
    );
    addTearDown(container.dispose);

    final controller = container.read(productSearchProvider.notifier);
    controller.searchProducts('K');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    controller.searchProducts('Ku');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    controller.searchProducts('Kur');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    controller.searchProducts('Kurkure');

    await waitForDebounce();

    expect(queries, ['Kurkure']);
  });

  test('an empty query keeps the existing empty success behavior', () {
    final container = createContainer(FakeFoodRepository((_) async => []));
    addTearDown(container.dispose);

    container.read(productSearchProvider.notifier).searchProducts('');

    final state = container.read(productSearchProvider);
    expect(state, isA<ProductSearchSuccess>());
    expect((state as ProductSearchSuccess).products, isEmpty);
  });

  test('trims a query before sending it to the repository', () async {
    final queries = <String>[];
    final container = createContainer(
      FakeFoodRepository((query) async {
        queries.add(query);
        return [];
      }),
    );
    addTearDown(container.dispose);

    container.read(productSearchProvider.notifier).searchProducts('  milk  ');
    await waitForDebounce();

    expect(queries, ['milk']);
  });

  test(
    'a stale in-flight search cannot replace a newer search result',
    () async {
      final firstResponse = Completer<List<Product>>();
      final secondResponse = Completer<List<Product>>();
      final container = createContainer(
        FakeFoodRepository((query) {
          return query == 'first'
              ? firstResponse.future
              : secondResponse.future;
        }),
      );
      addTearDown(container.dispose);

      final controller = container.read(productSearchProvider.notifier);
      controller.searchProducts('first');
      await Future<void>.delayed(const Duration(milliseconds: 450));

      controller.searchProducts('second');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      secondResponse.complete([createProduct('Second result')]);
      await pumpEventQueue();

      expect(
        (container.read(
          productSearchProvider,
        ) as ProductSearchSuccess).products.single.name,
        'Second result',
      );

      firstResponse.complete([createProduct('Stale result')]);
      await pumpEventQueue();

      expect(
        (container.read(
          productSearchProvider,
        ) as ProductSearchSuccess).products.single.name,
        'Second result',
      );
    },
  );
}

Future<void> waitForDebounce() {
  return Future<void>.delayed(const Duration(milliseconds: 450));
}

ProviderContainer createContainer(FoodRepository repository) {
  return ProviderContainer(
    overrides: [foodRepositoryProvider.overrideWithValue(repository)],
  );
}

class FakeFoodRepository extends FoodRepository {
  final Future<List<Product>> Function(String query) searchHandler;

  FakeFoodRepository(this.searchHandler) : super(OpenFoodService());

  @override
  Future<FoodRepositoryResult> searchProducts(String query) async {
    return FoodRepositoryResult(
      products: await searchHandler(query),
      isFromCache: false,
    );
  }
}

Product createProduct(String name) {
  return Product(
    code: name.toLowerCase(),
    name: name,
    brand: 'FoodSwap',
    imageUrl: '',
    categories: const [],
    nutrition: Nutrition(),
  );
}
