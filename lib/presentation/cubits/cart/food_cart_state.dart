import 'package:equatable/equatable.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';

class FoodCartState extends Equatable {
  const FoodCartState({
    this.items = const [],
    this.baseDeliveryFee = 1.99,
    this.appliedPromoCode,
    this.discountAmount = 0.0,
    this.promoMessage,
    this.promoIsValid = false,
    this.pendingConflictItem,
    this.pendingConflictDeliveryFee,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<CartItemEntity> items;
  final double baseDeliveryFee;
  final String? appliedPromoCode;
  final double discountAmount;
  final String? promoMessage;
  final bool promoIsValid;
  final CartItemEntity? pendingConflictItem;
  final double? pendingConflictDeliveryFee;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => items.isEmpty;

  bool get hasRestaurantConflict => pendingConflictItem != null;

  String? get activeRestaurantId =>
      items.isEmpty ? null : items.first.dish.restaurantId;

  String? get activeRestaurantName =>
      items.isEmpty ? null : items.first.dish.restaurantName;

  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal => double.parse(
    items
        .fold<double>(0.0, (sum, item) => sum + item.lineTotal)
        .toStringAsFixed(2),
  );

  double get effectiveDeliveryFee =>
      items.isEmpty ? 0.0 : double.parse(baseDeliveryFee.toStringAsFixed(2));

  double get grandTotal => double.parse(
    (subtotal + effectiveDeliveryFee - discountAmount)
        .clamp(0.0, double.infinity)
        .toStringAsFixed(2),
  );

  FoodCartState copyWith({
    List<CartItemEntity>? items,
    double? baseDeliveryFee,
    String? appliedPromoCode,
    bool clearPromo = false,
    double? discountAmount,
    String? promoMessage,
    bool clearPromoMessage = false,
    bool? promoIsValid,
    CartItemEntity? pendingConflictItem,
    double? pendingConflictDeliveryFee,
    bool clearConflict = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodCartState(
      items: items ?? this.items,
      baseDeliveryFee: baseDeliveryFee ?? this.baseDeliveryFee,
      appliedPromoCode: clearPromo
          ? null
          : (appliedPromoCode ?? this.appliedPromoCode),
      discountAmount: clearPromo
          ? 0.0
          : (discountAmount ?? this.discountAmount),
      promoMessage: (clearPromo || clearPromoMessage)
          ? null
          : (promoMessage ?? this.promoMessage),
      promoIsValid: clearPromo ? false : (promoIsValid ?? this.promoIsValid),
      pendingConflictItem: clearConflict
          ? null
          : (pendingConflictItem ?? this.pendingConflictItem),
      pendingConflictDeliveryFee: clearConflict
          ? null
          : (pendingConflictDeliveryFee ?? this.pendingConflictDeliveryFee),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    items,
    baseDeliveryFee,
    appliedPromoCode,
    discountAmount,
    promoMessage,
    promoIsValid,
    pendingConflictItem,
    pendingConflictDeliveryFee,
    isLoading,
    errorMessage,
  ];
}
