import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_swap/repositories/food_repository.dart';
import 'package:food_swap/services/openfood_service.dart';
import 'package:food_swap/services/product_cache.dart';

void main() {
  group('OpenFoodService', () {
    test(
      'parses a successful response and keeps missing values safe',
      () async {
        final service = OpenFoodService(
          client: StubHttpClient(() async {
            return http.Response(
              '{"products":['
              '{"code":"123","product_name":"Granola",'
              '"brands":"FoodSwap", "categories_tags":["en:snacks"],'
              '"nutriments":{"proteins_100g":"8.5",'
              '"sugars_100g":"4"},"nutriscore_grade":"b"},'
              '{"code":"456"}'
              ']}',
              200,
            );
          }),
        );

        final products = await service.searchProducts('granola');

        expect(products, hasLength(2));
        expect(products.first.name, 'Granola');
        expect(products.first.nutrition.protein, 8.5);
        expect(products.first.nutrition.fat, isNull);
        expect(products.last.name, 'Unknown product');
        expect(products.last.brand, 'Unknown brand');
      },
    );

    test('skips malformed individual product entries', () async {
      final service = OpenFoodService(
        client: StubHttpClient(() async {
          return http.Response(
            '{"products":[{"code":"valid"}, "not a product", null]}',
            200,
          );
        }),
      );

      final products = await service.searchProducts('snack');

      expect(products, hasLength(1));
      expect(products.single.code, 'valid');
    });

    test('parses an empty products response without failing', () async {
      final service = OpenFoodService(
        client: StubHttpClient(
          () async => http.Response('{"products":[]}', 200),
        ),
      );

      expect(await service.searchProducts('nothing'), isEmpty);
    });

    test('throws a parsing exception for invalid JSON or products data', () {
      final invalidJsonService = OpenFoodService(
        client: StubHttpClient(() async => http.Response('{', 200)),
      );
      final missingProductsService = OpenFoodService(
        client: StubHttpClient(
          () async => http.Response('{"products":"wrong"}', 200),
        ),
      );

      expect(
        () => invalidJsonService.searchProducts('food'),
        throwsA(isA<FoodParsingException>()),
      );
      expect(
        () => missingProductsService.searchProducts('food'),
        throwsA(isA<FoodParsingException>()),
      );
    });
  });

  group('FoodRepository', () {
    test('does not let an older search overwrite the current cache', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final firstResponse = Completer<http.Response>();
      final secondResponse = Completer<http.Response>();
      final repository = FoodRepository(
        OpenFoodService(
          client: QueryHttpClient((query) {
            return query == 'first'
                ? firstResponse.future
                : secondResponse.future;
          }),
        ),
        cache: ProductCache(preferences: Future.value(preferences)),
      );

      final firstSearch = repository.searchProducts('first');
      final secondSearch = repository.searchProducts('second');
      secondResponse.complete(
        http.Response(
          '{"products":[{"code":"second","product_name":"Second"}]}',
          200,
        ),
      );
      await secondSearch;
      firstResponse.complete(
        http.Response(
          '{"products":[{"code":"first","product_name":"First"}]}',
          200,
        ),
      );
      await firstSearch;

      expect(
        await repositoryCache(preferences).loadProducts(query: 'second'),
        hasLength(1),
      );
      expect(
        await repositoryCache(preferences).loadProducts(query: 'first'),
        isEmpty,
      );
    });

    test('removes duplicate products from successful searches', () async {
      final repository = FoodRepository(
        OpenFoodService(
          client: StubHttpClient(
            () async => http.Response(
              '{"products":['
              '{"code":"same","product_name":"One"},'
              '{"code":"SAME","product_name":"Duplicate"},'
              '{"product_name":"No Code","brands":"Brand"},'
              '{"product_name":"No Code","brands":"Brand"}'
              ']}',
              200,
            ),
          ),
        ),
      );

      final result = await repository.searchProducts('food');

      expect(result.products.map((product) => product.name), [
        'One',
        'No Code',
      ]);
    });

    test('maps timeout and HTTP failures to application errors', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final emptyCache = ProductCache(preferences: Future.value(preferences));
      final timeoutService = OpenFoodService(
        client: StubHttpClient(
          () => Future<http.Response>.delayed(
            const Duration(milliseconds: 20),
            () => http.Response('{}', 200),
          ),
        ),
        timeout: const Duration(milliseconds: 1),
      );
      final timeoutRepository = FoodRepository(
        timeoutService,
        cache: emptyCache,
      );

      expect(
        () => timeoutRepository.searchProducts('food'),
        throwsA(
          isA<FoodRepositoryException>().having(
            (error) => error.message,
            'message',
            'Searching food timed out. Please try again.',
          ),
        ),
      );

      final errorRepository = FoodRepository(
        OpenFoodService(
          client: StubHttpClient(() async => http.Response('nope', 503)),
        ),
        cache: emptyCache,
      );

      expect(
        () => errorRepository.searchProducts('food'),
        throwsA(
          isA<FoodRepositoryException>().having(
            (error) => error.message,
            'message',
            'Food search is currently unavailable.',
          ),
        ),
      );
    });
  });
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

class QueryHttpClient extends http.BaseClient {
  final Future<http.Response> Function(String query) responseFactory;

  QueryHttpClient(this.responseFactory);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final query = request.url.queryParameters['search_terms'] ?? '';
    final response = await responseFactory(query);

    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

ProductCache repositoryCache(SharedPreferences preferences) {
  return ProductCache(preferences: Future.value(preferences));
}
