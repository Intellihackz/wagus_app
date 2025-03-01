import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:wagus/theme/app_palette.dart';

class Portal extends HookWidget {
  Portal({super.key});

  static final Cluster cluster =
      Cluster.devnet; // Ensure using the correct cluster
  final adapter = SolanaWalletAdapter(
    AppIdentity(
      uri: Uri.parse('com.silnt.wagus://wallet'),
      name: 'wallet',
    ),
    cluster: cluster,
    hostAuthority: null,
  );

  @override
  Widget build(BuildContext context) {
    final output = useState<Object?>(null); // State for wallet address
    final isAuthorized =
        useState(false); // State for wallet authorization status

    Future<Object?> connect() async {
      try {
        final result = await adapter.authorize(
          walletUriBase: adapter.store.apps[0].walletUriBase,
        );
        return result;
      } catch (e) {
        return null;
      }
    }

    // Function to disconnect the wallet
    Future<void> disconnect() async {
      await adapter.deauthorize();
    }

    useEffect(() {
      SolanaWalletAdapter.initialize();

      if (adapter.isAuthorized) {
        output.value = adapter.connectedAccount?.address;
        isAuthorized.value = true;
      }

      return null;
    }, []);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await disconnect();
        },
        child: const Icon(Icons.home),
      ),
      backgroundColor: context.appColors.deepMidnightBlue,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                if (!adapter.isAuthorized) {
                  output.value = await connect();
                }
              },
              child: Text(
                '[ Connect Wallet ]',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
