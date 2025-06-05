import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/core/theme/app_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await PrivyService().initialize(); // restores session
    if (!mounted) return;

    if (user != null && user.embeddedSolanaWallets.isNotEmpty) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.contrastLight,
      body: Center(
        child: Image.asset(
          'assets/icons/logo.png',
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
