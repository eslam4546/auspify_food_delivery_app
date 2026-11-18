import 'package:food_delivery_application/data/datasources/food_cart_order_local_datasource.dart';
import 'package:food_delivery_application/data/datasources/food_cart_order_remote_datasource.dart';
import 'package:food_delivery_application/data/models/cart_order_models.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/repositories/food_cart_order_repository.dart';

/// Offline-first hybrid repository coordinating instant Hive reads/writes
/// with resilient Cloud Firestore synchronization for cart, orders, and addresses.
class FoodCartOrderRepositoryImpl implements FoodCartOrderRepository {
  const FoodCartOrderRepositoryImpl({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  final FoodCartOrderLocalDataSource _localDataSource;
  final FoodCartOrderRemoteDataSource _remoteDataSource;

  @override
  Future<List<CartItemEntity>> getCartItems({String? uid}) async {
    final localItems = await _localDataSource.getCartItems();
    if (uid == null || uid.isEmpty) return localItems;

    if (localItems.isNotEmpty) {
      return localItems;
    }

    try {
      final cloudItems = await _remoteDataSource.getCartItems(uid);
      if (cloudItems.isNotEmpty) {
        await _localDataSource.saveCartItems(cloudItems);
        return cloudItems;
      }
    } catch (_) {
      // Offline fallback: return local Hive state cleanly.
    }

    return localItems;
  }

  @override
  Future<void> saveCartItems({
    required List<CartItemEntity> items,
    String? uid,
  }) async {
    final models = items.map(CartItemModel.fromEntity).toList();
    await _localDataSource.saveCartItems(models);

    if (uid != null && uid.isNotEmpty) {
      try {
        await _remoteDataSource.syncCartItems(uid: uid, items: models);
      } catch (_) {
        // Offline-first: Hive write already succeeded.
      }
    }
  }

  @override
  Future<void> clearCart({String? uid}) async {
    await _localDataSource.clearCart();

    if (uid != null && uid.isNotEmpty) {
      try {
        await _remoteDataSource.clearCart(uid);
      } catch (_) {
        // Offline-first: Hive cart is already cleared.
      }
    }
  }

  @override
  Future<FoodOrderEntity> placeOrder({
    required FoodOrderEntity order,
    String? uid,
  }) async {
    final model = FoodOrderModel.fromEntity(order);
    await _localDataSource.saveOrder(model);

    if (uid != null && uid.isNotEmpty) {
      try {
        await _remoteDataSource.placeOrder(uid: uid, order: model);
      } catch (_) {
        // Offline-first: order persists locally in Hive even if offline.
      }
    }

    return model;
  }

  @override
  Future<List<FoodOrderEntity>> getOrderHistory({String? uid}) async {
    final localOrders = await _localDataSource.getOrders();
    if (uid == null || uid.isEmpty) return localOrders;

    try {
      final cloudOrders = await _remoteDataSource.getOrders(uid);
      final mergedById = <String, FoodOrderModel>{
        for (final order in localOrders) order.orderId: order,
      };

      for (final cloudOrder in cloudOrders) {
        final existing = mergedById[cloudOrder.orderId];
        if (existing == null ||
            cloudOrder.status.stepIndex > existing.status.stepIndex ||
            cloudOrder.updatedAt.isAfter(existing.updatedAt)) {
          mergedById[cloudOrder.orderId] = cloudOrder;
        }
      }

      final mergedList = mergedById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _localDataSource.saveOrders(mergedList);
      return mergedList;
    } catch (_) {
      return localOrders;
    }
  }

  @override
  Future<FoodOrderEntity> updateOrderStage({
    required FoodOrderEntity order,
    required OrderStage nextStage,
    String? uid,
  }) async {
    final now = DateTime.now();
    final updatedOrder = FoodOrderModel.fromEntity(
      order.copyWith(
        status: nextStage,
        estimatedMinutesRemaining: nextStage.defaultEtaMinutes,
        updatedAt: now,
      ),
    );

    await _localDataSource.saveOrder(updatedOrder);

    if (uid != null && uid.isNotEmpty) {
      try {
        await _remoteDataSource.updateOrderStage(
          uid: uid,
          orderId: updatedOrder.orderId,
          nextStage: nextStage,
          updatedAt: now,
        );
      } catch (_) {
        // Offline-first: local stage progression still succeeds smoothly.
      }
    }

    return updatedOrder;
  }

  @override
  Future<DeliveryAddressEntity?> getSavedDeliveryAddress({String? uid}) async {
    final localAddress = await _localDataSource.getSavedDeliveryAddress();
    if (localAddress != null) return localAddress;

    if (uid != null && uid.isNotEmpty) {
      try {
        final cloudAddress = await _remoteDataSource.getDefaultAddress(uid);
        if (cloudAddress != null) {
          await _localDataSource.saveDeliveryAddress(cloudAddress);
          return cloudAddress;
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  @override
  Future<void> saveDeliveryAddress({
    required DeliveryAddressEntity address,
    String? uid,
  }) async {
    if (!address.isValid) return;
    final model = DeliveryAddressModel.fromEntity(address);
    await _localDataSource.saveDeliveryAddress(model);

    if (uid != null && uid.isNotEmpty) {
      try {
        await _remoteDataSource.saveDefaultAddress(uid: uid, address: model);
      } catch (_) {
        // Offline-first: address already persisted in Hive.
      }
    }
  }
}
