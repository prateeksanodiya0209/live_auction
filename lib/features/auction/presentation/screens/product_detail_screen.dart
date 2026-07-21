import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:live_auction/core/constants/app_colors.dart';
import 'package:live_auction/features/auction/data/models/bid_model.dart';
import 'package:live_auction/features/auction/presentation/providers/auction_providers.dart';
import 'package:live_auction/features/auction/presentation/widgets/place_bid_bottom_sheet.dart';
import 'package:live_auction/features/auth/presentation/providers/auth_provider.dart';
import 'package:live_auction/shared/widgets/countdown_timer_widget.dart';
import 'package:live_auction/shared/widgets/custom_button.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailStreamProvider(widget.productId));
    final bidsAsync = ref.watch(productBidsStreamProvider(widget.productId));
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(
              child: Text('Product not found.', style: TextStyle(color: AppColors.textPrimary)),
            );
          }

          final currentUser = ref.watch(authControllerProvider).user;
          final bidsList = bidsAsync.value ?? [];

          final isClosed = product.auctionStatus != 'live' ||
              (product.endTime != null && DateTime.now().isAfter(product.endTime!));

          final hasUserBid = currentUser != null &&
              (bidsList.any((b) => b.userId == currentUser.uid) ||
                  product.currentHighestBidderId == currentUser.uid);

          String buttonText;
          bool isButtonEnabled;
          IconData buttonIcon;

          if (isClosed) {
            buttonText = 'Bidding is closed.';
            isButtonEnabled = false;
            buttonIcon = Icons.lock_clock_outlined;
          } else if (hasUserBid) {
            buttonText = 'You have already placed a bid for this item.';
            isButtonEnabled = false;
            buttonIcon = Icons.check_circle_outline;
          } else {
            buttonText = 'Place Bid Now';
            isButtonEnabled = true;
            buttonIcon = Icons.gavel_rounded;
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Image Gallery SliverAppBar
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    backgroundColor: AppColors.surface,
                    leading: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: product.images.isNotEmpty ? product.images.length : 1,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              if (product.images.isEmpty) {
                                return Container(
                                  color: AppColors.surfaceLight,
                                  child: const Icon(Icons.gavel_rounded, size: 64, color: AppColors.textMuted),
                                );
                              }
                              return Image.network(
                                product.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.surfaceLight,
                                  child: const Icon(Icons.gavel_rounded, size: 64, color: AppColors.textMuted),
                                ),
                              );
                            },
                          ),
                          // Gallery Dot Indicator
                          if (product.images.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  product.images.length,
                                  (idx) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _currentImageIndex == idx ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentImageIndex == idx ? AppColors.primary : Colors.white54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Chip & Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  product.category,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CountdownTimerWidget(
                                endTime: product.endTime,
                                status: product.auctionStatus,
                                compact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Product Title
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Countdown Timer Live Card
                          CountdownTimerWidget(
                            endTime: product.endTime,
                            status: product.auctionStatus,
                          ),
                          const SizedBox(height: 20),

                          // Current Highest Bid Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppColors.darkCardGradient,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Highest Bid',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormatter.format(product.currentHighestBid > 0
                                          ? product.currentHighestBid
                                          : product.startingPrice),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total Bids',
                                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${product.totalBids}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Item Overview Specs
                          Row(
                            children: [
                              Expanded(
                                child: _InfoBox(
                                  label: 'Starting Price',
                                  value: currencyFormatter.format(product.startingPrice),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoBox(
                                  label: 'Min Increment',
                                  value: '+${currencyFormatter.format(product.minimumBidIncrement)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Real-Time Bid History Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Live Bid History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${product.totalBids} bids placed',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Bid Stream List
                          bidsAsync.when(
                            data: (bids) {
                              if (bids.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.gavel_outlined, color: AppColors.textMuted, size: 36),
                                      SizedBox(height: 8),
                                      Text(
                                        'No bids placed yet. Be the first!',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bids.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final bid = bids[index];
                                  final isTop = index == 0;
                                  return _BidHistoryTile(
                                    bid: bid,
                                    isTopBid: isTop,
                                    currencyFormatter: currencyFormatter,
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                            error: (err, _) => Text(
                              'Error loading bids: $err',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                          const SizedBox(height: 100), // Bottom padding for sticky bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Fixed Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: const Border(top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: CustomButton(
                      text: buttonText,
                      onPressed: isButtonEnabled
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => PlaceBidBottomSheet(product: product),
                              );
                            }
                          : null,
                      icon: buttonIcon,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text('Error loading product: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _BidHistoryTile extends StatelessWidget {
  final BidModel bid;
  final bool isTopBid;
  final NumberFormat currencyFormatter;

  const _BidHistoryTile({
    required this.bid,
    required this.isTopBid,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = bid.createdAt != null
        ? DateFormat('hh:mm a, dd MMM').format(bid.createdAt!)
        : 'Just now';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isTopBid ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTopBid ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isTopBid ? AppColors.primary : AppColors.surfaceLight,
            child: Text(
              bid.userName.isNotEmpty ? bid.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isTopBid ? Colors.black : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bid.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isTopBid) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'HIGHEST',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(bid.bidAmount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isTopBid ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
