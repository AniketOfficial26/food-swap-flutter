import '../models/product.dart';

/// The recommendation data that can later be shown by the UI.
class RecommendationResult {
  final Product product;
  final int score;
  final List<String> reasons;

  const RecommendationResult({
    required this.product,
    required this.score,
    required this.reasons,
  });
}

/// Calculates simple, deterministic FoodSwap recommendations.
class RecommendationService {
  /// Calculates a FoodSwap Score from 0 to 100.
  int calculateScore(Product product) {
    var score = _scoreForNutriGrade(product.nutriScore);

    // Nutrition adjustments are intentionally small. This keeps the official
    // Nutri-Score important while still using extra data when it is available.
    final sugar = product.nutrition.sugar;
    if (_isAtMost(sugar, 5)) {
      score += 5;
    } else if (_isAtMost(sugar, 10)) {
      score += 2;
    } else if (_isAbove(sugar, 20)) {
      score -= 10;
    }

    final saturatedFat = product.nutrition.saturatedFat;
    if (_isAtMost(saturatedFat, 1)) {
      score += 4;
    } else if (_isAtMost(saturatedFat, 5)) {
      score += 1;
    } else if (_isAbove(saturatedFat, 10)) {
      score -= 8;
    }

    final salt = product.nutrition.salt;
    if (_isAtMost(salt, 0.3)) {
      score += 4;
    } else if (_isAtMost(salt, 1)) {
      score += 1;
    } else if (_isAbove(salt, 2)) {
      score -= 8;
    }

    final protein = product.nutrition.protein;
    if (_isAtLeast(protein, 10)) {
      score += 4;
    } else if (_isAtLeast(protein, 5)) {
      score += 2;
    }

    return _clampScore(score);
  }

  /// Ranks products from the highest FoodSwap Score to the lowest.
  List<RecommendationResult> rankProducts(List<Product> products) {
    final results = products.map(_createResult).toList();

    results.sort((first, second) {
      final scoreComparison = second.score.compareTo(first.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      // Stable tie-breakers make the result predictable for equal scores.
      final nameComparison = first.product.name.toLowerCase().compareTo(
        second.product.name.toLowerCase(),
      );
      if (nameComparison != 0) {
        return nameComparison;
      }

      return first.product.code.compareTo(second.product.code);
    });

    return results;
  }

  RecommendationResult _createResult(Product product) {
    return RecommendationResult(
      product: product,
      score: calculateScore(product),
      reasons: _buildReasons(product),
    );
  }

  List<String> _buildReasons(Product product) {
    final reasons = <String>[];
    final nutriGrade = product.nutriScore?.toLowerCase();

    if (nutriGrade != null && _nutriGradeScores.containsKey(nutriGrade)) {
      reasons.add('Nutri-Score ${nutriGrade.toUpperCase()}');
    }
    if (_isAtMost(product.nutrition.sugar, 5)) {
      reasons.add('Low sugar');
    }
    if (_isAtMost(product.nutrition.saturatedFat, 1)) {
      reasons.add('Low saturated fat');
    }
    if (_isAtMost(product.nutrition.salt, 0.3)) {
      reasons.add('Low salt');
    }
    if (_isAtLeast(product.nutrition.protein, 10)) {
      reasons.add('Good protein');
    }

    return reasons;
  }

  int _scoreForNutriGrade(String? grade) {
    // A starts high and E starts low. Missing or unknown grades stay neutral.
    return _nutriGradeScores[grade?.toLowerCase()] ?? 50;
  }

  int _clampScore(int score) {
    return score.clamp(0, 100).toInt();
  }

  bool _isAtMost(double? value, double maximum) {
    return value != null && value.isFinite && value >= 0 && value <= maximum;
  }

  bool _isAbove(double? value, double minimum) {
    return value != null && value.isFinite && value > minimum;
  }

  bool _isAtLeast(double? value, double minimum) {
    return value != null && value.isFinite && value >= minimum;
  }

  static const Map<String, int> _nutriGradeScores = {
    'a': 100,
    'b': 80,
    'c': 60,
    'd': 40,
    'e': 20,
  };
}
