import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_state.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_state.dart';
import 'package:food_delivery_application/presentation/widgets/dish_selection_card.dart';
import 'package:food_delivery_application/presentation/widgets/resilient_network_image.dart';

/// Stitch Screen 4 (`a0c2a0176f4147fd9ba31dc2595e16a8`): Restaurant Storefront & Menu.
class RestaurantDetailsPage extends StatefulWidget {
  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
    required this.onSelectDish,
    required this.onViewCart,
  });

  final RestaurantEntity restaurant;
  final void Function(RestaurantEntity restaurant, DishEntity dish)
  onSelectDish;
  final VoidCallback onViewCart;

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, restaurantState) {
        final currentRestaurant =
            restaurantState.restaurantById(widget.restaurant.id) ??
            widget.restaurant;

        final availableCategories = <String>['All'];
        for (final cat in currentRestaurant.menuCategories) {
          final hasItems = currentRestaurant.dishes.any(
            (d) => d.category == cat || (cat == 'Popular' && d.isPopular),
          );
          if (hasItems && !availableCategories.contains(cat)) {
            availableCategories.add(cat);
          }
        }

        final visibleDishes = currentRestaurant.dishes.where((dish) {
          if (_selectedCategory == 'All') return true;
          if (_selectedCategory == 'Popular') {
            return dish.isPopular || dish.category == 'Popular';
          }
          return dish.category == _selectedCategory;
        }).toList();

        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeroWithSummaryCard(
                      context,
                      currentRestaurant,
                      theme,
                      isDark,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyCategoryHeaderDelegate(
                      categories: availableCategories,
                      selectedCategory: _selectedCategory,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      onSelect: (category) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory == 'All'
                                ? 'Full Menu'
                                : _selectedCategory,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : const Color(0xFFEAEDFF),
                              borderRadius: BorderRadius.circular(
                                AppColors.radiusPill,
                              ),
                            ),
                            child: Text(
                              '${visibleDishes.length} items',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.separated(
                      itemCount: visibleDishes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final dish = visibleDishes[index];
                        return DishSelectionCard(
                          dish: dish,
                          onTap: () =>
                              widget.onSelectDish(currentRestaurant, dish),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 112)),
                ],
              ),
              BlocBuilder<FoodCartCubit, FoodCartState>(
                builder: (context, cartState) {
                  if (cartState.isEmpty) return const SizedBox.shrink();
                  return Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 14,
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusControl,
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.35),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusControl,
                        ),
                        onTap: widget.onViewCart,
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${cartState.totalItemCount}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '\$${cartState.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const Row(
                                children: [
                                  Text(
                                    'View Cart',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroWithSummaryCard(
    BuildContext context,
    RestaurantEntity restaurant,
    ThemeData theme,
    bool isDark,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        SizedBox(
          height: 240 + topPadding,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ResilientNetworkImage(
                imageUrl: restaurant.coverImage,
                fit: BoxFit.cover,
                fallbackIcon: Icons.storefront_rounded,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x55000000),
                      Colors.transparent,
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: topPadding + 10,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FrostedCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _FrostedCircleButton(
                      icon: restaurant.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: restaurant.isFavorite
                          ? AppColors.primary
                          : null,
                      onTap: () => context
                          .read<RestaurantCubit>()
                          .toggleFavorite(restaurant.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusCard),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: AppColors.cardShadow(theme.brightness),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisineTags.join(' • '),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : const Color(0xFFEAEDFF),
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount})',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.deliveryTimeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 15,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.deliveryFeeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: restaurant.deliveryFee <= 0
                                  ? AppColors.secondary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusPill,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: 14,
                              color: AppColors.secondaryDeep,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Eco Packaging',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : const Color(0xFFE2E7FF),
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Auspify Verified',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  const _FrostedCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: (isDark ? AppColors.darkCard : Colors.white).withValues(
        alpha: 0.9,
      ),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 21,
            color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyCategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.backgroundColor,
    required this.onSelect,
  });

  final List<String> categories;
  final String selectedCategory;
  final Color backgroundColor;
  final ValueChanged<String> onSelect;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: backgroundColor.withValues(alpha: 0.97),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return InkWell(
            onTap: () => onSelect(category),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category == 'Popular' ? 'Popular 🔥' : category,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: isSelected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.categories != categories ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
