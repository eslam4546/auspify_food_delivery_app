import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/core/theme/app_theme.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/entities/restaurant_dish_entities.dart';
import 'package:food_delivery_application/firebase_options.dart';
import 'package:food_delivery_application/injection_container.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_state.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/theme/theme_cubit.dart';
import 'package:food_delivery_application/presentation/pages/auth/login_page.dart';
import 'package:food_delivery_application/presentation/pages/cart/food_cart_checkout_page.dart';
import 'package:food_delivery_application/presentation/pages/customization/meal_customization_page.dart';
import 'package:food_delivery_application/presentation/pages/home/home_discovery_page.dart';
import 'package:food_delivery_application/presentation/pages/profile/user_profile_page.dart';
import 'package:food_delivery_application/presentation/pages/restaurant/restaurant_details_page.dart';
import 'package:food_delivery_application/presentation/pages/search/restaurant_search_page.dart';
import 'package:food_delivery_application/presentation/pages/shell/main_shell_page.dart';
import 'package:food_delivery_application/presentation/pages/tracking/live_order_tracking_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dependencies = await AppDependencies.init();
  runApp(FoodDeliveryApp(dependencies: dependencies));
}

class FoodDeliveryApp extends StatelessWidget {
  const FoodDeliveryApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => dependencies.createThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => dependencies.createAuthCubit()..checkAuthStatus(),
        ),
        BlocProvider<RestaurantCubit>(
          create: (_) => dependencies.createRestaurantCubit(),
        ),
        BlocProvider<FoodCartCubit>(
          create: (_) => dependencies.createFoodCartCubit(),
        ),
        BlocProvider<OrderTrackingCubit>(
          create: (_) => dependencies.createOrderTrackingCubit(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const _AuthRoutingGate(),
          );
        },
      ),
    );
  }
}

/// Initial app launch gate that routes to [AuthenticatedShellPage] or [LoginPage]
/// once [AuthCubit.checkAuthStatus] resolves.
class _AuthRoutingGate extends StatelessWidget {
  const _AuthRoutingGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading) {
          return const _BrandSplashLoader();
        }

        if (state.isAuthenticated && state.user != null) {
          return const AuthenticatedShellPage();
        }

        return const LoginPage();
      },
    );
  }
}

/// Authenticated root host wrapping [MainShellPage], hydrating user-scoped
/// Cubits (restaurants, cart, orders), and wiring navigation across all 8 screens.
class AuthenticatedShellPage extends StatefulWidget {
  const AuthenticatedShellPage({super.key});

  @override
  State<AuthenticatedShellPage> createState() => _AuthenticatedShellPageState();
}

class _AuthenticatedShellPageState extends State<AuthenticatedShellPage> {
  String? _hydratedUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthCubit>().state.user;
      if (user != null) {
        _hydrateUserSession(user.uid);
      }
    });
  }

  void _hydrateUserSession(String uid) {
    if (_hydratedUid == uid) return;
    _hydratedUid = uid;

    context.read<RestaurantCubit>()
      ..bindUser(uid)
      ..loadRestaurants(uid: uid);
    context.read<FoodCartCubit>()
      ..bindUser(uid)
      ..loadCart(uid: uid);
    context.read<OrderTrackingCubit>()
      ..bindUser(uid)
      ..loadOrdersAndAddress(uid: uid);
  }

  void _openOrderTracking(BuildContext context, FoodOrderEntity order) {
    context.read<OrderTrackingCubit>().selectActiveOrder(order);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveOrderTrackingPage(initialOrder: order),
      ),
    );
  }

  void _openDishCustomization(
    BuildContext context,
    RestaurantEntity restaurant,
    DishEntity dish,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MealCustomizationPage(restaurant: restaurant, dish: dish),
      ),
    );
  }

  void _openRestaurantDetails(
    BuildContext context,
    RestaurantEntity restaurant,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (detailsContext) => RestaurantDetailsPage(
          restaurant: restaurant,
          onSelectDish: (selectedRestaurant, dish) =>
              _openDishCustomization(detailsContext, selectedRestaurant, dish),
          onViewCart: () {
            Navigator.of(detailsContext).push(
              MaterialPageRoute<void>(
                builder: (cartContext) => FoodCartCheckoutPage(
                  showBackButton: true,
                  onBrowseRestaurants: () => Navigator.of(cartContext).pop(),
                  onOrderPlaced: (placedOrder) {
                    cartContext.read<OrderTrackingCubit>().selectActiveOrder(
                      placedOrder,
                    );
                    Navigator.of(cartContext).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LiveOrderTrackingPage(initialOrder: placedOrder),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current.isAuthenticated && current.user?.uid != previous.user?.uid,
      listener: (context, state) {
        if (state.user != null) {
          _hydrateUserSession(state.user!.uid);
        }
      },
      child: MainShellPage(
        buildTabs: (switchTab) => [
          HomeDiscoveryPage(
            onOpenRestaurant: (restaurant) =>
                _openRestaurantDetails(context, restaurant),
            onOpenOrderTracking: (order) => _openOrderTracking(context, order),
            onOpenSearchTab: () => switchTab(1),
            onOpenProfileTab: () => switchTab(3),
          ),
          RestaurantSearchPage(
            onOpenRestaurant: (restaurant) =>
                _openRestaurantDetails(context, restaurant),
            onOpenDishCustomization: (restaurant, dish) =>
                _openDishCustomization(context, restaurant, dish),
          ),
          FoodCartCheckoutPage(
            onBrowseRestaurants: () => switchTab(0),
            onOrderPlaced: (order) => _openOrderTracking(context, order),
          ),
          UserProfilePage(
            onOpenRestaurant: (restaurant) =>
                _openRestaurantDetails(context, restaurant),
            onOpenOrderTracking: (order) => _openOrderTracking(context, order),
            onReorderToCart: () => switchTab(2),
          ),
        ],
      ),
    );
  }
}

class _BrandSplashLoader extends StatelessWidget {
  const _BrandSplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [AppColors.primaryDeep, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('Cravee', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
