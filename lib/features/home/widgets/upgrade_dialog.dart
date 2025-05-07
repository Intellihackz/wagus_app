import 'package:flutter/material.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:provider/provider.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/services/user_service.dart';

class UpgradeDialog extends StatefulWidget {
  final EmbeddedSolanaWallet wallet;
  final String mint;
  final VoidCallback onSuccess;

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
  bool loading = true;
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
                Text("Cost: 1000 \$WAGUS",
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
                            await context.read<BankRepository>().withdrawFunds(
                                  wallet: widget.wallet,
                                  amount: 1000,
                                  destinationAddress:
                                      'DZuJUNmVxNQwq55wrrrpFeE4PES1cyBv2bxuSqm7UXdj',
                                  wagusMint: widget.mint,
                                );

                            await UserService().upgradeTier(
                                widget.wallet.address, 'adventurer');

                            widget.onSuccess();
                            Navigator.of(context).pop();
                          } catch (e) {
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
