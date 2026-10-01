import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/nutrition.dart';
import '../models/product.dart';

class FoodNetworkException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const FoodNetworkException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => message;
}

class FoodTimeoutException extends FoodNetworkException {
  const FoodTimeoutException(super.message, {super.cause});
}

class FoodParsingException extends FoodNetworkException {
  const FoodParsingException(super.message, {super.cause});
}

class OpenFoodService {
  static const _maxAutomaticRetries = 2;
  static const _transientStatusCodes = {429, 500, 502, 503, 504};

  final http.Client _client;
  final Duration timeout;

  OpenFoodService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       assert(timeout > Duration.zero);

  Future<List<Product>> searchProducts(String query) async {
    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'action': 'process',
      'search_terms': query,
      'search_simple': '1',
      'json': 'true',
      'page_size': '10',
      'fields':
          'code,product_name,brands,image_url,'
          'categories_tags,nutriscore_grade,nutriments',
    });

    final response = await _get(uri);
    return _productsFromResponse(response);
  }

  Future<List<Product>> searchSimilarProducts(Product selectedProduct) async {
    if (selectedProduct.categories.isEmpty) {
      return [];
    }

    final category = selectedProduct.categories.last
        .replaceFirst(RegExp(r'^en:'), '')
        .replaceAll('-', ' ');

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'action': 'process',
      'categories_tags_en': category,
      'json': 'true',
      'page_size': '20',
      'fields':
          'code,product_name,brands,image_url,'
          'categories_tags,nutriscore_grade,nutriments',
    });

    final response = await _get(uri);
    return _productsFromResponse(response)
        .where((product) => product.code != selectedProduct.code)
        .toList();
  }

  Future<http.Response> _get(Uri uri) async {
    for (var retry = 0; retry <= _maxAutomaticRetries; retry++) {
      try {
        final response = await _client
            .get(
              uri,
              headers: {
                'User-Agent':
                    'FoodSwap/1.0 (Android; contact: er.aniket200@gmail.com)',
                'Accept': 'application/json',
              },
            )
            .timeout(timeout);

        if (!_transientStatusCodes.contains(response.statusCode) ||
            retry == _maxAutomaticRetries) {
          return response;
        }

        await Future<void>.delayed(Duration(milliseconds: 800 * (1 << retry)));
      } on TimeoutException catch (error) {
        throw FoodTimeoutException(
          'The food service took too long to respond.',
          cause: error,
        );
      } on http.ClientException catch (error) {
        throw FoodNetworkException(
          'Unable to connect to the food service.',
          cause: error,
        );
      } on Exception catch (error) {
        throw FoodNetworkException(
          'Unable to connect to the food service.',
          cause: error,
        );
      }
    }

    throw StateError('HTTP retry loop completed without a response.');
  }

  List<Product> _productsFromResponse(http.Response response) {
    if (response.statusCode != 200) {
      final body = response.body;

      throw FoodNetworkException(
        'HTTP ${response.statusCode}: '
        '${body.length > 300 ? body.substring(0, 300) : body}',
        statusCode: response.statusCode,
      );
    }

    final dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw FoodParsingException(
        'The food service returned invalid JSON.',
        cause: error,
      );
    }

    if (data is! Map<String, dynamic>) {
      throw const FoodParsingException(
        'The food service returned an unexpected response.',
      );
    }

    final rawProducts = data['products'];
    if (rawProducts is! List) {
      throw const FoodParsingException(
        'The food service response did not contain products.',
      );
    }

    final products = <Product>[];
    for (final rawProduct in rawProducts) {
      if (rawProduct is! Map) {
        continue;
      }

      try {
        products.add(_productFromJson(Map<String, dynamic>.from(rawProduct)));
      } on FormatException {
        // Ignore one malformed product and keep the valid products.
        continue;
      } on TypeError {
        // Ignore one malformed product and keep the valid products.
        continue;
      }
    }

    return products;
  }

  Product _productFromJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] is Map
        ? Map<String, dynamic>.from(json['nutriments'] as Map)
        : <String, dynamic>{};

    final nutrition = Nutrition(
      calories: _toDouble(nutriments['energy-kcal_100g']),
      protein: _toDouble(nutriments['proteins_100g']),
      carbohydrates: _toDouble(nutriments['carbohydrates_100g']),
      sugar: _toDouble(nutriments['sugars_100g']),
      fat: _toDouble(nutriments['fat_100g']),
      saturatedFat: _toDouble(nutriments['saturated-fat_100g']),
      salt: _toDouble(nutriments['salt_100g']),
    );

    return Product(
      code: json['code']?.toString() ?? '',
      name: json['product_name']?.toString() ?? 'Unknown product',
      brand: json['brands']?.toString() ?? 'Unknown brand',
      imageUrl: json['image_url']?.toString() ?? '',
      categories: _parseCategories(json['categories_tags']),
      nutriScore: json['nutriscore_grade']?.toString(),
      nutrition: nutrition,
    );
  }

  List<String> _parseCategories(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      final number = value.toDouble();
      return number.isFinite ? number : null;
    }

    final number = double.tryParse(value.toString());
    return number != null && number.isFinite ? number : null;
  }
}
