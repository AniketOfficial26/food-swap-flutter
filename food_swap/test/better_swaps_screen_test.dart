import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/providers/food_providers.dart';
import 'package:food_swap/repositories/food_repository.dart';
import 'package:food_swap/screens/better_swaps_screen.dart';
import 'package:food_swap/screens/product_details.dart';
import 'package:food_swap/services/openfood_service.dart';
import 'package:food_swap/widgets/skeleton.dart';

void main() {
  testWidgets('shows loading state', (tester) async {
    final response = Completer<List<Product>>();
    await pumpBetterSwaps(tester, (_) => response.future);
    await tester.pump();

    expect(find.byType(SkeletonBlock), findsWidgets);

    response.complete([]);
    await tester.pump();
    await tester.pump();
  });

  testWidgets('shows successful alternatives', (tester) async {
    final alternatives = [createProduct('Better Granola', 'better', 'a')];
    await pumpBetterSwaps(tester, (_) async => alternatives);
    await tester.pump();
    await tester.pump();

    expect(find.text('Better Granola'), findsOneWidget);
    expect(find.text('FoodSwap Foods'), findsOneWidget);
    expect(find.text('Score 100'), findsOneWidget);
    expect(find.text('A'), findsNWidgets(2));
    expect(find.text('62'), findsOneWidget);
    expect(find.text('+38'), findsOneWidget);
    expect(find.text('8.0g'), findsNWidgets(2));
    expect(find.text('12.0g'), findsNWidgets(2));
    expect(find.text('Better'), findsOneWidget);
    expect(find.text('Why this is better'), findsOneWidget);
    expect(find.text('Higher FoodSwap Score'), findsOneWidget);
  });

  testWidgets('shows placeholders for missing comparison values', (
    tester,
  ) async {
    await pumpBetterSwaps(
      tester,
      (_) async => [
        createProduct(
          'Missing Nutrition',
          'missing',
          null,
          protein: null,
          sugar: null,
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('--'), findsNWidgets(7));
  });

  testWidgets('shows the empty state', (tester) async {
    await pumpBetterSwaps(tester, (_) async => []);
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No better alternatives found for this product.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error and retries successfully', (tester) async {
    var attempts = 0;
    await pumpBetterSwaps(tester, (_) async {
      attempts++;
      if (attempts == 1) {
        throw const FoodRepositoryException('Unable to load alternatives.');
      }
      return [createProduct('Retry Choice', 'retry', 'b')];
    });
    await tester.pump();
    await tester.pump();

    expect(find.text('Unable to load alternatives.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Retry Choice'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('tapping an alternative opens ProductDetailsScreen', (
    tester,
  ) async {
    await pumpBetterSwaps(
      tester,
      (_) async => [createProduct('Tap Alternative', 'alternative', 'a')],
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Tap Alternative'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Product details'), findsOneWidget);
  });
}

Future<void> pumpBetterSwaps(
  WidgetTester tester,
  Future<List<Product>> Function(Product selectedProduct) searchHandler,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        foodRepositoryProvider.overrideWithValue(
          FakeFoodRepository(searchHandler),
        ),
      ],
      child: MaterialApp(
        home: BetterSwapsScreen(
          product: createProduct('Current Product', 'selected', 'c'),
        ),
      ),
    ),
  );
}

class FakeFoodRepository extends FoodRepository {
  final Future<List<Product>> Function(Product selectedProduct) searchHandler;

  FakeFoodRepository(this.searchHandler) : super(OpenFoodService());

  @override
  Future<List<Product>> searchSimilarProducts(Product product) {
    return searchHandler(product);
  }
}

Product createProduct(
  String name,
  String code,
  String? nutriScore, {
  double? protein = 8,
  double? sugar = 12,
}) {
  return Product(
    code: code,
    name: name,
    brand: 'FoodSwap Foods',
    imageUrl: '',
    categories: const ['en:snacks'],
    nutriScore: nutriScore,
    nutrition: Nutrition(protein: protein, sugar: sugar),
  );
}
