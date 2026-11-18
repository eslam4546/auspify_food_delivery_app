import 'package:flutter/material.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';

/// Modular mandatory Size radio cards and optional Extra Add-ons checklist
/// faithful to Stitch Screen 5 (`c6024cac378048cdb28844e774376bca`).
class MealSizeSelectorSection extends StatelessWidget {
  const MealSizeSelectorSection({
    super.key,
    required this.sizes,
    required this.basePrice,
    required this.selectedSize,
    required this.onSelectSize,
  });

  final List<MealSizeOption> sizes;
  final double basePrice;
  final MealSizeOption selectedSize;
  final ValueChanged<MealSizeOption> onSelectSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Size',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(
                  alpha: isDark ? 0.25 : 1.0,
                ),
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
              ),
              child: const Text(
                'Required • Choose 1',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sizes.map((size) {
          final isSelected = size.id == selectedSize.id;
          final sizeTotal = basePrice + size.priceDelta;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              onTap: () => onSelectSize(size),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(
                          alpha: isDark ? 0.18 : 0.08,
                        )
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkOutline
                                    : AppColors.lightOutline),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              size.name,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          if (size.id == 'medium') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppColors.radiusPill,
                                ),
                              ),
                              child: const Text(
                                'Popular',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      size.priceDelta <= 0
                          ? '\$${sizeTotal.toStringAsFixed(2)}'
                          : '+\$${size.priceDelta.toStringAsFixed(2)} (\$${sizeTotal.toStringAsFixed(2)})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class MealAddonsSelectorSection extends StatelessWidget {
  const MealAddonsSelectorSection({
    super.key,
    required this.addons,
    required this.selectedAddons,
    required this.onToggleAddon,
  });

  final List<MealAddonOption> addons;
  final Set<String> selectedAddons;
  final ValueChanged<MealAddonOption> onToggleAddon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Extra Add-ons',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : const Color(0xFFE2E7FF),
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
              ),
              child: Text(
                'Optional • Multi-select',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...addons.map((addon) {
          final isChecked = selectedAddons.contains(addon.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              onTap: () => onToggleAddon(addon),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.primary.withValues(
                          alpha: isDark ? 0.14 : 0.06,
                        )
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusCard),
                  border: Border.all(
                    color: isChecked
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChecked
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkOutline
                                    : AppColors.lightOutline),
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        addon.name,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      '+\$${addon.price.toStringAsFixed(2)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isChecked
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
