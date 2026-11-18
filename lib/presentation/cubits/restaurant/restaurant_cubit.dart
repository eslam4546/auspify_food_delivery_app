import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/domain/repositories/restaurant_repository.dart';
import 'package:food_delivery_application/domain/usecases/restaurant_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_state.dart';

/// Manages restaurant discovery, multi-criteria filtering, search, sorting,
/// and favorite restaurant toggling across Hive and Cloud Firestore.
class RestaurantCubit extends Cubit<RestaurantState> {
  RestaurantCubit({
    required this._getRestaurantsUseCase,
    required this._filterAndSortUseCase,
    required this._searchMatchingDishesUseCase,
    required this._toggleFavoriteUseCase,
  }) : super(const RestaurantState());

  final GetRestaurantsUseCase _getRestaurantsUseCase;
  final FilterAndSortRestaurantsUseCase _filterAndSortUseCase;
  final SearchMatchingDishesUseCase _searchMatchingDishesUseCase;
  final ToggleFavoriteRestaurantUseCase _toggleFavoriteUseCase;

  String? _activeUid;

  void bindUser(String? uid) {
    _activeUid = uid;
  }

  Future<void> loadRestaurants({String? uid, bool forceRefresh = false}) async {
    if (uid != null) _activeUid = uid;
    emit(state.copyWith(status: RestaurantStatus.loading, clearError: true));

    try {
      final result = await _getRestaurantsUseCase(
        uid: _activeUid,
        forceRefresh: forceRefresh,
      );
      _emitRecomputed(
        allRestaurants: result.restaurants,
        status: RestaurantStatus.loaded,
        sourceTier: result.sourceTier,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RestaurantStatus.failure,
          errorMessage: 'Unable to load restaurants: $e',
        ),
      );
    }
  }

  void selectCuisine(String cuisine) {
    _emitRecomputed(selectedCuisine: cuisine);
  }

  void updateSearchQuery(String query) {
    _emitRecomputed(searchQuery: query);
  }

  void toggleUnder30MinsFilter() {
    _emitRecomputed(under30MinsOnly: !state.under30MinsOnly);
  }

  void toggleRating45PlusFilter() {
    _emitRecomputed(rating45PlusOnly: !state.rating45PlusOnly);
  }

  void toggleFreeOrLowDeliveryFilter() {
    _emitRecomputed(freeOrLowDeliveryOnly: !state.freeOrLowDeliveryOnly);
  }

  void updateSortOption(RestaurantSortOption sortOption) {
    _emitRecomputed(sortOption: sortOption);
  }

  void resetFilters() {
    _emitRecomputed(
      selectedCuisine: 'All',
      searchQuery: '',
      under30MinsOnly: false,
      rating45PlusOnly: false,
      freeOrLowDeliveryOnly: false,
      sortOption: RestaurantSortOption.popular,
    );
  }

  Future<void> toggleFavorite(String restaurantId) async {
    // Optimistic UI update for instant feedback
    final optimisticList = state.allRestaurants
        .map(
          (r) =>
              r.id == restaurantId ? r.copyWith(isFavorite: !r.isFavorite) : r,
        )
        .toList();
    _emitRecomputed(allRestaurants: optimisticList);

    try {
      final syncedIds = await _toggleFavoriteUseCase(
        restaurantId: restaurantId,
        uid: _activeUid,
      );
      final reconciled = state.allRestaurants
          .map((r) => r.copyWith(isFavorite: syncedIds.contains(r.id)))
          .toList();
      _emitRecomputed(allRestaurants: reconciled);
    } catch (_) {
      // Keep optimistic state if cloud sync is momentarily offline.
    }
  }

  void _emitRecomputed({
    RestaurantStatus? status,
    List<RestaurantEntity>? allRestaurants,
    String? selectedCuisine,
    String? searchQuery,
    bool? under30MinsOnly,
    bool? rating45PlusOnly,
    bool? freeOrLowDeliveryOnly,
    RestaurantSortOption? sortOption,
    CatalogDataSourceTier? sourceTier,
  }) {
    final resolvedAll = allRestaurants ?? state.allRestaurants;
    final resolvedCuisine = selectedCuisine ?? state.selectedCuisine;
    final resolvedQuery = searchQuery ?? state.searchQuery;
    final resolvedUnder30 = under30MinsOnly ?? state.under30MinsOnly;
    final resolvedRating45 = rating45PlusOnly ?? state.rating45PlusOnly;
    final resolvedLowDelivery =
        freeOrLowDeliveryOnly ?? state.freeOrLowDeliveryOnly;
    final resolvedSort = sortOption ?? state.sortOption;

    final filtered = _filterAndSortUseCase(
      restaurants: resolvedAll,
      params: RestaurantFilterParams(
        selectedCuisine: resolvedCuisine,
        searchQuery: resolvedQuery,
        under30MinsOnly: resolvedUnder30,
        rating45PlusOnly: resolvedRating45,
        freeOrLowDeliveryOnly: resolvedLowDelivery,
        sortOption: resolvedSort,
      ),
    );

    final matchingDishes = _searchMatchingDishesUseCase(
      restaurants: resolvedAll,
      query: resolvedQuery,
      selectedCuisine: resolvedCuisine,
    );

    emit(
      state.copyWith(
        status: status ?? state.status,
        allRestaurants: resolvedAll,
        filteredRestaurants: filtered,
        matchingDishes: matchingDishes,
        selectedCuisine: resolvedCuisine,
        searchQuery: resolvedQuery,
        under30MinsOnly: resolvedUnder30,
        rating45PlusOnly: resolvedRating45,
        freeOrLowDeliveryOnly: resolvedLowDelivery,
        sortOption: resolvedSort,
        sourceTier: sourceTier ?? state.sourceTier,
        clearError: true,
      ),
    );
  }
}
