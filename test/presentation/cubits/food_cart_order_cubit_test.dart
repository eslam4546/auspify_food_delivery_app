import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/data/datasources/mock_restaurants_seed.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/domain/repositories/food_cart_order_repository.dart';
import 'package:food_delivery_application/domain/usecases/food_cart_usecases.dart';
import 'package:food_delivery_application/domain/usecases/order_tracking_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockFoodCartOrderRepository extends Mock
    implements FoodCartOrderRepository {}

class FakeFoodOrderEntity extends Fake implements FoodOrderEntity {}

class FakeDeliveryAddressEntity extends Fake implements DeliveryAddressEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFoodOrderEntity());
    registerFallbackValue(FakeDeliveryAddressEntity());
    registerFallbackValue(OrderStage.confirmed);
  });

  final seedRestaurants = MockRestaurantsSeed.buildSeedRestaurants();
  final restaurantA = seedRestaurants[0];
  final restaurantB = seedRestaurants[1];
  final dishA = restaurantA.dishes.first;
  final dishB = restaurantB.dishes.first;

  CartItemEntity buildSampleCartItem({
    required DishEntity dish,
    MealSizeOption? size,
    List<MealAddonOption> addons = const [],
    int quantity = 1,
  }) {
    final chosenSize = size ?? MealSizeOption.defaultSizes[1]; // Medium +$2.00
    return CartItemEntity(
      cartItemId: CartItemEntity.buildCartItemId(
        dishId: dish.id,
        sizeId: chosenSize.id,
        addons: addons,
      ),
      dish: dish,
      selectedSize: chosenSize,
      selectedAddons: addons,
      quantity: quantity,
    );
  }

  group('FoodCartCubit', () {
    late MockFoodCartOrderRepository mockRepo;
    late FoodCartCubit cartCubit;

    setUp(() {
      mockRepo = MockFoodCartOrderRepository();
      when(
        () => mockRepo.saveCartItems(
          items: any(named: 'items'),
          uid: any(named: 'uid'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockRepo.clearCart(uid: any(named: 'uid')))
          .thenAnswer((_) async {});

      cartCubit = FoodCartCubit(
        getCartItemsUseCase: GetCartItemsUseCase(mockRepo),
        checkConflictUseCase: const CheckSingleRestaurantConflictUseCase(),
        addCartItemUseCase: AddCartItemUseCase(mockRepo),
        updateQuantityUseCase: UpdateCartItemQuantityUseCase(mockRepo),
        removeCartItemUseCase: RemoveCartItemUseCase(mockRepo),
        clearCartUseCase: ClearCartUseCase(mockRepo),
        applyPromoCodeUseCase: const ApplyPromoCodeUseCase(),
      );
    });

    tearDown(() => cartCubit.close());

    test(
      'computes size + add-ons unit price and merges identical items',
      () async {
        final addonCheese = MealAddonOption.defaultAddons[0]; // +$1.50
        final item = buildSampleCartItem(
          dish: dishA,
          size: MealSizeOption.defaultSizes[1], // +$2.00
          addons: [addonCheese],
          quantity: 2,
        );

        final expectedUnit = dishA.basePrice + 2.0 + 1.50;
        expect(item.unitPrice, closeTo(expectedUnit, 0.001));
        expect(item.lineTotal, closeTo(expectedUnit * 2, 0.001));

        final addedFirst = await cartCubit.addItem(item, deliveryFee: 1.99);
        expect(addedFirst, isTrue);
        expect(cartCubit.state.totalItemCount, 2);

        // Adding identical customized dish merges quantities cleanly
        final addedSecond = await cartCubit.addItem(item.copyWith(quantity: 1));
        expect(addedSecond, isTrue);
        expect(cartCubit.state.items.length, 1);
        expect(cartCubit.state.totalItemCount, 3);
      },
    );

    test('enforces Single-Restaurant Cart Rule with conflict detection and replacement', () async {
      final itemA = buildSampleCartItem(dish: dishA);
      final itemB = buildSampleCartItem(dish: dishB);

      final firstResult = await cartCubit.addItem(itemA, deliveryFee: 0.0);
      expect(firstResult, isTrue);
      expect(cartCubit.state.activeRestaurantId, restaurantA.id);

      // Adding item from Restaurant B must trigger conflict without overwriting
      final secondResult = await cartCubit.addItem(itemB, deliveryFee: 1.99);
      expect(secondResult, isFalse);
      expect(cartCubit.state.hasRestaurantConflict, isTrue);
      expect(cartCubit.state.activeRestaurantId, restaurantA.id);
      expect(cartCubit.state.pendingConflictItem, itemB);

      // Confirming replacement switches cleanly to Restaurant B
      await cartCubit.replaceCartWithPendingItem();
      expect(cartCubit.state.hasRestaurantConflict, isFalse);
      expect(cartCubit.state.activeRestaurantId, restaurantB.id);
      expect(cartCubit.state.items.length, 1);
      expect(cartCubit.state.effectiveDeliveryFee, 1.99);
    });

    test(
      'applies WELCOME20 and FREEDEL promo codes and rejects invalid codes',
      () async {
        final itemA = buildSampleCartItem(
          dish: dishA,
          size: MealSizeOption.defaultSizes.first,
          quantity: 2,
        );
        await cartCubit.addItem(itemA, deliveryFee: 2.00);

        cartCubit.applyPromoCode('welcome20');
        expect(cartCubit.state.promoIsValid, isTrue);
        expect(cartCubit.state.appliedPromoCode, AppConstants.promoWelcome20);
        expect(
          cartCubit.state.discountAmount,
          closeTo(cartCubit.state.subtotal * 0.20, 0.01),
        );

        cartCubit.applyPromoCode('FREEDEL');
        expect(cartCubit.state.promoIsValid, isTrue);
        expect(cartCubit.state.discountAmount, 2.00);
        expect(
          cartCubit.state.grandTotal,
          closeTo(cartCubit.state.subtotal, 0.01),
        );

        cartCubit.applyPromoCode('INVALIDCODE');
        expect(cartCubit.state.promoIsValid, isFalse);
        expect(cartCubit.state.appliedPromoCode, isNull);
        expect(cartCubit.state.discountAmount, 0.0);
      },
    );
  });

  group('OrderTrackingCubit', () {
    late MockFoodCartOrderRepository mockRepo;
    late OrderTrackingCubit orderCubit;

    setUp(() {
      mockRepo = MockFoodCartOrderRepository();
      when(
        () => mockRepo.placeOrder(
          order: any(named: 'order'),
          uid: any(named: 'uid'),
        ),
      ).thenAnswer(
        (inv) async => inv.namedArguments[#order] as FoodOrderEntity,
      );
      when(
        () => mockRepo.saveDeliveryAddress(
          address: any(named: 'address'),
          uid: any(named: 'uid'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockRepo.clearCart(uid: any(named: 'uid')))
          .thenAnswer((_) async {});
      when(
        () => mockRepo.saveCartItems(
          items: any(named: 'items'),
          uid: any(named: 'uid'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRepo.updateOrderStage(
          order: any(named: 'order'),
          nextStage: any(named: 'nextStage'),
          uid: any(named: 'uid'),
        ),
      ).thenAnswer((inv) async {
        final order = inv.namedArguments[#order] as FoodOrderEntity;
        final next = inv.namedArguments[#nextStage] as OrderStage;
        return order.copyWith(
          status: next,
          estimatedMinutesRemaining: next.defaultEtaMinutes,
        );
      });

      orderCubit = OrderTrackingCubit(
        placeFoodOrderUseCase: PlaceFoodOrderUseCase(mockRepo),
        getOrderHistoryUseCase: GetOrderHistoryUseCase(mockRepo),
        advanceOrderStageUseCase: AdvanceOrderStageUseCase(mockRepo),
        buildReorderCartItemsUseCase: BuildReorderCartItemsUseCase(mockRepo),
        getSavedDeliveryAddressUseCase: GetSavedDeliveryAddressUseCase(
          mockRepo,
        ),
        saveDeliveryAddressUseCase: SaveDeliveryAddressUseCase(mockRepo),
      );
    });

    tearDown(() => orderCubit.close());

    test(
      'places order, advances through all 4 stages, and supports reorder',
      () async {
        final item = buildSampleCartItem(dish: dishA, quantity: 2);

        final placed = await orderCubit.placeOrder(
          restaurantId: restaurantA.id,
          restaurantName: restaurantA.name,
          items: [item],
          subtotal: item.lineTotal,
          deliveryFee: 1.99,
          discountAmount: 0.0,
          totalPrice: item.lineTotal + 1.99,
          paymentMethod: AppConstants.paymentCashOnDelivery,
          deliveryAddress: DeliveryAddressEntity.defaultDemo,
        );

        expect(placed, isNotNull);
        expect(orderCubit.state.activeOrder?.status, OrderStage.confirmed);
        expect(orderCubit.state.hasInProgressOrder, isTrue);

        await orderCubit.advanceOrderStage(placed!.orderId);
        expect(orderCubit.state.activeOrder?.status, OrderStage.preparing);

        await orderCubit.advanceOrderStage(placed.orderId);
        expect(orderCubit.state.activeOrder?.status, OrderStage.outForDelivery);

        await orderCubit.advanceOrderStage(placed.orderId);
        expect(orderCubit.state.activeOrder?.status, OrderStage.delivered);
        expect(orderCubit.state.hasInProgressOrder, isFalse);

        final reordered = await orderCubit.reorderPastOrder(
          orderCubit.state.activeOrder!,
        );
        expect(reordered.length, 1);
        expect(reordered.first.dish.id, dishA.id);
        expect(reordered.first.quantity, 2);
      },
    );
  });
}
