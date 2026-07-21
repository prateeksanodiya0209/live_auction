import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:live_auction/core/constants/app_colors.dart';
import 'package:live_auction/features/auction/presentation/providers/auction_providers.dart';
import 'package:live_auction/features/auth/presentation/providers/auth_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please sign in to view notifications.')),
      );
    }

    final notifsAsync = ref.watch(userNotificationsStreamProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: notifsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'You will receive updates when outbid or winning!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isWinner = notif.type == 'winner';
              final timeStr = notif.createdAt != null
                  ? DateFormat('hh:mm a, dd MMM').format(notif.createdAt!)
                  : 'Just now';

              return GestureDetector(
                onTap: () {
                  if (!notif.isRead) {
                    ref.read(auctionRemoteDataSourceProvider).markNotificationAsRead(notif.id);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notif.isRead
                        ? AppColors.surface
                        : (isWinner
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: notif.isRead
                          ? AppColors.border
                          : (isWinner ? AppColors.primary : AppColors.accent),
                      width: notif.isRead ? 1.0 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isWinner
                              ? AppColors.primary
                              : (notif.type == 'outBid' ? AppColors.error : AppColors.accent),
                        ),
                        child: Icon(
                          isWinner
                              ? Icons.emoji_events_rounded
                              : (notif.type == 'outBid' ? Icons.gavel_rounded : Icons.notifications_active_rounded),
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isWinner ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                if (!notif.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading notifications: $err', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }
}
