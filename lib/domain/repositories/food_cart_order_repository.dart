import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';

/// Contract for hybrid (Hive + Cloud Firestore) single-restaurant cart and order lifecycle management.
abstract class FoodCartOrderRepository {
  /// Loads cart items from Hive immediately and hydrates from Firestore if signed in.
  Future<List<CartItemEntity>> getCartItems({String? uid});

  /// Persists the full cart state to Hive and syncs `users/{uid}/cart` in Firestore.
  Future<void> saveCartItems({
    required List<CartItemEntity> items,
    String? uid,
  });

  /// Clears all items from Hive cart box and removes `users/{uid}/cart` docs in Firestore.
  Future<void> clearCart({String? uid});

  /// Persists a newly placed order to Hive and Firestore `users/{uid}/orders/{orderId}`.
  Future<FoodOrderEntity> placeOrder({
    required FoodOrderEntity order,
    String? uid,
  });

  /// Loads order history sorted newest-first from Hive merged with Firestore.
  Future<List<FoodOrderEntity>> getOrderHistory({String? uid});

  /// Advances or updates an order's live tracking stage in both Hive and Firestore.
  Future<FoodOrderEntity> updateOrderStage({
    required FoodOrderEntity order,
    required OrderStage nextStage,
    String? uid,
  });

  /// Loads the last saved delivery address from Hive or Firestore.
  Future<DeliveryAddressEntity?> getSavedDeliveryAddress({String? uid});

  /// Saves the delivery address to Hive and Firestore `users/{uid}.defaultAddress`.
  Future<void> saveDeliveryAddress({
    required DeliveryAddressEntity address,
    String? uid,
  });
}
