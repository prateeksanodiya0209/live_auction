import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String category;
  final double startingPrice;
  final double currentHighestBid;
  final String currentHighestBidderId;
  final double minimumBidIncrement;
  final int totalBids;
  final String auctionStatus; // 'upcoming', 'live', 'ended'
  final DateTime? startTime;
  final DateTime? endTime;
  final String winnerId;
  final double winnerAmount;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.category,
    required this.startingPrice,
    required this.currentHighestBid,
    this.currentHighestBidderId = '',
    this.minimumBidIncrement = 100.0,
    this.totalBids = 0,
    this.auctionStatus = 'live',
    this.startTime,
    this.endTime,
    this.winnerId = '',
    this.winnerAmount = 0.0,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ProductModel(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      images: (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: map['category'] as String? ?? 'General',
      startingPrice: (map['startingPrice'] as num?)?.toDouble() ?? 0.0,
      currentHighestBid: (map['currentHighestBid'] as num?)?.toDouble() ?? 0.0,
      currentHighestBidderId: map['currentHighestBidderId'] as String? ?? '',
      minimumBidIncrement: (map['minimumBidIncrement'] as num?)?.toDouble() ?? 100.0,
      totalBids: map['totalBids'] as int? ?? 0,
      auctionStatus: map['auctionStatus'] as String? ?? 'live',
      startTime: parseDateTime(map['startTime']),
      endTime: parseDateTime(map['endTime']),
      winnerId: map['winnerId'] as String? ?? '',
      winnerAmount: (map['winnerAmount'] as num?)?.toDouble() ?? 0.0,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'images': images,
      'category': category,
      'startingPrice': startingPrice,
      'currentHighestBid': currentHighestBid,
      'currentHighestBidderId': currentHighestBidderId,
      'minimumBidIncrement': minimumBidIncrement,
      'totalBids': totalBids,
      'auctionStatus': auctionStatus,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : FieldValue.serverTimestamp(),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'winnerId': winnerId,
      'winnerAmount': winnerAmount,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    String? category,
    double? startingPrice,
    double? currentHighestBid,
    String? currentHighestBidderId,
    double? minimumBidIncrement,
    int? totalBids,
    String? auctionStatus,
    DateTime? startTime,
    DateTime? endTime,
    String? winnerId,
    double? winnerAmount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      category: category ?? this.category,
      startingPrice: startingPrice ?? this.startingPrice,
      currentHighestBid: currentHighestBid ?? this.currentHighestBid,
      currentHighestBidderId: currentHighestBidderId ?? this.currentHighestBidderId,
      minimumBidIncrement: minimumBidIncrement ?? this.minimumBidIncrement,
      totalBids: totalBids ?? this.totalBids,
      auctionStatus: auctionStatus ?? this.auctionStatus,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      winnerId: winnerId ?? this.winnerId,
      winnerAmount: winnerAmount ?? this.winnerAmount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
