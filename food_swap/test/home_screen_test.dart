import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/providers/food_providers.dart';
import 'package:food_swap/repositories/food_repository.dart';
import 'package:food_swap/screens/better_swaps_screen.dart';
import 'package:food_swap/screens/home_screen.dart';
import 'package:food_swap/screens/product_details.dart';
import 'package:food_swap/services/openfood_service.dart';
import 'package:food_swap/widgets/skeleton.dart';

void main() {
  testWidgets('shows the idle state before a search', (tester) async {
    await pumpHome(tester, (_) async => emptyResult());

    expect(find.text('Search for a food to get started.'), findsOneWidget);
  });

  testWidgets('shows loading while a search is waiting', (tester) async {
    final response = Completer<FoodRepositoryResult>();
    await pumpHome(tester, (_) => response.future);

    await enterSearch(tester, 'granola');

    expect(find.byType(SkeletonBlock), findsWidgets);

    response.complete(emptyResult());
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
  });

  testWidgets('shows successful search results', (tester) async {
    final product = createProduct('Granola');
    await pumpHome(
      tester,
      (_) async =>
          FoodRepositoryResult(products: [product], isFromCache: false),
    );

    await enterSearch(tester, 'granola');
    await waitForSearch(tester);

    expect(find.text('Granola'), findsOneWidget);
  });

  testWidgets('shows a no-products message for an empty search result', (
    tester,
  ) async {
    await pumpHome(tester, (_) async => emptyResult());

    await enterSearch(tester, 'unknown');
    await waitForSearch(tester);

    expect(find.text('No products found. Try another search.'), findsOneWidget);
    expect(find.text('Search for a food to get started.'), findsNothing);
  });

  testWidgets('shows repository errors', (tester) async {
    await pumpHome(
      tester,
      (_) async => throw const FoodRepositoryException(
        'Food search is currently unavailable.',
      ),
    );

    await enterSearch(tester, 'granola');
    await waitForSearch(tester);

    expect(find.text('Food search is currently unavailable.'), findsOneWidget);
  });

  testWidgets('shows the cached-result indicator', (tester) async {
    await pumpHome(
      tester,
      (_) async => FoodRepositoryResult(
        products: [createProduct('Cached Granola')],
        isFromCache: true,
      ),
    );

    await enterSearch(tester, 'granola');
    await waitForSearch(tester);

    expect(find.text('Showing cached results'), findsOneWidget);
  });

  testWidgets('tapping a product opens ProductDetailsScreen', (tester) async {
    await pumpHome(
      tester,
      (_) async => FoodRepositoryResult(
        products: [createProduct('Tap Me')],
        isFromCache: false,
      ),
    );

    await enterSearch(tester, 'food');
    await waitForSearch(tester);
    await tester.tap(find.text('Tap Me'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Product details'), findsOneWidget);
  });

  testWidgets('Find Better Swap opens BetterSwapsScreen', (tester) async {
    await pumpHome(
      tester,
      (_) async => FoodRepositoryResult(
        products: [createProduct('Granola')],
        isFromCache: false,
      ),
    );

    await enterSearch(tester, 'granola');
    await waitForSearch(tester);
    await tester.tap(find.text('Find Better Swap'));
    await tester.pumpAndSettle();

    expect(find.byType(BetterSwapsScreen), findsOneWidget);
  });
}

Future<void> pumpHome(
  WidgetTester tester,
  Future<FoodRepositoryResult> Function(String query) searchHandler,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        foodRepositoryProvider.overrideWithValue(
          FakeFoodRepository(searchHandler),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}

Future<void> enterSearch(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.tap(find.byTooltip('Search'));
  await tester.pump();
}

Future<void> waitForSearch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump();
}

FoodRepositoryResult emptyResult() {
  return const FoodRepositoryResult(products: [], isFromCache: false);
}

class FakeFoodRepository extends FoodRepository {
  final Future<FoodRepositoryResult> Function(String query) searchHandler;

  FakeFoodRepository(this.searchHandler) : super(OpenFoodService());

  @override
  Future<FoodRepositoryResult> searchProducts(String query) {
    return searchHandler(query);
  }

  @override
  Future<List<Product>> searchSimilarProducts(Product product) async {
    return [];
  }
}

Product createProduct(String name) {
  return Product(
    code: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    brand: 'FoodSwap Foods',
    imageUrl: '',
    categories: const [],
    nutriScore: 'b',
    nutrition: Nutrition(protein: 8, sugar: 12),
  );
}
