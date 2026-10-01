import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/product_search_provider.dart';
import '../services/product_filter_sort_service.dart';
import '../widgets/food_swap_info_dialog.dart';
import '../widgets/skeleton.dart';
import 'better_swaps_screen.dart';
import 'product_details.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductFilterSortService _filterSortService =
      ProductFilterSortService();

  ProductSortOption _sortOption = ProductSortOption.foodSwapScore;
  String? _selectedCategory;
  String? _selectedNutriScore;

  void _searchProducts() {
    final query = _searchController.text.trim();
    _clearFilters();
    ref.read(productSearchProvider.notifier).searchProducts(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final searchState = ref.watch(productSearchProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'FoodSwap',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About FoodSwap',
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => showFoodSwapInfoDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 20.0 : 32.0;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLandscape)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(flex: 6, child: _HomeIntro()),
                            const SizedBox(width: 24),
                            Expanded(flex: 5, child: _buildSearchField()),
                          ],
                        )
                      else ...[
                        const _HomeIntro(),
                        const SizedBox(height: 24),
                        _buildSearchField(),
                      ],
                      SizedBox(height: isLandscape ? 14 : 24),
                      Expanded(child: _buildResults(searchState)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _searchProducts(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search packaged food...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(6),
          child: IconButton(
            tooltip: 'Search',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.arrow_forward, size: 19),
            onPressed: _searchProducts,
          ),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ProductSearchState searchState) {
    if (searchState is ProductSearchLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 28),
        itemCount: 4,
        itemBuilder: (context, index) {
          return const _ProductCardSkeleton();
        },
      );
    }

    if (searchState is ProductSearchError) {
      return Center(
        child: Text(
          searchState.message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (searchState is ProductSearchSuccess && searchState.products.isEmpty) {
      return Center(
        child: Text(
          'No products found. Try another search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (searchState is! ProductSearchSuccess) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 42),
            SizedBox(height: 12),
            Text('Search for a food to get started.'),
          ],
        ),
      );
    }

    final visibleProducts = _filterSortService.filterAndSortProducts(
      products: searchState.products,
      sortBy: _sortOption,
      category: _selectedCategory,
      nutriScore: _selectedNutriScore,
    );

    return Column(
      children: [
        if (searchState.isFromCache) const _CachedResultsIndicator(),
        _FilterControls(products: searchState.products),
        if (visibleProducts.isEmpty)
          const Expanded(child: _NoFilteredProducts())
        else
          Expanded(
            child: ListView.builder(
              itemCount: visibleProducts.length,
              itemBuilder: (context, index) {
                return _ProductCard(product: visibleProducts[index]);
              },
            ),
          ),
      ],
    );
  }

  void _updateSortOption(ProductSortOption? option) {
    if (option == null) {
      return;
    }

    setState(() {
      _sortOption = option;
    });
  }

  void _updateCategory(String? category) {
    setState(() {
      _selectedCategory = category == '' ? null : category;
    });
  }

  void _updateNutriScore(String? score) {
    setState(() {
      _selectedNutriScore = score == '' ? null : score;
    });
  }

  void _clearFilters() {
    setState(() {
      _sortOption = ProductSortOption.foodSwapScore;
      _selectedCategory = null;
      _selectedNutriScore = null;
    });
  }

  List<String> _categoriesFrom(List<Product> products) {
    final categories = products
        .expand((product) => product.categories)
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}

class _FilterControls extends StatelessWidget {
  final List<Product> products;

  const _FilterControls({required this.products});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeScreenState>()!;
    final categories = state._categoriesFrom(products);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controls = [
            Expanded(child: _buildSortDropdown(context, state)),
            Expanded(child: _buildCategoryDropdown(context, state, categories)),
            Expanded(child: _buildNutriScoreDropdown(context, state)),
            _buildClearButton(context, state),
          ];

          if (constraints.maxWidth < 760) {
            return Column(
              children: [
                Row(
                  children: [
                    controls[0],
                    const SizedBox(width: 10),
                    controls[1],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    controls[2],
                    const SizedBox(width: 10),
                    controls[3],
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              controls[0],
              const SizedBox(width: 10),
              controls[1],
              const SizedBox(width: 10),
              controls[2],
              const SizedBox(width: 10),
              controls[3],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context, _HomeScreenState state) {
    return DropdownButtonFormField<ProductSortOption>(
      key: ValueKey('sort-filter-${state._sortOption.name}'),
      initialValue: state._sortOption,
      isExpanded: true,
      decoration: _dropdownDecoration(context, 'Sort by'),
      items: const [
        DropdownMenuItem(
          value: ProductSortOption.foodSwapScore,
          child: Text(
            'FoodSwap Score',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: ProductSortOption.protein,
          child: Text('Protein', maxLines: 1),
        ),
        DropdownMenuItem(
          value: ProductSortOption.sugar,
          child: Text('Sugar', maxLines: 1),
        ),
      ],
      onChanged: state._updateSortOption,
    );
  }

  Widget _buildCategoryDropdown(
    BuildContext context,
    _HomeScreenState state,
    List<String> categories,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey('category-filter-${state._selectedCategory ?? ''}'),
      initialValue: state._selectedCategory ?? '',
      isExpanded: true,
      decoration: _dropdownDecoration(context, 'Category'),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text(
            'All categories',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...categories.map(
          (category) => DropdownMenuItem(
            value: category,
            child: Text(
              _displayCategory(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: state._updateCategory,
    );
  }

  Widget _buildNutriScoreDropdown(
    BuildContext context,
    _HomeScreenState state,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey('nutri-score-filter-${state._selectedNutriScore ?? ''}'),
      initialValue: state._selectedNutriScore ?? '',
      isExpanded: true,
      decoration: _dropdownDecoration(context, 'Nutri-Score'),
      items: const [
        DropdownMenuItem(value: '', child: Text('All scores', maxLines: 1)),
        DropdownMenuItem(value: 'a', child: Text('Nutri-Score A', maxLines: 1)),
        DropdownMenuItem(value: 'b', child: Text('Nutri-Score B', maxLines: 1)),
        DropdownMenuItem(value: 'c', child: Text('Nutri-Score C', maxLines: 1)),
        DropdownMenuItem(value: 'd', child: Text('Nutri-Score D', maxLines: 1)),
        DropdownMenuItem(value: 'e', child: Text('Nutri-Score E', maxLines: 1)),
      ],
      onChanged: state._updateNutriScore,
    );
  }

  Widget _buildClearButton(BuildContext context, _HomeScreenState state) {
    return IconButton(
      key: const ValueKey('clear-filters'),
      tooltip: 'Clear filters',
      onPressed: state._clearFilters,
      icon: const Icon(Icons.filter_alt_off_outlined),
      color: Theme.of(context).colorScheme.primary,
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  String _displayCategory(String category) {
    return category.replaceFirst(RegExp(r'^en:'), '').replaceAll('-', ' ');
  }
}

class _NoFilteredProducts extends StatelessWidget {
  const _NoFilteredProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No products match your filters',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _CachedResultsIndicator extends StatelessWidget {
  const _CachedResultsIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 17),
          SizedBox(width: 8),
          Text(
            'Showing cached results',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(context),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDetails(context)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _NutritionChip(
                    label: 'Protein',
                    value: product.nutrition.protein,
                  ),
                  _NutritionChip(
                    label: 'Sugar',
                    value: product.nutrition.sugar,
                  ),
                  _NutritionChip(label: 'Fat', value: product.nutrition.fat),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BetterSwapsScreen(product: product),
                      ),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz, size: 19),
                  label: const Text('Find Better Swap'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
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
        if (product.nutriScore != null) _NutriScore(score: product.nutriScore!),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: product.imageUrl.isEmpty
          ? const Icon(Icons.fastfood_outlined, size: 42)
          : Image.network(
              product.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.fastfood_outlined, size: 42);
              },
            ),
    );
  }
}

class _NutriScore extends StatelessWidget {
  final String score;

  const _NutriScore({required this.score});

  @override
  Widget build(BuildContext context) {
    final normalizedScore = score.toLowerCase();
    final color = switch (normalizedScore) {
      'a' => const Color(0xFF16854A),
      'b' => const Color(0xFF76B852),
      'c' => const Color(0xFFF0B323),
      'd' => const Color(0xFFE27C2F),
      'e' => const Color(0xFFD75242),
      _ => const Color(0xFF708078),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NUTRI-SCORE',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 7),
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            score.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final double? value;

  const _NutritionChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: value == null ? '--' : '${value!.toStringAsFixed(1)}g',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
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
                        width: MediaQuery.sizeOf(context).width * 0.42,
                        height: 19,
                      ),
                      const SizedBox(height: 9),
                      const SkeletonBlock(width: 100, height: 14),
                      const SizedBox(height: 14),
                      const SkeletonBlock(width: 84, height: 28),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SkeletonBlock(width: 86, height: 36),
                SkeletonBlock(width: 78, height: 36),
                SkeletonBlock(width: 68, height: 36),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBlock(
              width: double.infinity,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeIntro extends StatelessWidget {
  const _HomeIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Make a better food choice.',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Search a packaged food and discover a better alternative.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}
