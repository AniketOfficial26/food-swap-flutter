import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/better_swaps_provider.dart';
import '../widgets/skeleton.dart';
import 'product_details.dart';

class BetterSwapsScreen extends ConsumerStatefulWidget {
  final Product product;

  const BetterSwapsScreen({super.key, required this.product});

  @override
  ConsumerState<BetterSwapsScreen> createState() => _BetterSwapsScreenState();
}

class _BetterSwapsScreenState extends ConsumerState<BetterSwapsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(betterSwapsProvider.notifier).loadAlternatives(widget.product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(betterSwapsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Better Swaps',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(state)),
    );
  }

  Widget _buildBody(BetterSwapsState state) {
    if (state is BetterSwapsLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: 3,
        itemBuilder: (context, index) {
          return const _AlternativeCardSkeleton();
        },
      );
    }

    if (state is BetterSwapsError) {
      return _buildError(state.message);
    }

    if (state is BetterSwapsSuccess && state.alternatives.isEmpty) {
      return _buildEmptyState();
    }

    if (state is BetterSwapsSuccess) {
      return _buildAlternatives(state.alternatives);
    }

    return const SizedBox.shrink();
  }

  Widget _buildAlternatives(List<BetterSwapRecommendation> alternatives) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          itemCount: alternatives.length,
          itemBuilder: (context, index) {
            return _AlternativeCard(recommendation: alternatives[index]);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 48),
            const SizedBox(height: 14),
            Text(
              'No better alternatives found for this product.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.error, size: 42),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(betterSwapsProvider.notifier)
                    .loadAlternatives(widget.product);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  final BetterSwapRecommendation recommendation;

  const _AlternativeCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final product = recommendation.product;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImage(imageUrl: product.imageUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ProductSummary(
                      product: product,
                      score: recommendation.score,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ComparisonSection(recommendation: recommendation),
              const SizedBox(height: 16),
              Text(
                'Why this is better',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...recommendation.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: colors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  final BetterSwapRecommendation recommendation;

  const _ComparisonSection({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          const _ComparisonRow(
            metric: 'Metric',
            current: 'Current',
            alternative: 'Alternative',
            difference: 'Difference',
            isHeader: true,
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            metric: 'FoodSwap Score',
            current: '${recommendation.currentScore}',
            alternative: '${recommendation.alternativeScore}',
            difference: _formatIntegerDifference(
              recommendation.scoreDifference,
            ),
            isImprovement: recommendation.scoreDifference > 0,
          ),
          _ComparisonRow(
            metric: 'Protein',
            current: _formatNutrition(recommendation.currentProtein),
            alternative: _formatNutrition(recommendation.alternativeProtein),
            difference: _formatNutritionDifference(
              recommendation.proteinDifference,
            ),
            isImprovement:
                recommendation.proteinDifference != null &&
                recommendation.proteinDifference! > 0,
            hasDifference: recommendation.proteinDifference != null,
          ),
          _ComparisonRow(
            metric: 'Sugar',
            current: _formatNutrition(recommendation.currentSugar),
            alternative: _formatNutrition(recommendation.alternativeSugar),
            difference: _formatNutritionDifference(
              recommendation.sugarDifference,
            ),
            isImprovement:
                recommendation.sugarDifference != null &&
                recommendation.sugarDifference! < 0,
            hasDifference: recommendation.sugarDifference != null,
          ),
          _ComparisonRow(
            metric: 'Nutri-Score',
            current: recommendation.currentNutriScore?.toUpperCase() ?? '--',
            alternative:
                recommendation.alternativeNutriScore?.toUpperCase() ?? '--',
            difference: _formatNutriDifference(
              recommendation.nutriScoreDifference,
            ),
            isImprovement:
                recommendation.nutriScoreDifference != null &&
                recommendation.nutriScoreDifference! < 0,
            hasDifference: recommendation.nutriScoreDifference != null,
          ),
        ],
      ),
    );
  }

  String _formatIntegerDifference(int difference) {
    if (difference > 0) {
      return '+$difference';
    }

    return '$difference';
  }

  String _formatNutrition(double? value) {
    if (value == null) {
      return '--';
    }

    return '${value.toStringAsFixed(1)}g';
  }

  String _formatNutritionDifference(double? difference) {
    if (difference == null) {
      return '--';
    }
    if (difference > 0) {
      return '+${difference.toStringAsFixed(1)}g';
    }

    return '${difference.toStringAsFixed(1)}g';
  }

  String _formatNutriDifference(int? difference) {
    if (difference == null) {
      return '--';
    }
    if (difference < 0) {
      return 'Better';
    }
    if (difference > 0) {
      return 'Worse';
    }

    return 'Same';
  }
}

class _ComparisonRow extends StatelessWidget {
  final String metric;
  final String current;
  final String alternative;
  final String difference;
  final bool isHeader;
  final bool? isImprovement;
  final bool hasDifference;

  const _ComparisonRow({
    required this.metric,
    required this.current,
    required this.alternative,
    required this.difference,
    this.isHeader = false,
    this.isImprovement,
    this.hasDifference = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final differenceColor = !hasDifference
        ? colors.onSurfaceVariant
        : isImprovement == true
        ? colors.primary
        : colors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.45),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              _metricText(context, metric, isHeader),
              _valueText(context, current, isHeader),
              _valueText(context, alternative, isHeader),
              _differenceText(context, difference, isHeader, differenceColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricText(BuildContext context, String value, bool header) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      value,
      softWrap: true,
      style: TextStyle(
        color: header ? colors.onSurfaceVariant : colors.onSurface,
        fontSize: 11,
        fontWeight: header ? FontWeight.w600 : FontWeight.w700,
      ),
    );
  }

  Widget _valueText(BuildContext context, String value, bool header) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        value,
        textAlign: TextAlign.center,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(
          color: header ? colors.onSurfaceVariant : colors.onSurface,
          fontSize: 11,
          fontWeight: header ? FontWeight.w600 : FontWeight.w700,
        ),
      ),
    );
  }

  Widget _differenceText(
    BuildContext context,
    String value,
    bool header,
    Color differenceColor,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        value,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          color: header ? colors.onSurfaceVariant : differenceColor,
          fontSize: 11,
          fontWeight: header ? FontWeight.w600 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  final Product product;
  final int score;

  const _ProductSummary({required this.product, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          product.brand,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ScoreBadge(score: score),
            const SizedBox(width: 10),
            _NutriScoreBadge(score: product.nutriScore),
          ],
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const _MissingImage()
          : Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const _MissingImage();
              },
            ),
    );
  }
}

class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.fastfood_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      size: 42,
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        'Score $score',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NutriScoreBadge extends StatelessWidget {
  final String? score;

  const _NutriScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = switch (score?.toLowerCase()) {
      'a' => const Color(0xFF16854A),
      'b' => const Color(0xFF76B852),
      'c' => const Color(0xFFF0B323),
      'd' => const Color(0xFFE27C2F),
      'e' => const Color(0xFFD75242),
      _ => const Color(0xFF708078),
    };

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        score?.toUpperCase() ?? '--',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AlternativeCardSkeleton extends StatelessWidget {
  const _AlternativeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBlock(
                  width: 104,
                  height: 104,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(
                        width: MediaQuery.sizeOf(context).width * 0.4,
                        height: 19,
                      ),
                      const SizedBox(height: 9),
                      const SkeletonBlock(width: 96, height: 14),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          SkeletonBlock(width: 72, height: 28),
                          SizedBox(width: 10),
                          SkeletonBlock(width: 28, height: 28),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _ComparisonSkeleton(),
            const SizedBox(height: 16),
            const SkeletonBlock(width: 130, height: 17),
            const SizedBox(height: 10),
            const SkeletonBlock(width: double.infinity, height: 14),
            const SizedBox(height: 7),
            const SkeletonBlock(width: 210, height: 14),
          ],
        ),
      ),
    );
  }
}

class _ComparisonSkeleton extends StatelessWidget {
  const _ComparisonSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          _ComparisonSkeletonRow(
            metricWidth: 60,
            valueWidth: 48,
            alternativeWidth: 68,
            differenceWidth: 62,
          ),
          SizedBox(height: 12),
          _ComparisonSkeletonRow(
            metricWidth: 76,
            valueWidth: 24,
            alternativeWidth: 24,
            differenceWidth: 30,
          ),
          SizedBox(height: 9),
          _ComparisonSkeletonRow(
            metricWidth: 48,
            valueWidth: 30,
            alternativeWidth: 30,
            differenceWidth: 34,
          ),
        ],
      ),
    );
  }
}

class _ComparisonSkeletonRow extends StatelessWidget {
  final double metricWidth;
  final double valueWidth;
  final double alternativeWidth;
  final double differenceWidth;

  const _ComparisonSkeletonRow({
    required this.metricWidth,
    required this.valueWidth,
    required this.alternativeWidth,
    required this.differenceWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SkeletonBlock(width: metricWidth, height: 12),
        SkeletonBlock(width: valueWidth, height: 12),
        SkeletonBlock(width: alternativeWidth, height: 12),
        SkeletonBlock(width: differenceWidth, height: 12),
      ],
    );
  }
}
