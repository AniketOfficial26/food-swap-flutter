import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/screens/product_details.dart';

void main() {
  testWidgets('product information and FoodSwap Score appear', (tester) async {
    final product = createProduct(
      name: 'Granola',
      brand: 'FoodSwap Foods',
      nutriScore: 'b',
      nutrition: Nutrition(
        calories: 420,
        protein: 8,
        carbohydrates: 60,
        sugar: 12,
        fat: 10,
        saturatedFat: 2,
        salt: 0.4,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailsScreen(product: product)),
    );

    expect(find.text('Granola'), findsOneWidget);
    expect(find.text('FoodSwap Foods'), findsOneWidget);
    expect(find.text('FoodSwap Score\nout of 100'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    expect(find.text('NUTRI-SCORE'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbohydrates'), findsOneWidget);
    expect(find.text('Sugar'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Saturated fat'), findsOneWidget);
    expect(find.text('Salt'), findsOneWidget);
    expect(find.text('Find Better Alternatives'), findsOneWidget);
  });

  testWidgets('missing image and nutrition values do not crash', (
    tester,
  ) async {
    final product = createProduct(
      name: 'Unknown Food',
      brand: 'Unknown Brand',
      nutrition: Nutrition(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailsScreen(product: product)),
    );

    expect(find.text('Unknown Food'), findsOneWidget);
    expect(find.text('Unknown Brand'), findsOneWidget);
    expect(find.byIcon(Icons.fastfood_outlined), findsOneWidget);
    expect(find.text('--'), findsNWidgets(8));
  });
}

Product createProduct({
  required String name,
  String brand = 'FoodSwap Foods',
  String? nutriScore,
  Nutrition? nutrition,
}) {
  return Product(
    code: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    brand: brand,
    imageUrl: '',
    categories: const [],
    nutriScore: nutriScore,
    nutrition: nutrition ?? Nutrition(),
  );
}
