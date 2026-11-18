import 'package:flutter/material.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';

/// Modular 4-stage animated order timeline stepper (`Confirmed` ->
/// `Preparing` -> `Out for Delivery` -> `Delivered`) adhering to Stitch Screen 7.
class OrderStageTimelineStepper extends StatelessWidget {
  const OrderStageTimelineStepper({
    super.key,
    required this.currentStage,
    required this.courierName,
  });

  final OrderStage currentStage;
  final String courierName;

  IconData _stageIcon(OrderStage stage) {
    return switch (stage) {
      OrderStage.confirmed => Icons.receipt_long_rounded,
      OrderStage.preparing => Icons.soup_kitchen_rounded,
      OrderStage.outForDelivery => Icons.two_wheeler_rounded,
      OrderStage.delivered => Icons.home_rounded,
    };
  }

  String _stageDescription(OrderStage stage) {
    return switch (stage) {
      OrderStage.confirmed => 'Restaurant approved and queued your ticket',
      OrderStage.preparing => 'Kitchen chefs are freshly preparing your order',
      OrderStage.outForDelivery =>
        '$courierName is heading safely to your door',
      OrderStage.delivered => 'Delivered hot & fresh — enjoy your meal!',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stages = OrderStage.values;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppColors.cardShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Order Progress',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: currentStage.isCompleted
                      ? AppColors.secondarySoft
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3.5,
                      backgroundColor: currentStage.isCompleted
                          ? AppColors.secondary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentStage.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: currentStage.isCompleted
                            ? AppColors.secondaryDeep
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(stages.length, (index) {
            final stage = stages[index];
            final isLast = index == stages.length - 1;
            final isCompleted =
                stage.stepIndex < currentStage.stepIndex ||
                (stage == OrderStage.delivered && currentStage.isCompleted);
            final isActive = stage == currentStage && !currentStage.isCompleted;
            final isUpcoming = stage.stepIndex > currentStage.stepIndex;

            final circleColor = isCompleted
                ? AppColors.secondary
                : isActive
                ? AppColors.primary
                : (isDark
                      ? AppColors.darkCardElevated
                      : const Color(0xFFE2E8F0));

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : _stageIcon(stage),
                            size: 16,
                            color: (isCompleted || isActive)
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              width: 2.5,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: stage.stepIndex < currentStage.stepIndex
                                  ? AppColors.secondary
                                  : (isDark
                                        ? AppColors.darkDivider
                                        : AppColors.lightDivider),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isUpcoming ? 0.48 : 1.0,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 2 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    stage.title,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isActive
                                          ? AppColors.primary
                                          : isCompleted &&
                                                stage == OrderStage.delivered
                                          ? AppColors.secondary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft.withValues(
                                        alpha: isDark ? 0.25 : 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppColors.radiusPill,
                                      ),
                                    ),
                                    child: const Text(
                                      'In Progress',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _stageDescription(stage),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
