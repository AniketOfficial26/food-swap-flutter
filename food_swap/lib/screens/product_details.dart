import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/recommendation_service.dart';
import 'better_swaps_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final VoidCallback? onFindAlternatives;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.onFindAlternatives,
  });

  @override
  Widget build(BuildContext context) {
    final score = RecommendationService().calculateScore(product);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Product details',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(context),
                  const SizedBox(height: 24),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurface, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _buildScoreSummary(context, score),
                  const SizedBox(height: 24),
                  Text(
                    'Nutrition per 100g',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNutritionGrid(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          onFindAlternatives ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    BetterSwapsScreen(product: product),
                              ),
                            );
                          },
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Find Better Alternatives'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: product.imageUrl.isEmpty
          ? const _MissingImage()
          : Image.network(
              product.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const _MissingImage();
              },
            ),
    );
  }

  Widget _buildScoreSummary(BuildContext context, int score) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 4),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                color: colors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'FoodSwap Score\nout of 100',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          _NutriScoreBadge(score: product.nutriScore),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid() {
    final nutrition = product.nutrition;
    final values = [
      ('Calories', nutrition.calories, 'kcal'),
      ('Protein', nutrition.protein, 'g'),
      ('Carbohydrates', nutrition.carbohydrates, 'g'),
      ('Sugar', nutrition.sugar, 'g'),
      ('Fat', nutrition.fat, 'g'),
      ('Saturated fat', nutrition.saturatedFat, 'g'),
      ('Salt', nutrition.salt, 'g'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: values
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _NutritionTile(
                    label: item.$1,
                    value: item.$2,
                    unit: item.$3,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Icon(Icons.fastfood_outlined, size: 58));
  }
}

class _NutriScoreBadge extends StatelessWidget {
  final String? score;

  const _NutriScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final normalizedScore = score?.toLowerCase();
    final color = switch (normalizedScore) {
      'a' => const Color(0xFF16854A),
      'b' => const Color(0xFF76B852),
      'c' => const Color(0xFFF0B323),
      'd' => const Color(0xFFE27C2F),
      'e' => const Color(0xFFD75242),
      _ => const Color(0xFF708078),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'NUTRI-SCORE',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            score?.toUpperCase() ?? '--',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NutritionTile extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _NutritionTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null ? '--' : _formatValue(value!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value == null ? displayValue : '$displayValue $unit',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(1);
  }
}
