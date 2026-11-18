import 'package:equatable/equatable.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/domain/repositories/restaurant_repository.dart';
import 'package:food_delivery_application/domain/usecases/restaurant_usecases.dart';

enum RestaurantStatus { initial, loading, loaded, failure }

class RestaurantState extends Equatable {
  const RestaurantState({
    this.status = RestaurantStatus.initial,
    this.allRestaurants = const [],
    this.filteredRestaurants = const [],
    this.matchingDishes = const [],
    this.selectedCuisine = 'All',
    this.searchQuery = '',
    this.under30MinsOnly = false,
    this.rating45PlusOnly = false,
    this.freeOrLowDeliveryOnly = false,
    this.sortOption = RestaurantSortOption.popular,
    this.sourceTier,
    this.errorMessage,
  });

  final RestaurantStatus status;
  final List<RestaurantEntity> allRestaurants;
  final List<RestaurantEntity> filteredRestaurants;
  final List<DishEntity> matchingDishes;
  final String selectedCuisine;
  final String searchQuery;
  final bool under30MinsOnly;
  final bool rating45PlusOnly;
  final bool freeOrLowDeliveryOnly;
  final RestaurantSortOption sortOption;
  final CatalogDataSourceTier? sourceTier;
  final String? errorMessage;

  List<RestaurantEntity> get fastestRestaurants {
    final sorted = List<RestaurantEntity>.from(allRestaurants)
      ..sort((a, b) => a.deliveryTimeMinutes.compareTo(b.deliveryTimeMinutes));
    return sorted.take(5).toList();
  }

  List<RestaurantEntity> get favoriteRestaurants =>
      allRestaurants.where((r) => r.isFavorite).toList();

  bool get hasActiveFilters =>
      selectedCuisine != 'All' ||
      searchQuery.trim().isNotEmpty ||
      under30MinsOnly ||
      rating45PlusOnly ||
      freeOrLowDeliveryOnly ||
      sortOption != RestaurantSortOption.popular;

  RestaurantEntity? restaurantById(String id) {
    for (final restaurant in allRestaurants) {
      if (restaurant.id == id) return restaurant;
    }
    return null;
  }

  RestaurantState copyWith({
    RestaurantStatus? status,
    List<RestaurantEntity>? allRestaurants,
    List<RestaurantEntity>? filteredRestaurants,
    List<DishEntity>? matchingDishes,
    String? selectedCuisine,
    String? searchQuery,
    bool? under30MinsOnly,
    bool? rating45PlusOnly,
    bool? freeOrLowDeliveryOnly,
    RestaurantSortOption? sortOption,
    CatalogDataSourceTier? sourceTier,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RestaurantState(
      status: status ?? this.status,
      allRestaurants: allRestaurants ?? this.allRestaurants,
      filteredRestaurants: filteredRestaurants ?? this.filteredRestaurants,
      matchingDishes: matchingDishes ?? this.matchingDishes,
      selectedCuisine: selectedCuisine ?? this.selectedCuisine,
      searchQuery: searchQuery ?? this.searchQuery,
      under30MinsOnly: under30MinsOnly ?? this.under30MinsOnly,
      rating45PlusOnly: rating45PlusOnly ?? this.rating45PlusOnly,
      freeOrLowDeliveryOnly:
          freeOrLowDeliveryOnly ?? this.freeOrLowDeliveryOnly,
      sortOption: sortOption ?? this.sortOption,
      sourceTier: sourceTier ?? this.sourceTier,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    allRestaurants,
    filteredRestaurants,
    matchingDishes,
    selectedCuisine,
    searchQuery,
    under30MinsOnly,
    rating45PlusOnly,
    freeOrLowDeliveryOnly,
    sortOption,
    sourceTier,
    errorMessage,
  ];
}
