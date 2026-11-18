import 'package:food_delivery_application/data/datasources/food_cart_order_remote_datasource.dart';
import 'package:food_delivery_application/data/datasources/mock_restaurants_seed.dart';
import 'package:food_delivery_application/data/datasources/restaurant_local_datasource.dart';
import 'package:food_delivery_application/data/datasources/restaurant_remote_datasource.dart';
import 'package:food_delivery_application/data/models/restaurant_dish_models.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/domain/repositories/restaurant_repository.dart';

/// Coordinates the 3-tier resilient restaurant & menu catalog pipeline:
/// Tier 1 (DummyJSON REST API) -> Tier 2 (Hive Cache) -> Tier 3 (Bundled Seed Data).
class RestaurantRepositoryImpl implements RestaurantRepository {
  const RestaurantRepositoryImpl({
    required this._remoteDataSource,
    required this._localDataSource,
    required this._cloudUserDataSource,
  });

  final RestaurantRemoteDataSource _remoteDataSource;
  final RestaurantLocalDataSource _localDataSource;
  final FoodCartOrderRemoteDataSource _cloudUserDataSource;

  @override
  Future<RestaurantCatalogResult> getRestaurants({
    String? uid,
    bool forceRefresh = false,
  }) async {
    final favoriteIds = await getFavoriteRestaurantIds(uid: uid);

    // Tier 1: Live DummyJSON Recipes API
    try {
      final liveRestaurants = await _remoteDataSource.fetchRestaurants();
      if (liveRestaurants.isNotEmpty) {
        try {
          await _localDataSource.cacheRestaurants(liveRestaurants);
        } catch (_) {
          // Cache write failure should never block live results.
        }
        return RestaurantCatalogResult(
          restaurants: _applyFavorites(liveRestaurants, favoriteIds),
          sourceTier: CatalogDataSourceTier.liveApi,
        );
      }
    } catch (_) {
      // Fall through cleanly to Tier 2 Hive cache.
    }

    // Tier 2: Local Hive Cache
    try {
      final cachedRestaurants = await _localDataSource.getCachedRestaurants();
      if (cachedRestaurants.isNotEmpty) {
        return RestaurantCatalogResult(
          restaurants: _applyFavorites(cachedRestaurants, favoriteIds),
          sourceTier: CatalogDataSourceTier.localCache,
        );
      }
    } catch (_) {
      // Fall through cleanly to Tier 3 bundled seed data.
    }

    // Tier 3: Bundled Offline Seed Data (Zero-Deadlock Guarantee)
    final seededRestaurants = MockRestaurantsSeed.buildSeedRestaurants();
    try {
      await _localDataSource.cacheRestaurants(seededRestaurants);
    } catch (_) {
      // Ignore cache error on seed fallback.
    }
    return RestaurantCatalogResult(
      restaurants: _applyFavorites(seededRestaurants, favoriteIds),
      sourceTier: CatalogDataSourceTier.bundledSeed,
    );
  }

  @override
  Future<List<DishEntity>> searchDishes(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    try {
      final remoteMatches = await _remoteDataSource.searchDishes(normalized);
      if (remoteMatches.isNotEmpty) return remoteMatches;
    } catch (_) {
      // Fall back to local catalog search below.
    }

    final catalog = await getRestaurants();
    final lower = normalized.toLowerCase();
    final localMatches = <DishEntity>[];
    for (final restaurant in catalog.restaurants) {
      for (final dish in restaurant.dishes) {
        if (dish.name.toLowerCase().contains(lower) ||
            dish.description.toLowerCase().contains(lower) ||
            dish.ingredients.any((i) => i.toLowerCase().contains(lower))) {
          localMatches.add(dish);
        }
      }
    }
    return localMatches;
  }

  @override
  Future<Set<String>> getFavoriteRestaurantIds({String? uid}) async {
    final localIds = await _localDataSource.getFavoriteRestaurantIds();
    if (uid == null || uid.isEmpty) return localIds;

    try {
      final cloudIds = await _cloudUserDataSource.getFavoriteRestaurantIds(uid);
      final merged = {...localIds, ...cloudIds};
      if (merged.length != localIds.length) {
        await _localDataSource.saveFavoriteRestaurantIds(merged);
      }
      return merged;
    } catch (_) {
      return localIds;
    }
  }

  @override
  Future<Set<String>> toggleFavoriteRestaurant({
    required String restaurantId,
    String? uid,
  }) async {
    final current = await _localDataSource.getFavoriteRestaurantIds();
    final updated = Set<String>.from(current);
    if (updated.contains(restaurantId)) {
      updated.remove(restaurantId);
    } else {
      updated.add(restaurantId);
    }

    await _localDataSource.saveFavoriteRestaurantIds(updated);

    if (uid != null && uid.isNotEmpty) {
      try {
        await _cloudUserDataSource.syncFavoriteRestaurantIds(
          uid: uid,
          favoriteIds: updated,
        );
      } catch (_) {
        // Offline-first: local Hive state remains authoritative until online.
      }
    }

    return updated;
  }

  List<RestaurantEntity> _applyFavorites(
    List<RestaurantModel> restaurants,
    Set<String> favoriteIds,
  ) {
    return restaurants
        .map(
          (restaurant) => restaurant.copyWith(
            isFavorite: favoriteIds.contains(restaurant.id),
          ),
        )
        .toList();
  }
}
