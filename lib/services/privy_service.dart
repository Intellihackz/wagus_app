import 'package:flutter/foundation.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:wagus/router.dart';

class PrivyService {
  static final PrivyService _instance = PrivyService._internal();
  late final Privy privy;
  bool _isInitialized = false;

  factory PrivyService() {
    return _instance;
  }

  // Private constructor
  PrivyService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    final privyConfig = PrivyConfig(
      appId: dotenv.env['PRIVY_APP_ID'] ?? '',
      appClientId: dotenv.env['PRIVY_CLIENT_ID'] ?? '',
      logLevel: PrivyLogLevel.verbose,
    );

    privy = Privy.init(config: privyConfig);
    await privy.awaitReady();
    _isInitialized = true;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    if (!_isInitialized) return false;
    return privy.currentAuthState.isAuthenticated;
  }

  void loginWithEmail(String email) async {
    try {
      final Result<void> result = await privy.email.sendCode(email);

      result.fold(
        onSuccess: (_) {
          // OTP was sent successfully
          debugPrint('OTP sent successfully to $email');
        },
        onFailure: (error) {
          // Handle error sending OTP
          debugPrint('Error sending OTP: ${error.message}');
        },
      );
    } catch (e) {
      debugPrint('Error sending email login: $e');
    }
  }

  void verifyOtp(String email, String otp, BuildContext context) async {
    try {
      final Result<PrivyUser> result = await privy.email.loginWithCode(
        code: otp,
        email: email,
      );

      result.fold(
        onSuccess: (user) {
          // User authenticated successfully
          debugPrint('User authenticated successfully: ${user.id}');
          if (context.mounted) {
            context.go(portal);
          }
        },
        onFailure: (error) {
          // Handle authentication error
          debugPrint('Authentication error: ${error.message}');
        },
      );
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      await privy.logout();
      return true;
    } catch (e) {
      debugPrint('Error logging out: $e');
      return false;
    }
  }
}
