import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_state.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_state.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_state.dart';
import 'package:food_delivery_application/presentation/cubits/theme/theme_cubit.dart';
import 'package:food_delivery_application/presentation/widgets/resilient_network_image.dart';
import 'package:intl/intl.dart';

/// Stitch Screen 8 (`cc4184ae01ee49478af6369ff8cf55b1`):
/// User Profile, Saved Favorite Restaurants, Order History & One-Tap Reorder.
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({
    super.key,
    required this.onOpenRestaurant,
    required this.onOpenOrderTracking,
    required this.onReorderToCart,
  });

  final ValueChanged<RestaurantEntity> onOpenRestaurant;
  final ValueChanged<FoodOrderEntity> onOpenOrderTracking;
  final VoidCallback onReorderToCart;

  Future<void> _handleReorder(
    BuildContext context,
    FoodOrderEntity order,
  ) async {
    final orderCubit = context.read<OrderTrackingCubit>();
    final cartCubit = context.read<FoodCartCubit>();
    final restaurantCubit = context.read<RestaurantCubit>();

    final reorderedItems = await orderCubit.reorderPastOrder(order);
    if (!context.mounted) return;

    if (reorderedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items available to reorder.')),
      );
      return;
    }

    final restaurant = restaurantCubit.state.restaurantById(order.restaurantId);
    cartCubit.replaceCartFromReorder(
      items: reorderedItems,
      deliveryFee: restaurant?.deliveryFee ?? order.deliveryFee,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Reordered ${order.totalItemCount} item(s) from ${order.restaurantName}!',
          ),
        ),
      );
    onReorderToCart();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
        children: [
          Text('Profile & Orders', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 14),
          _buildProfileHeroCard(context, theme, isDark),
          const SizedBox(height: 22),
          _buildFavoriteRestaurantsSection(context, theme, isDark),
          const SizedBox(height: 22),
          _buildOrdersHistorySection(context, theme, isDark),
          const SizedBox(height: 22),
          _buildPreferencesCard(context, theme, isDark),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => context.read<AuthCubit>().signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.12),
                foregroundColor: AppColors.error,
                elevation: 0,
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out of Cravee'),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cravee • Warm Courier • Clean Architecture & Cubit',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeroCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final displayName = user?.name ?? 'Warm Courier Diner';
        final email = user?.email ?? 'guest@cravee.app';
        final initials = user?.initials ?? 'WC';

        return BlocBuilder<RestaurantCubit, RestaurantState>(
          builder: (context, restaurantState) {
            return BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
              builder: (context, orderState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppColors.radiusCard),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    boxShadow: AppColors.cardShadow(theme.brightness),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (user?.photoUrl != null &&
                              user!.photoUrl!.trim().isNotEmpty)
                            ResilientNetworkImage(
                              imageUrl: user.photoUrl!,
                              width: 68,
                              height: 68,
                              borderRadius: BorderRadius.circular(34),
                              fallbackIcon: Icons.person_rounded,
                            )
                          else
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: AppColors.secondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft.withValues(
                                      alpha: isDark ? 0.25 : 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusPill,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cravee VIP Member ★',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : const Color(0xFFF2F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCounter(
                                value: '${orderState.orders.length}',
                                label: 'Orders',
                                color: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: _StatCounter(
                                value:
                                    '${restaurantState.favoriteRestaurants.length}',
                                label: 'Fav Spots',
                                color: AppColors.secondary,
                              ),
                            ),
                            Expanded(
                              child: _StatCounter(
                                value: orderState.orders
                                    .where((o) => o.isActive)
                                    .length
                                    .toString(),
                                label: 'Active',
                                color: AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteRestaurantsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, state) {
        final favorites = state.favoriteRestaurants;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Saved Favorite Restaurants',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  '(${favorites.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (favorites.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap the heart icon on any restaurant to save your favorites here.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final restaurant = favorites[index];
                    return GestureDetector(
                      onTap: () => onOpenRestaurant(restaurant),
                      child: Container(
                        width: 176,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusCard,
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          boxShadow: AppColors.cardShadow(theme.brightness),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 98,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ResilientNetworkImage(
                                    imageUrl: restaurant.coverImage,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Material(
                                      color:
                                          (isDark
                                                  ? AppColors.darkCard
                                                  : Colors.white)
                                              .withValues(alpha: 0.9),
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () => context
                                            .read<RestaurantCubit>()
                                            .toggleFavorite(restaurant.id),
                                        child: const Padding(
                                          padding: EdgeInsets.all(5),
                                          child: Icon(
                                            Icons.favorite_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.65,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppColors.radiusPill,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 12,
                                            color: AppColors.tertiary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            restaurant.rating.toStringAsFixed(
                                              1,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurant.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  Text(
                                    '${restaurant.cuisineTags.first} • ${restaurant.deliveryTimeLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
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
          ],
        );
      },
    );
  }

  Widget _buildOrdersHistorySection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
      builder: (context, orderState) {
        final orders = orderState.orders;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Orders & Reorder Hub',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (orders.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No orders placed yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your active deliveries and one-tap past reorders will appear here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderHistoryCard(
                    order: order,
                    onTrackOrder: () => onOpenOrderTracking(order),
                    onReorder: () => _handleReorder(context, order),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPreferencesCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: AppColors.cardShadow(theme.brightness),
          ),
          child: Column(
            children: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) {
                  final dark = mode == ThemeMode.dark;
                  return SwitchListTile(
                    secondary: CircleAvatar(
                      backgroundColor: isDark
                          ? AppColors.darkCardElevated
                          : const Color(0xFFEAEDFF),
                      child: Icon(
                        dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.tertiary,
                        size: 20,
                      ),
                    ),
                    title: Text('Dark Mode', style: theme.textTheme.labelLarge),
                    subtitle: Text(
                      dark
                          ? 'Warm Courier Dark Theme'
                          : 'Warm Courier Light Theme',
                      style: theme.textTheme.bodySmall,
                    ),
                    activeTrackColor: AppColors.primary,
                    value: dark,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                  );
                },
              ),
              const Divider(indent: 64),
              BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
                builder: (context, orderState) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDark
                          ? AppColors.darkCardElevated
                          : const Color(0xFFEAEDFF),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Default Delivery Address',
                      style: theme.textTheme.labelLarge,
                    ),
                    subtitle: Text(
                      orderState.savedAddress.shortSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCounter extends StatelessWidget {
  const _StatCounter({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.onTrackOrder,
    required this.onReorder,
  });

  final FoodOrderEntity order;
  final VoidCallback onTrackOrder;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateLabel = DateFormat('MMM d, h:mm a').format(order.createdAt);
    final itemsSummary = order.items
        .map((i) => '${i.quantity}× ${i.dish.name}')
        .join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      onTap: onTrackOrder,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          border: Border.all(
            color: order.isActive
                ? AppColors.primary.withValues(alpha: 0.45)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: AppColors.cardShadow(theme.brightness),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lunch_dining_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        '\$${order.totalPrice.toStringAsFixed(2)} • ${order.totalItemCount} item(s) • $dateLabel',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.status.isCompleted
                        ? AppColors.secondarySoft
                        : AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                  child: Text(
                    order.status.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: order.status.isCompleted
                          ? AppColors.secondaryDeep
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                itemsSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTrackOrder,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    icon: Icon(
                      order.isActive
                          ? Icons.two_wheeler_rounded
                          : Icons.receipt_long_rounded,
                      size: 17,
                    ),
                    label: Text(order.isActive ? 'Track Live' : 'View Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReorder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Reorder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
