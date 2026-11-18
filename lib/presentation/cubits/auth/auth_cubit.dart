import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/errors/failures.dart';
import 'package:food_delivery_application/domain/entities/app_user_entity.dart';
import 'package:food_delivery_application/domain/usecases/auth_usecases.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_state.dart';

/// Manages Firebase Authentication session state across the application.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this._watchAuthStateUseCase,
    required this._getCurrentUserUseCase,
    required this._signInWithEmailUseCase,
    required this._signUpWithEmailUseCase,
    required this._signInWithGoogleUseCase,
    required this._signOutUseCase,
  }) : super(const AuthState());

  final WatchAuthStateUseCase _watchAuthStateUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutUseCase _signOutUseCase;

  StreamSubscription<AppUserEntity?>? _authSubscription;

  Future<void> checkAuthStatus() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final currentUser = await _getCurrentUserUseCase();
      if (currentUser != null) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: currentUser,
            isSubmitting: false,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            isSubmitting: false,
            clearError: true,
          ),
        );
      }

      await _authSubscription?.cancel();
      _authSubscription = _watchAuthStateUseCase().listen(
        (user) {
          if (isClosed || state.isSubmitting) return;
          if (user != null) {
            emit(
              state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
                isSubmitting: false,
                clearError: true,
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: AuthStatus.unauthenticated,
                clearUser: true,
                isSubmitting: false,
              ),
            );
          }
        },
        onError: (_) {
          // Keep current state resilient on transient stream glitches.
        },
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
          errorMessage: failure.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
          errorMessage: 'Unable to check session: $e',
        ),
      );
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _signInWithEmailUseCase(
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: failure.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: 'Sign-in failed: $e',
        ),
      );
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _signUpWithEmailUseCase(
        name: name,
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: failure.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: 'Account creation failed: $e',
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _signInWithGoogleUseCase();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: failure.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: 'Google Sign-In failed: $e',
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _signOutUseCase();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: failure.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          errorMessage: 'Sign-out failed: $e',
        ),
      );
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
