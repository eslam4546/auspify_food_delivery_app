import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';

/// Data model for [MealSizeOption] supporting JSON, Firestore, and Hive maps.
class MealSizeOptionModel extends MealSizeOption {
  const MealSizeOptionModel({
    required super.id,
    required super.name,
    required super.priceDelta,
  });

  factory MealSizeOptionModel.fromEntity(MealSizeOption entity) {
    return MealSizeOptionModel(
      id: entity.id,
      name: entity.name,
      priceDelta: entity.priceDelta,
    );
  }

  factory MealSizeOptionModel.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return MealSizeOptionModel(
      id:
          (map['id'] as String?) ??
          ((map['name'] as String?) ?? 'small').toLowerCase().replaceAll(
            ' ',
            '_',
          ),
      name: (map['name'] as String?) ?? 'Small (Regular)',
      priceDelta: (map['priceDelta'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'priceDelta': priceDelta};
  }
}

/// Data model for [MealAddonOption] supporting JSON, Firestore, and Hive maps.
class MealAddonOptionModel extends MealAddonOption {
  const MealAddonOptionModel({
    required super.id,
    required super.name,
    required super.price,
  });

  factory MealAddonOptionModel.fromEntity(MealAddonOption entity) {
    return MealAddonOptionModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
    );
  }

  factory MealAddonOptionModel.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return MealAddonOptionModel(
      id:
          (map['id'] as String?) ??
          ((map['name'] as String?) ?? 'addon').toLowerCase().replaceAll(
            ' ',
            '_',
          ),
      name: (map['name'] as String?) ?? 'Extra Topping',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price};
  }
}

/// Data model for [DishEntity] supporting DummyJSON payloads and Hive maps.
class DishModel extends DishEntity {
  const DishModel({
    required super.id,
    required super.restaurantId,
    required super.restaurantName,
    required super.name,
    required super.description,
    required super.image,
    required super.category,
    required super.basePrice,
    required super.calories,
    required super.prepTimeMinutes,
    required super.rating,
    super.ingredients,
    super.isPopular,
    super.availableSizes,
    super.availableAddons,
  });

  factory DishModel.fromEntity(DishEntity entity) {
    return DishModel(
      id: entity.id,
      restaurantId: entity.restaurantId,
      restaurantName: entity.restaurantName,
      name: entity.name,
      description: entity.description,
      image: entity.image,
      category: entity.category,
      basePrice: entity.basePrice,
      calories: entity.calories,
      prepTimeMinutes: entity.prepTimeMinutes,
      rating: entity.rating,
      ingredients: entity.ingredients,
      isPopular: entity.isPopular,
      availableSizes: entity.availableSizes,
      availableAddons: entity.availableAddons,
    );
  }

  /// Maps a DummyJSON `/recipes` item into a customizable [DishModel].
  factory DishModel.fromDummyJson(
    Map<String, dynamic> json, {
    required String restaurantId,
    required String restaurantName,
    required String category,
    bool isPopular = false,
  }) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    final name = (json['name'] as String?)?.trim() ?? 'Chef Special Dish';
    final ingredients = ((json['ingredients'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final instructions = ((json['instructions'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final calories = (json['caloriesPerServing'] as num?)?.toInt() ?? 420;
    final prepMins =
        ((json['prepTimeMinutes'] as num?)?.toInt() ?? 15) +
        (((json['cookTimeMinutes'] as num?)?.toInt() ?? 10) ~/ 2);
    final rating = (json['rating'] as num?)?.toDouble() ?? 4.6;

    // Deterministic appetizing restaurant menu pricing ($8.99 - $22.99)
    final derivedPrice = double.parse(
      (8.99 + ((id * 1.75) % 13.0) + (calories > 450 ? 1.50 : 0.0))
          .toStringAsFixed(2),
    );

    final description = ingredients.isNotEmpty
        ? 'Crafted fresh with ${ingredients.take(4).join(', ')}.'
        : (instructions.isNotEmpty
              ? instructions.first
              : 'Freshly prepared to order by our kitchen.');

    return DishModel(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      name: name,
      description: description,
      image: (json['image'] as String?) ?? '',
      category: category,
      basePrice: derivedPrice,
      calories: calories,
      prepTimeMinutes: prepMins.clamp(10, 45),
      rating: double.parse(rating.clamp(3.5, 5.0).toStringAsFixed(1)),
      ingredients: ingredients,
      isPopular: isPopular || rating >= 4.7,
      availableSizes: MealSizeOption.defaultSizes,
      availableAddons: MealAddonOption.defaultAddons,
    );
  }

  factory DishModel.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final sizesRaw = (map['availableSizes'] as List?) ?? const [];
    final addonsRaw = (map['availableAddons'] as List?) ?? const [];

    return DishModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      restaurantId: (map['restaurantId'] as String?) ?? '',
      restaurantName: (map['restaurantName'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      image: (map['image'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Main Dishes',
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toInt() ?? 350,
      prepTimeMinutes: (map['prepTimeMinutes'] as num?)?.toInt() ?? 20,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      ingredients: ((map['ingredients'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      isPopular: (map['isPopular'] as bool?) ?? false,
      availableSizes: sizesRaw.isEmpty
          ? MealSizeOption.defaultSizes
          : sizesRaw
                .map(
                  (e) =>
                      MealSizeOptionModel.fromMap(e as Map<dynamic, dynamic>),
                )
                .toList(),
      availableAddons: addonsRaw.isEmpty
          ? MealAddonOption.defaultAddons
          : addonsRaw
                .map(
                  (e) =>
                      MealAddonOptionModel.fromMap(e as Map<dynamic, dynamic>),
                )
                .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'name': name,
      'description': description,
      'image': image,
      'category': category,
      'basePrice': basePrice,
      'calories': calories,
      'prepTimeMinutes': prepTimeMinutes,
      'rating': rating,
      'ingredients': ingredients,
      'isPopular': isPopular,
      'availableSizes': availableSizes
          .map((s) => MealSizeOptionModel.fromEntity(s).toMap())
          .toList(),
      'availableAddons': availableAddons
          .map((a) => MealAddonOptionModel.fromEntity(a).toMap())
          .toList(),
    };
  }
}

/// Data model for [RestaurantEntity] serialized to/from Hive local cache.
class RestaurantModel extends RestaurantEntity {
  const RestaurantModel({
    required super.id,
    required super.name,
    required super.coverImage,
    required super.cuisineTags,
    required super.rating,
    required super.reviewCount,
    required super.deliveryTimeMinutes,
    required super.deliveryFee,
    required super.minOrderAmount,
    required super.menuCategories,
    required super.dishes,
    super.promoBadge,
    super.isFavorite,
  });

  factory RestaurantModel.fromEntity(RestaurantEntity entity) {
    return RestaurantModel(
      id: entity.id,
      name: entity.name,
      coverImage: entity.coverImage,
      cuisineTags: entity.cuisineTags,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      deliveryTimeMinutes: entity.deliveryTimeMinutes,
      deliveryFee: entity.deliveryFee,
      minOrderAmount: entity.minOrderAmount,
      promoBadge: entity.promoBadge,
      isFavorite: entity.isFavorite,
      menuCategories: entity.menuCategories,
      dishes: entity.dishes,
    );
  }

  factory RestaurantModel.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return RestaurantModel(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      coverImage: (map['coverImage'] as String?) ?? '',
      cuisineTags: ((map['cuisineTags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 100,
      deliveryTimeMinutes: (map['deliveryTimeMinutes'] as num?)?.toInt() ?? 25,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 1.99,
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 10.0,
      promoBadge: map['promoBadge'] as String?,
      isFavorite: (map['isFavorite'] as bool?) ?? false,
      menuCategories: ((map['menuCategories'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      dishes: ((map['dishes'] as List?) ?? const [])
          .map((e) => DishModel.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coverImage': coverImage,
      'cuisineTags': cuisineTags,
      'rating': rating,
      'reviewCount': reviewCount,
      'deliveryTimeMinutes': deliveryTimeMinutes,
      'deliveryFee': deliveryFee,
      'minOrderAmount': minOrderAmount,
      'promoBadge': promoBadge,
      'isFavorite': isFavorite,
      'menuCategories': menuCategories,
      'dishes': dishes.map((d) => DishModel.fromEntity(d).toMap()).toList(),
    };
  }
}
