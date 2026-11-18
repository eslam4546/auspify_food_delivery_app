import 'package:food_delivery_application/core/errors/exceptions.dart';
import 'package:food_delivery_application/core/errors/failures.dart';
import 'package:food_delivery_application/data/datasources/auth_remote_datasource.dart';
import 'package:food_delivery_application/domain/entities/app_user_entity.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this._remoteDataSource});

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUserEntity?> watchAuthState() => _remoteDataSource.watchAuthState();

  @override
  Future<AppUserEntity?> getCurrentUser() async {
    try {
      return await _remoteDataSource.getCurrentUser();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<AppUserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Sign-in failed: $e');
    }
  }

  @override
  Future<AppUserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Sign-up failed: $e');
    }
  }

  @override
  Future<AppUserEntity> signInWithGoogle() async {
    try {
      return await _remoteDataSource.signInWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> updateDefaultAddress({
    required String uid,
    required DeliveryAddressEntity address,
  }) {
    return _remoteDataSource.updateDefaultAddress(uid: uid, address: address);
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }
}
