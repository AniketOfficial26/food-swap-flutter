import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nutrition.dart';
import '../models/product.dart';

class ProductCache {
  static const _productsKey = 'food_swap_products';
  static const _queryKey = 'food_swap_products_query';

  final Future<SharedPreferences>? preferences;

  ProductCache({this.preferences});

  Future<SharedPreferences> _getPreferences() {
    return preferences ?? SharedPreferences.getInstance();
  }

  Future<void> saveProducts(List<Product> products, {String? query}) async {
    final preferences = await _getPreferences();
    final productData = products.map(_productToJson).toList();
    await preferences.setString(_productsKey, jsonEncode(productData));

    if (query == null) {
      await preferences.remove(_queryKey);
    } else {
      await preferences.setString(_queryKey, _normaliseQuery(query));
    }
  }

  Future<List<Product>> loadProducts({String? query}) async {
    final preferences = await _getPreferences();
    final cachedData = preferences.getString(_productsKey);

    if (cachedData == null || cachedData.isEmpty) {
      return [];
    }

    if (query != null &&
        preferences.getString(_queryKey) != _normaliseQuery(query)) {
      return [];
    }

    try {
      final decodedData = jsonDecode(cachedData);
      if (decodedData is! List) {
        return [];
      }

      final products = <Product>[];
      for (final item in decodedData) {
        if (item is! Map) {
          continue;
        }

        try {
          products.add(_productFromJson(Map<String, dynamic>.from(item)));
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }

      return products;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Map<String, dynamic> _productToJson(Product product) {
    return {
      'code': product.code,
      'name': product.name,
      'brand': product.brand,
      'imageUrl': product.imageUrl,
      'categories': product.categories,
      'nutriScore': product.nutriScore,
      'nutrition': {
        'calories': product.nutrition.calories,
        'protein': product.nutrition.protein,
        'carbohydrates': product.nutrition.carbohydrates,
        'sugar': product.nutrition.sugar,
        'fat': product.nutrition.fat,
        'saturatedFat': product.nutrition.saturatedFat,
        'salt': product.nutrition.salt,
      },
    };
  }

  Product _productFromJson(Map<String, dynamic> json) {
    final nutritionData = json['nutrition'];
    final nutrition = nutritionData is Map
        ? Nutrition(
            calories: _toDouble(nutritionData['calories']),
            protein: _toDouble(nutritionData['protein']),
            carbohydrates: _toDouble(nutritionData['carbohydrates']),
            sugar: _toDouble(nutritionData['sugar']),
            fat: _toDouble(nutritionData['fat']),
            saturatedFat: _toDouble(nutritionData['saturatedFat']),
            salt: _toDouble(nutritionData['salt']),
          )
        : Nutrition();

    final categories = json['categories'];

    return Product(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown product',
      brand: json['brand']?.toString() ?? 'Unknown brand',
      imageUrl: json['imageUrl']?.toString() ?? '',
      categories: categories is List
          ? categories.map((item) => item.toString()).toList()
          : [],
      nutriScore: json['nutriScore']?.toString(),
      nutrition: nutrition,
    );
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

  String _normaliseQuery(String query) => query.trim().toLowerCase();
}
