import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/errors/exceptions.dart';
import 'package:food_delivery_application/data/models/restaurant_dish_models.dart';
import 'package:hive/hive.dart';

/// Contract for Tier 2 Hive restaurant catalog caching and local favorites persistence.
abstract class RestaurantLocalDataSource {
  Future<List<RestaurantModel>> getCachedRestaurants();

  Future<void> cacheRestaurants(List<RestaurantModel> restaurants);

  Future<Set<String>> getFavoriteRestaurantIds();

  Future<void> saveFavoriteRestaurantIds(Set<String> favoriteIds);
}

class RestaurantLocalDataSourceImpl implements RestaurantLocalDataSource {
  RestaurantLocalDataSourceImpl({
    required this._restaurantsCacheBox,
    required this._favoritesBox,
  });

  final Box<dynamic> _restaurantsCacheBox;
  final Box<dynamic> _favoritesBox;

  @override
  Future<List<RestaurantModel>> getCachedRestaurants() async {
    try {
      final raw = _restaurantsCacheBox.get(AppConstants.cachedRestaurantsKey);
      if (raw is! List) return const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map(RestaurantModel.fromMap)
          .toList();
    } catch (e) {
      throw CacheException('Failed to read cached restaurants: $e');
    }
  }

  @override
  Future<void> cacheRestaurants(List<RestaurantModel> restaurants) async {
    try {
      final serialized = restaurants.map((r) => r.toMap()).toList();
      await _restaurantsCacheBox.put(
        AppConstants.cachedRestaurantsKey,
        serialized,
      );
    } catch (e) {
      throw CacheException('Failed to write restaurant cache: $e');
    }
  }

  @override
  Future<Set<String>> getFavoriteRestaurantIds() async {
    try {
      final raw = _favoritesBox.get(AppConstants.favoriteRestaurantIdsKey);
      if (raw is! List) return <String>{};
      return raw.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> saveFavoriteRestaurantIds(Set<String> favoriteIds) async {
    try {
      await _favoritesBox.put(
        AppConstants.favoriteRestaurantIdsKey,
        favoriteIds.toList(),
      );
    } catch (e) {
      throw CacheException('Failed to persist favorite restaurants: $e');
    }
  }
}
