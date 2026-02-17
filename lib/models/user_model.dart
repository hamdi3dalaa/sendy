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
  final Map<String, dynamic>? location;
  final String? fcmToken;
  final DateTime? createdAt;
  final String? profileImageUrl;
  final String? pendingProfileImageUrl;
  final bool hasPendingImageChange;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.name,
    required this.userType,
    this.approvalStatus,
    this.idCardUrl,
    this.restaurantName,
    this.location,
    this.fcmToken,
    this.createdAt,
    this.profileImageUrl,
    this.pendingProfileImageUrl,
    this.hasPendingImageChange = false,
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
      'location': location,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'profileImageUrl': profileImageUrl,
      'pendingProfileImageUrl': pendingProfileImageUrl,
      'hasPendingImageChange': hasPendingImageChange,
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
    Map<String, dynamic>? location,
    String? fcmToken,
    DateTime? createdAt,
    String? profileImageUrl,
    String? pendingProfileImageUrl,
    bool? hasPendingImageChange,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      restaurantName: restaurantName ?? this.restaurantName,
      location: location ?? this.location,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      pendingProfileImageUrl: pendingProfileImageUrl ?? this.pendingProfileImageUrl,
      hasPendingImageChange: hasPendingImageChange ?? this.hasPendingImageChange,
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
