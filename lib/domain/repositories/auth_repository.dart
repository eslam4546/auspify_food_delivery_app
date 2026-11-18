import 'package:food_delivery_application/domain/entities/app_user_entity.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';

/// Contract for Firebase Authentication and user profile persistence.
abstract class AuthRepository {
  /// Emits the authenticated user whenever the auth session changes, or `null` if signed out.
  Stream<AppUserEntity?> watchAuthState();

  /// Returns the currently authenticated user profile if available.
  Future<AppUserEntity?> getCurrentUser();

  /// Signs in with email and password and syncs the Firestore user profile.
  Future<AppUserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new email/password account and provisions `users/{uid}` in Firestore.
  Future<AppUserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Authenticates via Google OAuth (`google_sign_in`) and syncs `users/{uid}`.
  Future<AppUserEntity> signInWithGoogle();

  /// Persists the user's preferred delivery address locally and in Firestore.
  Future<void> updateDefaultAddress({
    required String uid,
    required DeliveryAddressEntity address,
  });

  /// Signs out of Firebase Authentication and Google Sign-In.
  Future<void> signOut();
}
