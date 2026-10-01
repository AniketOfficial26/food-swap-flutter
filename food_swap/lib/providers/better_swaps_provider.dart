import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../repositories/food_repository.dart';
import '../services/recommendation_service.dart';
import 'food_providers.dart';

abstract class BetterSwapsState {
  const BetterSwapsState();
}

class BetterSwapsIdle extends BetterSwapsState {
  const BetterSwapsIdle();
}

class BetterSwapsLoading extends BetterSwapsState {
  const BetterSwapsLoading();
}

class BetterSwapRecommendation {
  final Product product;
  final int currentScore;
  final int alternativeScore;
  final int scoreDifference;
  final double? currentProtein;
  final double? alternativeProtein;
  final double? proteinDifference;
  final double? currentSugar;
  final double? alternativeSugar;
  final double? sugarDifference;
  final String? currentNutriScore;
  final String? alternativeNutriScore;
  final int? nutriScoreDifference;
  final List<String> reasons;

  const BetterSwapRecommendation({
    required this.product,
    required this.currentScore,
    required this.alternativeScore,
    required this.scoreDifference,
    required this.currentProtein,
    required this.alternativeProtein,
    required this.proteinDifference,
    required this.currentSugar,
    required this.alternativeSugar,
    required this.sugarDifference,
    required this.currentNutriScore,
    required this.alternativeNutriScore,
    required this.nutriScoreDifference,
    required this.reasons,
  });

  int get score => alternativeScore;
}

class BetterSwapsSuccess extends BetterSwapsState {
  final List<BetterSwapRecommendation> alternatives;

  const BetterSwapsSuccess(this.alternatives);
}

class BetterSwapsError extends BetterSwapsState {
  final String message;

  const BetterSwapsError(this.message);
}

final betterSwapsProvider =
    NotifierProvider<BetterSwapsController, BetterSwapsState>(
      BetterSwapsController.new,
    );

class BetterSwapsController extends Notifier<BetterSwapsState> {
  late FoodRepository _repository;
  final RecommendationService _recommendationService = RecommendationService();
  int _loadVersion = 0;

  @override
  BetterSwapsState build() {
    _repository = ref.watch(foodRepositoryProvider);
    return const BetterSwapsIdle();
  }

  Future<void> loadAlternatives(Product selectedProduct) async {
    final loadVersion = ++_loadVersion;
    state = const BetterSwapsLoading();

    try {
      final products = await _repository.searchSimilarProducts(selectedProduct);
      if (loadVersion != _loadVersion) {
        return;
      }

      final seenProducts = <String>{};
      final alternatives = <BetterSwapRecommendation>[];

      for (final product in products) {
        if (_isSelectedProduct(product, selectedProduct)) {
          continue;
        }

        final identity = _productIdentity(product);
        if (!seenProducts.add(identity)) {
          continue;
        }

        alternatives.add(_buildRecommendation(product, selectedProduct));
      }

      alternatives.sort((first, second) {
        final scoreComparison = second.score.compareTo(first.score);
        if (scoreComparison != 0) {
          return scoreComparison;
        }

        final nameComparison = first.product.name.toLowerCase().compareTo(
          second.product.name.toLowerCase(),
        );
        if (nameComparison != 0) {
          return nameComparison;
        }

        return first.product.code.compareTo(second.product.code);
      });

      state = BetterSwapsSuccess(alternatives);
    } on FoodRepositoryException catch (error) {
      if (loadVersion != _loadVersion) {
        return;
      }

      state = BetterSwapsError(error.message);
    } on Exception {
      if (loadVersion != _loadVersion) {
        return;
      }

      state = const BetterSwapsError(
        'Unable to find better alternatives. Please try again.',
      );
    }
  }

  BetterSwapRecommendation _buildRecommendation(
    Product product,
    Product selectedProduct,
  ) {
    final currentScore = _recommendationService.calculateScore(selectedProduct);
    final alternativeScore = _recommendationService.calculateScore(product);
    final currentProtein = _validNutritionValue(
      selectedProduct.nutrition.protein,
    );
    final alternativeProtein = _validNutritionValue(product.nutrition.protein);
    final currentSugar = _validNutritionValue(selectedProduct.nutrition.sugar);
    final alternativeSugar = _validNutritionValue(product.nutrition.sugar);
    final currentNutriScore = selectedProduct.nutriScore;
    final alternativeNutriScore = product.nutriScore;

    return BetterSwapRecommendation(
      product: product,
      currentScore: currentScore,
      alternativeScore: alternativeScore,
      scoreDifference: alternativeScore - currentScore,
      currentProtein: currentProtein,
      alternativeProtein: alternativeProtein,
      proteinDifference: _difference(alternativeProtein, currentProtein),
      currentSugar: currentSugar,
      alternativeSugar: alternativeSugar,
      sugarDifference: _difference(alternativeSugar, currentSugar),
      currentNutriScore: currentNutriScore,
      alternativeNutriScore: alternativeNutriScore,
      nutriScoreDifference: _nutriScoreDifference(
        alternativeNutriScore,
        currentNutriScore,
      ),
      reasons: _buildReasons(
        product: product,
        selectedProduct: selectedProduct,
        currentScore: currentScore,
        alternativeScore: alternativeScore,
      ),
    );
  }

  bool _isSelectedProduct(Product product, Product selectedProduct) {
    if (product.code.isNotEmpty && selectedProduct.code.isNotEmpty) {
      return product.code.toLowerCase() == selectedProduct.code.toLowerCase();
    }

    return product.name == selectedProduct.name &&
        product.brand == selectedProduct.brand;
  }

  String _productIdentity(Product product) {
    if (product.code.isNotEmpty) {
      return 'code:${product.code.toLowerCase()}';
    }

    return 'name:${product.name.toLowerCase()}|brand:${product.brand.toLowerCase()}';
  }

  List<String> _buildReasons({
    required Product product,
    required Product selectedProduct,
    required int currentScore,
    required int alternativeScore,
  }) {
    final reasons = <String>[];
    final productNutrition = product.nutrition;
    final selectedNutrition = selectedProduct.nutrition;

    if (alternativeScore > currentScore) {
      reasons.add('Higher FoodSwap Score');
    }
    if (_hasHigherValue(productNutrition.protein, selectedNutrition.protein)) {
      reasons.add('Higher protein');
    }
    if (_hasLowerValue(productNutrition.sugar, selectedNutrition.sugar)) {
      reasons.add('Lower sugar');
    }
    if (_hasBetterNutriScore(product.nutriScore, selectedProduct.nutriScore)) {
      reasons.add('Better Nutri-Score');
    }

    if (reasons.isEmpty) {
      reasons.add('Compare this option with your current product');
    }

    return reasons;
  }

  double? _difference(double? alternative, double? current) {
    if (alternative == null || current == null) {
      return null;
    }

    return alternative - current;
  }

  double? _validNutritionValue(double? value) {
    if (value == null || !value.isFinite || value < 0) {
      return null;
    }

    return value;
  }

  bool _hasHigherValue(double? value, double? selectedValue) {
    return value != null && selectedValue != null && value > selectedValue;
  }

  bool _hasLowerValue(double? value, double? selectedValue) {
    return value != null && selectedValue != null && value < selectedValue;
  }

  bool _hasBetterNutriScore(String? score, String? selectedScore) {
    final productRank = _nutriScoreRank(score);
    final selectedRank = _nutriScoreRank(selectedScore);

    return productRank != null &&
        selectedRank != null &&
        productRank < selectedRank;
  }

  int? _nutriScoreDifference(String? alternative, String? current) {
    final alternativeRank = _nutriScoreRank(alternative);
    final currentRank = _nutriScoreRank(current);

    if (alternativeRank == null || currentRank == null) {
      return null;
    }

    return alternativeRank - currentRank;
  }

  int? _nutriScoreRank(String? score) {
    return switch (score?.toLowerCase()) {
      'a' => 1,
      'b' => 2,
      'c' => 3,
      'd' => 4,
      'e' => 5,
      _ => null,
    };
  }
}
