import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/usecases/order_tracking_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_state.dart';

/// Manages order placement, 4-stage live tracking progression (`confirmed` ->
/// `preparing` -> `outForDelivery` -> `delivered`), order history, saved
/// delivery address, and one-tap past-order reordering.
class OrderTrackingCubit extends Cubit<OrderTrackingState> {
  OrderTrackingCubit({
    required this._placeFoodOrderUseCase,
    required this._getOrderHistoryUseCase,
    required this._advanceOrderStageUseCase,
    required this._buildReorderCartItemsUseCase,
    required this._getSavedDeliveryAddressUseCase,
    required this._saveDeliveryAddressUseCase,
  }) : super(const OrderTrackingState());

  final PlaceFoodOrderUseCase _placeFoodOrderUseCase;
  final GetOrderHistoryUseCase _getOrderHistoryUseCase;
  final AdvanceOrderStageUseCase _advanceOrderStageUseCase;
  final BuildReorderCartItemsUseCase _buildReorderCartItemsUseCase;
  final GetSavedDeliveryAddressUseCase _getSavedDeliveryAddressUseCase;
  final SaveDeliveryAddressUseCase _saveDeliveryAddressUseCase;

  String? _activeUid;

  void bindUser(String? uid) {
    _activeUid = uid;
  }

  Future<void> loadOrdersAndAddress({String? uid}) async {
    if (uid != null) _activeUid = uid;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final orders = await _getOrderHistoryUseCase(uid: _activeUid);
      final savedAddress = await _getSavedDeliveryAddressUseCase(
        uid: _activeUid,
      );

      FoodOrderEntity? resolvedActive = state.activeOrder;
      if (resolvedActive != null) {
        final match = orders.where((o) => o.orderId == resolvedActive!.orderId);
        resolvedActive = match.isNotEmpty ? match.first : null;
      }
      resolvedActive ??=
          orders.where((o) => o.isActive).firstOrNull ?? orders.firstOrNull;

      emit(
        state.copyWith(
          orders: orders,
          activeOrder: resolvedActive,
          savedAddress: savedAddress ?? state.savedAddress,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load order history: $e',
        ),
      );
    }
  }

  Future<FoodOrderEntity?> placeOrder({
    required String restaurantId,
    required String restaurantName,
    required List<CartItemEntity> items,
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required double totalPrice,
    required String paymentMethod,
    required DeliveryAddressEntity deliveryAddress,
  }) async {
    if (items.isEmpty) {
      emit(state.copyWith(errorMessage: 'Your cart is empty.'));
      return null;
    }

    emit(state.copyWith(isPlacingOrder: true, clearError: true));
    try {
      final placedOrder = await _placeFoodOrderUseCase(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discountAmount: discountAmount,
        totalPrice: totalPrice,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        uid: _activeUid,
      );

      final updatedOrders = [
        placedOrder,
        ...state.orders.where((o) => o.orderId != placedOrder.orderId),
      ];

      emit(
        state.copyWith(
          orders: updatedOrders,
          activeOrder: placedOrder,
          savedAddress: deliveryAddress,
          isPlacingOrder: false,
          clearError: true,
        ),
      );
      return placedOrder;
    } catch (e) {
      emit(
        state.copyWith(
          isPlacingOrder: false,
          errorMessage: 'Unable to place order: $e',
        ),
      );
      return null;
    }
  }

  void selectActiveOrder(FoodOrderEntity order) {
    emit(state.copyWith(activeOrder: order, clearError: true));
  }

  /// Advances [orderId] monotonically to its next stage in Hive & Cloud Firestore.
  Future<FoodOrderEntity?> advanceOrderStage(String orderId) async {
    final targetIndex = state.orders.indexWhere((o) => o.orderId == orderId);
    final currentOrder = targetIndex >= 0
        ? state.orders[targetIndex]
        : (state.activeOrder?.orderId == orderId ? state.activeOrder : null);
    if (currentOrder == null || currentOrder.status.isCompleted) {
      return currentOrder;
    }

    emit(state.copyWith(isAdvancingStage: true, clearError: true));
    try {
      final updatedOrder = await _advanceOrderStageUseCase(
        order: currentOrder,
        uid: _activeUid,
      );

      final updatedOrders = state.orders
          .map((o) => o.orderId == updatedOrder.orderId ? updatedOrder : o)
          .toList();

      emit(
        state.copyWith(
          orders: updatedOrders,
          activeOrder: state.activeOrder?.orderId == updatedOrder.orderId
              ? updatedOrder
              : state.activeOrder,
          isAdvancingStage: false,
          clearError: true,
        ),
      );
      return updatedOrder;
    } catch (e) {
      emit(
        state.copyWith(
          isAdvancingStage: false,
          errorMessage: 'Unable to advance order stage: $e',
        ),
      );
      return null;
    }
  }

  /// Re-hydrates persisted cart items from a past order for one-tap Reorder.
  Future<List<CartItemEntity>> reorderPastOrder(
    FoodOrderEntity pastOrder,
  ) async {
    try {
      return await _buildReorderCartItemsUseCase(
        pastOrder: pastOrder,
        uid: _activeUid,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to reorder past meal: $e'));
      return const [];
    }
  }

  Future<void> updateDeliveryAddress(DeliveryAddressEntity address) async {
    if (!address.isValid) return;
    emit(state.copyWith(savedAddress: address, clearError: true));
    try {
      await _saveDeliveryAddressUseCase(address: address, uid: _activeUid);
    } catch (_) {
      // UI address stays updated locally.
    }
  }
}
