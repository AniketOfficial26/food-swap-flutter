import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/services/product_filter_sort_service.dart';

void main() {
  final service = ProductFilterSortService();

  test('sorts products by FoodSwap Score from highest to lowest', () {
    final products = [
      createProduct('Cereal', nutriScore: 'c'),
      createProduct('Fruit Bar', nutriScore: 'a'),
      createProduct('Snack', nutriScore: 'e'),
    ];

    final sorted = service.filterAndSortProducts(
      products: products,
      sortBy: ProductSortOption.foodSwapScore,
    );

    expect(sorted.map((product) => product.name).toList(), [
      'Fruit Bar',
      'Cereal',
      'Snack',
    ]);
  });

  test('sorts by protein and puts missing values last', () {
    final products = [
      createProduct('Missing Protein'),
      createProduct('Medium Protein', protein: 5),
      createProduct('High Protein', protein: 12),
    ];

    final sorted = service.filterAndSortProducts(
      products: products,
      sortBy: ProductSortOption.protein,
    );

    expect(sorted.map((product) => product.name).toList(), [
      'High Protein',
      'Medium Protein',
      'Missing Protein',
    ]);
  });

  test('sorts by sugar from lowest to highest', () {
    final products = [
      createProduct('Sweet', sugar: 18),
      createProduct('Low Sugar', sugar: 2),
      createProduct('Medium Sugar', sugar: 8),
    ];

    final sorted = service.filterAndSortProducts(
      products: products,
      sortBy: ProductSortOption.sugar,
    );

    expect(sorted.map((product) => product.name).toList(), [
      'Low Sugar',
      'Medium Sugar',
      'Sweet',
    ]);
  });

  test('filters products by category', () {
    final products = [
      createProduct('Crisps', categories: ['en:snacks']),
      createProduct('Juice', categories: ['en:drinks']),
    ];

    final filtered = service.filterAndSortProducts(
      products: products,
      category: 'snacks',
    );

    expect(filtered.map((product) => product.name), ['Crisps']);
  });

  test('filters products by Nutri-Score', () {
    final products = [
      createProduct('Healthy Bar', nutriScore: 'A'),
      createProduct('Sweet Bar', nutriScore: 'E'),
      createProduct('Unknown Bar'),
    ];

    final filtered = service.filterAndSortProducts(
      products: products,
      nutriScore: 'a',
    );

    expect(filtered.map((product) => product.name), ['Healthy Bar']);
  });

  test('does not change the original product list', () {
    final products = [
      createProduct('Low Protein', protein: 2),
      createProduct('High Protein', protein: 20),
    ];

    service.filterAndSortProducts(
      products: products,
      sortBy: ProductSortOption.protein,
    );

    expect(products.map((product) => product.name).toList(), [
      'Low Protein',
      'High Protein',
    ]);
  });
}

Product createProduct(
  String name, {
  String? nutriScore,
  double? protein,
  double? sugar,
  List<String> categories = const [],
}) {
  return Product(
    code: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    brand: 'FoodSwap',
    imageUrl: '',
    categories: categories,
    nutriScore: nutriScore,
    nutrition: Nutrition(protein: protein, sugar: sugar),
  );
}
