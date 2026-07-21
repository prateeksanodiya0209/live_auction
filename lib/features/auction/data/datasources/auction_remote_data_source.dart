import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_auction/features/auction/data/models/bid_model.dart';
import 'package:live_auction/features/auction/data/models/product_model.dart';
import 'package:live_auction/features/notification/data/models/notification_model.dart';

class AuctionRemoteDataSource {
  final FirebaseFirestore _firestore;

  AuctionRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of all products (with automatic winner declaration check and pagination limit)
  Stream<List<ProductModel>> getProductsStream({String? category, String? status, int? limit}) {
    Query query = _firestore.collection('products').orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('auctionStatus', isEqualTo: status);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
      _processExpiredAuctions(list);
      return list;
    });
  }

  // Realtime stream of a single product
  Stream<ProductModel?> getProductStream(String productId) {
    return _firestore.collection('products').doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        final prod = ProductModel.fromDocument(doc);
        if (prod.auctionStatus == 'live' && prod.endTime != null && DateTime.now().isAfter(prod.endTime!)) {
          _declareWinner(prod);
        }
        return prod;
      }
      return null;
    });
  }

  // Realtime stream of bids for a product
  Stream<List<BidModel>> getBidsStream(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('bids')
        .orderBy('bidAmount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BidModel.fromDocument(doc)).toList();
    });
  }

  // Realtime stream of user notifications
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromDocument(doc)).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // Firestore Atomic Transaction for placing a bid
  Future<void> placeBidInTransaction({
    required String productId,
    required String userId,
    required String userName,
    required String profileImage,
    required double bidAmount,
  }) async {
    final productRef = _firestore.collection('products').doc(productId);
    final bidsRef = productRef.collection('bids').doc();
    final userRef = _firestore.collection('users').doc(userId);

    // Check if user has already placed a bid on this product before transaction
    final userBids = await productRef.collection('bids').where('userId', isEqualTo: userId).limit(1).get();
    if (userBids.docs.isNotEmpty) {
      throw Exception('You have already placed a bid for this item.');
    }

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);

      if (!productSnapshot.exists) {
        throw Exception('Product does not exist!');
      }

      final product = ProductModel.fromDocument(productSnapshot);

      // Validation 1: Bidding Closed / Countdown Finished
      if (product.auctionStatus != 'live' || (product.endTime != null && DateTime.now().isAfter(product.endTime!))) {
        throw Exception('Bidding is closed.');
      }

      // Validation 2: User Already Bid (Current Highest Bidder check)
      if (product.currentHighestBidderId == userId) {
        throw Exception('You have already placed a bid for this item.');
      }

      // Validation 4: Bid amount must meet minimum requirement
      final minRequired = product.totalBids == 0
          ? product.startingPrice
          : product.currentHighestBid + product.minimumBidIncrement;

      if (bidAmount < minRequired) {
        throw Exception('Bid must be at least ₹${minRequired.toStringAsFixed(0)}');
      }

      final previousBidderId = product.currentHighestBidderId;

      // 1. Update Product document
      transaction.update(productRef, {
        'currentHighestBid': bidAmount,
        'currentHighestBidderId': userId,
        'totalBids': product.totalBids + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Create Bid document in subcollection
      final bidModel = BidModel(
        bidId: bidsRef.id,
        userId: userId,
        userName: userName,
        profileImage: profileImage,
        bidAmount: bidAmount,
        createdAt: DateTime.now(),
      );
      transaction.set(bidsRef, bidModel.toMap());

      // 3. Update user totalBids count
      transaction.set(
        userRef,
        {
          'totalBids': FieldValue.increment(1),
          'totalAuctionsJoined': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 4. Send outBid notification to previous highest bidder if it's another user
      if (previousBidderId.isNotEmpty && previousBidderId != userId) {
        final notifRef = _firestore.collection('notifications').doc();
        final notification = NotificationModel(
          id: notifRef.id,
          userId: previousBidderId,
          productId: productId,
          title: 'You were outbid!',
          message: 'Someone placed a higher bid of ₹${bidAmount.toStringAsFixed(0)} on "${product.title}".',
          type: 'outBid',
          isRead: false,
          createdAt: DateTime.now(),
        );
        transaction.set(notifRef, notification.toMap());
      }
    });
  }

  // Automatic Winner Selection & Declaration
  void _processExpiredAuctions(List<ProductModel> products) {
    final now = DateTime.now();
    for (final prod in products) {
      if (prod.auctionStatus == 'live' && prod.endTime != null && now.isAfter(prod.endTime!)) {
        _declareWinner(prod);
      }
    }
  }

  Future<void> _declareWinner(ProductModel prod) async {
    try {
      final winnerId = prod.currentHighestBidderId;
      final winnerAmount = prod.currentHighestBid;

      // 1. Update product status to ended
      await _firestore.collection('products').doc(prod.id).update({
        'auctionStatus': 'ended',
        'winnerId': winnerId,
        'winnerAmount': winnerAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Write to winners/{productId}
      if (winnerId.isNotEmpty) {
        final winnerUserDoc = await _firestore.collection('users').doc(winnerId).get();
        final winnerName = winnerUserDoc.data()?['name'] as String? ?? 'Winning Bidder';

        await _firestore.collection('winners').doc(prod.id).set({
          'productId': prod.id,
          'winnerId': winnerId,
          'winnerName': winnerName,
          'winningAmount': winnerAmount,
          'endedAt': FieldValue.serverTimestamp(),
        });

        // 3. Send victory notification to winner
        final notifRef = _firestore.collection('notifications').doc();
        final notification = NotificationModel(
          id: notifRef.id,
          userId: winnerId,
          productId: prod.id,
          title: 'Congratulations! You Won 🎉',
          message: 'You won the auction for "${prod.title}" with a winning bid of ₹${winnerAmount.toStringAsFixed(0)}!',
          type: 'winner',
          isRead: false,
          createdAt: DateTime.now(),
        );
        await notifRef.set(notification.toMap());

        // Increment totalWins for winner user
        await _firestore.collection('users').doc(winnerId).set({
          'totalWins': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Ignore if already processed
    }
  }

  // Populate complete rich testing data into Firestore
  Future<void> seedFullTestingData(String currentUserId, String currentUserName) async {
    final productsCollection = _firestore.collection('products');

    final sampleProducts = [
      ProductModel(
        id: 'p1',
        title: 'Rolex Submariner Date 41mm',
        description: 'Authentic 2023 Rolex Submariner Date in Oystersteel with Black Cerachrom Bezel. Mint condition with original box & certificates.',
        images: [
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
          'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=800&q=80',
        ],
        category: 'Watches',
        startingPrice: 50000,
        currentHighestBid: 65000,
        currentHighestBidderId: 'user_alex',
        minimumBidIncrement: 1000,
        totalBids: 5,
        auctionStatus: 'live',
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().add(const Duration(hours: 18, minutes: 45)),
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'p2',
        title: 'Vintage 1968 Fender Stratocaster',
        description: 'Rare Sunburst finish 1968 Fender Stratocaster guitar. Original pickups and hardware, rich vintage tone, collector item.',
        images: [
          'https://images.unsplash.com/photo-1550291652-6ea9114a47b1?w=800&q=80',
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80',
        ],
        category: 'Collectibles',
        startingPrice: 80000,
        currentHighestBid: 95000,
        currentHighestBidderId: 'user_sarah',
        minimumBidIncrement: 2000,
        totalBids: 6,
        auctionStatus: 'live',
        startTime: DateTime.now().subtract(const Duration(hours: 12)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 6)),
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'p3',
        title: 'Apple Vision Pro 1TB Spatial Computer',
        description: 'Brand new sealed Apple Vision Pro spatial computer 1TB storage edition with Dual Loop Band and travel case included.',
        images: [
          'https://images.unsplash.com/photo-1592478411213-6153e4ebc07d?w=800&q=80',
          'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=800&q=80',
        ],
        category: 'Electronics',
        startingPrice: 30000,
        currentHighestBid: 42000,
        currentHighestBidderId: 'user_david',
        minimumBidIncrement: 500,
        totalBids: 4,
        auctionStatus: 'live',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 5, minutes: 20)),
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'p4',
        title: 'Air Jordan 1 Retro Reverse Mocha',
        description: 'Exclusive Travis Scott x Air Jordan 1 High OG in Reverse Mocha colorway. Size 10 US, brand new in original box.',
        images: [
          'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&q=80',
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
        ],
        category: 'Collectibles',
        startingPrice: 15000,
        currentHighestBid: 24500,
        currentHighestBidderId: currentUserId,
        minimumBidIncrement: 500,
        totalBids: 7,
        auctionStatus: 'live',
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        endTime: DateTime.now().add(const Duration(hours: 12, minutes: 10)),
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'p5',
        title: '2024 Ducati Panigale V4 S Superbike',
        description: 'Ultra high performance 2024 Ducati Panigale V4 S with Akrapovič full titanium exhaust system and carbon fiber wings.',
        images: [
          'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800&q=80',
          'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800&q=80',
        ],
        category: 'Vehicles',
        startingPrice: 1500000,
        currentHighestBid: 1850000,
        currentHighestBidderId: 'user_marcus',
        minimumBidIncrement: 25000,
        totalBids: 3,
        auctionStatus: 'upcoming',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(days: 3)),
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'p6',
        title: 'MacBook Pro 16" M3 Max 64GB RAM',
        description: 'Space Black Apple MacBook Pro 16-inch with M3 Max 16-core CPU, 40-core GPU, 64GB Unified Memory, and 2TB SSD.',
        images: [
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80',
        ],
        category: 'Electronics',
        startingPrice: 180000,
        currentHighestBid: 210000,
        currentHighestBidderId: 'user_emily',
        minimumBidIncrement: 2000,
        totalBids: 5,
        auctionStatus: 'live',
        startTime: DateTime.now().subtract(const Duration(hours: 6)),
        endTime: DateTime.now().add(const Duration(hours: 8, minutes: 30)),
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'p7',
        title: '18K Solid Gold Commemorative Coin',
        description: 'Pure 18K Solid Gold 50g Commemorative Coin with custom velvet wooden display box and authenticity certificate.',
        images: [
          'https://images.unsplash.com/photo-1610375461246-83df859d849d?w=800&q=80',
        ],
        category: 'Collectibles',
        startingPrice: 90000,
        currentHighestBid: 125000,
        currentHighestBidderId: currentUserId,
        minimumBidIncrement: 1000,
        totalBids: 9,
        auctionStatus: 'ended',
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
        winnerId: currentUserId,
        winnerAmount: 125000,
        createdBy: 'user_gold_dealer',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Write Products
    for (final prod in sampleProducts) {
      await productsCollection.doc(prod.id).set(prod.toMap());

      // Write sample bids for each product
      final bidsCollection = productsCollection.doc(prod.id).collection('bids');

      final sampleBids = [
        BidModel(
          bidId: 'b_${prod.id}_1',
          userId: 'user_alex',
          userName: 'Alex Johnson',
          bidAmount: prod.startingPrice + prod.minimumBidIncrement,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        BidModel(
          bidId: 'b_${prod.id}_2',
          userId: 'user_sarah',
          userName: 'Sarah Connor',
          bidAmount: prod.startingPrice + (prod.minimumBidIncrement * 2),
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        BidModel(
          bidId: 'b_${prod.id}_3',
          userId: prod.currentHighestBidderId.isNotEmpty ? prod.currentHighestBidderId : currentUserId,
          userName: prod.currentHighestBidderId == currentUserId ? currentUserName : 'Marcus Wright',
          bidAmount: prod.currentHighestBid,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];

      for (final bid in sampleBids) {
        await bidsCollection.doc(bid.bidId).set(bid.toMap());
      }
    }

    // Write Winner record for p7
    await _firestore.collection('winners').doc('p7').set({
      'productId': 'p7',
      'winnerId': currentUserId,
      'winnerName': currentUserName,
      'winningAmount': 125000,
      'endedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
    });

    // Write sample Notifications for current user
    final notificationsCollection = _firestore.collection('notifications');

    final sampleNotifications = [
      NotificationModel(
        id: 'n1',
        userId: currentUserId,
        productId: 'p1',
        title: 'You were outbid!',
        message: 'Alex Johnson placed a higher bid of ₹65,000 on "Rolex Submariner Date 41mm".',
        type: 'outBid',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      NotificationModel(
        id: 'n2',
        userId: currentUserId,
        productId: 'p7',
        title: 'Congratulations! You Won 🎉',
        message: 'You won the auction for "18K Solid Gold Commemorative Coin" with a winning bid of ₹125,000!',
        type: 'winner',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'n3',
        userId: currentUserId,
        productId: 'p5',
        title: 'Auction Starting Soon ⏳',
        message: 'The auction for "2024 Ducati Panigale V4 S Superbike" is starting in 2 hours.',
        type: 'auctionStart',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];

    for (final notif in sampleNotifications) {
      await notificationsCollection.doc(notif.id).set(notif.toMap());
    }

    // Global settings document
    await _firestore.collection('settings').doc('auction').set({
      'minimumBidIncrement': 100,
      'currency': '₹',
      'allowAutoBid': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
