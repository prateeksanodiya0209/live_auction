import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String productId;
  final String title;
  final String message;
  final String type; // 'auctionStart', 'outBid', 'winner', 'auctionEnded'
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return NotificationModel(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'outBid',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
