import 'dart:async';
import 'package:wagus/services/privy_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/router.dart';

class PortalRepository {
  PortalRepository();
  final _privyService = PrivyService();

  Future<void> init() async {}

  Future<void> connect(BuildContext context) async {
    try {
      final user = _privyService.privy.user;
      if (user != null) {
        final walletResult = await user.createSolanaWallet();

        return walletResult.fold(
          onSuccess: (wallet) {
            print(wallet);
            debugPrint('Solana wallet created successfully');
            if (context.mounted) {
              context.go(home);
            }
          },
          onFailure: (error) {
            debugPrint('Error creating Solana wallet: ${error.message}');
          },
        );
      }
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
    }
  }

  /// [disconnect] function to disconnect the wallet
  Future<bool?> disconnect() async {
    final success = await _privyService.logout();
    return success ? true : null;
  }
}
