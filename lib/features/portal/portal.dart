import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:uni_links3/uni_links.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/utils.dart';

class Portal extends HookWidget {
  Portal({super.key});

  static final Cluster cluster =
      Cluster.devnet; // Ensure using the correct cluster
  final adapter = SolanaWalletAdapter(
    AppIdentity(
      uri: Uri.parse(
          'https://c010-2601-98a-c81-c140-f881-be76-3d5c-1b25.ngrok-free.app/.well-known/appple-app-site-association'), // Custom deep link URI scheme
      icon: Uri.parse('favicon.png'),
      name: 'Example',
    ),
    cluster: cluster,
    hostAuthority: null,
  );

  // Function to handle deep links and process the result
  Future<void> _listenForDeepLinks(void Function() onDeepLinkReceived) async {
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      print('Initial deep link received: $initialLink');
      if (initialLink.contains(
          "https://c010-2601-98a-c81-c140-f881-be76-3d5c-1b25.ngrok-free.app/.well-known/appple-app-site-association")) {
        onDeepLinkReceived();
      }
    }

    // Listen for subsequent deep link events
    linkStream.listen((String? link) {
      if (link != null &&
          link.contains(
              "https://c010-2601-98a-c81-c140-f881-be76-3d5c-1b25.ngrok-free.app/.well-known/appple-app-site-association")) {
        print('Deep link received: $link');
        onDeepLinkReceived();
      }
    }, onError: (err) {
      print('Error receiving deep link: $err');
    });
  }

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
        print('Connected wallet: $result');
        output.value = result.toJson();
        return result;
      } catch (e) {
        print('Error connecting wallet: $e');
        return null;
      }
    }

    // Function to disconnect the wallet
    Future<void> disconnect() async {
      await adapter.deauthorize();
      print('Wallet disconnected');
    }

    useEffect(() {
      SolanaWalletAdapter.initialize();
      print('Adapter initialized');

      // Ensure the app is checking for authorization when it first loads or after deep link
      if (adapter.isAuthorized) {
        output.value = adapter.connectedAccount?.address;
        isAuthorized.value = true;
      }

      // Start listening for deep links
      _listenForDeepLinks(() {
        if (adapter.isAuthorized) {
          output.value = adapter.connectedAccount?.address;
          isAuthorized.value = true;
        }
      });

      return null;
    }, []); // Only run this once on widget build

    return Scaffold(
      backgroundColor: context.appColors.electricBlue,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                if (!adapter.isAuthorized) {
                  // Only try to connect if the wallet isn't already authorized
                  output.value = await connect();
                  print(output.value);
                  isAuthorized.value =
                      true; // Mark the wallet as authorized after successful connection
                }
              },
              child: Text(
                output.value != null
                    ? output.value.toString()
                    : '[ Connect Wallet ]',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            if (isAuthorized.value) // Only show disconnect button if authorized
              GestureDetector(
                onTap: () async {
                  await disconnect();
                  output.value = null; // Clear the output when disconnected
                  isAuthorized.value = false; // Reset the authorization state
                },
                child: Text(
                  '[ Disconnect Wallet ]',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
