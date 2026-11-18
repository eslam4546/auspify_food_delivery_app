import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';

/// Indicates which tier of the 3-tier catalog pipeline supplied the data.
enum CatalogDataSourceTier { liveApi, localCache, bundledSeed }

/// Result wrapper containing the resolved restaurant catalog and its source tier.
class RestaurantCatalogResult {
  const RestaurantCatalogResult({
    required this.restaurants,
    required this.sourceTier,
  });

  final List<RestaurantEntity> restaurants;
  final CatalogDataSourceTier sourceTier;
}

/// Contract for the 3-tier resilient restaurant & menu catalog and favorites sync.
abstract class RestaurantRepository {
  /// Loads restaurants via Tier 1 (DummyJSON API) -> Tier 2 (Hive Cache) -> Tier 3 (Bundled Seed).
  Future<RestaurantCatalogResult> getRestaurants({
    String? uid,
    bool forceRefresh = false,
  });

  /// Searches dishes via DummyJSON API with local catalog fallback when offline.
  Future<List<DishEntity>> searchDishes(String query);

  /// Retrieves favorite restaurant IDs merged from Hive and Firestore.
  Future<Set<String>> getFavoriteRestaurantIds({String? uid});

  /// Toggles a restaurant's favorite state in Hive immediately and syncs to Firestore.
  Future<Set<String>> toggleFavoriteRestaurant({
    required String restaurantId,
    String? uid,
  });
}
