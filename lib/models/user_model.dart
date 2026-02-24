// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { client, delivery, restaurant, admin }

enum ApprovalStatus { pending, approved, rejected }

class UserModel {
  final String uid;
  final String phoneNumber;
  final String? name;
  final UserType userType;
  final ApprovalStatus? approvalStatus;
  final String? idCardUrl;
  final String? restaurantName;
  final String? restaurantAddress;
  final String? city;
  final Map<String, dynamic>? location;
  final String? fcmToken;
  final DateTime? createdAt;
  final String? profileImageUrl;
  final String? pendingProfileImageUrl;
  final bool hasPendingImageChange;
  // Restaurant availability
  final bool isAvailable;
  final String? openTime;  // "HH:mm" format
  final String? closeTime; // "HH:mm" format

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.name,
    required this.userType,
    this.approvalStatus,
    this.idCardUrl,
    this.restaurantName,
    this.restaurantAddress,
    this.city,
    this.location,
    this.fcmToken,
    this.createdAt,
    this.profileImageUrl,
    this.pendingProfileImageUrl,
    this.hasPendingImageChange = false,
    this.isAvailable = true,
    this.openTime,
    this.closeTime,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'],
      userType: UserType.values[map['userType'] ?? 0],
      approvalStatus: map['approvalStatus'] != null
          ? ApprovalStatus.values[map['approvalStatus']]
          : null,
      idCardUrl: map['idCardUrl'],
      restaurantName: map['restaurantName'],
      restaurantAddress: map['restaurantAddress'],
      city: map['city'],
      location: map['location'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'].toString()))
          : null,
      profileImageUrl: map['profileImageUrl'],
      pendingProfileImageUrl: map['pendingProfileImageUrl'],
      hasPendingImageChange: map['hasPendingImageChange'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      openTime: map['openTime'],
      closeTime: map['closeTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'userType': userType.index,
      'approvalStatus': approvalStatus?.index,
      'idCardUrl': idCardUrl,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'city': city,
      'location': location,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'profileImageUrl': profileImageUrl,
      'pendingProfileImageUrl': pendingProfileImageUrl,
      'hasPendingImageChange': hasPendingImageChange,
      'isAvailable': isAvailable,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    String? name,
    UserType? userType,
    ApprovalStatus? approvalStatus,
    String? idCardUrl,
    String? restaurantName,
    String? restaurantAddress,
    String? city,
    Map<String, dynamic>? location,
    String? fcmToken,
    DateTime? createdAt,
    String? profileImageUrl,
    String? pendingProfileImageUrl,
    bool? hasPendingImageChange,
    bool? isAvailable,
    String? openTime,
    String? closeTime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      city: city ?? this.city,
      location: location ?? this.location,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      pendingProfileImageUrl: pendingProfileImageUrl ?? this.pendingProfileImageUrl,
      hasPendingImageChange: hasPendingImageChange ?? this.hasPendingImageChange,
      isAvailable: isAvailable ?? this.isAvailable,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  String get displayName => name ?? phoneNumber;
  bool get hasName => name != null && name!.isNotEmpty;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isRejected => approvalStatus == ApprovalStatus.rejected;
  bool get isAdmin => userType == UserType.admin;

  String get userTypeString {
    switch (userType) {
      case UserType.client:
        return 'Client';
      case UserType.delivery:
        return 'Livreur';
      case UserType.restaurant:
        return 'Restaurant';
      case UserType.admin:
        return 'Administrateur';
    }
  }

  String get approvalStatusString {
    if (approvalStatus == null) return 'N/A';
    switch (approvalStatus!) {
      case ApprovalStatus.pending:
        return 'En attente';
      case ApprovalStatus.approved:
        return 'Approuvé';
      case ApprovalStatus.rejected:
        return 'Rejeté';
    }
  }
}

/// Restaurant-specific user model with restaurant fields
class RestaurantUser extends UserModel {
  RestaurantUser._({
    required super.uid,
    required super.phoneNumber,
    super.name,
    super.approvalStatus,
    super.idCardUrl,
    super.restaurantName,
    super.restaurantAddress,
    super.city,
    super.location,
    super.fcmToken,
    super.createdAt,
    super.profileImageUrl,
    super.pendingProfileImageUrl,
    super.hasPendingImageChange,
    super.isAvailable,
    super.openTime,
    super.closeTime,
  }) : super(userType: UserType.restaurant);

  factory RestaurantUser.fromUserModel(UserModel user) {
    return RestaurantUser._(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      name: user.name,
      approvalStatus: user.approvalStatus,
      idCardUrl: user.idCardUrl,
      restaurantName: user.restaurantName,
      restaurantAddress: user.restaurantAddress,
      city: user.city,
      location: user.location,
      fcmToken: user.fcmToken,
      createdAt: user.createdAt,
      profileImageUrl: user.profileImageUrl,
      pendingProfileImageUrl: user.pendingProfileImageUrl,
      hasPendingImageChange: user.hasPendingImageChange,
      isAvailable: user.isAvailable,
      openTime: user.openTime,
      closeTime: user.closeTime,
    );
  }

  factory RestaurantUser.fromMap(Map<String, dynamic> map) {
    return RestaurantUser.fromUserModel(UserModel.fromMap(map));
  }

  /// Restaurant display name (restaurantName or name)
  String get displayRestaurantName =>
      restaurantName ?? name ?? phoneNumber;

  /// Full address string
  String get fullAddress {
    final parts = <String>[];
    if (restaurantAddress != null && restaurantAddress!.isNotEmpty) {
      parts.add(restaurantAddress!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    return parts.join(', ');
  }

  /// Whether the restaurant has a logo
  bool get hasLogo =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Whether the restaurant has a complete profile
  bool get hasCompleteProfile =>
      restaurantName != null &&
      restaurantName!.isNotEmpty &&
      restaurantAddress != null &&
      restaurantAddress!.isNotEmpty;

  /// Whether the restaurant has set working hours
  bool get hasWorkingHours =>
      openTime != null && openTime!.isNotEmpty &&
      closeTime != null && closeTime!.isNotEmpty;

  /// Whether the restaurant is currently within working hours
  bool get isWithinWorkingHours {
    if (!hasWorkingHours) return true; // No hours set = always open
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final openParts = openTime!.split(':');
    final closeParts = closeTime!.split(':');
    final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    if (closeMinutes > openMinutes) {
      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    } else {
      // Overnight (e.g., 22:00 - 02:00)
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }
  }

  /// Whether the restaurant is effectively open (available + within hours)
  bool get isOpen => isAvailable && isWithinWorkingHours;
}

/// Delivery-specific user model with delivery fields
class DeliveryUser extends UserModel {
  DeliveryUser._({
    required super.uid,
    required super.phoneNumber,
    super.name,
    super.approvalStatus,
    super.idCardUrl,
    super.city,
    super.location,
    super.fcmToken,
    super.createdAt,
    super.profileImageUrl,
    super.pendingProfileImageUrl,
    super.hasPendingImageChange,
  }) : super(userType: UserType.delivery);

  factory DeliveryUser.fromUserModel(UserModel user) {
    return DeliveryUser._(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      name: user.name,
      approvalStatus: user.approvalStatus,
      idCardUrl: user.idCardUrl,
      city: user.city,
      location: user.location,
      fcmToken: user.fcmToken,
      createdAt: user.createdAt,
      profileImageUrl: user.profileImageUrl,
      pendingProfileImageUrl: user.pendingProfileImageUrl,
      hasPendingImageChange: user.hasPendingImageChange,
    );
  }

  factory DeliveryUser.fromMap(Map<String, dynamic> map) {
    return DeliveryUser.fromUserModel(UserModel.fromMap(map));
  }

  /// Delivery person's operating city
  String get operatingCity => city ?? '';

  /// Whether the delivery person has set their city
  bool get hasCitySet => city != null && city!.isNotEmpty;

  /// Whether the delivery person has a profile photo
  bool get hasProfilePhoto =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Whether the delivery person has a complete profile
  bool get hasCompleteProfile =>
      name != null &&
      name!.isNotEmpty &&
      idCardUrl != null &&
      idCardUrl!.isNotEmpty &&
      hasCitySet;

  /// Current GPS location (lat/lng)
  double? get latitude =>
      location != null ? (location!['latitude'] as num?)?.toDouble() : null;

  double? get longitude =>
      location != null ? (location!['longitude'] as num?)?.toDouble() : null;

  /// Whether the delivery person has a valid GPS location
  bool get hasLocation => latitude != null && longitude != null;
}
