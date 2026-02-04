// lib/models/user_model.dart
enum UserType { client, delivery, restaurant }

enum ApprovalStatus { pending, approved, rejected }

class UserModel {
  final String uid;
  final String phoneNumber;
  final UserType userType;
  final ApprovalStatus? approvalStatus;
  final String? idCardUrl;
  final String? restaurantName;
  final Map<String, dynamic>? location;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.userType,
    this.approvalStatus,
    this.idCardUrl,
    this.restaurantName,
    this.location,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      userType: UserType.values[map['userType'] ?? 0],
      approvalStatus: map['approvalStatus'] != null
          ? ApprovalStatus.values[map['approvalStatus']]
          : null,
      idCardUrl: map['idCardUrl'],
      restaurantName: map['restaurantName'],
      location: map['location'],
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'userType': userType.index,
      'approvalStatus': approvalStatus?.index,
      'idCardUrl': idCardUrl,
      'restaurantName': restaurantName,
      'location': location,
      'fcmToken': fcmToken,
    };
  }
}
