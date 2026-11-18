import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/domain/repositories/restaurant_repository.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_state.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_state.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_state.dart';
import 'package:food_delivery_application/presentation/cubits/theme/theme_cubit.dart';
import 'package:food_delivery_application/presentation/widgets/restaurant_card.dart';
import 'package:shimmer/shimmer.dart';

/// Stitch Screen 2 (`c9bc534eedfa4b149e02b39b20f7b48c`): Home & Restaurant Discovery.
class HomeDiscoveryPage extends StatelessWidget {
  const HomeDiscoveryPage({
    super.key,
    required this.onOpenRestaurant,
    required this.onOpenOrderTracking,
    required this.onOpenSearchTab,
    required this.onOpenProfileTab,
  });

  final ValueChanged<RestaurantEntity> onOpenRestaurant;
  final ValueChanged<FoodOrderEntity> onOpenOrderTracking;
  final VoidCallback onOpenSearchTab;
  final VoidCallback onOpenProfileTab;

  static const Map<String, String> _cuisineEmoji = {
    'All': '🔥',
    'Burgers': '🍔',
    'Pizza': '🍕',
    'Asian': '🍜',
    'Italian': '🍝',
    'Healthy': '🥗',
    'Desserts': '🍰',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            context.read<RestaurantCubit>().loadRestaurants(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: _buildHeaderRow(context, theme, isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
                builder: (context, orderState) {
                  final active = orderState.latestInProgressOrder;
                  if (active == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _ActiveOrderStatusBanner(
                      order: active,
                      onTap: () => onOpenOrderTracking(active),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: _PromoHeroBanner(onClaimDeal: onOpenSearchTab),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildCuisinePillsSection(context, theme, isDark),
            ),
            BlocBuilder<RestaurantCubit, RestaurantState>(
              builder: (context, state) {
                if (state.status == RestaurantStatus.loading &&
                    state.allRestaurants.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildLoadingShimmer(isDark),
                  );
                }

                if (state.status == RestaurantStatus.failure &&
                    state.allRestaurants.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildErrorFallback(context, state.errorMessage),
                  );
                }

                final fastest = state.fastestRestaurants;
                final list = state.filteredRestaurants;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (state.sourceTier != null &&
                        state.sourceTier != CatalogDataSourceTier.liveApi)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.offline_bolt_rounded,
                                size: 16,
                                color: AppColors.secondaryDeep,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.sourceTier ==
                                          CatalogDataSourceTier.localCache
                                      ? 'Offline mode active — showing cached restaurants.'
                                      : 'Offline mode active — showing bundled starter restaurants.',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondaryDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (fastest.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Fastest Near You',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: onOpenSearchTab,
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 238,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: fastest.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final restaurant = fastest[index];
                            return FastRestaurantCompactCard(
                              restaurant: restaurant,
                              onTap: () => onOpenRestaurant(restaurant),
                              onToggleFavorite: () => context
                                  .read<RestaurantCubit>()
                                  .toggleFavorite(restaurant.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.selectedCuisine == 'All'
                                    ? 'All Restaurants'
                                    : '${state.selectedCuisine} Spots',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusPill,
                            ),
                            onTap: onOpenSearchTab,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : const Color(0xFFF2F3FF),
                                borderRadius: BorderRadius.circular(
                                  AppColors.radiusPill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 15,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filter',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No restaurants match "${state.selectedCuisine}"',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context
                                  .read<RestaurantCubit>()
                                  .selectCuisine('All'),
                              child: const Text('Show All Restaurants'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...list.map(
                        (restaurant) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: RestaurantCard(
                            restaurant: restaurant,
                            onTap: () => onOpenRestaurant(restaurant),
                            onToggleFavorite: () => context
                                .read<RestaurantCubit>()
                                .toggleFavorite(restaurant.id),
                          ),
                        ),
                      ),
                    const SizedBox(height: 96),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
            builder: (context, orderState) {
              return InkWell(
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                onTap: () =>
                    _showEditAddressSheet(context, orderState.savedAddress),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DELIVER TO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    orderState.savedAddress.shortSummary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            final dark = mode == ThemeMode.dark;
            return Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.read<ThemeCubit>().toggleTheme(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Icon(
                    dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 20,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final initials = authState.user?.initials ?? 'WC';
            return InkWell(
              customBorder: const CircleBorder(),
              onTap: onOpenProfileTab,
              child: CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCuisinePillsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return BlocBuilder<RestaurantCubit, RestaurantState>(
      buildWhen: (prev, curr) => prev.selectedCuisine != curr.selectedCuisine,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Explore Cuisines', style: theme.textTheme.titleMedium),
                  Text(
                    'Swipe',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppConstants.cuisineCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cuisine = AppConstants.cuisineCategories[index];
                  final isSelected = state.selectedCuisine == cuisine;
                  return GestureDetector(
                    onTap: () =>
                        context.read<RestaurantCubit>().selectCuisine(cuisine),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.primary : AppColors.lightInk)
                            : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusPill,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_cuisineEmoji[cuisine] ?? '🍽️'),
                          const SizedBox(width: 6),
                          Text(
                            cuisine,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    final base = isDark
        ? AppColors.darkShimmerBase
        : AppColors.lightShimmerBase;
    final highlight = isDark
        ? AppColors.darkShimmerHighlight
        : AppColors.lightShimmerHighlight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              height: 210,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(AppColors.radiusCard),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorFallback(BuildContext context, String? message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'Could not load restaurants right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<RestaurantCubit>().loadRestaurants(
              forceRefresh: true,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showEditAddressSheet(
    BuildContext context,
    DeliveryAddressEntity current,
  ) {
    final streetCtrl = TextEditingController(text: current.street);
    final cityCtrl = TextEditingController(text: current.city);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Delivery Address',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Street & Apartment',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City / Area',
                  prefixIcon: Icon(Icons.location_city_rounded),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final street = streetCtrl.text.trim();
                  final city = cityCtrl.text.trim();
                  if (street.isNotEmpty && city.isNotEmpty) {
                    context.read<OrderTrackingCubit>().updateDeliveryAddress(
                      current.copyWith(street: street, city: city),
                    );
                  }
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Save Delivery Location'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveOrderStatusBanner extends StatelessWidget {
  const _ActiveOrderStatusBanner({required this.order, required this.onTap});

  final FoodOrderEntity order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF451A03) : AppColors.tertiarySoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.restaurantName} • ${order.status.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2A1700),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETA: ${order.estimatedMinutesRemaining} mins • Tap to track live',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.tertiarySoft
                          : AppColors.tertiaryDeep,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? AppColors.tertiarySoft : AppColors.tertiaryDeep,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoHeroBanner extends StatelessWidget {
  const _PromoHeroBanner({required this.onClaimDeal});

  final VoidCallback onClaimDeal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                  child: const Text(
                    'FIRST-TIME OFFER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '20% OFF\nYour First Feast!',
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use code WELCOME20 or FREEDEL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFE4DE),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onClaimDeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(124, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Explore Deals'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lunch_dining_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
