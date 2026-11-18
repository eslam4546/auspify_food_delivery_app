import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_state.dart';
import 'package:food_delivery_application/presentation/widgets/order_stage_timeline_stepper.dart';
import 'package:intl/intl.dart';

/// Stitch Screen 7 (`ffae4087610748caafb229faf7e058fb`): Interactive Live Order Tracking.
class LiveOrderTrackingPage extends StatelessWidget {
  const LiveOrderTrackingPage({super.key, required this.initialOrder});

  final FoodOrderEntity initialOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Order Tracking'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Warm Courier 24/7 Support is connected to your order.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.headset_mic_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              label: const Text(
                'Help',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
        builder: (context, state) {
          final order =
              state.orders
                  .where((o) => o.orderId == initialOrder.orderId)
                  .firstOrNull ??
              (state.activeOrder?.orderId == initialOrder.orderId
                  ? state.activeOrder
                  : initialOrder)!;

          final nextStage = order.status.nextStage;
          final placedAtFormatted = DateFormat('MMM d, h:mm a')
              .format(order.createdAt);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #${order.orderId}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: order.status.isCompleted
                              ? AppColors.secondarySoft
                              : AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusPill,
                          ),
                        ),
                        child: Text(
                          order.status.isCompleted ? 'Completed' : 'Live',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: order.status.isCompleted
                                ? AppColors.secondaryDeep
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(placedAtFormatted, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 14),
              _StylizedRouteHeader(order: order),
              const SizedBox(height: 16),
              OrderStageTimelineStepper(
                currentStage: order.status,
                courierName: order.courierName,
              ),
              const SizedBox(height: 16),
              _SimulatedCourierCard(courierName: order.courierName),
              const SizedBox(height: 16),
              _OrderReceiptCard(order: order),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : const Color(0xFFE2E7FF).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          size: 20,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Interactive Live Tracking Simulation',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Advance the delivery stage in real time — updates both Hive and Cloud Firestore immediately.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: (nextStage == null || state.isAdvancingStage)
                          ? null
                          : () => context
                                .read<OrderTrackingCubit>()
                                .advanceOrderStage(order.orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nextStage == null
                            ? AppColors.secondary
                            : AppColors.primary,
                        disabledBackgroundColor: AppColors.secondary,
                        disabledForegroundColor: Colors.white,
                      ),
                      icon: state.isAdvancingStage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              nextStage == null
                                  ? Icons.check_circle_rounded
                                  : Icons.autorenew_rounded,
                            ),
                      label: Text(
                        nextStage == null
                            ? 'Order Delivered — Enjoy Your Meal!'
                            : 'Simulate Next Stage (${order.status.title} → ${nextStage.title})',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StylizedRouteHeader extends StatelessWidget {
  const _StylizedRouteHeader({required this.order});

  final FoodOrderEntity order;

  Alignment get _courierAlignment {
    return switch (order.status) {
      OrderStage.confirmed => const Alignment(-0.72, -0.35),
      OrderStage.preparing => const Alignment(-0.35, -0.10),
      OrderStage.outForDelivery => const Alignment(0.18, 0.18),
      OrderStage.delivered => const Alignment(0.72, 0.45),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF17223B), Color(0xFF0F172A)]
              : const [Color(0xFFEEF2FF), Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DeliveryRoutePainter(isDark: isDark)),
          ),
          // Floating ETA Pill
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkCard : Colors.white)
                      .withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  boxShadow: AppColors.cardShadow(Theme.of(context).brightness),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.status.isCompleted
                          ? Icons.celebration_rounded
                          : Icons.bolt_rounded,
                      size: 18,
                      color: order.status.isCompleted
                          ? AppColors.secondary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        order.status.isCompleted
                            ? 'Order Delivered! Enjoy your meal.'
                            : '${order.estimatedMinutesRemaining} mins remaining • ${order.status.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Restaurant Origin Pin
          Positioned(
            top: 66,
            left: 20,
            child: _MapPinLabel(
              icon: Icons.restaurant_rounded,
              color: AppColors.primaryContainer,
              label: order.restaurantName,
            ),
          ),
          // Animated Moving Courier Pin
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: _courierAlignment,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: order.status.isCompleted
                    ? AppColors.secondary
                    : AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                order.status.isCompleted
                    ? Icons.check_rounded
                    : Icons.two_wheeler_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Customer Destination Pin
          Positioned(
            bottom: 16,
            right: 20,
            child: _MapPinLabel(
              icon: Icons.home_rounded,
              color: AppColors.secondary,
              label: order.deliveryAddress.street,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPinLabel extends StatelessWidget {
  const _MapPinLabel({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 130),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkCard : Colors.white).withValues(
              alpha: 0.92,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryRoutePainter extends CustomPainter {
  const _DeliveryRoutePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.lightInk).withValues(
        alpha: 0.05,
      )
      ..strokeWidth = 1;

    for (double x = 24; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePath = Path()
      ..moveTo(size.width * 0.16, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.46,
        size.width * 0.82,
        size.height * 0.74,
      );

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.14 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, glowPaint);

    final routePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (final metric in routePath.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + 9).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), routePaint);
        distance += 16;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DeliveryRoutePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _SimulatedCourierCard extends StatelessWidget {
  const _SimulatedCourierCard({required this.courierName});

  final String courierName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firstName = courierName.split(' ').first;

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
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      firstName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(courierName, style: theme.textTheme.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardElevated
                                : const Color(0xFFEAEDFF),
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusPill,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.tertiary,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '820+ verified deliveries • Thermal Bag',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.moped_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Honda PCX Scooter • White (WC-4912)',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling $courierName (simulated)...'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondarySoft,
                    foregroundColor: AppColors.secondaryDeep,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text('Call $firstName'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Message sent to $courierName: "Please ring the bell on arrival."',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderReceiptCard extends StatelessWidget {
  const _OrderReceiptCard({required this.order});

  final FoodOrderEntity order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${order.totalItemCount} item(s) • ${order.paymentMethod}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '\$${order.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}× ${item.dish.name} (${item.selectedSize.name})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${item.lineTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (order.discountAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promo Discount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  '-\$${order.discountAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
