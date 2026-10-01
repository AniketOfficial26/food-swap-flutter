import '../models/product.dart';
import 'recommendation_service.dart';

enum ProductSortOption { foodSwapScore, protein, sugar }

/// Filters and sorts products already held in memory.
class ProductFilterSortService {
  final RecommendationService _recommendationService;

  ProductFilterSortService({RecommendationService? recommendationService})
    : _recommendationService = recommendationService ?? RecommendationService();

  List<Product> filterAndSortProducts({
    required List<Product> products,
    ProductSortOption sortBy = ProductSortOption.foodSwapScore,
    String? category,
    String? nutriScore,
  }) {
    final filteredProducts = products.where((product) {
      final matchesCategory =
          category == null ||
          category.trim().isEmpty ||
          _hasCategory(product, category);
      final matchesNutriScore =
          nutriScore == null ||
          nutriScore.trim().isEmpty ||
          product.nutriScore?.toLowerCase() == nutriScore.trim().toLowerCase();

      return matchesCategory && matchesNutriScore;
    }).toList();

    // Sorting this copy keeps the caller's original list unchanged.
    filteredProducts.sort((first, second) {
      switch (sortBy) {
        case ProductSortOption.foodSwapScore:
          return _recommendationService
              .calculateScore(second)
              .compareTo(_recommendationService.calculateScore(first));
        case ProductSortOption.protein:
          return _compareNumbersDescending(
            first.nutrition.protein,
            second.nutrition.protein,
          );
        case ProductSortOption.sugar:
          return _compareNumbersAscending(
            first.nutrition.sugar,
            second.nutrition.sugar,
          );
      }
    });

    return filteredProducts;
  }

  bool _hasCategory(Product product, String category) {
    final wantedCategory = _normaliseCategory(category);

    return product.categories.any(
      (productCategory) =>
          _normaliseCategory(productCategory) == wantedCategory,
    );
  }

  String _normaliseCategory(String category) {
    final lowerCaseCategory = category.trim().toLowerCase();
    final colonIndex = lowerCaseCategory.indexOf(':');

    if (colonIndex == -1) {
      return lowerCaseCategory;
    }

    return lowerCaseCategory.substring(colonIndex + 1);
  }

  int _compareNumbersDescending(double? first, double? second) {
    if (first == null && second == null) {
      return 0;
    }
    if (first == null) {
      return 1;
    }
    if (second == null) {
      return -1;
    }

    return second.compareTo(first);
  }

  int _compareNumbersAscending(double? first, double? second) {
    if (first == null && second == null) {
      return 0;
    }
    if (first == null) {
      return 1;
    }
    if (second == null) {
      return -1;
    }

    return first.compareTo(second);
  }
}
