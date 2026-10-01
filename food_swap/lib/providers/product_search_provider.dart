import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../repositories/food_repository.dart';
import 'food_providers.dart';

abstract class ProductSearchState {
  const ProductSearchState();
}

class ProductSearchIdle extends ProductSearchState {
  const ProductSearchIdle();
}

class ProductSearchLoading extends ProductSearchState {
  const ProductSearchLoading();
}

class ProductSearchSuccess extends ProductSearchState {
  final List<Product> products;
  final bool isFromCache;

  const ProductSearchSuccess(this.products, {this.isFromCache = false});
}

class ProductSearchError extends ProductSearchState {
  final String message;

  const ProductSearchError(this.message);
}

final productSearchProvider =
    NotifierProvider<ProductSearchController, ProductSearchState>(
      ProductSearchController.new,
    );

class ProductSearchController extends Notifier<ProductSearchState> {
  late FoodRepository _repository;
  Timer? _debounceTimer;
  int _searchVersion = 0;

  static const _debounceDuration = Duration(milliseconds: 400);

  @override
  ProductSearchState build() {
    _repository = ref.watch(foodRepositoryProvider);
    ref.onDispose(_cancelDebounce);
    return const ProductSearchIdle();
  }

  void searchProducts(String query) {
    final normalizedQuery = query.trim();
    final searchVersion = ++_searchVersion;
    _debounceTimer?.cancel();

    if (normalizedQuery.isEmpty) {
      state = const ProductSearchSuccess([]);
      return;
    }

    state = const ProductSearchLoading();

    _debounceTimer = Timer(_debounceDuration, () {
      _debounceTimer = null;
      _searchAfterDebounce(normalizedQuery, searchVersion);
    });
  }

  Future<void> _searchAfterDebounce(String query, int searchVersion) async {
    try {
      final result = await _repository.searchProducts(query);
      if (searchVersion != _searchVersion) {
        return;
      }

      state = ProductSearchSuccess(
        result.products,
        isFromCache: result.isFromCache,
      );
    } on FoodRepositoryException catch (error) {
      if (searchVersion != _searchVersion) {
        return;
      }

      state = ProductSearchError(error.message);
    } on Exception {
      if (searchVersion != _searchVersion) {
        return;
      }

      state = const ProductSearchError(
        'Something went wrong while searching. Please try again.',
      );
    }
  }

  void _cancelDebounce() {
    _searchVersion++;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
