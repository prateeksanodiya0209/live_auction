import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_auction/core/theme/app_theme.dart';
import 'package:live_auction/features/auth/presentation/screens/splash_screen.dart';
import 'package:live_auction/features/notification/data/datasources/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Enable Firestore Offline Cache & Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    const ProviderScope(
      child: LiveAuctionApp(),
    ),
  );
}

class LiveAuctionApp extends ConsumerStatefulWidget {
  const LiveAuctionApp({super.key});

  @override
  ConsumerState<LiveAuctionApp> createState() => _LiveAuctionAppState();
}

class _LiveAuctionAppState extends ConsumerState<LiveAuctionApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService().initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Auction',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
