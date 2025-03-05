import 'dart:async';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:flutter/material.dart';

class PortalRepository {
  PortalRepository();
  final _privyService = PrivyService();

  Future<PrivyUser?> init() async {
    final user = await PrivyService().initialize();

    return user;
  }

  Future<PrivyUser?> connect() async {
    try {
      final user = _privyService.privy.user;
      if (user != null) {
        var solanaWallet = user.embeddedSolanaWallets;
        if (solanaWallet.isNotEmpty) {
          debugPrint('Solana wallet already exists');
          return user;
        }

        final Completer<PrivyUser?> completer = Completer<PrivyUser?>();

        final walletResult = await user.createSolanaWallet();
        walletResult.fold(
          onSuccess: (wallet) {
            debugPrint('Solana wallet created successfully');
            completer.complete(user);
          },
          onFailure: (error) {
            debugPrint('Error creating Solana wallet: ${error.message}');
            completer.complete(null);
          },
        );

        return completer.future;
      }
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
    }
    return null;
  }

  /// [disconnect] function to disconnect the wallet
  Future<bool?> disconnect() async {
    final success = await _privyService.logout();
    return success ? true : null;
  }
}
