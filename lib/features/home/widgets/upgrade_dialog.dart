import 'package:flutter/material.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';

class UpgradeDialog extends StatefulWidget {
  final EmbeddedSolanaWallet wallet;
  final String mint;
  final Future<bool> Function() onSuccess;

  const UpgradeDialog({
    super.key,
    required this.wallet,
    required this.mint,
    required this.onSuccess,
  });

  @override
  State<UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<UpgradeDialog> {
  bool loading = false;
  bool failed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: loading
          ? IntrinsicHeight(
              child: Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent)))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Upgrade to Adventurer",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("Cost: 2500 \$WAGUS",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                if (failed)
                  Text("❌ Transaction failed. Please try again.",
                      style: TextStyle(color: Colors.redAccent)),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() {
                            loading = true;
                            failed = false;
                          });

                          try {
                            final success = await widget.onSuccess();
                            if (!success) {
                              setState(() {
                                failed = true;
                                loading = false;
                              });
                            }
                          } catch (_) {
                            setState(() {
                              failed = true;
                              loading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text("Confirm Upgrade"),
                ),
              ],
            ),
    );
  }
}
