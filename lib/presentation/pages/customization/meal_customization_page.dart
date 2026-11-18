import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/widgets/cart_conflict_dialog.dart';
import 'package:food_delivery_application/presentation/widgets/meal_option_selectors.dart';
import 'package:food_delivery_application/presentation/widgets/resilient_network_image.dart';

/// Stitch Screen 5 (`c6024cac378048cdb28844e774376bca`): Meal Customization.
class MealCustomizationPage extends StatefulWidget {
  const MealCustomizationPage({
    super.key,
    required this.restaurant,
    required this.dish,
  });

  final RestaurantEntity restaurant;
  final DishEntity dish;

  @override
  State<MealCustomizationPage> createState() => _MealCustomizationPageState();
}

class _MealCustomizationPageState extends State<MealCustomizationPage> {
  late MealSizeOption _selectedSize;
  final Set<String> _selectedAddonIds = <String>{};
  final _notesController = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.dish.availableSizes.isNotEmpty
        ? widget.dish.availableSizes.first
        : MealSizeOption.defaultSizes.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<MealAddonOption> get _chosenAddons => widget.dish.availableAddons
      .where((a) => _selectedAddonIds.contains(a.id))
      .toList();

  double get _unitTotal =>
      widget.dish.basePrice +
      _selectedSize.priceDelta +
      _chosenAddons.fold<double>(0.0, (sum, a) => sum + a.price);

  double get _grandTotal => _unitTotal * _quantity;

  Future<void> _handleAddToCart() async {
    final cartCubit = context.read<FoodCartCubit>();
    final note = _notesController.text.trim();
    final cartItem = CartItemEntity(
      cartItemId: CartItemEntity.buildCartItemId(
        dishId: widget.dish.id,
        sizeId: _selectedSize.id,
        addons: _chosenAddons,
        specialInstructions: note.isEmpty ? null : note,
      ),
      dish: widget.dish,
      selectedSize: _selectedSize,
      selectedAddons: _chosenAddons,
      specialInstructions: note.isEmpty ? null : note,
      quantity: _quantity,
    );

    final addedImmediately = await cartCubit.addItem(
      cartItem,
      deliveryFee: widget.restaurant.deliveryFee,
    );

    if (!mounted) return;

    if (addedImmediately) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Added $_quantity× ${widget.dish.name} to cart!'),
          ),
        );
      Navigator.of(context).pop();
      return;
    }

    final currentName =
        cartCubit.state.activeRestaurantName ?? 'another restaurant';
    final shouldReplace = await CartConflictDialog.show(
      context,
      currentRestaurantName: currentName,
      newRestaurantName: widget.restaurant.name,
    );

    if (!mounted) return;

    if (shouldReplace) {
      await cartCubit.replaceCartWithPendingItem();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Started new cart with ${widget.dish.name}!')),
        );
      Navigator.of(context).pop();
    } else {
      cartCubit.dismissConflict();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  ),
                  Flexible(
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
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ResilientNetworkImage(
                            imageUrl: widget.dish.image,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (widget.dish.isPopular)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(
                                        AppColors.radiusPill,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Chef Special',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
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
                                        widget.dish.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.dish.name,
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaSpecChip(
                          icon: Icons.schedule_rounded,
                          label: '${widget.dish.prepTimeMinutes} min prep',
                        ),
                        _MetaSpecChip(
                          icon: Icons.local_fire_department_outlined,
                          label: '${widget.dish.calories} kcal',
                        ),
                        _MetaSpecChip(
                          icon: Icons.verified_rounded,
                          label: 'Made Fresh',
                          highlight: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.dish.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (widget.dish.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.dish.ingredients
                            .take(6)
                            .map(
                              (ingredient) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(
                                    AppColors.radiusPill,
                                  ),
                                ),
                                child: Text(
                                  ingredient,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(),
                    ),
                    MealSizeSelectorSection(
                      sizes: widget.dish.availableSizes,
                      basePrice: widget.dish.basePrice,
                      selectedSize: _selectedSize,
                      onSelectSize: (size) =>
                          setState(() => _selectedSize = size),
                    ),
                    const SizedBox(height: 14),
                    MealAddonsSelectorSection(
                      addons: widget.dish.availableAddons,
                      selectedAddons: _selectedAddonIds,
                      onToggleAddon: (addon) {
                        setState(() {
                          if (_selectedAddonIds.contains(addon.id)) {
                            _selectedAddonIds.remove(addon.id);
                          } else {
                            _selectedAddonIds.add(addon.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Special Kitchen Instructions',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Sauce on the side, extra crispy, no onions...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: AppColors.stickyBarShadow(theme.brightness),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove_rounded,
                          onTap: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        _QtyButton(
                          icon: Icons.add_rounded,
                          onTap: _quantity < 20
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAddToCart,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shopping_bag_rounded, size: 19),
                              SizedBox(width: 8),
                              Text('Add to Cart'),
                            ],
                          ),
                          Text(
                            '\$${_grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaSpecChip extends StatelessWidget {
  const _MetaSpecChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.secondarySoft
            : (isDark ? AppColors.darkCard : const Color(0xFFF2F3FF)),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlight
                ? AppColors.secondaryDeep
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlight
                  ? AppColors.secondaryDeep
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
