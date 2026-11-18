import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/errors/exceptions.dart';
import 'package:food_delivery_application/core/network/dio_client.dart';
import 'package:food_delivery_application/data/models/restaurant_dish_models.dart';

/// Contract for Tier 1 remote restaurant & recipe fetching via DummyJSON API.
abstract class RestaurantRemoteDataSource {
  Future<List<RestaurantModel>> fetchRestaurants();

  Future<List<DishModel>> searchDishes(String query);

  Future<List<DishModel>> fetchDishesByTag(String tag);
}

class _StorefrontBlueprint {
  const _StorefrontBlueprint({
    required this.id,
    required this.name,
    required this.cuisineTags,
    required this.deliveryTimeMinutes,
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.promoBadge,
    required this.fallbackCoverImage,
    required this.reviewCount,
  });

  final String id;
  final String name;
  final List<String> cuisineTags;
  final int deliveryTimeMinutes;
  final double deliveryFee;
  final double minOrderAmount;
  final String? promoBadge;
  final String fallbackCoverImage;
  final int reviewCount;
}

class RestaurantRemoteDataSourceImpl implements RestaurantRemoteDataSource {
  RestaurantRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  static const Map<String, _StorefrontBlueprint> _blueprints = {
    'italian_pizza': _StorefrontBlueprint(
      id: 'rest_napoli_hearth_pizza',
      name: 'Napoli Hearth Artisan Pizza',
      cuisineTags: ['Pizza', 'Italian'],
      deliveryTimeMinutes: 22,
      deliveryFee: 1.99,
      minOrderAmount: 12.0,
      promoBadge: '20% Off WELCOME20',
      fallbackCoverImage: 'https://cdn.dummyjson.com/recipe-images/1.webp',
      reviewCount: 530,
    ),
    'asian': _StorefrontBlueprint(
      id: 'rest_kyoto_wok_kitchen',
      name: 'Kyoto Wok & Ramen House',
      cuisineTags: ['Asian', 'Japanese', 'Noodles'],
      deliveryTimeMinutes: 25,
      deliveryFee: 2.49,
      minOrderAmount: 14.0,
      promoBadge: 'Top Rated Asian',
      fallbackCoverImage: 'https://cdn.dummyjson.com/recipe-images/2.webp',
      reviewCount: 384,
    ),
    'burgers_grill': _StorefrontBlueprint(
      id: 'rest_fire_flame_burgers',
      name: 'Fire & Flame Smash Grill',
      cuisineTags: ['Burgers', 'American', 'Grill'],
      deliveryTimeMinutes: 18,
      deliveryFee: 0.0,
      minOrderAmount: 10.0,
      promoBadge: 'Free Delivery',
      fallbackCoverImage: 'https://cdn.dummyjson.com/recipe-images/14.webp',
      reviewCount: 446,
    ),
    'healthy': _StorefrontBlueprint(
      id: 'rest_verde_harvest_bowls',
      name: 'Verde Harvest Fresh Bowls',
      cuisineTags: ['Healthy', 'Mediterranean', 'Salads'],
      deliveryTimeMinutes: 16,
      deliveryFee: 0.0,
      minOrderAmount: 9.0,
      promoBadge: 'Under 20 Mins',
      fallbackCoverImage: 'https://cdn.dummyjson.com/recipe-images/7.webp',
      reviewCount: 271,
    ),
    'desserts': _StorefrontBlueprint(
      id: 'rest_velvet_crumb_patisserie',
      name: 'Velvet Crumb Patisserie',
      cuisineTags: ['Desserts', 'Bakery', 'Cafe'],
      deliveryTimeMinutes: 20,
      deliveryFee: 1.49,
      minOrderAmount: 8.0,
      promoBadge: 'Fresh Baked',
      fallbackCoverImage: 'https://cdn.dummyjson.com/recipe-images/3.webp',
      reviewCount: 318,
    ),
    'world_kitchen': _StorefrontBlueprint(
      id: 'rest_saffron_spice_bistro',
      name: 'Saffron & Spice Kitchen',
      cuisineTags: ['Asian', 'Italian', 'Healthy'],
      deliveryTimeMinutes: 28,
      deliveryFee: 2.29,
      minOrderAmount: 13.0,
      promoBadge: 'Chef Curated',
      fallbackCoverImage: 'https://cdn.dummyjson.com/recipe-images/11.webp',
      reviewCount: 256,
    ),
  };

  @override
  Future<List<RestaurantModel>> fetchRestaurants() async {
    final json = await _dioClient.getJson(
      AppConstants.recipesEndpoint,
      queryParameters: {'limit': AppConstants.defaultRecipesLimit},
    );

    final recipesRaw = (json['recipes'] as List?) ?? const [];
    if (recipesRaw.isEmpty) {
      throw const ServerException('Recipe API returned an empty catalog.');
    }

    final grouped = <String, List<Map<String, dynamic>>>{
      for (final key in _blueprints.keys) key: [],
    };

    for (final item in recipesRaw) {
      if (item is! Map<String, dynamic>) continue;
      final bucketKey = _resolveStorefrontBucket(item);
      grouped[bucketKey]!.add(item);
    }

    final restaurants = <RestaurantModel>[];
    for (final entry in _blueprints.entries) {
      final recipeList = grouped[entry.key]!;
      if (recipeList.isEmpty) continue;

      final bp = entry.value;
      final dishes = <DishModel>[];

      for (var i = 0; i < recipeList.length; i++) {
        final rawRecipe = recipeList[i];
        final category = _resolveMenuCategory(rawRecipe, index: i);
        dishes.add(
          DishModel.fromDummyJson(
            rawRecipe,
            restaurantId: bp.id,
            restaurantName: bp.name,
            category: category,
            isPopular: i == 0 || i == 1,
          ),
        );
      }

      final avgRating = dishes.isEmpty
          ? 4.7
          : dishes.fold<double>(0.0, (sum, d) => sum + d.rating) /
                dishes.length;

      final coverImage = (dishes.isNotEmpty && dishes.first.image.isNotEmpty)
          ? dishes.first.image
          : bp.fallbackCoverImage;

      restaurants.add(
        RestaurantModel(
          id: bp.id,
          name: bp.name,
          coverImage: coverImage,
          cuisineTags: bp.cuisineTags,
          rating: double.parse(avgRating.clamp(4.2, 5.0).toStringAsFixed(1)),
          reviewCount: bp.reviewCount,
          deliveryTimeMinutes: bp.deliveryTimeMinutes,
          deliveryFee: bp.deliveryFee,
          minOrderAmount: bp.minOrderAmount,
          promoBadge: bp.promoBadge,
          menuCategories: AppConstants.menuCategories,
          dishes: dishes,
        ),
      );
    }

    if (restaurants.isEmpty) {
      throw const ServerException('Unable to build restaurant storefronts.');
    }
    return restaurants;
  }

  @override
  Future<List<DishModel>> searchDishes(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final json = await _dioClient.getJson(
      AppConstants.recipesSearchEndpoint,
      queryParameters: {'q': trimmed},
    );
    return _parseDishList(json);
  }

  @override
  Future<List<DishModel>> fetchDishesByTag(String tag) async {
    final encodedTag = Uri.encodeComponent(tag.trim());
    final json = await _dioClient.getJson(
      '${AppConstants.recipesTagEndpoint}/$encodedTag',
    );
    return _parseDishList(json);
  }

  List<DishModel> _parseDishList(Map<String, dynamic> json) {
    final recipesRaw = (json['recipes'] as List?) ?? const [];
    final dishes = <DishModel>[];

    for (var i = 0; i < recipesRaw.length; i++) {
      final item = recipesRaw[i];
      if (item is! Map<String, dynamic>) continue;
      final bucketKey = _resolveStorefrontBucket(item);
      final bp = _blueprints[bucketKey]!;
      dishes.add(
        DishModel.fromDummyJson(
          item,
          restaurantId: bp.id,
          restaurantName: bp.name,
          category: _resolveMenuCategory(item, index: i),
        ),
      );
    }
    return dishes;
  }

  String _resolveStorefrontBucket(Map<String, dynamic> recipe) {
    final cuisine = ((recipe['cuisine'] as String?) ?? '').toLowerCase();
    final name = ((recipe['name'] as String?) ?? '').toLowerCase();
    final mealTypes = ((recipe['mealType'] as List?) ?? const [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    final tags = ((recipe['tags'] as List?) ?? const [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    if (mealTypes.any((m) => m.contains('dessert') || m.contains('beverage')) ||
        tags.any(
          (t) =>
              t.contains('dessert') ||
              t.contains('cookie') ||
              t.contains('smoothie'),
        ) ||
        name.contains('cookie') ||
        name.contains('tiramisu') ||
        name.contains('smoothie') ||
        name.contains('lassi')) {
      return 'desserts';
    }

    if (cuisine.contains('italian') ||
        name.contains('pizza') ||
        name.contains('pasta') ||
        tags.any((t) => t.contains('pizza') || t.contains('pasta'))) {
      return 'italian_pizza';
    }

    if (cuisine.contains('asian') ||
        cuisine.contains('japanese') ||
        cuisine.contains('korean') ||
        cuisine.contains('thai') ||
        cuisine.contains('vietnamese') ||
        name.contains('ramen') ||
        name.contains('stir-fry')) {
      return 'asian';
    }

    if (cuisine.contains('mediterranean') ||
        cuisine.contains('greek') ||
        cuisine.contains('lebanese') ||
        name.contains('salad') ||
        name.contains('quinoa') ||
        tags.any((t) => t.contains('salad') || t.contains('vegetarian'))) {
      return 'healthy';
    }

    if (cuisine.contains('american') ||
        cuisine.contains('mexican') ||
        cuisine.contains('brazilian') ||
        name.contains('burger') ||
        name.contains('wings') ||
        name.contains('tacos') ||
        name.contains('beef')) {
      return 'burgers_grill';
    }

    return 'world_kitchen';
  }

  String _resolveMenuCategory(
    Map<String, dynamic> recipe, {
    required int index,
  }) {
    final mealTypes = ((recipe['mealType'] as List?) ?? const [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    final name = ((recipe['name'] as String?) ?? '').toLowerCase();

    if (mealTypes.any((m) => m.contains('dessert') || m.contains('beverage')) ||
        name.contains('smoothie') ||
        name.contains('cookie') ||
        name.contains('tiramisu') ||
        name.contains('lassi')) {
      return 'Drinks & Desserts';
    }

    if (mealTypes.any(
          (m) =>
              m.contains('snack') ||
              m.contains('appetizer') ||
              m.contains('side'),
        ) ||
        name.contains('salad') ||
        name.contains('soup') ||
        name.contains('bruschetta')) {
      return 'Sides & Appetizers';
    }

    if (index == 0) {
      return 'Popular';
    }

    return 'Main Dishes';
  }
}
