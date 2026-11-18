import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_application/core/errors/failures.dart';
import 'package:food_delivery_application/data/datasources/mock_restaurants_seed.dart';
import 'package:food_delivery_application/domain/entities/app_user_entity.dart';
import 'package:food_delivery_application/domain/repositories/auth_repository.dart';
import 'package:food_delivery_application/domain/repositories/restaurant_repository.dart';
import 'package:food_delivery_application/domain/usecases/auth_usecases.dart';
import 'package:food_delivery_application/domain/usecases/restaurant_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_state.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/restaurant/restaurant_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRestaurantRepository extends Mock implements RestaurantRepository {}

void main() {
  group('AuthCubit', () {
    late MockAuthRepository mockAuthRepo;
    late AuthCubit authCubit;

    const testUser = AppUserEntity(
      uid: 'uid_123',
      name: 'Alex Morgan',
      email: 'alex@cravee.app',
    );

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      authCubit = AuthCubit(
        watchAuthStateUseCase: WatchAuthStateUseCase(mockAuthRepo),
        getCurrentUserUseCase: GetCurrentUserUseCase(mockAuthRepo),
        signInWithEmailUseCase: SignInWithEmailUseCase(mockAuthRepo),
        signUpWithEmailUseCase: SignUpWithEmailUseCase(mockAuthRepo),
        signInWithGoogleUseCase: SignInWithGoogleUseCase(mockAuthRepo),
        signOutUseCase: SignOutUseCase(mockAuthRepo),
      );
    });

    tearDown(() => authCubit.close());

    blocTest<AuthCubit, AuthState>(
      'emits authenticated when checkAuthStatus finds a signed-in user',
      setUp: () {
        when(() => mockAuthRepo.getCurrentUser())
            .thenAnswer((_) async => testUser);
        when(() => mockAuthRepo.watchAuthState())
            .thenAnswer((_) => const Stream<AppUserEntity?>.empty());
      },
      build: () => authCubit,
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          isSubmitting: false,
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits submitting then authenticated on signInWithEmail success',
      setUp: () {
        when(
          () => mockAuthRepo.signInWithEmail(
            email: 'alex@cravee.app',
            password: 'password123',
          ),
        ).thenAnswer((_) async => testUser);
      },
      build: () => authCubit,
      act: (cubit) => cubit.signInWithEmail(
        email: 'alex@cravee.app',
        password: 'password123',
      ),
      expect: () => [
        const AuthState(isSubmitting: true),
        const AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          isSubmitting: false,
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits failure with message on AuthFailure during signInWithEmail',
      setUp: () {
        when(
          () => mockAuthRepo.signInWithEmail(
            email: 'alex@cravee.app',
            password: 'wrong',
          ),
        ).thenThrow(const AuthFailure('Incorrect email or password.'));
      },
      build: () => authCubit,
      act: (cubit) =>
          cubit.signInWithEmail(email: 'alex@cravee.app', password: 'wrong'),
      expect: () => [
        const AuthState(isSubmitting: true),
        const AuthState(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: 'Incorrect email or password.',
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits unauthenticated after signOut',
      setUp: () {
        when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      },
      build: () => authCubit,
      seed: () =>
          const AuthState(status: AuthStatus.authenticated, user: testUser),
      act: (cubit) => cubit.signOut(),
      expect: () => [
        const AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          isSubmitting: true,
        ),
        const AuthState(
          status: AuthStatus.unauthenticated,
          user: null,
          isSubmitting: false,
        ),
      ],
    );
  });

  group('RestaurantCubit', () {
    late MockRestaurantRepository mockRestaurantRepo;
    late RestaurantCubit restaurantCubit;
    final seedRestaurants = MockRestaurantsSeed.buildSeedRestaurants();

    setUp(() {
      mockRestaurantRepo = MockRestaurantRepository();
      restaurantCubit = RestaurantCubit(
        getRestaurantsUseCase: GetRestaurantsUseCase(mockRestaurantRepo),
        filterAndSortUseCase: const FilterAndSortRestaurantsUseCase(),
        searchMatchingDishesUseCase: const SearchMatchingDishesUseCase(),
        toggleFavoriteUseCase: ToggleFavoriteRestaurantUseCase(
          mockRestaurantRepo,
        ),
      );
    });

    tearDown(() => restaurantCubit.close());

    blocTest<RestaurantCubit, RestaurantState>(
      'loads restaurants and preserves sourceTier metadata',
      setUp: () {
        when(
          () => mockRestaurantRepo.getRestaurants(
            uid: any(named: 'uid'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => RestaurantCatalogResult(
            restaurants: seedRestaurants,
            sourceTier: CatalogDataSourceTier.bundledSeed,
          ),
        );
      },
      build: () => restaurantCubit,
      act: (cubit) => cubit.loadRestaurants(uid: 'uid_123'),
      verify: (cubit) {
        expect(cubit.state.status, RestaurantStatus.loaded);
        expect(cubit.state.allRestaurants.length, seedRestaurants.length);
        expect(cubit.state.sourceTier, CatalogDataSourceTier.bundledSeed);
      },
    );

    test(
      'filters by cuisine, under 30 mins, 4.5+ rating, and search query',
      () async {
        when(
          () => mockRestaurantRepo.getRestaurants(
            uid: any(named: 'uid'),
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => RestaurantCatalogResult(
            restaurants: seedRestaurants,
            sourceTier: CatalogDataSourceTier.liveApi,
          ),
        );

        await restaurantCubit.loadRestaurants();

        restaurantCubit.selectCuisine('Pizza');
        expect(
          restaurantCubit.state.filteredRestaurants.every(
            (r) => r.cuisineTags.contains('Pizza'),
          ),
          isTrue,
        );

        restaurantCubit.resetFilters();
        restaurantCubit.toggleUnder30MinsFilter();
        restaurantCubit.toggleRating45PlusFilter();
        expect(
          restaurantCubit.state.filteredRestaurants.every(
            (r) => r.deliveryTimeMinutes < 30 && r.rating >= 4.5,
          ),
          isTrue,
        );

        restaurantCubit.resetFilters();
        restaurantCubit.updateSearchQuery('Wagyu');
        expect(restaurantCubit.state.matchingDishes, isNotEmpty);
        expect(
          restaurantCubit.state.matchingDishes.first.name.toLowerCase(),
          contains('wagyu'),
        );
      },
    );

    test('toggles favorite restaurant optimistically and syncs IDs', () async {
      when(
        () => mockRestaurantRepo.getRestaurants(
          uid: any(named: 'uid'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => RestaurantCatalogResult(
          restaurants: seedRestaurants,
          sourceTier: CatalogDataSourceTier.liveApi,
        ),
      );
      final targetId = seedRestaurants.first.id;
      when(
        () => mockRestaurantRepo.toggleFavoriteRestaurant(
          restaurantId: targetId,
          uid: any(named: 'uid'),
        ),
      ).thenAnswer((_) async => {targetId});

      await restaurantCubit.loadRestaurants(uid: 'uid_123');
      await restaurantCubit.toggleFavorite(targetId);

      expect(
        restaurantCubit.state.favoriteRestaurants.any((r) => r.id == targetId),
        isTrue,
      );
    });
  });
}
