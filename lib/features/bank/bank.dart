import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/wagus.dart';

class Bank extends StatelessWidget {
  const Bank({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return Scaffold(
          body: CustomPaint(
            painter: CryptoBackgroundPainter(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      padding: const EdgeInsets.only(left: 16.0, top: 32.0),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppPalette.contrastLight,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 24.0,
                    children: [
                      Text(
                        'Deposit SOL or \$WAGUS Tokens to this address:',
                        textAlign: TextAlign.center,
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                            text: context
                                .read<PortalBloc>()
                                .state
                                .user!
                                .embeddedSolanaWallets
                                .first
                                .address,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          context
                              .read<PortalBloc>()
                              .state
                              .user!
                              .embeddedSolanaWallets
                              .first
                              .address,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Column(
                        spacing: 12.0,
                        children: [
                          Text(
                            'Bank Balance',
                            style: TextStyle(
                              color: AppPalette.contrastLight,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '0.00 SOL',
                            style: TextStyle(
                              color: AppPalette.contrastLight,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${portalState.holder?.tokenAmount.toStringAsFixed(2) ?? '0.00'} \$WAGUS',
                            style: TextStyle(
                              color: AppPalette.contrastLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 32.0, right: 32.0, bottom: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Withdraw funds to destination address',
                                        style: TextStyle(
                                          color: AppPalette.contrastDark,
                                          fontSize: 12,
                                        ),
                                      ),
                                      content: TextField(
                                        decoration: const InputDecoration(
                                          hintText: 'Enter destination address',
                                          hintStyle: TextStyle(
                                            color: AppPalette.contrastDark,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Withdraw'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    context.appColors.contrastLight),
                                shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                      horizontal: 32.0, vertical: 12.0),
                                ),
                              ),
                              child: Text(
                                'Withdraw Funds',
                                style: TextStyle(
                                  color: context.appColors.contrastDark,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
