import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_auction/core/constants/app_colors.dart';
import 'package:live_auction/features/auction/presentation/providers/auction_providers.dart';
import 'package:live_auction/features/auction/presentation/widgets/product_card.dart';
import 'package:live_auction/features/auth/presentation/providers/auth_provider.dart';
import 'package:live_auction/features/auth/presentation/screens/login_screen.dart';
import 'package:live_auction/features/notification/presentation/screens/notification_screen.dart';
import 'package:live_auction/features/notification/data/datasources/push_notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _categories = ['All', 'Watches', 'Electronics', 'Collectibles', 'Vehicles'];
  String _selectedStatus = 'live'; // 'live', 'upcoming', 'ended'

  @override
  void initState() {
    super.initState();
    // Auto-seed testing data into Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        ref.read(auctionRemoteDataSourceProvider).seedFullTestingData(user.uid, user.name);
        PushNotificationService().listenToRealTimeNotifications(user.uid);
      }
    });

    // Handle Infinite Scrolling Pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        final currentLimit = ref.read(productsLimitProvider);
        final selectedCategory = ref.read(selectedCategoryProvider);
        final loadedCount = ref.read(productsStreamProvider((category: selectedCategory, status: _selectedStatus))).value?.length ?? 0;

        // If we loaded exactly the limit, there might be more items to fetch
        if (loadedCount >= currentLimit) {
          ref.read(productsLimitProvider.notifier).state = currentLimit + 4;
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currentLimit = ref.watch(productsLimitProvider);

    final productsAsync = ref.watch(
      productsStreamProvider((category: selectedCategory, status: _selectedStatus)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.gavel_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Live Auction',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              if (user == null) return const SizedBox.shrink();
              final notifsAsync = ref.watch(userNotificationsStreamProvider(user.uid));
              final unreadCount = notifsAsync.value?.where((n) => !n.isRead).length ?? 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
            tooltip: 'Seed Test Data into Firestore',
            onPressed: () async {
              if (user != null) {
                await ref.read(auctionRemoteDataSourceProvider).seedFullTestingData(user.uid, user.name);
                ref.read(productsLimitProvider.notifier).state = 4;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Firestore test data seeded successfully!'),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header User Card & Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back 👋',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name.isNotEmpty == true ? user!.name : 'Bidding Master',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Bar Input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val.toLowerCase().trim();
                    },
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search live auctions, watches, guitars...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Selector Filter Chips (Live, Upcoming, Ended)
                  Row(
                    children: [
                      _StatusChip(
                        label: '🔥 Live Auctions',
                        isSelected: _selectedStatus == 'live',
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'live';
                          });
                          ref.read(productsLimitProvider.notifier).state = 4;
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: '⏳ Upcoming',
                        isSelected: _selectedStatus == 'upcoming',
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'upcoming';
                          });
                          ref.read(productsLimitProvider.notifier).state = 4;
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: '🏁 Ended',
                        isSelected: _selectedStatus == 'ended',
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'ended';
                          });
                          ref.read(productsLimitProvider.notifier).state = 4;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Selector horizontal list
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSel = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          onSelected: (_) {
                            ref.read(selectedCategoryProvider.notifier).state = cat;
                            ref.read(productsLimitProvider.notifier).state = 4;
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : AppColors.textSecondary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isSel ? AppColors.primary : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Real-Time Product List
          productsAsync.when(
            data: (products) {
              final filtered = products.where((p) {
                if (searchQuery.isEmpty) return true;
                return p.title.toLowerCase().contains(searchQuery) ||
                    p.description.toLowerCase().contains(searchQuery) ||
                    p.category.toLowerCase().contains(searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.gavel_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text(
                            'No auctions found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Try searching for something else'
                                : 'No auctions available for this filter.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final showLoadingIndicator = filtered.length >= currentLimit;

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ),
                        );
                      }
                      final product = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: ProductCard(product: product),
                      );
                    },
                    childCount: filtered.length + (showLoadingIndicator ? 1 : 0),
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Error loading auctions: $err', style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
