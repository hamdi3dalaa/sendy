// lib/models/settlement_model.dart
enum SettlementStatus { pending, approved, rejected }

class SettlementModel {
  final String settlementId;
  final String deliveryPersonId;
  final String deliveryPersonName;
  final String deliveryPersonPhone;
  final double amount;
  final String proofImageUrl;
  final SettlementStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? adminNote;

  SettlementModel({
    required this.settlementId,
    required this.deliveryPersonId,
    required this.deliveryPersonName,
    required this.deliveryPersonPhone,
    required this.amount,
    required this.proofImageUrl,
    this.status = SettlementStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.adminNote,
  });

  factory SettlementModel.fromMap(Map<String, dynamic> map) {
    return SettlementModel(
      settlementId: map['settlementId'] ?? '',
      deliveryPersonId: map['deliveryPersonId'] ?? '',
      deliveryPersonName: map['deliveryPersonName'] ?? '',
      deliveryPersonPhone: map['deliveryPersonPhone'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      proofImageUrl: map['proofImageUrl'] ?? '',
      status: SettlementStatus.values[map['status'] ?? 0],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.parse(map['reviewedAt'])
          : null,
      reviewedBy: map['reviewedBy'],
      adminNote: map['adminNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settlementId': settlementId,
      'deliveryPersonId': deliveryPersonId,
      'deliveryPersonName': deliveryPersonName,
      'deliveryPersonPhone': deliveryPersonPhone,
      'amount': amount,
      'proofImageUrl': proofImageUrl,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'adminNote': adminNote,
    };
  }
}
