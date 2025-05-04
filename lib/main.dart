import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wagus/app.dart';
import 'package:wagus/config_service.dart';
import 'package:wagus/observer.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  final configService = ConfigService();

  if (await configService.isKillSwitchEnabled()) {
    runApp(
        MaterialApp(home: Scaffold(body: Center(child: Text('App disabled')))));
    return;
  }

  if (await configService.isAppOutdated()) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Please update to continue',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    const androidUrl =
                        'https://play.google.com/store/apps/details?id=com.silnt.wagus';
                    const iosUrl =
                        'https://apps.apple.com/us/app/wagus/id6742799148';

                    final url = Platform.isIOS ? iosUrl : androidUrl;

                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text('Update Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  await _requestNotificationPermission();

  // Set up foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a foreground message: ${message.messageId}');
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
    // TODO: Handle the message and update UI as needed
  });

  // Set up message opened app handler
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked!: ${message.messageId}');
    // TODO: Navigate to a specific screen based on the message
  });

  Bloc.observer = AppBlocObserver();

  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print(
        '🔥 App launched from terminated state via notification: ${initialMessage.messageId}');
    // You could pass this to the App widget or trigger navigation logic here
  }

  String? token = await FirebaseMessaging.instance.getToken();
  print('📲 FCM Token: $token');

  await FirebaseMessaging.instance.subscribeToTopic('daily_reward');
  print('✅ Subscribed to daily_reward topic');

  await PrivyService().initialize();

  runApp(App(router: appRouter));
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
