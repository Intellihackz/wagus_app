import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';

class PrivyService {
  static final PrivyService _instance = PrivyService._internal();
  factory PrivyService() => _instance;

  PrivyService._internal();

  Privy? _privyInternal;
  bool _isInitialized = false;

  Privy get privy {
    if (!_isInitialized || _privyInternal == null) {
      throw Exception('PrivyService not initialized. Call initialize() first.');
    }
    return _privyInternal!;
  }

  Future<PrivyUser?> initialize({TokenProvider? tokenProvider}) async {
    if (_isInitialized && _privyInternal != null) return _privyInternal!.user;

    final privyConfig = PrivyConfig(
      appId: dotenv.env['PRIVY_APP_ID'] ?? '',
      appClientId: dotenv.env['PRIVY_CLIENT_ID'] ?? '',
      logLevel: PrivyLogLevel.verbose,
      customAuthConfig: tokenProvider != null
          ? LoginWithCustomAuthConfig(tokenProvider: tokenProvider)
          : null,
    );

    _privyInternal = Privy.init(config: privyConfig);
    await _privyInternal!.awaitReady();
    _isInitialized = true;
    return _privyInternal!.user;
  }

  bool isAuthenticated() {
    if (!_isInitialized || _privyInternal == null) return false;
    return privy.currentAuthState.isAuthenticated;
  }

  void loginWithEmail(String email) async {
    await initialize();

    final Result<void> result = await privy.email.sendCode(email);
    result.fold(
      onSuccess: (_) => debugPrint('OTP sent successfully to $email'),
      onFailure: (error) => debugPrint('Error sending OTP: ${error.message}'),
    );
  }

  Future<void> verifyOtp(String email, String otp, BuildContext context) async {
    await initialize();

    final Result<PrivyUser> result = await privy.email.loginWithCode(
      code: otp,
      email: email,
    );

    result.fold(
      onSuccess: (user) {
        debugPrint('User authenticated successfully: ${user.id}');
        if (context.mounted) context.go(portal);
      },
      onFailure: (error) {
        debugPrint('Authentication error: ${error.message}');
      },
    );
  }

  Future<bool> logout(BuildContext context) async {
    try {
      // Don't call initialize again — it revives the session
      if (_isInitialized && _privyInternal != null) {
        await _privyInternal!.logout();
      }

      // Fully clear references
      _isInitialized = false;
      _privyInternal = null;

      // Also clear Bloc state
      if (context.mounted) {
        context.read<PortalBloc>().add(PortalClearEvent());
      }

      return true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }
}
