import 'package:equatable/equatable.dart';
import 'package:food_delivery_application/domain/entities/cart_order_entities.dart';

/// Authenticated application user profile synchronized with Cloud Firestore.
class AppUserEntity extends Equatable {
  const AppUserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.defaultAddress,
    this.favoriteRestaurantIds = const [],
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DeliveryAddressEntity? defaultAddress;
  final List<String> favoriteRestaurantIds;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'WC';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  AppUserEntity copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    DeliveryAddressEntity? defaultAddress,
    List<String>? favoriteRestaurantIds,
  }) {
    return AppUserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      favoriteRestaurantIds:
          favoriteRestaurantIds ?? this.favoriteRestaurantIds,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    photoUrl,
    defaultAddress,
    favoriteRestaurantIds,
  ];
}
