import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_swap/models/nutrition.dart';
import 'package:food_swap/models/product.dart';
import 'package:food_swap/providers/better_swaps_provider.dart';
import 'package:food_swap/providers/food_providers.dart';
import 'package:food_swap/repositories/food_repository.dart';
import 'package:food_swap/services/openfood_service.dart';

void main() {
  test('starts in the idle state and becomes loading', () async {
    final response = Completer<List<Product>>();
    final container = createContainer(
      FakeFoodRepository((_) => response.future),
    );
    addTearDown(container.dispose);

    final controller = container.read(betterSwapsProvider.notifier);
    expect(container.read(betterSwapsProvider), isA<BetterSwapsIdle>());

    controller.loadAlternatives(createProduct('Current', 'current', 'c'));
    expect(container.read(betterSwapsProvider), isA<BetterSwapsLoading>());

    response.complete([]);
    await pumpEventQueue();
  });

  test(
    'loads alternatives sorted by FoodSwap Score and excludes selected',
    () async {
      final selected = createProduct('Current', 'selected', 'c');
      final alternatives = [
        createProduct('Lower Score', 'lower', 'e'),
        selected,
        createProduct('Highest Score', 'highest', 'a'),
      ];
      final container = createContainer(
        FakeFoodRepository((_) async => alternatives),
      );
      addTearDown(container.dispose);

      await container
          .read(betterSwapsProvider.notifier)
          .loadAlternatives(selected);

      final state = container.read(betterSwapsProvider) as BetterSwapsSuccess;
      expect(state.alternatives.map((item) => item.product.name).toList(), [
        'Highest Score',
        'Lower Score',
      ]);
      expect(state.alternatives.first.score, 100);
    },
  );

  test('returns an empty success state when no alternatives exist', () async {
    final selected = createProduct('Current', 'selected', 'c');
    final container = createContainer(FakeFoodRepository((_) async => []));
    addTearDown(container.dispose);

    await container
        .read(betterSwapsProvider.notifier)
        .loadAlternatives(selected);

    final state = container.read(betterSwapsProvider);
    expect(state, isA<BetterSwapsSuccess>());
    expect((state as BetterSwapsSuccess).alternatives, isEmpty);
  });

  test('returns a repository error state', () async {
    final container = createContainer(
      FakeFoodRepository(
        (_) async => throw const FoodRepositoryException(
          'Finding similar food is currently unavailable.',
        ),
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(betterSwapsProvider.notifier)
        .loadAlternatives(createProduct('Current', 'selected', 'c'));

    final state = container.read(betterSwapsProvider);
    expect(state, isA<BetterSwapsError>());
    expect(
      (state as BetterSwapsError).message,
      'Finding similar food is currently unavailable.',
    );
  });

  test('calculates comparison values and improvement reasons', () async {
    final selected = Product(
      code: 'selected',
      name: 'Current',
      brand: 'FoodSwap Foods',
      imageUrl: '',
      categories: const [],
      nutriScore: 'c',
      nutrition: Nutrition(protein: 8, sugar: 12),
    );
    final alternative = Product(
      code: 'alternative',
      name: 'Better Choice',
      brand: 'FoodSwap Foods',
      imageUrl: '',
      categories: const [],
      nutriScore: 'a',
      nutrition: Nutrition(protein: 12, sugar: 5),
    );
    final container = createContainer(
      FakeFoodRepository((_) async => [alternative]),
    );
    addTearDown(container.dispose);

    await container
        .read(betterSwapsProvider.notifier)
        .loadAlternatives(selected);

    final recommendation = (container.read(
      betterSwapsProvider,
    ) as BetterSwapsSuccess).alternatives.single;
    expect(recommendation.currentScore, 62);
    expect(recommendation.alternativeScore, 100);
    expect(recommendation.scoreDifference, 38);
    expect(recommendation.currentProtein, 8);
    expect(recommendation.alternativeProtein, 12);
    expect(recommendation.proteinDifference, 4);
    expect(recommendation.currentSugar, 12);
    expect(recommendation.alternativeSugar, 5);
    expect(recommendation.sugarDifference, -7);
    expect(recommendation.currentNutriScore, 'c');
    expect(recommendation.alternativeNutriScore, 'a');
    expect(recommendation.nutriScoreDifference, -2);
    expect(recommendation.reasons, [
      'Higher FoodSwap Score',
      'Higher protein',
      'Lower sugar',
      'Better Nutri-Score',
    ]);
  });

  test('does not claim worse or equal metrics as improvements', () async {
    final selected = Product(
      code: 'selected',
      name: 'Current',
      brand: 'FoodSwap Foods',
      imageUrl: '',
      categories: const [],
      nutriScore: 'c',
      nutrition: Nutrition(protein: 8, sugar: 5),
    );
    final worseNutrition = Product(
      code: 'worse-nutrition',
      name: 'Higher Score Only',
      brand: 'FoodSwap Foods',
      imageUrl: '',
      categories: const [],
      nutriScore: 'a',
      nutrition: Nutrition(protein: 4, sugar: 12),
    );
    final equal = Product(
      code: 'equal',
      name: 'Equal Choice',
      brand: 'FoodSwap Foods',
      imageUrl: '',
      categories: const [],
      nutriScore: 'c',
      nutrition: Nutrition(protein: 8, sugar: 5),
    );
    final container = createContainer(
      FakeFoodRepository((_) async => [worseNutrition, equal]),
    );
    addTearDown(container.dispose);

    await container
        .read(betterSwapsProvider.notifier)
        .loadAlternatives(selected);

    final alternatives = (container.read(
      betterSwapsProvider,
    ) as BetterSwapsSuccess).alternatives;
    final higherScoreOnly = alternatives.firstWhere(
      (item) => item.product.code == 'worse-nutrition',
    );
    final equalChoice = alternatives.firstWhere(
      (item) => item.product.code == 'equal',
    );

    expect(higherScoreOnly.reasons, [
      'Higher FoodSwap Score',
      'Better Nutri-Score',
    ]);
    expect(equalChoice.reasons, [
      'Compare this option with your current product',
    ]);
  });

  test('handles missing nutrition values without fake differences', () async {
    final selected = createProduct('Current', 'selected', 'c');
    final alternative = createProduct(
      'Missing Values',
      'missing',
      'c',
      protein: null,
      sugar: null,
    );
    final container = createContainer(
      FakeFoodRepository((_) async => [alternative]),
    );
    addTearDown(container.dispose);

    await container
        .read(betterSwapsProvider.notifier)
        .loadAlternatives(selected);

    final recommendation = (container.read(
      betterSwapsProvider,
    ) as BetterSwapsSuccess).alternatives.single;
    expect(recommendation.proteinDifference, isNull);
    expect(recommendation.sugarDifference, isNull);
    expect(recommendation.reasons, [
      'Compare this option with your current product',
    ]);
  });

  test('removes duplicate alternatives before returning success', () async {
    final selected = createProduct('Current', 'selected', 'c');
    final duplicate = createProduct('Same Choice', 'same', 'a');
    final container = createContainer(
      FakeFoodRepository((_) async => [duplicate, duplicate]),
    );
    addTearDown(container.dispose);

    await container
        .read(betterSwapsProvider.notifier)
        .loadAlternatives(selected);

    final state = container.read(betterSwapsProvider) as BetterSwapsSuccess;
    expect(state.alternatives, hasLength(1));
    expect(state.alternatives.single.product.code, 'same');
  });

  test(
    'normalizes invalid comparison nutrition and orders score ties',
    () async {
      final selected = createProduct('Current', 'selected', 'c');
      final invalid = createProduct(
        'Invalid Values',
        'invalid',
        'c',
        protein: -1,
        sugar: double.infinity,
      );
      final zed = createProduct('Zed', 'zed', 'c');
      final alpha = createProduct('Alpha', 'alpha', 'c');
      final container = createContainer(
        FakeFoodRepository((_) async => [invalid, zed, alpha]),
      );
      addTearDown(container.dispose);

      await container
          .read(betterSwapsProvider.notifier)
          .loadAlternatives(selected);

      final alternatives = (container.read(
        betterSwapsProvider,
      ) as BetterSwapsSuccess).alternatives;
      expect(alternatives.map((item) => item.product.name).toList(), [
        'Alpha',
        'Zed',
        'Invalid Values',
      ]);
      final invalidRecommendation = alternatives.firstWhere(
        (item) => item.product.code == 'invalid',
      );
      expect(invalidRecommendation.alternativeProtein, isNull);
      expect(invalidRecommendation.alternativeSugar, isNull);
      expect(invalidRecommendation.proteinDifference, isNull);
      expect(invalidRecommendation.sugarDifference, isNull);
      expect(invalidRecommendation.reasons, [
        'Compare this option with your current product',
      ]);
    },
  );

  test('retry loads alternatives again after an error', () async {
    var attempts = 0;
    final container = createContainer(
      FakeFoodRepository((_) async {
        attempts++;
        if (attempts == 1) {
          throw const FoodRepositoryException('Try again');
        }
        return [createProduct('Better Choice', 'better', 'a')];
      }),
    );
    addTearDown(container.dispose);

    final controller = container.read(betterSwapsProvider.notifier);
    final selected = createProduct('Current', 'selected', 'c');
    await controller.loadAlternatives(selected);
    expect(container.read(betterSwapsProvider), isA<BetterSwapsError>());

    await controller.loadAlternatives(selected);

    final state = container.read(betterSwapsProvider);
    expect(state, isA<BetterSwapsSuccess>());
    expect(
      (state as BetterSwapsSuccess).alternatives.single.product.name,
      'Better Choice',
    );
    expect(attempts, 2);
  });

  test('a stale alternatives request cannot replace a newer request', () async {
    final firstResponse = Completer<List<Product>>();
    final secondResponse = Completer<List<Product>>();
    final container = createContainer(
      FakeFoodRepository((selectedProduct) {
        return selectedProduct.code == 'first'
            ? firstResponse.future
            : secondResponse.future;
      }),
    );
    addTearDown(container.dispose);

    final controller = container.read(betterSwapsProvider.notifier);
    controller.loadAlternatives(createProduct('First', 'first', 'c'));
    controller.loadAlternatives(createProduct('Second', 'second', 'c'));

    secondResponse.complete([
      createProduct('Second alternative', 'alt-2', 'a'),
    ]);
    await pumpEventQueue();
    expect(
      (container.read(
        betterSwapsProvider,
      ) as BetterSwapsSuccess).alternatives.single.product.name,
      'Second alternative',
    );

    firstResponse.complete([createProduct('Stale alternative', 'alt-1', 'a')]);
    await pumpEventQueue();
    expect(
      (container.read(
        betterSwapsProvider,
      ) as BetterSwapsSuccess).alternatives.single.product.name,
      'Second alternative',
    );
  });
}

ProviderContainer createContainer(FoodRepository repository) {
  return ProviderContainer(
    overrides: [foodRepositoryProvider.overrideWithValue(repository)],
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
