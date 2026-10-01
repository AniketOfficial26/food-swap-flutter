import '../models/product.dart';
import '../services/product_cache.dart';
import '../services/openfood_service.dart';

class FoodRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const FoodRepositoryException(this.message, {this.cause});

  @override
  String toString() => message;
}

class FoodRepositoryResult {
  final List<Product> products;
  final bool isFromCache;

  const FoodRepositoryResult({
    required this.products,
    required this.isFromCache,
  });
}

class FoodRepository {
  final OpenFoodService _service;
  final ProductCache _cache;
  int _searchVersion = 0;

  FoodRepository(this._service, {ProductCache? cache})
    : _cache = cache ?? ProductCache();

  Future<FoodRepositoryResult> searchProducts(String query) async {
    final searchVersion = ++_searchVersion;
    List<Product> products;

    try {
      products = _deduplicateProducts(await _service.searchProducts(query));
    } on FoodNetworkException catch (error) {
      List<Product> cachedProducts;
      try {
        cachedProducts = _deduplicateProducts(
          await _cache.loadProducts(query: query),
        );
      } catch (_) {
        throw _mapSearchError(error);
      }

      if (cachedProducts.isNotEmpty) {
        return FoodRepositoryResult(
          products: cachedProducts,
          isFromCache: true,
        );
      }

      throw _mapSearchError(error);
    }

    if (searchVersion == _searchVersion) {
      try {
        await _cache.saveProducts(products, query: query);
      } catch (_) {
        // A cache write should not make a successful network search fail.
      }
    }

    return FoodRepositoryResult(products: products, isFromCache: false);
  }

  Future<List<Product>> searchSimilarProducts(Product product) async {
    try {
      return await _service.searchSimilarProducts(product);
    } on FoodTimeoutException catch (error) {
      throw FoodRepositoryException(
        'Finding similar food timed out. Please try again.',
        cause: error,
      );
    } on FoodParsingException catch (error) {
      throw FoodRepositoryException(
        'The food service returned unusable data.',
        cause: error,
      );
    } on FoodNetworkException catch (error) {
      throw FoodRepositoryException(
        'Finding similar food is currently unavailable.',
        cause: error,
      );
    }
  }

  FoodRepositoryException _mapSearchError(FoodNetworkException error) {
    if (error is FoodTimeoutException) {
      return FoodRepositoryException(
        'Searching food timed out. Please try again.',
        cause: error,
      );
    }
    if (error is FoodParsingException) {
      return FoodRepositoryException(
        'The food service returned unusable data.',
        cause: error,
      );
    }

    return FoodRepositoryException(
      'Food search is currently unavailable.',
      cause: error,
    );
  }

  List<Product> _deduplicateProducts(List<Product> products) {
    final seenProducts = <String>{};
    final uniqueProducts = <Product>[];

    for (final product in products) {
      final identity = product.code.isNotEmpty
          ? 'code:${product.code.toLowerCase()}'
          : 'name:${product.name.toLowerCase()}|brand:${product.brand.toLowerCase()}';
      if (seenProducts.add(identity)) {
        uniqueProducts.add(product);
      }
    }

    return uniqueProducts;
  }
}
