import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_state.dart';

/// Main 4-tab application shell matching Stitch Screen 2's floating pill dock:
/// 0: Home, 1: Search, 2: Cart (with live item count badge), 3: Profile & Orders.
class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    required this.buildTabs,
    this.initialIndex = 0,
  });

  final List<Widget> Function(ValueChanged<int> onSelectTab) buildTabs;
  final int initialIndex;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = widget.buildTabs(_selectTab);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex.clamp(0, tabs.length - 1),
        children: tabs,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCard : Colors.white).withValues(
                alpha: 0.96,
              ),
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: AppColors.stickyBarShadow(theme.brightness),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DockNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _DockNavItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  isSelected: _currentIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                BlocBuilder<FoodCartCubit, FoodCartState>(
                  buildWhen: (prev, curr) =>
                      prev.totalItemCount != curr.totalItemCount,
                  builder: (context, cartState) {
                    return _DockNavItem(
                      icon: Icons.shopping_bag_rounded,
                      label: 'Cart',
                      isSelected: _currentIndex == 2,
                      badgeCount: cartState.totalItemCount,
                      onTap: () => _selectTab(2),
                    );
                  },
                ),
                _DockNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 3,
                  onTap: () => _selectTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockNavItem extends StatelessWidget {
  const _DockNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(AppColors.radiusPill),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: color),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusPill,
                        ),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
