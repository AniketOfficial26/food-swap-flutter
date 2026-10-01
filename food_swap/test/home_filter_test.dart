import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/providers/food_providers.dart';
import 'package:food_swap/repositories/food_repository.dart';
import 'package:food_swap/screens/home_screen.dart';
import 'package:food_swap/services/openfood_service.dart';
import 'package:food_swap/services/product_filter_sort_service.dart';

void main() {
  testWidgets('uses FoodSwap Score order by default', (tester) async {
    await pumpWithProducts(tester, testProducts);

    await expectOrder(tester, ['Alpha', 'Beta', 'Gamma']);
  });

  testWidgets('sorts loaded products by protein', (tester) async {
    await pumpWithProducts(tester, testProducts);
    await selectSort(tester, 'Protein');

    await expectOrder(tester, ['Beta', 'Gamma', 'Alpha']);
  });

  testWidgets('sorts loaded products by sugar', (tester) async {
    await pumpWithProducts(tester, testProducts);
    await selectSort(tester, 'Sugar');

    await expectOrder(tester, ['Beta', 'Gamma', 'Alpha']);
  });

  testWidgets('filters loaded products by category', (tester) async {
    await pumpWithProducts(tester, testProducts);
    await selectCategory(tester, 'snacks');

    expect(find.text('Alpha'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Gamma'),
      300,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
  });

  testWidgets('filters loaded products by Nutri-Score', (tester) async {
    await pumpWithProducts(tester, testProducts);
    await selectNutriScore(tester, 'B');

    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Gamma'), findsNothing);
  });

  testWidgets('combines category and Nutri-Score filters', (tester) async {
    await pumpWithProducts(tester, testProducts);
    await selectCategory(tester, 'snacks');
    await selectNutriScore(tester, 'A');

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(find.text('Gamma'), findsNothing);
  });

  testWidgets('clearing filters restores the default score view', (
    tester,
  ) async {
    await pumpWithProducts(tester, testProducts);
    await selectSort(tester, 'Protein');
    await selectCategory(tester, 'drinks');
    await tester.tap(find.byTooltip('Clear filters'));
    await tester.pumpAndSettle();

    await expectOrder(tester, ['Alpha', 'Beta', 'Gamma']);
  });

  testWidgets('shows a clear state when filters match no products', (
    tester,
  ) async {
    await pumpWithProducts(tester, testProducts);
    await selectNutriScore(tester, 'E');

    expect(find.text('No products match your filters'), findsOneWidget);
  });

  testWidgets('changing filters does not search again', (tester) async {
    var searchCount = 0;
    await pumpWithProducts(
      tester,
      testProducts,
      onSearch: (_) async {
        searchCount++;
        return FoodRepositoryResult(products: testProducts, isFromCache: false);
      },
    );

    expect(searchCount, 1);
    await selectSort(tester, 'Protein');
    await selectCategory(tester, 'snacks');
    await selectNutriScore(tester, 'A');

    expect(searchCount, 1);
  });

  testWidgets('a new search resets local filters and sorting', (tester) async {
    await pumpWithProducts(tester, testProducts);
    await selectSort(tester, 'Protein');
    await expectOrder(tester, ['Beta', 'Gamma', 'Alpha']);

    await enterSearch(tester, 'new query');
    await waitForSearch(tester);

    await expectOrder(tester, ['Alpha', 'Beta', 'Gamma']);
  });
}

Future<void> pumpWithProducts(
  WidgetTester tester,
  List<Product> products, {
  Future<FoodRepositoryResult> Function(String query)? onSearch,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        foodRepositoryProvider.overrideWithValue(
          FakeFoodRepository(
            onSearch ??
                (_) async => FoodRepositoryResult(
                  products: products,
                  isFromCache: false,
                ),
          ),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );

  await tester.enterText(find.byType(TextField), 'food');
  await tester.tap(find.byTooltip('Search'));
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump();
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

Future<void> selectSort(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<ProductSortOption>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> selectCategory(WidgetTester tester, String category) async {
  final dropdowns = find.byType(DropdownButtonFormField<String>);
  await tester.tap(dropdowns.at(0));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_displayCategory(category)).last);
  await tester.pumpAndSettle();
}

Future<void> selectNutriScore(WidgetTester tester, String score) async {
  final dropdowns = find.byType(DropdownButtonFormField<String>);
  await tester.tap(dropdowns.at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nutri-Score $score').last);
  await tester.pumpAndSettle();
}

Future<void> expectOrder(WidgetTester tester, List<String> names) async {
  expect(find.text(names.first), findsOneWidget);

  for (final name in names.skip(1)) {
    await tester.scrollUntilVisible(
      find.text(name),
      300,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
  }
}

String _displayCategory(String category) {
  return category.replaceFirst(RegExp(r'^en:'), '').replaceAll('-', ' ');
}

class FakeFoodRepository extends FoodRepository {
  final Future<FoodRepositoryResult> Function(String query) searchHandler;

  FakeFoodRepository(this.searchHandler) : super(OpenFoodService());

  @override
  Future<FoodRepositoryResult> searchProducts(String query) {
    return searchHandler(query);
  }
}

Product product({
  required String name,
  required String code,
  required String score,
  required double protein,
  required double sugar,
  required List<String> categories,
}) {
  return Product(
    code: code,
    name: name,
    brand: 'FoodSwap Foods',
    imageUrl: '',
    categories: categories,
    nutriScore: score,
    nutrition: Nutrition(protein: protein, sugar: sugar),
  );
}

final testProducts = [
  product(
    name: 'Alpha',
    code: 'alpha',
    score: 'a',
    protein: 2,
    sugar: 20,
    categories: ['en:snacks'],
  ),
  product(
    name: 'Beta',
    code: 'beta',
    score: 'b',
    protein: 20,
    sugar: 5,
    categories: ['en:drinks'],
  ),
  product(
    name: 'Gamma',
    code: 'gamma',
    score: 'c',
    protein: 10,
    sugar: 10,
    categories: ['en:snacks'],
  ),
];
