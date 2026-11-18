import 'package:equatable/equatable.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';

class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.orders = const [],
    this.activeOrder,
    this.savedAddress = DeliveryAddressEntity.defaultDemo,
    this.isLoading = false,
    this.isPlacingOrder = false,
    this.isAdvancingStage = false,
    this.errorMessage,
  });

  final List<FoodOrderEntity> orders;
  final FoodOrderEntity? activeOrder;
  final DeliveryAddressEntity savedAddress;
  final bool isLoading;
  final bool isPlacingOrder;
  final bool isAdvancingStage;
  final String? errorMessage;

  /// Latest order still in progress (`confirmed`, `preparing`, or `outForDelivery`).
  FoodOrderEntity? get latestInProgressOrder {
    for (final order in orders) {
      if (order.isActive) return order;
    }
    return null;
  }

  bool get hasInProgressOrder => latestInProgressOrder != null;

  OrderTrackingState copyWith({
    List<FoodOrderEntity>? orders,
    FoodOrderEntity? activeOrder,
    bool clearActiveOrder = false,
    DeliveryAddressEntity? savedAddress,
    bool? isLoading,
    bool? isPlacingOrder,
    bool? isAdvancingStage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderTrackingState(
      orders: orders ?? this.orders,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      savedAddress: savedAddress ?? this.savedAddress,
      isLoading: isLoading ?? this.isLoading,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      isAdvancingStage: isAdvancingStage ?? this.isAdvancingStage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    orders,
    activeOrder,
    savedAddress,
    isLoading,
    isPlacingOrder,
    isAdvancingStage,
    errorMessage,
  ];
}
