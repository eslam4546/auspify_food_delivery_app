import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/errors/exceptions.dart';
import 'package:food_delivery_application/data/models/cart_order_models.dart';
import 'package:hive/hive.dart';

/// Contract for instant offline-first Hive cart, order, and address storage.
abstract class FoodCartOrderLocalDataSource {
  Future<List<CartItemModel>> getCartItems();

  Future<void> saveCartItems(List<CartItemModel> items);

  Future<void> clearCart();

  Future<List<FoodOrderModel>> getOrders();

  Future<void> saveOrder(FoodOrderModel order);

  Future<void> saveOrders(List<FoodOrderModel> orders);

  Future<DeliveryAddressModel?> getSavedDeliveryAddress();

  Future<void> saveDeliveryAddress(DeliveryAddressModel address);
}

class FoodCartOrderLocalDataSourceImpl implements FoodCartOrderLocalDataSource {
  FoodCartOrderLocalDataSourceImpl({
    required this._cartBox,
    required this._ordersBox,
    required this._settingsBox,
  });

  final Box<dynamic> _cartBox;
  final Box<dynamic> _ordersBox;
  final Box<dynamic> _settingsBox;

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      return _cartBox.values
          .whereType<Map<dynamic, dynamic>>()
          .map(CartItemModel.fromMap)
          .toList();
    } catch (e) {
      throw CacheException('Failed to load local cart items: $e');
    }
  }

  @override
  Future<void> saveCartItems(List<CartItemModel> items) async {
    try {
      await _cartBox.clear();
      for (final item in items) {
        await _cartBox.put(item.cartItemId, item.toHiveMap());
      }
    } catch (e) {
      throw CacheException('Failed to save local cart items: $e');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _cartBox.clear();
    } catch (e) {
      throw CacheException('Failed to clear local cart: $e');
    }
  }

  @override
  Future<List<FoodOrderModel>> getOrders() async {
    try {
      final orders = _ordersBox.values
          .whereType<Map<dynamic, dynamic>>()
          .map(FoodOrderModel.fromMap)
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw CacheException('Failed to load local orders: $e');
    }
  }

  @override
  Future<void> saveOrder(FoodOrderModel order) async {
    try {
      await _ordersBox.put(order.orderId, order.toHiveMap());
    } catch (e) {
      throw CacheException('Failed to save local order: $e');
    }
  }

  @override
  Future<void> saveOrders(List<FoodOrderModel> orders) async {
    try {
      for (final order in orders) {
        await _ordersBox.put(order.orderId, order.toHiveMap());
      }
    } catch (e) {
      throw CacheException('Failed to cache local orders: $e');
    }
  }

  @override
  Future<DeliveryAddressModel?> getSavedDeliveryAddress() async {
    try {
      final raw = _settingsBox.get(AppConstants.defaultAddressKey);
      if (raw is Map<dynamic, dynamic>) {
        final model = DeliveryAddressModel.fromMap(raw);
        return model.isValid ? model : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDeliveryAddress(DeliveryAddressModel address) async {
    try {
      await _settingsBox.put(AppConstants.defaultAddressKey, address.toMap());
    } catch (e) {
      throw CacheException('Failed to persist delivery address: $e');
    }
  }
}
