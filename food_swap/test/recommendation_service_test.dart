import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/services/recommendation_service.dart';

void main() {
  final service = RecommendationService();

  test('maps every Nutri-Score grade and unknown grade correctly', () {
    expect(score(nutriScore: 'a'), 100);
    expect(score(nutriScore: 'B'), 80);
    expect(score(nutriScore: 'c'), 60);
    expect(score(nutriScore: 'D'), 40);
    expect(score(nutriScore: 'e'), 20);
    expect(score(nutriScore: null), 50);
    expect(score(nutriScore: 'unknown'), 50);
  });

  test('applies sugar adjustments at every boundary', () {
    expect(score(sugar: 5), 55);
    expect(score(sugar: 5.1), 52);
    expect(score(sugar: 10), 52);
    expect(score(sugar: 10.1), 50);
    expect(score(sugar: 20), 50);
    expect(score(sugar: 20.1), 40);
  });

  test('applies saturated fat adjustments at every boundary', () {
    expect(score(saturatedFat: 1), 54);
    expect(score(saturatedFat: 1.1), 51);
    expect(score(saturatedFat: 5), 51);
    expect(score(saturatedFat: 5.1), 50);
    expect(score(saturatedFat: 10), 50);
    expect(score(saturatedFat: 10.1), 42);
  });

  test('applies salt adjustments at every boundary', () {
    expect(score(salt: 0.3), 54);
    expect(score(salt: 0.31), 51);
    expect(score(salt: 1), 51);
    expect(score(salt: 1.1), 50);
    expect(score(salt: 2), 50);
    expect(score(salt: 2.1), 42);
  });

  test('applies protein adjustments at every boundary', () {
    expect(score(protein: 4.9), 50);
    expect(score(protein: 5), 52);
    expect(score(protein: 9.9), 52);
    expect(score(protein: 10), 54);
  });

  test('ignores null, negative, and non-finite nutrition values safely', () {
    expect(score(), 50);
    expect(score(sugar: -1), 50);
    expect(score(protein: -1), 50);
    expect(score(sugar: double.infinity), 50);
    expect(score(saturatedFat: double.nan), 50);
    expect(score(salt: double.negativeInfinity), 50);
  });

  test('clamps a score above 100', () {
    expect(
      score(nutriScore: 'a', sugar: 5, saturatedFat: 1, salt: 0.3, protein: 10),
      100,
    );
  });

  test('returns reasons only for matching positive nutrition boundaries', () {
    final result = service.rankProducts([
      createProduct(
        name: 'Strong Choice',
        nutriScore: 'a',
        nutrition: Nutrition(sugar: 5, saturatedFat: 1, salt: 0.3, protein: 10),
      ),
    ]).single;

    expect(result.reasons, [
      'Nutri-Score A',
      'Low sugar',
      'Low saturated fat',
      'Low salt',
      'Good protein',
    ]);
  });

  test('does not add reasons for worse, missing, or out-of-range values', () {
    final result = service.rankProducts([
      createProduct(
        name: 'Neutral Choice',
        nutriScore: 'unknown',
        nutrition: Nutrition(sugar: 6, saturatedFat: 2, salt: 0.5, protein: 4),
      ),
    ]).single;

    expect(result.reasons, isEmpty);
  });

  test('ranks by score and uses deterministic name and code tie-breakers', () {
    final products = [
      createProduct(name: 'Zed', code: 'z', nutriScore: 'c'),
      createProduct(name: 'Alpha', code: 'a', nutriScore: 'c'),
      createProduct(name: 'Same', code: 'z-code', nutriScore: 'c'),
      createProduct(name: 'Same', code: 'a-code', nutriScore: 'c'),
    ];

    final ranked = service.rankProducts(products);

    expect(ranked.map((result) => result.product.name).toList(), [
      'Alpha',
      'Same',
      'Same',
      'Zed',
    ]);
    expect(ranked[1].product.code, 'a-code');
    expect(ranked[2].product.code, 'z-code');
    expect(products.first.name, 'Zed');
  });
}

int score({
  String? nutriScore,
  double? protein,
  double? sugar,
  double? saturatedFat,
  double? salt,
}) {
  return RecommendationService().calculateScore(
    createProduct(
      nutriScore: nutriScore,
      nutrition: Nutrition(
        protein: protein,
        sugar: sugar,
        saturatedFat: saturatedFat,
        salt: salt,
      ),
    ),
  );
}

Product createProduct({
  String name = 'Product',
  String code = 'code',
  String? nutriScore,
  Nutrition? nutrition,
}) {
  return Product(
    code: code,
    name: name,
    brand: 'FoodSwap',
    imageUrl: '',
    categories: const [],
    nutriScore: nutriScore,
    nutrition: nutrition ?? Nutrition(),
  );
}
