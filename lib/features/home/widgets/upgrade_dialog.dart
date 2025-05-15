import 'package:flutter/material.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class UpgradeDialog extends StatefulWidget {
  final EmbeddedSolanaWallet wallet;
  final String mint;
  final Future<bool> Function() onSuccess;
  final TierStatus tierStatus;
  final int tokenAmount;

  const UpgradeDialog({
    super.key,
    required this.wallet,
    required this.mint,
    required this.onSuccess,
    required this.tierStatus,
    required this.tokenAmount,
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
                  child: CircularProgressIndicator(
                    color: widget.tierStatus == TierStatus.adventurer
                        ? TierStatus.adventurer.color
                        : TierStatus.basic.color,
                  ),
                ),
              )
            : Builder(builder: (context) {
                final tokenText = widget.tokenAmount > 0
                    ? '~${widget.tokenAmount} tokens (≈ \$3.50)'
                    : '...';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Upgrade to Adventurer",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Cost: $tokenText',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    if (failed)
                      const Text("❌ Transaction failed. Please try again.",
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
                        backgroundColor:
                            widget.tierStatus == TierStatus.adventurer
                                ? TierStatus.adventurer.color
                                : TierStatus.basic.color,
                        foregroundColor: Colors.black,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text("Confirm Upgrade"),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel",
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                );
              }));
  }
}
