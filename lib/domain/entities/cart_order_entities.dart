import 'package:equatable/equatable.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';

/// Represents a customized dish line item in the user's cart or placed order.
class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.cartItemId,
    required this.dish,
    required this.selectedSize,
    required this.selectedAddons,
    required this.quantity,
    this.specialInstructions,
  });

  final String cartItemId;
  final DishEntity dish;
  final MealSizeOption selectedSize;
  final List<MealAddonOption> selectedAddons;
  final String? specialInstructions;
  final int quantity;

  /// Unit price including selected size delta and all chosen extra add-ons.
  double get unitPrice =>
      dish.basePrice +
      selectedSize.priceDelta +
      selectedAddons.fold<double>(0.0, (sum, addon) => sum + addon.price);

  /// Line subtotal for this item (`unitPrice * quantity`).
  double get lineTotal => unitPrice * quantity;

  /// Generates a deterministic composite identifier for identical customizations.
  static String buildCartItemId({
    required int dishId,
    required String sizeId,
    required List<MealAddonOption> addons,
    String? specialInstructions,
  }) {
    final sortedAddonIds = addons.map((a) => a.id).toList()..sort();
    final noteKey = (specialInstructions ?? '').trim().toLowerCase();
    final noteHash = noteKey.isEmpty
        ? 'none'
        : noteKey.hashCode.abs().toString();
    final addonsKey = sortedAddonIds.isEmpty
        ? 'no_addons'
        : sortedAddonIds.join('_');
    return 'dish_${dishId}_${sizeId}_${addonsKey}_$noteHash';
  }

  CartItemEntity copyWith({
    String? cartItemId,
    DishEntity? dish,
    MealSizeOption? selectedSize,
    List<MealAddonOption>? selectedAddons,
    String? specialInstructions,
    int? quantity,
  }) {
    return CartItemEntity(
      cartItemId: cartItemId ?? this.cartItemId,
      dish: dish ?? this.dish,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [
    cartItemId,
    dish,
    selectedSize,
    selectedAddons,
    specialInstructions,
    quantity,
  ];
}

/// Customer delivery address used for checkout and profile defaults.
class DeliveryAddressEntity extends Equatable {
  const DeliveryAddressEntity({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
  });

  final String fullName;
  final String phone;
  final String street;
  final String city;

  static const DeliveryAddressEntity defaultDemo = DeliveryAddressEntity(
    fullName: 'Alex Morgan',
    phone: '+1 (555) 234-8910',
    street: '742 Maple Avenue, Apt 4B',
    city: 'Downtown Metro',
  );

  bool get isValid =>
      fullName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      street.trim().isNotEmpty &&
      city.trim().isNotEmpty;

  String get shortSummary => '$street, $city';

  DeliveryAddressEntity copyWith({
    String? fullName,
    String? phone,
    String? street,
    String? city,
  }) {
    return DeliveryAddressEntity(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
    );
  }

  @override
  List<Object?> get props => [fullName, phone, street, city];
}

/// 4-stage live order delivery lifecycle.
enum OrderStage {
  confirmed(
    firestoreValue: 'confirmed',
    title: 'Order Confirmed',
    subtitle: 'Restaurant has received your order',
    stepIndex: 0,
    defaultEtaMinutes: 28,
  ),
  preparing(
    firestoreValue: 'preparing',
    title: 'Preparing in Kitchen',
    subtitle: 'Chef is freshly cooking your meal',
    stepIndex: 1,
    defaultEtaMinutes: 18,
  ),
  outForDelivery(
    firestoreValue: 'out_for_delivery',
    title: 'Out for Delivery',
    subtitle: 'Courier is heading to your doorstep',
    stepIndex: 2,
    defaultEtaMinutes: 8,
  ),
  delivered(
    firestoreValue: 'delivered',
    title: 'Delivered',
    subtitle: 'Enjoy your meal!',
    stepIndex: 3,
    defaultEtaMinutes: 0,
  );

  const OrderStage({
    required this.firestoreValue,
    required this.title,
    required this.subtitle,
    required this.stepIndex,
    required this.defaultEtaMinutes,
  });

  final String firestoreValue;
  final String title;
  final String subtitle;
  final int stepIndex;
  final int defaultEtaMinutes;

  bool get isCompleted => this == OrderStage.delivered;

  OrderStage? get nextStage {
    return switch (this) {
      OrderStage.confirmed => OrderStage.preparing,
      OrderStage.preparing => OrderStage.outForDelivery,
      OrderStage.outForDelivery => OrderStage.delivered,
      OrderStage.delivered => null,
    };
  }

  static OrderStage fromValue(String value) {
    return OrderStage.values.firstWhere(
      (stage) => stage.firestoreValue == value || stage.name == value,
      orElse: () => OrderStage.confirmed,
    );
  }
}

/// Represents a placed food delivery order tracked in Hive and Firestore.
class FoodOrderEntity extends Equatable {
  const FoodOrderEntity({
    required this.orderId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.totalPrice,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.status,
    required this.estimatedMinutesRemaining,
    required this.courierName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String orderId;
  final String restaurantId;
  final String restaurantName;
  final List<CartItemEntity> items;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double totalPrice;
  final String paymentMethod;
  final DeliveryAddressEntity deliveryAddress;
  final OrderStage status;
  final int estimatedMinutesRemaining;
  final String courierName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => !status.isCompleted;

  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  FoodOrderEntity copyWith({
    String? orderId,
    String? restaurantId,
    String? restaurantName,
    List<CartItemEntity>? items,
    double? subtotal,
    double? deliveryFee,
    double? discountAmount,
    double? totalPrice,
    String? paymentMethod,
    DeliveryAddressEntity? deliveryAddress,
    OrderStage? status,
    int? estimatedMinutesRemaining,
    String? courierName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodOrderEntity(
      orderId: orderId ?? this.orderId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      estimatedMinutesRemaining:
          estimatedMinutesRemaining ?? this.estimatedMinutesRemaining,
      courierName: courierName ?? this.courierName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    restaurantId,
    restaurantName,
    items,
    subtotal,
    deliveryFee,
    discountAmount,
    totalPrice,
    paymentMethod,
    deliveryAddress,
    status,
    estimatedMinutesRemaining,
    courierName,
    createdAt,
    updatedAt,
  ];
}
