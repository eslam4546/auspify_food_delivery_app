import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/errors/exceptions.dart';
import 'package:food_delivery_application/data/models/cart_order_models.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';

/// Contract for Cloud Firestore sync of `users/{uid}/cart`, `users/{uid}/orders`,
/// `favoriteRestaurantIds`, and `defaultAddress`.
abstract class FoodCartOrderRemoteDataSource {
  Future<List<CartItemModel>> getCartItems(String uid);

  Future<void> syncCartItems({
    required String uid,
    required List<CartItemModel> items,
  });

  Future<void> clearCart(String uid);

  Future<void> placeOrder({required String uid, required FoodOrderModel order});

  Future<List<FoodOrderModel>> getOrders(String uid);

  Future<void> updateOrderStage({
    required String uid,
    required String orderId,
    required OrderStage nextStage,
    required DateTime updatedAt,
  });

  Future<Set<String>> getFavoriteRestaurantIds(String uid);

  Future<void> syncFavoriteRestaurantIds({
    required String uid,
    required Set<String> favoriteIds,
  });

  Future<DeliveryAddressModel?> getDefaultAddress(String uid);

  Future<void> saveDefaultAddress({
    required String uid,
    required DeliveryAddressModel address,
  });
}

class FoodCartOrderRemoteDataSourceImpl
    implements FoodCartOrderRemoteDataSource {
  FoodCartOrderRemoteDataSourceImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.usersCollection).doc(uid);

  CollectionReference<Map<String, dynamic>> _cartCol(String uid) =>
      _userDoc(uid).collection(AppConstants.cartSubcollection);

  CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
      _userDoc(uid).collection(AppConstants.ordersSubcollection);

  @override
  Future<List<CartItemModel>> getCartItems(String uid) async {
    try {
      final snapshot = await _cartCol(uid).get();
      return snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch cloud cart: $e');
    }
  }

  @override
  Future<void> syncCartItems({
    required String uid,
    required List<CartItemModel> items,
  }) async {
    try {
      final existingSnap = await _cartCol(uid).get();
      final incomingIds = items.map((i) => i.cartItemId).toSet();
      final batch = _firestore.batch();

      for (final doc in existingSnap.docs) {
        if (!incomingIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }

      final now = DateTime.now();
      for (final item in items) {
        batch.set(
          _cartCol(uid).doc(item.cartItemId),
          item.toFirestore(updatedAt: now),
        );
      }

      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to sync cloud cart: $e');
    }
  }

  @override
  Future<void> clearCart(String uid) async {
    try {
      final snapshot = await _cartCol(uid).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to clear cloud cart: $e');
    }
  }

  @override
  Future<void> placeOrder({
    required String uid,
    required FoodOrderModel order,
  }) async {
    try {
      await _ordersCol(uid).doc(order.orderId).set(order.toFirestore());
    } catch (e) {
      throw ServerException('Failed to persist order in cloud: $e');
    }
  }

  @override
  Future<List<FoodOrderModel>> getOrders(String uid) async {
    try {
      final snapshot = await _ordersCol(uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => FoodOrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch cloud order history: $e');
    }
  }

  @override
  Future<void> updateOrderStage({
    required String uid,
    required String orderId,
    required OrderStage nextStage,
    required DateTime updatedAt,
  }) async {
    try {
      // Strictly updates only the 3 fields permitted by firestore.rules.
      await _ordersCol(uid).doc(orderId).update({
        'status': nextStage.firestoreValue,
        'estimatedMinutesRemaining': nextStage.defaultEtaMinutes,
        'updatedAt': Timestamp.fromDate(updatedAt),
      });
    } catch (e) {
      throw ServerException('Failed to update order stage in cloud: $e');
    }
  }

  @override
  Future<Set<String>> getFavoriteRestaurantIds(String uid) async {
    try {
      final snap = await _userDoc(uid).get();
      if (!snap.exists || snap.data() == null) return <String>{};
      final raw = snap.data()!['favoriteRestaurantIds'];
      if (raw is! List) return <String>{};
      return raw.map((e) => e.toString()).toSet();
    } catch (e) {
      throw ServerException('Failed to load cloud favorites: $e');
    }
  }

  @override
  Future<void> syncFavoriteRestaurantIds({
    required String uid,
    required Set<String> favoriteIds,
  }) async {
    try {
      final docRef = _userDoc(uid);
      final snap = await docRef.get();
      if (snap.exists) {
        await docRef.update({
          'favoriteRestaurantIds': favoriteIds.toList(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw ServerException('Failed to sync cloud favorites: $e');
    }
  }

  @override
  Future<DeliveryAddressModel?> getDefaultAddress(String uid) async {
    try {
      final snap = await _userDoc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      final raw = snap.data()!['defaultAddress'];
      if (raw is Map<dynamic, dynamic>) {
        final model = DeliveryAddressModel.fromMap(raw);
        return model.isValid ? model : null;
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to load default address from cloud: $e');
    }
  }

  @override
  Future<void> saveDefaultAddress({
    required String uid,
    required DeliveryAddressModel address,
  }) async {
    try {
      final docRef = _userDoc(uid);
      final snap = await docRef.get();
      if (snap.exists) {
        await docRef.update({
          'defaultAddress': address.toMap(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw ServerException('Failed to save default address to cloud: $e');
    }
  }
}
