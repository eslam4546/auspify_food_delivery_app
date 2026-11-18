import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:food_delivery_application/data/models/cart_order_models.dart';
import 'package:food_delivery_application/domain/entities/app_user_entity.dart';

/// Data model for [AppUserEntity] aligned with `users/{uid}` Firestore rules.
class AppUserModel extends AppUserEntity {
  const AppUserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.photoUrl,
    super.defaultAddress,
    super.favoriteRestaurantIds,
  });

  factory AppUserModel.fromEntity(AppUserEntity entity) {
    return AppUserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      photoUrl: entity.photoUrl,
      defaultAddress: entity.defaultAddress,
      favoriteRestaurantIds: entity.favoriteRestaurantIds,
    );
  }

  factory AppUserModel.fromFirebaseUser(
    fb_auth.User user, {
    String? fallbackName,
  }) {
    final resolvedName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (fallbackName?.trim().isNotEmpty ?? false)
        ? fallbackName!.trim()
        : (user.email?.split('@').first ?? 'Warm Courier Guest');

    return AppUserModel(
      uid: user.uid,
      name: resolvedName,
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  factory AppUserModel.fromFirestore(Map<String, dynamic> map) {
    return AppUserModel(
      uid: (map['uid'] as String?) ?? '',
      name: (map['name'] as String?) ?? 'Warm Courier User',
      email: (map['email'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      defaultAddress: map['defaultAddress'] is Map
          ? DeliveryAddressModel.fromMap(
              map['defaultAddress'] as Map<dynamic, dynamic>,
            )
          : null,
      favoriteRestaurantIds:
          ((map['favoriteRestaurantIds'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  /// Exact Firestore document payload aligned with `firestore.rules` allowlist.
  Map<String, dynamic> toFirestore({bool includeCreatedAt = false}) {
    final now = Timestamp.now();
    final payload = <String, dynamic>{
      'uid': uid,
      'name': name.trim().isEmpty ? 'Warm Courier User' : name.trim(),
      'email': email.trim(),
      'photoUrl': (photoUrl != null && photoUrl!.trim().isNotEmpty)
          ? photoUrl!.trim()
          : null,
      'defaultAddress': defaultAddress != null && defaultAddress!.isValid
          ? DeliveryAddressModel.fromEntity(defaultAddress!).toMap()
          : null,
      'favoriteRestaurantIds': favoriteRestaurantIds,
      'updatedAt': now,
    };

    if (includeCreatedAt) {
      payload['createdAt'] = now;
    }

    return payload;
  }
}
