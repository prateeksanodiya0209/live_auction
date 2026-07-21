import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String bidId;
  final String userId;
  final String userName;
  final String profileImage;
  final double bidAmount;
  final DateTime? createdAt;

  BidModel({
    required this.bidId,
    required this.userId,
    required this.userName,
    this.profileImage = '',
    required this.bidAmount,
    this.createdAt,
  });

  factory BidModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return BidModel(
      bidId: docId.isNotEmpty ? docId : (map['bidId'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous',
      profileImage: map['profileImage'] as String? ?? '',
      bidAmount: (map['bidAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  factory BidModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BidModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'bidId': bidId,
      'userId': userId,
      'userName': userName,
      'profileImage': profileImage,
      'bidAmount': bidAmount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
