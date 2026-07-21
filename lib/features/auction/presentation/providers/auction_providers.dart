import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auction_remote_data_source.dart';
import '../../data/models/bid_model.dart';
import '../../data/models/product_model.dart';
import '../../../notification/data/models/notification_model.dart';

final auctionRemoteDataSourceProvider = Provider<AuctionRemoteDataSource>((ref) {
  return AuctionRemoteDataSource();
});

// Stream of products filtered by category & status
final productsStreamProvider = StreamProvider.family<List<ProductModel>, ({String? category, String? status})>((ref, filter) {
  final dataSource = ref.watch(auctionRemoteDataSourceProvider);
  return dataSource.getProductsStream(category: filter.category, status: filter.status);
});

// Stream of a single product
final productDetailStreamProvider = StreamProvider.family<ProductModel?, String>((ref, productId) {
  final dataSource = ref.watch(auctionRemoteDataSourceProvider);
  return dataSource.getProductStream(productId);
});

// Stream of bids for a product
final productBidsStreamProvider = StreamProvider.family<List<BidModel>, String>((ref, productId) {
  final dataSource = ref.watch(auctionRemoteDataSourceProvider);
  return dataSource.getBidsStream(productId);
});

// Stream of user notifications
final userNotificationsStreamProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  final dataSource = ref.watch(auctionRemoteDataSourceProvider);
  return dataSource.getUserNotificationsStream(userId);
});

// Selected Category State
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Search Query State
final searchQueryProvider = StateProvider<String>((ref) => '');

// Bidding Controller State
class BiddingState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  const BiddingState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  BiddingState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return BiddingState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class BiddingNotifier extends StateNotifier<BiddingState> {
  final AuctionRemoteDataSource _dataSource;

  BiddingNotifier(this._dataSource) : super(const BiddingState());

  Future<bool> placeBid({
    required String productId,
    required String userId,
    required String userName,
    required String profileImage,
    required double bidAmount,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      await _dataSource.placeBidInTransaction(
        productId: productId,
        userId: userId,
        userName: userName,
        profileImage: profileImage,
        bidAmount: bidAmount,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Bid placed successfully!',
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  void clearState() {
    state = const BiddingState();
  }
}

final biddingControllerProvider = StateNotifierProvider<BiddingNotifier, BiddingState>((ref) {
  final dataSource = ref.watch(auctionRemoteDataSourceProvider);
  return BiddingNotifier(dataSource);
});
