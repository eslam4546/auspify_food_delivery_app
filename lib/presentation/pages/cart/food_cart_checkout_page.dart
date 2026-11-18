import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_state.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_state.dart';
import 'package:food_delivery_application/presentation/widgets/checkout_payment_address_section.dart';
import 'package:food_delivery_application/presentation/widgets/resilient_network_image.dart';

/// Stitch Screen 6 (`c87e6391957d410c98ffbedb9757652d`): Cart & Simulated Checkout.
class FoodCartCheckoutPage extends StatefulWidget {
  const FoodCartCheckoutPage({
    super.key,
    required this.onOrderPlaced,
    this.onBrowseRestaurants,
    this.showBackButton = false,
  });

  final ValueChanged<FoodOrderEntity> onOrderPlaced;
  final VoidCallback? onBrowseRestaurants;
  final bool showBackButton;

  @override
  State<FoodCartCheckoutPage> createState() => _FoodCartCheckoutPageState();
}

class _FoodCartCheckoutPageState extends State<FoodCartCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _promoController = TextEditingController();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;

  String _selectedPaymentMethod = AppConstants.paymentCreditDebitCard;

  @override
  void initState() {
    super.initState();
    final saved = context.read<OrderTrackingCubit>().state.savedAddress;
    _fullNameController = TextEditingController(text: saved.fullName);
    _phoneController = TextEditingController(text: saved.phone);
    _streetController = TextEditingController(text: saved.street);
    _cityController = TextEditingController(text: saved.city);
  }

  @override
  void dispose() {
    _promoController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(FoodCartState cartState) async {
    if (cartState.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your delivery address details.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final address = DeliveryAddressEntity(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
    );

    final orderCubit = context.read<OrderTrackingCubit>();
    final cartCubit = context.read<FoodCartCubit>();

    final placedOrder = await orderCubit.placeOrder(
      restaurantId: cartState.activeRestaurantId ?? '',
      restaurantName: cartState.activeRestaurantName ?? 'Warm Courier Kitchen',
      items: cartState.items,
      subtotal: cartState.subtotal,
      deliveryFee: cartState.effectiveDeliveryFee,
      discountAmount: cartState.discountAmount,
      totalPrice: cartState.grandTotal,
      paymentMethod: _selectedPaymentMethod,
      deliveryAddress: address,
    );

    if (!mounted) return;
    if (placedOrder != null) {
      await cartCubit.clearCart();
      if (!mounted) return;
      widget.onOrderPlaced(placedOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = widget.showBackButton
        ? MediaQuery.of(context).padding.bottom + 12
        : 92.0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text('Cart & Checkout'),
        actions: [
          BlocBuilder<FoodCartCubit, FoodCartState>(
            buildWhen: (prev, curr) => prev.isEmpty != curr.isEmpty,
            builder: (context, cartState) {
              if (cartState.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<FoodCartCubit>().clearCart(),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FoodCartCubit, FoodCartState>(
        builder: (context, cartState) {
          if (cartState.isEmpty) {
            return _buildEmptyCart(context, theme);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 20),
              children: [
                _buildActiveRestaurantHeader(cartState, theme, isDark),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Selected Items',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${cartState.totalItemCount} item(s)',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...cartState.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CartItemCard(
                      item: item,
                      onIncrement: () =>
                          context.read<FoodCartCubit>().updateItemQuantity(
                            cartItemId: item.cartItemId,
                            newQuantity: item.quantity + 1,
                          ),
                      onDecrement: () =>
                          context.read<FoodCartCubit>().updateItemQuantity(
                            cartItemId: item.cartItemId,
                            newQuantity: item.quantity - 1,
                          ),
                      onRemove: () => context.read<FoodCartCubit>().removeItem(
                        item.cartItemId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildPromoSection(cartState, theme, isDark),
                const SizedBox(height: 14),
                CheckoutPaymentAddressSection(
                  fullNameController: _fullNameController,
                  phoneController: _phoneController,
                  streetController: _streetController,
                  cityController: _cityController,
                  selectedPaymentMethod: _selectedPaymentMethod,
                  onPaymentMethodChanged: (method) =>
                      setState(() => _selectedPaymentMethod = method),
                ),
                const SizedBox(height: 14),
                _buildBillSummaryCard(cartState, theme, isDark),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 4,
                      backgroundColor: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Offline-ready • Hybrid Hive & Firestore Sync',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
                  buildWhen: (prev, curr) =>
                      prev.isPlacingOrder != curr.isPlacingOrder,
                  builder: (context, orderState) {
                    return ElevatedButton(
                      onPressed: orderState.isPlacingOrder
                          ? null
                          : () => _placeOrder(cartState),
                      child: orderState.isPlacingOrder
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shopping_bag_rounded, size: 19),
                                    SizedBox(width: 8),
                                    Text('Place Order'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '\$${cartState.grandTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveRestaurantHeader(
    FoodCartState cartState,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF2F3FF),
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDERING FROM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      cartState.activeRestaurantName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.secondarySoft,
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.secondaryDeep,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Single-Restaurant Rule active: All items from ${cartState.activeRestaurantName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoSection(
    FoodCartState cartState,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Text('Promo Code', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (cartState.appliedPromoCode != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_rounded,
                    color: AppColors.secondaryDeep,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartState.appliedPromoCode!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryDeep,
                          ),
                        ),
                        Text(
                          'Savings: -\$${cartState.discountAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _promoController.clear();
                      context.read<FoodCartCubit>().removePromoCode();
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Try WELCOME20 or FREEDEL',
                      prefixIcon: Icon(Icons.local_offer_outlined, size: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.read<FoodCartCubit>().applyPromoCode(
                    _promoController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(86, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('WELCOME20 (20% Off)'),
                  onPressed: () {
                    _promoController.text = AppConstants.promoWelcome20;
                    context.read<FoodCartCubit>().applyPromoCode(
                      AppConstants.promoWelcome20,
                    );
                  },
                ),
                ActionChip(
                  label: const Text('FREEDEL (Free Delivery)'),
                  onPressed: () {
                    _promoController.text = AppConstants.promoFreeDel;
                    context.read<FoodCartCubit>().applyPromoCode(
                      AppConstants.promoFreeDel,
                    );
                  },
                ),
              ],
            ),
          ],
          if (cartState.promoMessage != null && !cartState.promoIsValid) ...[
            const SizedBox(height: 6),
            Text(
              cartState.promoMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard(
    FoodCartState cartState,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Text('Bill Summary', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          _BillRow(
            label: 'Subtotal',
            value: '\$${cartState.subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 6),
          _BillRow(
            label: 'Delivery Fee',
            value: cartState.effectiveDeliveryFee <= 0
                ? 'Free'
                : '\$${cartState.effectiveDeliveryFee.toStringAsFixed(2)}',
          ),
          if (cartState.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _BillRow(
              label: 'Promo (${cartState.appliedPromoCode ?? ''})',
              value: '-\$${cartState.discountAmount.toStringAsFixed(2)}',
              valueColor: AppColors.secondary,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${cartState.grandTotal.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your food bag is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Explore nearby restaurants, customize your meal size and add-ons, and check out in seconds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.onBrowseRestaurants != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: widget.onBrowseRestaurants,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
                child: const Text('Browse Restaurants'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final addonsText = item.selectedAddons.isEmpty
        ? null
        : item.selectedAddons.map((a) => a.name).join(', ');
    final summaryParts = <String>[item.selectedSize.name, ?addonsText];

    return Dismissible(
      key: ValueKey(item.cartItemId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResilientNetworkImage(
              imageUrl: item.dish.image,
              width: 78,
              height: 78,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.dish.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      InkWell(
                        onTap: onRemove,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summaryParts.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (item.specialInstructions != null &&
                      item.specialInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Note: "${item.specialInstructions}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.lineTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: onDecrement,
                              child: const Padding(
                                padding: EdgeInsets.all(5),
                                child: Icon(Icons.remove_rounded, size: 16),
                              ),
                            ),
                            SizedBox(
                              width: 26,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: onIncrement,
                              child: const Padding(
                                padding: EdgeInsets.all(5),
                                child: Icon(Icons.add_rounded, size: 16),
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
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
