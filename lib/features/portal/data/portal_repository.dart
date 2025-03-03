import 'dart:async';

import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:wagus/services/privy_service.dart';

class PortalRepository {
  PortalRepository();

  static final Cluster cluster = Cluster.devnet;
  final adapter = SolanaWalletAdapter(
    AppIdentity(
      uri: Uri.parse('com.silnt.wagus://wallet'),
      name: 'wallet',
    ),
    cluster: cluster,
    hostAuthority: null,
  );

  final _privyService = PrivyService();

  Future<void> init() async {
    await SolanaWalletAdapter.initialize();
  }

  /// [connect] function to connect the wallet
  Future<bool?> connect() async {
    // If already authenticated, return true
    if (_privyService.isAuthenticated()) {
      return true;
    }

    // Otherwise, return null to indicate we need to go to login
    return null;
  }

  /// [disconnect] function to disconnect the wallet
  Future<bool?> disconnect() async {
    final success = await _privyService.logout();
    return success ? true : null;
  }
}
