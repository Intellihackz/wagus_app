import 'dart:async';

import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';

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

  Future<void> init() async {
    await SolanaWalletAdapter.initialize();
  }

  /// [connect] function to connect the wallet
  Future<AuthorizeResult?> connect() async {
    try {
      final result = await adapter.authorize(
        walletUriBase: adapter.store.apps[0].walletUriBase,
      );

      return result;
    } catch (e) {
      return null;
    }
  }

  /// [disconnect] function to disconnect the wallet
  Future<DeauthorizeResult?> disconnect() async {
    final result = await adapter.deauthorize();

    return result;
  }
}
