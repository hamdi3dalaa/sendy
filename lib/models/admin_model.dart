// lib/models/admin_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String uid;
  final String phoneNumber;
  final String? name;
  final String? email;
  final DateTime? createdAt;
  final bool isActive;

  AdminModel({
    required this.uid,
    required this.phoneNumber,
    this.name,
    this.email,
    this.createdAt,
    this.isActive = true,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'],
      email: map['email'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'].toString()))
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'isActive': isActive,
    };
  }

  String get displayName => name ?? phoneNumber;
}
