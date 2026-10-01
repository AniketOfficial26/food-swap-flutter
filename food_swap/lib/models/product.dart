import 'nutrition.dart';

class Product {
  final String code;
  final String name;
  final String brand;
  final String imageUrl;
  final List<String> categories;
  final String? nutriScore;
  final Nutrition nutrition;

  Product({
    required this.code,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.categories,
    this.nutriScore,
    required this.nutrition,
  });
}
