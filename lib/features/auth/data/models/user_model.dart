import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String deviceToken;
  final bool isOnline;
  final bool isBlocked;
  final int totalAuctionsJoined;
  final int totalWins;
  final int totalBids;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.profileImage = '',
    this.deviceToken = '',
    this.isOnline = true,
    this.isBlocked = false,
    this.totalAuctionsJoined = 0,
    this.totalWins = 0,
    this.totalBids = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId.isNotEmpty ? docId : (map['uid'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      profileImage: map['profileImage'] as String? ?? '',
      deviceToken: map['deviceToken'] as String? ?? '',
      isOnline: map['isOnline'] as bool? ?? true,
      isBlocked: map['isBlocked'] as bool? ?? false,
      totalAuctionsJoined: map['totalAuctionsJoined'] as int? ?? 0,
      totalWins: map['totalWins'] as int? ?? 0,
      totalBids: map['totalBids'] as int? ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String ? DateTime.tryParse(map['createdAt']) : null),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] is String ? DateTime.tryParse(map['updatedAt']) : null),
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'deviceToken': deviceToken,
      'isOnline': isOnline,
      'isBlocked': isBlocked,
      'totalAuctionsJoined': totalAuctionsJoined,
      'totalWins': totalWins,
      'totalBids': totalBids,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? deviceToken,
    bool? isOnline,
    bool? isBlocked,
    int? totalAuctionsJoined,
    int? totalWins,
    int? totalBids,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      deviceToken: deviceToken ?? this.deviceToken,
      isOnline: isOnline ?? this.isOnline,
      isBlocked: isBlocked ?? this.isBlocked,
      totalAuctionsJoined: totalAuctionsJoined ?? this.totalAuctionsJoined,
      totalWins: totalWins ?? this.totalWins,
      totalBids: totalBids ?? this.totalBids,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
