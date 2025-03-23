import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/bank/bloc/bank_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/wagus.dart';

class Bank extends HookWidget {
  const Bank({super.key});

  @override
  Widget build(BuildContext context) {
    final amountController = useTextEditingController();
    final destinationController = useTextEditingController();

    return BlocConsumer<BankBloc, BankState>(
      listener: (context, state) {
        if (state.status == BankStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error fetching data'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        print('Bank State: ${state.status}');

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
                      SizedBox(
                        height: 50,
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
                            '${context.read<PortalBloc>().state.holder?.tokenAmount.toStringAsFixed(2) ?? '0.00'} \$WAGUS',
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
                            Builder(builder: (context) {
                              return ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        scrollable: true,
                                        title: const Text(
                                          'Withdraw funds to destination address',
                                          style: TextStyle(
                                            color: AppPalette.contrastDark,
                                            fontSize: 12,
                                          ),
                                        ),
                                        content: Center(
                                          child: Column(
                                            children: [
                                              TextField(
                                                controller: amountController,
                                                style: TextStyle(
                                                  color: context
                                                      .appColors.contrastDark,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText:
                                                      'Enter amount to withdraw',
                                                  hintStyle: TextStyle(
                                                    color:
                                                        AppPalette.contrastDark,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                  decimal: true,
                                                ),
                                              ),
                                              TextField(
                                                controller:
                                                    destinationController,
                                                style: TextStyle(
                                                  color: context
                                                      .appColors.contrastDark,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText:
                                                      'Enter destination address',
                                                  hintStyle: TextStyle(
                                                    color:
                                                        AppPalette.contrastDark,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              context.pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final amount = int.tryParse(
                                                (amountController.text.isEmpty
                                                    ? '0'
                                                    : amountController.text),
                                              );

                                              if (amount == null ||
                                                  amount <= 0 ||
                                                  destinationController
                                                      .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Please enter a valid amount and destination address'),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                                context.pop();
                                                return;
                                              }

                                              context
                                                  .read<BankBloc>()
                                                  .add(BankWithdrawEvent(
                                                    senderWallet: context
                                                        .read<PortalBloc>()
                                                        .state
                                                        .user!
                                                        .embeddedSolanaWallets
                                                        .first,
                                                    amount: amount,
                                                    destinationAddress:
                                                        destinationController
                                                            .text,
                                                  ));

                                              context.pop();
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
                              );
                            }),
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
