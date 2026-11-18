import 'package:equatable/equatable.dart';

/// Represents a selectable meal portion size (e.g., Small, Medium, Large).
class MealSizeOption extends Equatable {
  const MealSizeOption({
    required this.id,
    required this.name,
    required this.priceDelta,
  });

  final String id;
  final String name;
  final double priceDelta;

  static const List<MealSizeOption> defaultSizes = [
    MealSizeOption(id: 'small', name: 'Small (Regular)', priceDelta: 0.0),
    MealSizeOption(id: 'medium', name: 'Medium', priceDelta: 2.0),
    MealSizeOption(id: 'large', name: 'Large', priceDelta: 4.0),
  ];

  @override
  List<Object?> get props => [id, name, priceDelta];
}

/// Represents an optional extra topping or add-on for a meal.
class MealAddonOption extends Equatable {
  const MealAddonOption({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  static const List<MealAddonOption> defaultAddons = [
    MealAddonOption(id: 'extra_cheese', name: 'Extra Cheese', price: 1.50),
    MealAddonOption(id: 'crispy_beef', name: 'Crispy Smoked Beef', price: 2.50),
    MealAddonOption(
      id: 'signature_sauce',
      name: 'Signature Sauce',
      price: 0.75,
    ),
    MealAddonOption(id: 'drink_combo', name: 'Soft Drink Combo', price: 2.00),
  ];

  @override
  List<Object?> get props => [id, name, price];
}

/// Represents a customizable dish on a restaurant's menu.
class DishEntity extends Equatable {
  const DishEntity({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.name,
    required this.description,
    required this.image,
    required this.category,
    required this.basePrice,
    required this.calories,
    required this.prepTimeMinutes,
    required this.rating,
    this.ingredients = const [],
    this.isPopular = false,
    this.availableSizes = MealSizeOption.defaultSizes,
    this.availableAddons = MealAddonOption.defaultAddons,
  });

  final int id;
  final String restaurantId;
  final String restaurantName;
  final String name;
  final String description;
  final String image;
  final String category;
  final double basePrice;
  final int calories;
  final int prepTimeMinutes;
  final double rating;
  final List<String> ingredients;
  final bool isPopular;
  final List<MealSizeOption> availableSizes;
  final List<MealAddonOption> availableAddons;

  DishEntity copyWith({
    int? id,
    String? restaurantId,
    String? restaurantName,
    String? name,
    String? description,
    String? image,
    String? category,
    double? basePrice,
    int? calories,
    int? prepTimeMinutes,
    double? rating,
    List<String>? ingredients,
    bool? isPopular,
    List<MealSizeOption>? availableSizes,
    List<MealAddonOption>? availableAddons,
  }) {
    return DishEntity(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      calories: calories ?? this.calories,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      rating: rating ?? this.rating,
      ingredients: ingredients ?? this.ingredients,
      isPopular: isPopular ?? this.isPopular,
      availableSizes: availableSizes ?? this.availableSizes,
      availableAddons: availableAddons ?? this.availableAddons,
    );
  }

  @override
  List<Object?> get props => [
    id,
    restaurantId,
    restaurantName,
    name,
    description,
    image,
    category,
    basePrice,
    calories,
    prepTimeMinutes,
    rating,
    ingredients,
    isPopular,
    availableSizes,
    availableAddons,
  ];
}

/// Represents a restaurant storefront with its metadata and categorized menu.
class RestaurantEntity extends Equatable {
  const RestaurantEntity({
    required this.id,
    required this.name,
    required this.coverImage,
    required this.cuisineTags,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTimeMinutes,
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.menuCategories,
    required this.dishes,
    this.promoBadge,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String coverImage;
  final List<String> cuisineTags;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMinutes;
  final double deliveryFee;
  final double minOrderAmount;
  final String? promoBadge;
  final bool isFavorite;
  final List<String> menuCategories;
  final List<DishEntity> dishes;

  String get deliveryTimeLabel =>
      '$deliveryTimeMinutes-${deliveryTimeMinutes + 10} min';

  String get deliveryFeeLabel => deliveryFee <= 0
      ? 'Free Delivery'
      : '\$${deliveryFee.toStringAsFixed(2)} delivery';

  RestaurantEntity copyWith({
    String? id,
    String? name,
    String? coverImage,
    List<String>? cuisineTags,
    double? rating,
    int? reviewCount,
    int? deliveryTimeMinutes,
    double? deliveryFee,
    double? minOrderAmount,
    String? promoBadge,
    bool? isFavorite,
    List<String>? menuCategories,
    List<DishEntity>? dishes,
  }) {
    return RestaurantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImage: coverImage ?? this.coverImage,
      cuisineTags: cuisineTags ?? this.cuisineTags,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      promoBadge: promoBadge ?? this.promoBadge,
      isFavorite: isFavorite ?? this.isFavorite,
      menuCategories: menuCategories ?? this.menuCategories,
      dishes: dishes ?? this.dishes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    coverImage,
    cuisineTags,
    rating,
    reviewCount,
    deliveryTimeMinutes,
    deliveryFee,
    minOrderAmount,
    promoBadge,
    isFavorite,
    menuCategories,
    dishes,
  ];
}
