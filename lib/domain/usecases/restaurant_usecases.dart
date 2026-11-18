import 'package:equatable/equatable.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/domain/repositories/restaurant_repository.dart';

/// Supported sorting options for restaurant discovery and search.
enum RestaurantSortOption {
  popular('Popular'),
  fastestDelivery('Fastest Delivery'),
  lowestDeliveryFee('Lowest Delivery Fee'),
  topRated('Top Rated');

  const RestaurantSortOption(this.label);

  final String label;
}

/// Encapsulates active discovery & search filter parameters.
class RestaurantFilterParams extends Equatable {
  const RestaurantFilterParams({
    this.selectedCuisine = 'All',
    this.searchQuery = '',
    this.under30MinsOnly = false,
    this.rating45PlusOnly = false,
    this.freeOrLowDeliveryOnly = false,
    this.sortOption = RestaurantSortOption.popular,
  });

  final String selectedCuisine;
  final String searchQuery;
  final bool under30MinsOnly;
  final bool rating45PlusOnly;
  final bool freeOrLowDeliveryOnly;
  final RestaurantSortOption sortOption;

  @override
  List<Object?> get props => [
    selectedCuisine,
    searchQuery,
    under30MinsOnly,
    rating45PlusOnly,
    freeOrLowDeliveryOnly,
    sortOption,
  ];
}

class GetRestaurantsUseCase {
  const GetRestaurantsUseCase(this._repository);

  final RestaurantRepository _repository;

  Future<RestaurantCatalogResult> call({
    String? uid,
    bool forceRefresh = false,
  }) {
    return _repository.getRestaurants(uid: uid, forceRefresh: forceRefresh);
  }
}

class ToggleFavoriteRestaurantUseCase {
  const ToggleFavoriteRestaurantUseCase(this._repository);

  final RestaurantRepository _repository;

  Future<Set<String>> call({required String restaurantId, String? uid}) {
    return _repository.toggleFavoriteRestaurant(
      restaurantId: restaurantId,
      uid: uid,
    );
  }
}

/// Filters and sorts restaurants by cuisine, delivery speed, rating, fee, and search text.
class FilterAndSortRestaurantsUseCase {
  const FilterAndSortRestaurantsUseCase();

  List<RestaurantEntity> call({
    required List<RestaurantEntity> restaurants,
    required RestaurantFilterParams params,
  }) {
    final normalizedCuisine = params.selectedCuisine.trim().toLowerCase();
    final normalizedQuery = params.searchQuery.trim().toLowerCase();

    final filtered = restaurants.where((restaurant) {
      if (normalizedCuisine.isNotEmpty && normalizedCuisine != 'all') {
        final hasCuisine = restaurant.cuisineTags.any(
          (tag) => tag.toLowerCase().contains(normalizedCuisine),
        );
        if (!hasCuisine) return false;
      }

      if (params.under30MinsOnly && restaurant.deliveryTimeMinutes >= 30) {
        return false;
      }

      if (params.rating45PlusOnly && restaurant.rating < 4.5) {
        return false;
      }

      if (params.freeOrLowDeliveryOnly && restaurant.deliveryFee > 2.50) {
        return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final matchesName = restaurant.name.toLowerCase().contains(
          normalizedQuery,
        );
        final matchesCuisine = restaurant.cuisineTags.any(
          (tag) => tag.toLowerCase().contains(normalizedQuery),
        );
        final matchesDish = restaurant.dishes.any(
          (dish) =>
              dish.name.toLowerCase().contains(normalizedQuery) ||
              dish.description.toLowerCase().contains(normalizedQuery) ||
              dish.category.toLowerCase().contains(normalizedQuery),
        );
        if (!matchesName && !matchesCuisine && !matchesDish) return false;
      }

      return true;
    }).toList();

    switch (params.sortOption) {
      case RestaurantSortOption.popular:
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case RestaurantSortOption.fastestDelivery:
        filtered.sort(
          (a, b) => a.deliveryTimeMinutes.compareTo(b.deliveryTimeMinutes),
        );
      case RestaurantSortOption.lowestDeliveryFee:
        filtered.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
      case RestaurantSortOption.topRated:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return filtered;
  }
}

/// Returns dishes across all restaurants matching a search query and active filters.
class SearchMatchingDishesUseCase {
  const SearchMatchingDishesUseCase();

  List<DishEntity> call({
    required List<RestaurantEntity> restaurants,
    required String query,
    String selectedCuisine = 'All',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    final normalizedCuisine = selectedCuisine.trim().toLowerCase();
    final matches = <DishEntity>[];

    for (final restaurant in restaurants) {
      if (normalizedCuisine.isNotEmpty && normalizedCuisine != 'all') {
        final cuisineMatch = restaurant.cuisineTags.any(
          (tag) => tag.toLowerCase().contains(normalizedCuisine),
        );
        if (!cuisineMatch) continue;
      }

      for (final dish in restaurant.dishes) {
        final isMatch =
            dish.name.toLowerCase().contains(normalizedQuery) ||
            dish.description.toLowerCase().contains(normalizedQuery) ||
            dish.ingredients.any(
              (i) => i.toLowerCase().contains(normalizedQuery),
            );
        if (isMatch) {
          matches.add(dish);
        }
      }
    }

    return matches;
  }
}
