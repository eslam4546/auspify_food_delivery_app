import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/usecases/food_cart_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_state.dart';

/// Manages the single-restaurant hybrid cart (Hive + Firestore),
/// conflict resolution, quantity updates, and promo code calculations.
class FoodCartCubit extends Cubit<FoodCartState> {
  FoodCartCubit({
    required this._getCartItemsUseCase,
    required this._checkConflictUseCase,
    required this._addCartItemUseCase,
    required this._updateQuantityUseCase,
    required this._removeCartItemUseCase,
    required this._clearCartUseCase,
    required this._applyPromoCodeUseCase,
  }) : super(const FoodCartState());

  final GetCartItemsUseCase _getCartItemsUseCase;
  final CheckSingleRestaurantConflictUseCase _checkConflictUseCase;
  final AddCartItemUseCase _addCartItemUseCase;
  final UpdateCartItemQuantityUseCase _updateQuantityUseCase;
  final RemoveCartItemUseCase _removeCartItemUseCase;
  final ClearCartUseCase _clearCartUseCase;
  final ApplyPromoCodeUseCase _applyPromoCodeUseCase;

  String? _activeUid;

  void bindUser(String? uid) {
    _activeUid = uid;
  }

  Future<void> loadCart({String? uid}) async {
    if (uid != null) _activeUid = uid;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await _getCartItemsUseCase(uid: _activeUid);
      _emitUpdatedCart(items: items, isLoading: false);
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load cart: $e',
        ),
      );
    }
  }

  /// Attempts to add [item]. Returns `true` if added immediately, or `false`
  /// if a single-restaurant conflict was detected (emitting `pendingConflictItem`).
  Future<bool> addItem(CartItemEntity item, {double? deliveryFee}) async {
    final hasConflict = _checkConflictUseCase(
      currentItems: state.items,
      incomingItem: item,
    );

    if (hasConflict) {
      emit(
        state.copyWith(
          pendingConflictItem: item,
          pendingConflictDeliveryFee: deliveryFee ?? state.baseDeliveryFee,
          clearError: true,
        ),
      );
      return false;
    }

    try {
      final updated = await _addCartItemUseCase(
        currentItems: state.items,
        item: item,
        uid: _activeUid,
      );
      _emitUpdatedCart(
        items: updated,
        baseDeliveryFee: deliveryFee ?? state.baseDeliveryFee,
        clearConflict: true,
      );
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to add item to cart: $e'));
      return false;
    }
  }

  /// Replaces the existing cart with the pending item from a different restaurant.
  Future<void> replaceCartWithPendingItem() async {
    final pendingItem = state.pendingConflictItem;
    if (pendingItem == null) return;

    try {
      final updated = await _addCartItemUseCase(
        currentItems: const [],
        item: pendingItem,
        replaceExisting: true,
        uid: _activeUid,
      );
      _emitUpdatedCart(
        items: updated,
        baseDeliveryFee: state.pendingConflictDeliveryFee ?? 1.99,
        clearConflict: true,
        clearPromo: true,
      );
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Unable to switch restaurant cart: $e'),
      );
    }
  }

  void dismissConflict() {
    if (state.hasRestaurantConflict) {
      emit(state.copyWith(clearConflict: true));
    }
  }

  Future<void> updateItemQuantity({
    required String cartItemId,
    required int newQuantity,
  }) async {
    try {
      final updated = await _updateQuantityUseCase(
        currentItems: state.items,
        cartItemId: cartItemId,
        newQuantity: newQuantity,
        uid: _activeUid,
      );
      _emitUpdatedCart(items: updated, clearPromo: updated.isEmpty);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to update quantity: $e'));
    }
  }

  Future<void> removeItem(String cartItemId) async {
    try {
      final updated = await _removeCartItemUseCase(
        currentItems: state.items,
        cartItemId: cartItemId,
        uid: _activeUid,
      );
      _emitUpdatedCart(items: updated, clearPromo: updated.isEmpty);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to remove item: $e'));
    }
  }

  void applyPromoCode(String code) {
    final result = _applyPromoCodeUseCase(
      code: code,
      subtotal: state.subtotal,
      deliveryFee: state.effectiveDeliveryFee,
    );

    if (result.isValid) {
      emit(
        state.copyWith(
          appliedPromoCode: result.normalizedCode,
          discountAmount: result.discountAmount,
          promoMessage: result.message,
          promoIsValid: true,
          clearError: true,
        ),
      );
    } else {
      emit(
        state
            .copyWith(clearPromo: true)
            .copyWith(
              promoMessage: result.message,
              promoIsValid: false,
              clearError: true,
            ),
      );
    }
  }

  void removePromoCode() {
    emit(state.copyWith(clearPromo: true));
  }

  Future<void> clearCart() async {
    try {
      await _clearCartUseCase(uid: _activeUid);
      emit(const FoodCartState());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to clear cart: $e'));
    }
  }

  /// Hydrates the active cart directly from a past order (one-tap Reorder).
  void replaceCartFromReorder({
    required List<CartItemEntity> items,
    double deliveryFee = 1.99,
  }) {
    _emitUpdatedCart(
      items: items,
      baseDeliveryFee: deliveryFee,
      clearConflict: true,
      clearPromo: true,
    );
  }

  void _emitUpdatedCart({
    required List<CartItemEntity> items,
    double? baseDeliveryFee,
    bool? isLoading,
    bool clearConflict = false,
    bool clearPromo = false,
  }) {
    final resolvedFee = baseDeliveryFee ?? state.baseDeliveryFee;
    final newSubtotal = items.fold<double>(0.0, (sum, i) => sum + i.lineTotal);
    final effectiveFee = items.isEmpty ? 0.0 : resolvedFee;

    String? promoCode = clearPromo ? null : state.appliedPromoCode;
    double discount = 0.0;
    bool promoValid = false;
    String? promoMessage = clearPromo ? null : state.promoMessage;

    if (promoCode != null && items.isNotEmpty) {
      final evaluated = _applyPromoCodeUseCase(
        code: promoCode,
        subtotal: newSubtotal,
        deliveryFee: effectiveFee,
      );
      if (evaluated.isValid) {
        discount = evaluated.discountAmount;
        promoValid = true;
        promoMessage = evaluated.message;
      } else {
        promoCode = null;
        promoMessage = null;
      }
    }

    emit(
      state.copyWith(
        items: items,
        baseDeliveryFee: resolvedFee,
        appliedPromoCode: promoCode,
        discountAmount: discount,
        promoIsValid: promoValid,
        promoMessage: promoMessage,
        clearPromo: promoCode == null && clearPromo,
        clearConflict: clearConflict,
        isLoading: isLoading ?? state.isLoading,
        clearError: true,
      ),
    );
  }
}
