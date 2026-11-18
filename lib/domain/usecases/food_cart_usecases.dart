import 'package:equatable/equatable.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/repositories/food_cart_order_repository.dart';

/// Result of validating and computing a promo code against cart totals.
class PromoEvaluationResult extends Equatable {
  const PromoEvaluationResult({
    required this.isValid,
    required this.discountAmount,
    required this.waivesDeliveryFee,
    required this.message,
    this.normalizedCode,
  });

  final bool isValid;
  final String? normalizedCode;
  final double discountAmount;
  final bool waivesDeliveryFee;
  final String message;

  @override
  List<Object?> get props => [
    isValid,
    normalizedCode,
    discountAmount,
    waivesDeliveryFee,
    message,
  ];
}

class GetCartItemsUseCase {
  const GetCartItemsUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<List<CartItemEntity>> call({String? uid}) {
    return _repository.getCartItems(uid: uid);
  }
}

/// Enforces the single-restaurant cart constraint by checking whether
/// adding [incomingItem] conflicts with the restaurant already in the cart.
class CheckSingleRestaurantConflictUseCase {
  const CheckSingleRestaurantConflictUseCase();

  bool call({
    required List<CartItemEntity> currentItems,
    required CartItemEntity incomingItem,
  }) {
    if (currentItems.isEmpty) return false;
    final activeRestaurantId = currentItems.first.dish.restaurantId;
    return activeRestaurantId != incomingItem.dish.restaurantId;
  }
}

class AddCartItemUseCase {
  const AddCartItemUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  /// Adds or merges [item] into [currentItems] (or replaces cart when [replaceExisting] is true)
  /// and persists the updated cart to Hive and Firestore.
  Future<List<CartItemEntity>> call({
    required List<CartItemEntity> currentItems,
    required CartItemEntity item,
    bool replaceExisting = false,
    String? uid,
  }) async {
    final List<CartItemEntity> updated;

    if (replaceExisting) {
      updated = [item];
    } else {
      final existingIndex = currentItems.indexWhere(
        (existing) => existing.cartItemId == item.cartItemId,
      );
      if (existingIndex >= 0) {
        final existing = currentItems[existingIndex];
        final mergedQty = (existing.quantity + item.quantity).clamp(1, 99);
        updated = List<CartItemEntity>.from(currentItems)
          ..[existingIndex] = existing.copyWith(quantity: mergedQty);
      } else {
        updated = [...currentItems, item];
      }
    }

    await _repository.saveCartItems(items: updated, uid: uid);
    return updated;
  }
}

class UpdateCartItemQuantityUseCase {
  const UpdateCartItemQuantityUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<List<CartItemEntity>> call({
    required List<CartItemEntity> currentItems,
    required String cartItemId,
    required int newQuantity,
    String? uid,
  }) async {
    final List<CartItemEntity> updated;
    if (newQuantity <= 0) {
      updated = currentItems
          .where((item) => item.cartItemId != cartItemId)
          .toList();
    } else {
      final clampedQty = newQuantity.clamp(1, 99);
      updated = currentItems
          .map(
            (item) => item.cartItemId == cartItemId
                ? item.copyWith(quantity: clampedQty)
                : item,
          )
          .toList();
    }

    if (updated.isEmpty) {
      await _repository.clearCart(uid: uid);
    } else {
      await _repository.saveCartItems(items: updated, uid: uid);
    }
    return updated;
  }
}

class RemoveCartItemUseCase {
  const RemoveCartItemUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<List<CartItemEntity>> call({
    required List<CartItemEntity> currentItems,
    required String cartItemId,
    String? uid,
  }) async {
    final updated = currentItems
        .where((item) => item.cartItemId != cartItemId)
        .toList();
    if (updated.isEmpty) {
      await _repository.clearCart(uid: uid);
    } else {
      await _repository.saveCartItems(items: updated, uid: uid);
    }
    return updated;
  }
}

class ClearCartUseCase {
  const ClearCartUseCase(this._repository);

  final FoodCartOrderRepository _repository;

  Future<void> call({String? uid}) => _repository.clearCart(uid: uid);
}

/// Evaluates supported food delivery promo codes (`WELCOME20`, `FREEDEL`).
class ApplyPromoCodeUseCase {
  const ApplyPromoCodeUseCase();

  PromoEvaluationResult call({
    required String code,
    required double subtotal,
    required double deliveryFee,
  }) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const PromoEvaluationResult(
        isValid: false,
        discountAmount: 0.0,
        waivesDeliveryFee: false,
        message: 'Enter a promo code such as WELCOME20 or FREEDEL.',
      );
    }

    if (normalized == AppConstants.promoWelcome20) {
      final discount = double.parse(
        (subtotal * AppConstants.welcome20DiscountRate).toStringAsFixed(2),
      );
      return PromoEvaluationResult(
        isValid: true,
        normalizedCode: normalized,
        discountAmount: discount,
        waivesDeliveryFee: false,
        message: 'WELCOME20 applied — 20% off your food subtotal!',
      );
    }

    if (normalized == AppConstants.promoFreeDel) {
      final discount = double.parse(deliveryFee.toStringAsFixed(2));
      return PromoEvaluationResult(
        isValid: true,
        normalizedCode: normalized,
        discountAmount: discount,
        waivesDeliveryFee: true,
        message: 'FREEDEL applied — delivery fee waived!',
      );
    }

    return const PromoEvaluationResult(
      isValid: false,
      discountAmount: 0.0,
      waivesDeliveryFee: false,
      message: 'Invalid promo code. Try WELCOME20 or FREEDEL.',
    );
  }
}
