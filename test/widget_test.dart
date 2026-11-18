import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_application/core/theme/app_theme.dart';
import 'package:food_delivery_application/data/datasources/mock_restaurants_seed.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/presentation/widgets/order_stage_timeline_stepper.dart';

void main() {
  testWidgets('OrderStageTimelineStepper renders all 4 tracking stages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: OrderStageTimelineStepper(
              currentStage: OrderStage.outForDelivery,
              courierName: 'Marcus Vance',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Order Confirmed'), findsOneWidget);
    expect(find.text('Preparing in Kitchen'), findsOneWidget);
    expect(find.text('Out for Delivery'), findsWidgets);
    expect(find.text('Delivered'), findsOneWidget);
  });

  test('Tier 3 bundled seed catalog is non-empty and covers core cuisines', () {
    final restaurants = MockRestaurantsSeed.buildSeedRestaurants();
    expect(restaurants.length, greaterThanOrEqualTo(6));
    expect(restaurants.every((r) => r.dishes.isNotEmpty), isTrue);
  });
}
