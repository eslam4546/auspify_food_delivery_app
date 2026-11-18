import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/domain/usecases/restaurant_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_state.dart';
import 'package:food_delivery_application/presentation/widgets/resilient_network_image.dart';
import 'package:food_delivery_application/presentation/widgets/restaurant_card.dart';

/// Stitch Screen 3 (`d7d50ca1bf0b4726bd0b899ec9cece84`): Search & Cuisines Filter.
class RestaurantSearchPage extends StatefulWidget {
  const RestaurantSearchPage({
    super.key,
    required this.onOpenRestaurant,
    required this.onOpenDishCustomization,
  });

  final ValueChanged<RestaurantEntity> onOpenRestaurant;
  final void Function(RestaurantEntity restaurant, DishEntity dish)
  onOpenDishCustomization;

  @override
  State<RestaurantSearchPage> createState() => _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends State<RestaurantSearchPage> {
  final _searchController = TextEditingController();
  int _selectedSegment = 0; // 0: Restaurants, 1: Dishes & Items
  final List<String> _quickSearches = [
    'Pizza',
    'Chicken',
    'Pasta',
    'Salad',
    'Burger',
    'Cookie',
  ];

  @override
  void initState() {
    super.initState();
    final currentQuery = context.read<RestaurantCubit>().state.searchQuery;
    if (currentQuery.isNotEmpty) {
      _searchController.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyQuery(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    context.read<RestaurantCubit>().updateSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: BlocBuilder<RestaurantCubit, RestaurantState>(
        builder: (context, state) {
          final matchingDishes = state.searchQuery.trim().isEmpty
              ? state.filteredRestaurants
                    .expand((r) => r.dishes.take(2))
                    .toList()
              : state.matchingDishes;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search & Filter',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => context
                                  .read<RestaurantCubit>()
                                  .updateSearchQuery(value),
                              decoration: InputDecoration(
                                hintText: 'Dishes, cuisines, restaurants...',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () => _applyQuery(''),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusControl,
                            ),
                            onTap: () => _showSortBottomSheet(context, state),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppColors.radiusControl,
                                ),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterPill(
                        label: 'Under 30 Mins',
                        isActive: state.under30MinsOnly,
                        onTap: () => context
                            .read<RestaurantCubit>()
                            .toggleUnder30MinsFilter(),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: '4.5+ ★',
                        isActive: state.rating45PlusOnly,
                        onTap: () => context
                            .read<RestaurantCubit>()
                            .toggleRating45PlusFilter(),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Free / Low Delivery',
                        isActive: state.freeOrLowDeliveryOnly,
                        onTap: () => context
                            .read<RestaurantCubit>()
                            .toggleFreeOrLowDeliveryFilter(),
                      ),
                      const SizedBox(width: 8),
                      ...AppConstants.cuisineCategories
                          .where((c) => c != 'All')
                          .map(
                            (cuisine) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterPill(
                                label: cuisine,
                                isActive: state.selectedCuisine == cuisine,
                                onTap: () {
                                  final cubit = context.read<RestaurantCubit>();
                                  cubit.selectCuisine(
                                    state.selectedCuisine == cuisine
                                        ? 'All'
                                        : cuisine,
                                  );
                                },
                              ),
                            ),
                          ),
                      if (state.hasActiveFilters)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            context.read<RestaurantCubit>().resetFilters();
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 17,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Found ${state.filteredRestaurants.length} restaurants & ${matchingDishes.length} dishes',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showSortBottomSheet(context, state),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : const Color(0xFFEAEDFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Sort: ${state.sortOption.label}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusControl,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SegmentButton(
                                label:
                                    'Restaurants (${state.filteredRestaurants.length})',
                                isSelected: _selectedSegment == 0,
                                onTap: () =>
                                    setState(() => _selectedSegment = 0),
                              ),
                            ),
                            Expanded(
                              child: _SegmentButton(
                                label:
                                    'Dishes & Items (${matchingDishes.length})',
                                isSelected: _selectedSegment == 1,
                                onTap: () =>
                                    setState(() => _selectedSegment = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.searchQuery.trim().isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusCard,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 17,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Popular Searches',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickSearches
                                .map(
                                  (term) => ActionChip(
                                    avatar: const Icon(
                                      Icons.search_rounded,
                                      size: 15,
                                    ),
                                    label: Text(term),
                                    onPressed: () => _applyQuery(term),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_selectedSegment == 0)
                _buildRestaurantsSliver(context, state)
              else
                _buildDishesSliver(context, state, matchingDishes),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRestaurantsSliver(BuildContext context, RestaurantState state) {
    if (state.filteredRestaurants.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptySearchResult(
          onReset: () {
            _searchController.clear();
            context.read<RestaurantCubit>().resetFilters();
          },
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: state.filteredRestaurants.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final restaurant = state.filteredRestaurants[index];
          return RestaurantCard(
            restaurant: restaurant,
            onTap: () => widget.onOpenRestaurant(restaurant),
            onToggleFavorite: () =>
                context.read<RestaurantCubit>().toggleFavorite(restaurant.id),
          );
        },
      ),
    );
  }

  Widget _buildDishesSliver(
    BuildContext context,
    RestaurantState state,
    List<DishEntity> dishes,
  ) {
    if (dishes.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptySearchResult(
          onReset: () {
            _searchController.clear();
            context.read<RestaurantCubit>().resetFilters();
          },
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: dishes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final dish = dishes[index];
          final restaurant = state.restaurantById(dish.restaurantId);
          return InkWell(
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            onTap: () {
              if (restaurant != null) {
                widget.onOpenDishCustomization(restaurant, dish);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusCard),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: AppColors.cardShadow(theme.brightness),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (dish.isPopular) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft.withValues(
                                    alpha: isDark ? 0.25 : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'BESTSELLER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                dish.restaurantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dish.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dish.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$${dish.basePrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${dish.calories} kcal',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ResilientNetworkImage(
                        imageUrl: dish.image,
                        width: 92,
                        height: 92,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: AppColors.cardShadow(theme.brightness),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context, RestaurantState state) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort Restaurants By',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ...RestaurantSortOption.values.map(
                (option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option.label,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  trailing: state.sortOption == option
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : const Icon(Icons.radio_button_off_rounded),
                  onTap: () {
                    context.read<RestaurantCubit>().updateSortOption(option);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.primary : AppColors.lightInk)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkCardElevated : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            'No matching restaurants or dishes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing filters or searching for another cuisine.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onReset,
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
            child: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }
}
