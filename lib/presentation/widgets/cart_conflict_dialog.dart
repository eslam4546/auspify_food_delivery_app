import 'package:flutter/material.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';

/// Confirmation dialog enforcing the industry-standard Single-Restaurant Cart Rule.
class CartConflictDialog extends StatelessWidget {
  const CartConflictDialog({
    super.key,
    required this.currentRestaurantName,
    required this.newRestaurantName,
  });

  final String currentRestaurantName;
  final String newRestaurantName;

  static Future<bool> show(
    BuildContext context, {
    required String currentRestaurantName,
    required String newRestaurantName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => CartConflictDialog(
        currentRestaurantName: currentRestaurantName,
        newRestaurantName: newRestaurantName,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: AppColors.primary,
          size: 26,
        ),
      ),
      title: Text(
        'Start a new cart?',
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Your cart currently contains items from $currentRestaurantName. '
        'Orders can only be placed from one restaurant at a time. '
        'Would you like to clear your cart and add this meal from $newRestaurantName?',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Current'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start New Cart'),
          ),
        ),
      ],
    );
  }
}
