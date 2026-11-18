import 'package:flutter/material.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';

/// Modular Delivery Address form and Payment Method selector (`Cash on Delivery`
/// vs `Simulated Credit/Debit Card UI`) adhering to Stitch Screen 6.
class CheckoutPaymentAddressSection extends StatelessWidget {
  const CheckoutPaymentAddressSection({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    required this.streetController,
    required this.cityController,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
  });

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController streetController;
  final TextEditingController cityController;
  final String selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
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
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text('Delivery Address', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Recipient Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Full name is required.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Phone is required.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: streetController,
                decoration: const InputDecoration(
                  labelText: 'Street & Apartment',
                  prefixIcon: Icon(Icons.home_outlined, size: 20),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Street is required.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City / Area',
                  prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'City is required.' : null,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF451A03)
                      : AppColors.tertiarySoft.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 17,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Estimated Delivery: 20–30 mins',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.tertiarySoft
                            : AppColors.tertiaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
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
                  Text('Payment Method', style: theme.textTheme.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : const Color(0xFFEAEDFF),
                      borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('Simulated', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PaymentOptionTile(
                isSelected:
                    selectedPaymentMethod ==
                    AppConstants.paymentCreditDebitCard,
                leading: Container(
                  width: 44,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.lightInk,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'VISA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: 'Credit / Debit Card',
                subtitle: 'Simulated Visa ending in •••• 4242',
                onTap: () =>
                    onPaymentMethodChanged(AppConstants.paymentCreditDebitCard),
              ),
              const SizedBox(height: 10),
              _PaymentOptionTile(
                isSelected:
                    selectedPaymentMethod == AppConstants.paymentCashOnDelivery,
                leading: Container(
                  width: 44,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.secondaryDeep,
                  ),
                ),
                title: 'Cash on Delivery',
                subtitle: 'Pay with cash upon courier arrival',
                onTap: () =>
                    onPaymentMethodChanged(AppConstants.paymentCashOnDelivery),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.isSelected,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isSelected;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.07)
              : (isDark ? AppColors.darkInputBg : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelLarge),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
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
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
