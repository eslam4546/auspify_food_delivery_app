import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/network/dio_client.dart';
import 'package:food_delivery_application/data/datasources/auth_remote_datasource.dart';
import 'package:food_delivery_application/data/datasources/food_cart_order_local_datasource.dart';
import 'package:food_delivery_application/data/datasources/food_cart_order_remote_datasource.dart';
import 'package:food_delivery_application/data/datasources/restaurant_local_datasource.dart';
import 'package:food_delivery_application/data/datasources/restaurant_remote_datasource.dart';
import 'package:food_delivery_application/data/repositories/auth_repository_impl.dart';
import 'package:food_delivery_application/data/repositories/food_cart_order_repository_impl.dart';
import 'package:food_delivery_application/data/repositories/restaurant_repository_impl.dart';
import 'package:food_delivery_application/domain/repositories/auth_repository.dart';
import 'package:food_delivery_application/domain/repositories/food_cart_order_repository.dart';
import 'package:food_delivery_application/domain/repositories/restaurant_repository.dart';
import 'package:food_delivery_application/domain/usecases/auth_usecases.dart';
import 'package:food_delivery_application/domain/usecases/food_cart_usecases.dart';
import 'package:food_delivery_application/domain/usecases/order_tracking_usecases.dart';
import 'package:food_delivery_application/domain/usecases/restaurant_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/cart/food_cart_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/order/order_tracking_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/theme/theme_cubit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Compile-time type-safe Dependency Injection Container wiring Hive,
/// Firebase, Dio, DataSources, Repositories, UseCases, and Cubit factories.
class AppDependencies {
  AppDependencies._({
    required this.settingsBox,
    required this.authRepository,
    required this.restaurantRepository,
    required this.foodCartOrderRepository,
  });

  final Box<dynamic> settingsBox;
  final AuthRepository authRepository;
  final RestaurantRepository restaurantRepository;
  final FoodCartOrderRepository foodCartOrderRepository;

  static Future<AppDependencies> init({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
    DioClient? dioClient,
  }) async {
    await Hive.initFlutter();

    final settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
    final restaurantsCacheBox = await Hive.openBox<dynamic>(
      AppConstants.restaurantsCacheBox,
    );
    final favoritesBox = await Hive.openBox<dynamic>(
      AppConstants.favoriteRestaurantsBox,
    );
    final cartBox = await Hive.openBox<dynamic>(AppConstants.foodCartBox);
    final ordersBox = await Hive.openBox<dynamic>(AppConstants.foodOrdersBox);

    final resolvedAuth = firebaseAuth ?? FirebaseAuth.instance;
    final resolvedGoogleSignIn = googleSignIn ?? GoogleSignIn();
    final resolvedFirestore = firestore ?? FirebaseFirestore.instance;
    final resolvedDioClient = dioClient ?? DioClient();

    // DataSources
    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      firebaseAuth: resolvedAuth,
      googleSignIn: resolvedGoogleSignIn,
      firestore: resolvedFirestore,
    );

    final restaurantRemoteDataSource = RestaurantRemoteDataSourceImpl(
      dioClient: resolvedDioClient,
    );

    final restaurantLocalDataSource = RestaurantLocalDataSourceImpl(
      restaurantsCacheBox: restaurantsCacheBox,
      favoritesBox: favoritesBox,
    );

    final cartOrderLocalDataSource = FoodCartOrderLocalDataSourceImpl(
      cartBox: cartBox,
      ordersBox: ordersBox,
      settingsBox: settingsBox,
    );

    final cartOrderRemoteDataSource = FoodCartOrderRemoteDataSourceImpl(
      firestore: resolvedFirestore,
    );

    // Repositories
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
    );

    final restaurantRepository = RestaurantRepositoryImpl(
      remoteDataSource: restaurantRemoteDataSource,
      localDataSource: restaurantLocalDataSource,
      cloudUserDataSource: cartOrderRemoteDataSource,
    );

    final foodCartOrderRepository = FoodCartOrderRepositoryImpl(
      localDataSource: cartOrderLocalDataSource,
      remoteDataSource: cartOrderRemoteDataSource,
    );

    return AppDependencies._(
      settingsBox: settingsBox,
      authRepository: authRepository,
      restaurantRepository: restaurantRepository,
      foodCartOrderRepository: foodCartOrderRepository,
    );
  }

  ThemeCubit createThemeCubit() => ThemeCubit(settingsBox: settingsBox);

  AuthCubit createAuthCubit() {
    return AuthCubit(
      watchAuthStateUseCase: WatchAuthStateUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      signInWithEmailUseCase: SignInWithEmailUseCase(authRepository),
      signUpWithEmailUseCase: SignUpWithEmailUseCase(authRepository),
      signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
    );
  }

  RestaurantCubit createRestaurantCubit() {
    return RestaurantCubit(
      getRestaurantsUseCase: GetRestaurantsUseCase(restaurantRepository),
      filterAndSortUseCase: const FilterAndSortRestaurantsUseCase(),
      searchMatchingDishesUseCase: const SearchMatchingDishesUseCase(),
      toggleFavoriteUseCase: ToggleFavoriteRestaurantUseCase(
        restaurantRepository,
      ),
    );
  }

  FoodCartCubit createFoodCartCubit() {
    return FoodCartCubit(
      getCartItemsUseCase: GetCartItemsUseCase(foodCartOrderRepository),
      checkConflictUseCase: const CheckSingleRestaurantConflictUseCase(),
      addCartItemUseCase: AddCartItemUseCase(foodCartOrderRepository),
      updateQuantityUseCase: UpdateCartItemQuantityUseCase(
        foodCartOrderRepository,
      ),
      removeCartItemUseCase: RemoveCartItemUseCase(foodCartOrderRepository),
      clearCartUseCase: ClearCartUseCase(foodCartOrderRepository),
      applyPromoCodeUseCase: const ApplyPromoCodeUseCase(),
    );
  }

  OrderTrackingCubit createOrderTrackingCubit() {
    return OrderTrackingCubit(
      placeFoodOrderUseCase: PlaceFoodOrderUseCase(foodCartOrderRepository),
      getOrderHistoryUseCase: GetOrderHistoryUseCase(foodCartOrderRepository),
      advanceOrderStageUseCase: AdvanceOrderStageUseCase(
        foodCartOrderRepository,
      ),
      buildReorderCartItemsUseCase: BuildReorderCartItemsUseCase(
        foodCartOrderRepository,
      ),
      getSavedDeliveryAddressUseCase: GetSavedDeliveryAddressUseCase(
        foodCartOrderRepository,
      ),
      saveDeliveryAddressUseCase: SaveDeliveryAddressUseCase(
        foodCartOrderRepository,
      ),
    );
  }
}
