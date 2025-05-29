import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badge/flutter_app_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wagus/app.dart';
import 'package:wagus/config_service.dart';
import 'package:wagus/lifecycle_handler.dart';
import 'package:wagus/observer.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/update_required_screen.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('🧯 FlutterError: ${details.exception}');
  };
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();

    final configService = ConfigService();

    final killSwitch = await configService.isKillSwitchEnabled();
    final outdated = await configService.isAppOutdated();

    if (killSwitch) {
      runApp(MaterialApp(
          home: Scaffold(body: Center(child: Text('App disabled')))));
      return;
    }

    if (outdated) {
      runApp(UpdateRequiredScreen());
      return;
    }

    runApp(App(router: appRouter));
    _postBootAsync();
  } catch (e, st) {
    // Fallback UI to avoid hard crash
    runApp(MaterialApp(
        home: Scaffold(body: Center(child: Text('Startup error')))));
    print('🔥 App crash in main(): $e');
    print(st);
  }
}

Future<void> _tryRemoveAppBadge() async {
  try {
    await FlutterAppBadge.count(0);
    print('✅ App badge removed successfully');
  } catch (e) {
    print('⚠️ Failed to remove app badge: $e');
  }
}

Future<void> _postBootAsync() async {
  try {
    await _tryRemoveAppBadge();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestNotificationPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!: ${message.messageId}');
    });

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
      print('📲 FCM Token: $token');
      await FirebaseMessaging.instance.subscribeToTopic('global_users');
    } catch (e) {
      print('⚠️ Failed to get FCM token: $e');
    }

    print('📲 FCM Token: $token');

    final privyUser = await PrivyService().initialize();
    final wallet = privyUser?.embeddedSolanaWallets.firstOrNull?.address;
    print('🔑 Wallet address: $wallet');

    if (wallet != null) {
      WidgetsBinding.instance.addObserver(LifecycleHandler(wallet));
      await UserService().setUserOnline(wallet);
    } else {
      print("⚠️ No wallet found, skipping lifecycle observer.");
    }

    if (wallet != null && token != null) {
      // Save FCM token to Firestore under user's doc
      await FirebaseFirestore.instance.collection('users').doc(wallet).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  } catch (e, st) {
    print('🛑 Startup error: $e');
    print(st);
  }
}

/// Requests notification permissions from the user
Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
}
