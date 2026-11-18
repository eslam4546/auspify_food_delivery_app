import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/errors/exceptions.dart';
import 'package:food_delivery_application/data/models/app_user_model.dart';
import 'package:food_delivery_application/data/models/cart_order_models.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Contract for Firebase Authentication and `users/{uid}` Firestore profile operations.
abstract class AuthRemoteDataSource {
  Stream<AppUserModel?> watchAuthState();

  Future<AppUserModel?> getCurrentUser();

  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUserModel> signInWithGoogle();

  Future<void> updateDefaultAddress({
    required String uid,
    required DeliveryAddressEntity address,
  });

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required this._firebaseAuth,
    required this._googleSignIn,
    required this._firestore,
  });

  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.usersCollection).doc(uid);

  @override
  Stream<AppUserModel?> watchAuthState() {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _hydrateProfile(fbUser);
    });
  }

  @override
  Future<AppUserModel?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return _hydrateProfile(fbUser);
  }

  @override
  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Sign-in failed. No user account returned.');
      }
      return await _syncUserProfile(fbUser);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-in failed: $e');
    }
  }

  @override
  Future<AppUserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Account creation failed. Please try again.');
      }
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await fbUser.updateDisplayName(trimmedName);
        await fbUser.reload();
      }
      final refreshedUser = _firebaseAuth.currentUser ?? fbUser;
      return await _syncUserProfile(refreshedUser, fallbackName: trimmedName);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-up failed: $e');
    }
  }

  @override
  Future<AppUserModel> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw const AuthException('Google Sign-In was cancelled.');
      }
      final googleAuth = await googleAccount.authentication;
      final oauthCredential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final credential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException(
          'Google Sign-In did not return a user profile.',
        );
      }
      return await _syncUserProfile(
        fbUser,
        fallbackName: googleAccount.displayName,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> updateDefaultAddress({
    required String uid,
    required DeliveryAddressEntity address,
  }) async {
    if (!address.isValid) return;
    try {
      final docRef = _userDoc(uid);
      final snap = await docRef.get();
      final addressMap = DeliveryAddressModel.fromEntity(address).toMap();
      if (snap.exists) {
        await docRef.update({
          'defaultAddress': addressMap,
          'updatedAt': Timestamp.now(),
        });
      } else {
        final fbUser = _firebaseAuth.currentUser;
        if (fbUser != null) {
          final model = AppUserModel.fromFirebaseUser(fbUser);
          final payload = model.toFirestore(includeCreatedAt: true);
          payload['defaultAddress'] = addressMap;
          await docRef.set(payload);
        }
      }
    } catch (_) {
      // Allow offline checkout flows to continue cleanly using Hive persistence.
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google Sign-In sign-out errors if user authenticated via Email/Password.
    }
    await _firebaseAuth.signOut();
  }

  /// Syncs `users/{uid}` in Cloud Firestore while preserving `createdAt` immutability.
  Future<AppUserModel> _syncUserProfile(
    fb_auth.User fbUser, {
    String? fallbackName,
  }) async {
    final baseModel = AppUserModel.fromFirebaseUser(
      fbUser,
      fallbackName: fallbackName,
    );

    try {
      final docRef = _userDoc(fbUser.uid);
      final existingSnap = await docRef.get();

      if (existingSnap.exists && existingSnap.data() != null) {
        final existingModel = AppUserModel.fromFirestore(existingSnap.data()!);
        final mergedName = existingModel.name.trim().isNotEmpty
            ? existingModel.name
            : baseModel.name;
        final mergedPhoto = baseModel.photoUrl ?? existingModel.photoUrl;

        await docRef.update({
          'name': mergedName,
          'email': baseModel.email,
          'photoUrl': (mergedPhoto != null && mergedPhoto.trim().isNotEmpty)
              ? mergedPhoto.trim()
              : null,
          'updatedAt': Timestamp.now(),
        });

        return AppUserModel(
          uid: fbUser.uid,
          name: mergedName,
          email: baseModel.email,
          photoUrl: mergedPhoto,
          defaultAddress: existingModel.defaultAddress,
          favoriteRestaurantIds: existingModel.favoriteRestaurantIds,
        );
      } else {
        await docRef.set(baseModel.toFirestore(includeCreatedAt: true));
        return baseModel;
      }
    } catch (_) {
      // Never block authentication if Firestore is momentarily offline.
      return baseModel;
    }
  }

  /// Reads the Firestore profile if reachable, falling back to Firebase Auth claims.
  Future<AppUserModel> _hydrateProfile(fb_auth.User fbUser) async {
    final fallback = AppUserModel.fromFirebaseUser(fbUser);
    try {
      final snap = await _userDoc(fbUser.uid).get();
      if (snap.exists && snap.data() != null) {
        return AppUserModel.fromFirestore(snap.data()!);
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _mapFirebaseAuthError(fb_auth.FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'No account found for that email address.',
      'wrong-password' ||
      'invalid-credential' => 'Incorrect email or password. Please try again.',
      'email-already-in-use' =>
        'An account already exists with this email. Try signing in instead.',
      'invalid-email' => 'Please enter a valid email address.',
      'weak-password' => 'Password is too weak. Use at least 6 characters.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Network error. Check your internet connection and retry.',
      'user-disabled' => 'This account has been disabled.',
      _ => e.message ?? 'Authentication failed (${e.code}).',
    };
  }
}
