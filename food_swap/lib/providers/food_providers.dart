import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/food_repository.dart';
import '../services/openfood_service.dart';

final openFoodServiceProvider = Provider<OpenFoodService>((ref) {
  return OpenFoodService();
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final service = ref.watch(openFoodServiceProvider);

  return FoodRepository(service);
});
