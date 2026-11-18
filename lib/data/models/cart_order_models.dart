import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_application/data/models/restaurant_dish_models.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.now();
}

/// Data model for [DeliveryAddressEntity] matching Firestore & Hive schemas.
class DeliveryAddressModel extends DeliveryAddressEntity {
  const DeliveryAddressModel({
    required super.fullName,
    required super.phone,
    required super.street,
    required super.city,
  });

  factory DeliveryAddressModel.fromEntity(DeliveryAddressEntity entity) {
    return DeliveryAddressModel(
      fullName: entity.fullName,
      phone: entity.phone,
      street: entity.street,
      city: entity.city,
    );
  }

  factory DeliveryAddressModel.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return DeliveryAddressModel(
      fullName: (map['fullName'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      street: (map['street'] as String?) ?? '',
      city: (map['city'] as String?) ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'street': street.trim(),
      'city': city.trim(),
    };
  }
}

/// Data model for [CartItemEntity] compliant with `users/{uid}/cart/{cartItemId}` rules.
class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.cartItemId,
    required super.dish,
    required super.selectedSize,
    required super.selectedAddons,
    required super.quantity,
    super.specialInstructions,
  });

  factory CartItemModel.fromEntity(CartItemEntity entity) {
    return CartItemModel(
      cartItemId: entity.cartItemId,
      dish: entity.dish,
      selectedSize: entity.selectedSize,
      selectedAddons: entity.selectedAddons,
      quantity: entity.quantity,
      specialInstructions: entity.specialInstructions,
    );
  }

  factory CartItemModel.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final selectedSize = map['selectedSize'] is Map
        ? MealSizeOptionModel.fromMap(
            map['selectedSize'] as Map<dynamic, dynamic>,
          )
        : MealSizeOption.defaultSizes.first;

    final selectedAddons = ((map['selectedAddons'] as List?) ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(MealAddonOptionModel.fromMap)
        .toList();

    final dish = map['dish'] is Map
        ? DishModel.fromMap(map['dish'] as Map<dynamic, dynamic>)
        : DishEntity(
            id: (map['dishId'] as num?)?.toInt() ?? 0,
            restaurantId: (map['restaurantId'] as String?) ?? '',
            restaurantName: (map['restaurantName'] as String?) ?? '',
            name: (map['dishName'] as String?) ?? '',
            description: '',
            image: (map['dishImage'] as String?) ?? '',
            category: 'Main Dishes',
            basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
            calories: 400,
            prepTimeMinutes: 20,
            rating: 4.6,
          );

    return CartItemModel(
      cartItemId: (map['cartItemId'] as String?) ?? '',
      dish: dish,
      selectedSize: selectedSize,
      selectedAddons: selectedAddons,
      specialInstructions: map['specialInstructions'] as String?,
      quantity: ((map['quantity'] as num?)?.toInt() ?? 1).clamp(1, 99),
    );
  }

  /// Exact Firestore document payload aligned with `firestore.rules` allowlist.
  Map<String, dynamic> toFirestore({DateTime? updatedAt}) {
    final trimmedNote = specialInstructions?.trim();
    return {
      'cartItemId': cartItemId,
      'restaurantId': dish.restaurantId,
      'restaurantName': dish.restaurantName,
      'dishId': dish.id,
      'dishName': dish.name,
      'dishImage': dish.image,
      'basePrice': double.parse(dish.basePrice.toStringAsFixed(2)),
      'selectedSize': MealSizeOptionModel.fromEntity(selectedSize).toMap(),
      'selectedAddons': selectedAddons
          .map((a) => MealAddonOptionModel.fromEntity(a).toMap())
          .toList(),
      'specialInstructions': (trimmedNote == null || trimmedNote.isEmpty)
          ? null
          : trimmedNote,
      'quantity': quantity.clamp(1, 99),
      'unitTotalPrice': double.parse(unitPrice.toStringAsFixed(2)),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  /// Map payload suitable for Hive storage and order item snapshots.
  Map<String, dynamic> toHiveMap() {
    final trimmedNote = specialInstructions?.trim();
    return {
      'cartItemId': cartItemId,
      'restaurantId': dish.restaurantId,
      'restaurantName': dish.restaurantName,
      'dishId': dish.id,
      'dishName': dish.name,
      'dishImage': dish.image,
      'basePrice': double.parse(dish.basePrice.toStringAsFixed(2)),
      'selectedSize': MealSizeOptionModel.fromEntity(selectedSize).toMap(),
      'selectedAddons': selectedAddons
          .map((a) => MealAddonOptionModel.fromEntity(a).toMap())
          .toList(),
      'specialInstructions': (trimmedNote == null || trimmedNote.isEmpty)
          ? null
          : trimmedNote,
      'quantity': quantity.clamp(1, 99),
      'unitTotalPrice': double.parse(unitPrice.toStringAsFixed(2)),
      'dish': DishModel.fromEntity(dish).toMap(),
    };
  }

  /// Compact map stored inside `users/{uid}/orders/{orderId}.items`.
  Map<String, dynamic> toOrderItemMap() {
    final trimmedNote = specialInstructions?.trim();
    return {
      'cartItemId': cartItemId,
      'restaurantId': dish.restaurantId,
      'restaurantName': dish.restaurantName,
      'dishId': dish.id,
      'dishName': dish.name,
      'dishImage': dish.image,
      'basePrice': double.parse(dish.basePrice.toStringAsFixed(2)),
      'selectedSize': MealSizeOptionModel.fromEntity(selectedSize).toMap(),
      'selectedAddons': selectedAddons
          .map((a) => MealAddonOptionModel.fromEntity(a).toMap())
          .toList(),
      'specialInstructions': (trimmedNote == null || trimmedNote.isEmpty)
          ? null
          : trimmedNote,
      'quantity': quantity.clamp(1, 99),
      'unitTotalPrice': double.parse(unitPrice.toStringAsFixed(2)),
    };
  }
}

/// Data model for [FoodOrderEntity] compliant with `users/{uid}/orders/{orderId}` rules.
class FoodOrderModel extends FoodOrderEntity {
  const FoodOrderModel({
    required super.orderId,
    required super.restaurantId,
    required super.restaurantName,
    required super.items,
    required super.subtotal,
    required super.deliveryFee,
    required super.discountAmount,
    required super.totalPrice,
    required super.paymentMethod,
    required super.deliveryAddress,
    required super.status,
    required super.estimatedMinutesRemaining,
    required super.courierName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FoodOrderModel.fromEntity(FoodOrderEntity entity) {
    return FoodOrderModel(
      orderId: entity.orderId,
      restaurantId: entity.restaurantId,
      restaurantName: entity.restaurantName,
      items: entity.items,
      subtotal: entity.subtotal,
      deliveryFee: entity.deliveryFee,
      discountAmount: entity.discountAmount,
      totalPrice: entity.totalPrice,
      paymentMethod: entity.paymentMethod,
      deliveryAddress: entity.deliveryAddress,
      status: entity.status,
      estimatedMinutesRemaining: entity.estimatedMinutesRemaining,
      courierName: entity.courierName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory FoodOrderModel.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final items = ((map['items'] as List?) ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(CartItemModel.fromMap)
        .toList();

    final address = map['deliveryAddress'] is Map
        ? DeliveryAddressModel.fromMap(
            map['deliveryAddress'] as Map<dynamic, dynamic>,
          )
        : DeliveryAddressEntity.defaultDemo;

    return FoodOrderModel(
      orderId: (map['orderId'] as String?) ?? '',
      restaurantId: (map['restaurantId'] as String?) ?? '',
      restaurantName: (map['restaurantName'] as String?) ?? '',
      items: items,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (map['paymentMethod'] as String?) ?? 'Cash on Delivery',
      deliveryAddress: address,
      status: OrderStage.fromValue((map['status'] as String?) ?? 'confirmed'),
      estimatedMinutesRemaining:
          ((map['estimatedMinutesRemaining'] as num?)?.toInt() ?? 0).clamp(
            0,
            180,
          ),
      courierName: (map['courierName'] as String?) ?? 'Marcus Vance',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Exact Firestore document payload aligned with `firestore.rules` allowlist.
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items
          .map((item) => CartItemModel.fromEntity(item).toOrderItemMap())
          .toList(),
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'deliveryFee': double.parse(deliveryFee.toStringAsFixed(2)),
      'discountAmount': double.parse(discountAmount.toStringAsFixed(2)),
      'totalPrice': double.parse(totalPrice.toStringAsFixed(2)),
      'paymentMethod': paymentMethod,
      'deliveryAddress': DeliveryAddressModel.fromEntity(deliveryAddress)
          .toMap(),
      'status': status.firestoreValue,
      'estimatedMinutesRemaining': estimatedMinutesRemaining.clamp(0, 180),
      'courierName': courierName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Hive map representation using ISO-8601 date strings.
  Map<String, dynamic> toHiveMap() {
    return {
      'orderId': orderId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items
          .map((item) => CartItemModel.fromEntity(item).toHiveMap())
          .toList(),
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'deliveryFee': double.parse(deliveryFee.toStringAsFixed(2)),
      'discountAmount': double.parse(discountAmount.toStringAsFixed(2)),
      'totalPrice': double.parse(totalPrice.toStringAsFixed(2)),
      'paymentMethod': paymentMethod,
      'deliveryAddress': DeliveryAddressModel.fromEntity(deliveryAddress)
          .toMap(),
      'status': status.firestoreValue,
      'estimatedMinutesRemaining': estimatedMinutesRemaining.clamp(0, 180),
      'courierName': courierName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
