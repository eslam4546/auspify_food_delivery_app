import 'package:food_delivery_application/domain/entities/app_user_entity.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';
import 'package:food_delivery_application/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AppUserEntity?> call() => _repository.watchAuthState();
}

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUserEntity?> call() => _repository.getCurrentUser();
}

class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUserEntity> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email.trim(), password: password);
  }
}

class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUserEntity> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.signUpWithEmail(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
  }
}

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUserEntity> call() => _repository.signInWithGoogle();
}

class UpdateDefaultAddressUseCase {
  const UpdateDefaultAddressUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String uid,
    required DeliveryAddressEntity address,
  }) {
    return _repository.updateDefaultAddress(uid: uid, address: address);
  }
}

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
