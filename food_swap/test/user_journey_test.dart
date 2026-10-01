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

void main() {
  testWidgets('completes the search to alternative back-navigation journey', (
    tester,
  ) async {
    final current = createProduct('Current Granola', 'current', 'c');
    final alternative = createProduct('Better Granola', 'alternative', 'a');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(
            JourneyFoodRepository(current, alternative),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'granola');
    await tester.tap(find.byTooltip('Search'));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    expect(find.text('Current Granola'), findsOneWidget);

    await tester.tap(find.text('Current Granola'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Current Granola'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Find Better Alternatives'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Find Better Alternatives'));
    await tester.pumpAndSettle();
    expect(find.byType(BetterSwapsScreen), findsOneWidget);
    expect(find.text('Better Granola'), findsOneWidget);

    await tester.tap(find.text('Better Granola'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Better Granola'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(BetterSwapsScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Current Granola'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

class JourneyFoodRepository extends FoodRepository {
  final Product current;
  final Product alternative;

  JourneyFoodRepository(this.current, this.alternative)
    : super(OpenFoodService());

  @override
  Future<FoodRepositoryResult> searchProducts(String query) async {
    return FoodRepositoryResult(products: [current], isFromCache: false);
  }

  @override
  Future<List<Product>> searchSimilarProducts(Product product) async {
    return [alternative];
  }
}

Product createProduct(String name, String code, String nutriScore) {
  return Product(
    code: code,
    name: name,
    brand: 'FoodSwap Foods',
    imageUrl: '',
    categories: const ['en:snacks'],
    nutriScore: nutriScore,
    nutrition: Nutrition(protein: 8, sugar: 12),
  );
}
