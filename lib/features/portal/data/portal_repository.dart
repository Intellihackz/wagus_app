import 'dart:async';
import 'dart:io' show Platform;

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

  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  Future<void> init() async {
    await SolanaWalletAdapter.initialize();
  }

  /// [connect] function to connect the wallet
  Future<AuthorizeResult?> connect() async {
    try {
      final result = await adapter.authorize(
        walletUriBase: adapter.store.apps[0].walletUriBase,
      );

      if (result != null) {
        
        _isAuthorized = !Platform.isIOS;
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  Future<bool> requestAuthorization() async {
    if (_isAuthorized) return true; // Already authorized

    try {
      if (Platform.isIOS) {
        if (adapter.store.apps.isEmpty ||
            adapter.store.apps[0].walletUriBase == null) {
          return false;
        }

        final result = await adapter.reauthorize(
          walletUriBase: adapter.store.apps[0].walletUriBase,
        );

        if (result != null) {
          _isAuthorized = true;
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// [disconnect] function to disconnect the wallet
  Future<DeauthorizeResult?> disconnect() async {
    final result = await adapter.deauthorize();

    // Reset authorization state on disconnect
    if (result != null) {
      _isAuthorized = false;
    }

    return result;
  }
}
