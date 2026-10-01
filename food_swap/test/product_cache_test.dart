import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/repositories/food_repository.dart';
import 'package:food_swap/services/openfood_service.dart';
import 'package:food_swap/services/product_cache.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and loads all product data', () async {
    final cache = await createCache();
    final product = createProduct();

    await cache.saveProducts([product]);
    final loadedProducts = await cache.loadProducts();

    expect(loadedProducts, hasLength(1));
    expect(loadedProducts.single.code, product.code);
    expect(loadedProducts.single.name, product.name);
    expect(loadedProducts.single.brand, product.brand);
    expect(loadedProducts.single.imageUrl, product.imageUrl);
    expect(loadedProducts.single.categories, product.categories);
    expect(loadedProducts.single.nutriScore, product.nutriScore);
    expect(loadedProducts.single.nutrition.protein, 8.5);
    expect(loadedProducts.single.nutrition.salt, 0.4);
  });

  test('returns an empty list for corrupted cache data', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('food_swap_products', 'not valid json');
    final cache = ProductCache(preferences: Future.value(preferences));

    expect(await cache.loadProducts(), isEmpty);
  });

  test('turns non-finite cached nutrition values into null', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'food_swap_products',
      '[{"code":"1","name":"Food","nutrition":{"protein":"Infinity"}}]',
    );
    final cache = ProductCache(preferences: Future.value(preferences));

    final products = await cache.loadProducts();

    expect(products.single.nutrition.protein, isNull);
  });

  test('does not return a cache entry for a different query', () async {
    final cache = await createCache();
    await cache.saveProducts([createProduct()], query: 'granola');

    expect(await cache.loadProducts(query: 'chips'), isEmpty);
    expect(await cache.loadProducts(query: 'GRANOLA'), hasLength(1));
  });

  test('successful network search saves products to cache', () async {
    final cache = await createCache();
    final repository = FoodRepository(successfulService(), cache: cache);

    final result = await repository.searchProducts('granola');
    final cachedProducts = await cache.loadProducts();

    expect(result.isFromCache, isFalse);
    expect(result.products.single.name, 'Granola');
    expect(cachedProducts.single.name, 'Granola');
  });

  test(
    'network failure returns cached products as an offline fallback',
    () async {
      final cache = await createCache();
      await cache.saveProducts([createProduct()], query: 'granola');
      final repository = FoodRepository(failingService(), cache: cache);

      final result = await repository.searchProducts('granola');

      expect(result.isFromCache, isTrue);
      expect(result.products.single.name, 'Cached Granola');
    },
  );

  test(
    'network failure without a cache still returns a repository error',
    () async {
      final repository = FoodRepository(
        failingService(),
        cache: await createCache(),
      );

      expect(
        () => repository.searchProducts('granola'),
        throwsA(isA<FoodRepositoryException>()),
      );
    },
  );
}

Future<ProductCache> createCache() async {
  final preferences = await SharedPreferences.getInstance();
  return ProductCache(preferences: Future.value(preferences));
}

OpenFoodService successfulService() {
  return OpenFoodService(
    client: StubHttpClient(
      () async => http.Response(
        '{"products":[{"code":"123","product_name":"Granola"}]}',
        200,
      ),
    ),
  );
}

OpenFoodService failingService() {
  return OpenFoodService(
    client: StubHttpClient(() async => http.Response('error', 503)),
  );
}

class StubHttpClient extends http.BaseClient {
  final Future<http.Response> Function() responseFactory;

  StubHttpClient(this.responseFactory);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await responseFactory();

    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

Product createProduct() {
  return Product(
    code: 'cached-123',
    name: 'Cached Granola',
    brand: 'FoodSwap',
    imageUrl: 'https://example.com/granola.png',
    categories: const ['en:snacks'],
    nutriScore: 'b',
    nutrition: Nutrition(
      calories: 400,
      protein: 8.5,
      carbohydrates: 60,
      sugar: 12,
      fat: 10,
      saturatedFat: 2,
      salt: 0.4,
    ),
  );
}
