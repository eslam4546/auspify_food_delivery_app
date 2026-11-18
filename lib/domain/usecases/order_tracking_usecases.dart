import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/repositories/food_cart_order_repository.dart';
import 'package:uuid/uuid.dart';

class PlaceFoodOrderUseCase {
  PlaceFoodOrderUseCase(this._repository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final FoodCartOrderRepository _repository;
  final Uuid _uuid;

  Future<FoodOrderEntity> call({
    required String restaurantId,
    required String restaurantName,
    required List<CartItemEntity> items,
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required double totalPrice,
    required String paymentMethod,
    required DeliveryAddressEntity deliveryAddress,
    String? uid,
  }) async {
    final now = DateTime.now();
    final shortCode = _uuid.v4().substring(0, 8).toUpperCase();
    final orderId = 'ORD-$shortCode';
    final courierIndex =
        now.millisecondsSinceEpoch % AppConstants.simulatedCouriers.length;
    final courierName = AppConstants.simulatedCouriers[courierIndex];

    final order = FoodOrderEntity(
      orderId: orderId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: List<CartItemEntity>.unmodifiable(items),
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      deliveryFee: double.parse(deliveryFee.toStringAsFixed(2)),
      discountAmount: double.parse(discountAmount.toStringAsFixed(2)),
      totalPrice: double.parse(
        totalPrice.clamp(0.0, double.infinity).toStringAsFixed(2),
      ),
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      status: OrderStage.confirmed,
      estimatedMinutesRemaining: OrderStage.confirmed.defaultEtaMinutes,
      courierName: courierName,
      createdAt: now,
      updatedAt: now,
    );

    final persistedOrder = await _repository.placeOrder(order: order, uid: uid);
    await _repository.saveDeliveryAddress(address: deliveryAddress, uid: uid);
    await _repository.clearCart(uid: uid);
    return persistedOrder;
  }
}

class GetOrderHistoryUseCase {
  const GetOrderHistoryUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<List<FoodOrderEntity>> call({String? uid}) {
    return _repository.getOrderHistory(uid: uid);
  }
}

class AdvanceOrderStageUseCase {
  const AdvanceOrderStageUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  /// Advances [order] to the next monotonic delivery stage in Hive and Firestore.
  /// Returns [order] unchanged if it is already delivered.
  Future<FoodOrderEntity> call({
    required FoodOrderEntity order,
    String? uid,
  }) async {
    final nextStage = order.status.nextStage;
    if (nextStage == null) return order;
    return _repository.updateOrderStage(
      order: order,
      nextStage: nextStage,
      uid: uid,
    );
  }
}

/// Converts a past order's items into active cart items for one-tap reorder.
class BuildReorderCartItemsUseCase {
  const BuildReorderCartItemsUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<List<CartItemEntity>> call({
    required FoodOrderEntity pastOrder,
    String? uid,
  }) async {
    final clonedItems = pastOrder.items
        .map((item) => item.copyWith(quantity: item.quantity.clamp(1, 99)))
        .toList();
    await _repository.saveCartItems(items: clonedItems, uid: uid);
    return clonedItems;
  }
}

class GetSavedDeliveryAddressUseCase {
  const GetSavedDeliveryAddressUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<DeliveryAddressEntity?> call({String? uid}) {
    return _repository.getSavedDeliveryAddress(uid: uid);
  }
}

class SaveDeliveryAddressUseCase {
  const SaveDeliveryAddressUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<void> call({required DeliveryAddressEntity address, String? uid}) {
    return _repository.saveDeliveryAddress(address: address, uid: uid);
  }
}
