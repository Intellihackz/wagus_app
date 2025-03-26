import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/bank/bloc/bank_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/shared/holder/holder.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/wagus.dart';

class Bank extends HookWidget {
  const Bank({super.key});

  @override
  Widget build(BuildContext context) {
    final amountController = useTextEditingController();
    final destinationController = useTextEditingController();

    return BlocConsumer<BankBloc, BankState>(
      listener: (context, state) async {
        if (state.status == BankStatus.failure &&
            state.dialogStatus == DialogStatus.input) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Withdrawal failed. Please try again.'),
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
                      const SizedBox(height: 50),
                      BlocSelector<PortalBloc, PortalState, Holder>(
                        selector: (state) {
                          return state.holder!;
                        },
                        builder: (context, portalState) {
                          return Column(
                            spacing: 12.0,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Bank Balance',
                                    style: TextStyle(
                                      color: AppPalette.contrastLight,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.refresh,
                                      color: context.appColors.contrastLight,
                                    ),
                                    onPressed: () {
                                      context
                                          .read<PortalBloc>()
                                          .add(PortalRefreshEvent());
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                '${portalState.solanaAmount.toStringAsFixed(5)} SOL',
                                style: TextStyle(
                                  color: AppPalette.contrastLight,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${portalState.tokenAmount.toStringAsFixed(0)} \$WAGUS Tokens',
                                style: TextStyle(
                                  color: AppPalette.contrastLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
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
                                  barrierDismissible: false,
                                  builder: (dialogContext) {
                                    return BlocProvider.value(
                                      value: context.read<BankBloc>(),
                                      child: BlocConsumer<BankBloc, BankState>(
                                        listener: (context, state) {
                                          if (state.dialogStatus ==
                                              DialogStatus.success) {
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 1500), () {
                                              if (context.mounted) {
                                                context.pop();
                                                context.read<BankBloc>().add(
                                                    BankResetDialogEvent());
                                                context.read<PortalBloc>().add(
                                                      PortalRefreshEvent(),
                                                    );
                                              }
                                            });
                                          }
                                        },
                                        builder: (context, state) {
                                          return AlertDialog(
                                            scrollable: true,
                                            title: const Text(
                                              'Withdraw \$WAGUS Tokens',
                                              style: TextStyle(
                                                color: AppPalette.contrastDark,
                                                fontSize: 12,
                                              ),
                                            ),
                                            content: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.8,
                                              child: _buildDialogContent(
                                                context,
                                                state,
                                                amountController,
                                                destinationController,
                                                isTokenWithdrawal: true,
                                              ),
                                            ),
                                            actions: _buildDialogActions(
                                              context,
                                              state,
                                              amountController,
                                              destinationController,
                                              isTokenWithdrawal: true,
                                            ),
                                          );
                                        },
                                      ),
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
                                'Withdraw \$WAGUS Tokens',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appColors.contrastDark,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(
                                height: 16), // Add spacing between buttons
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) {
                                    return BlocProvider.value(
                                      value: context.read<BankBloc>(),
                                      child: BlocConsumer<BankBloc, BankState>(
                                        listener: (context, state) {
                                          if (state.dialogStatus ==
                                              DialogStatus.success) {
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 1500), () {
                                              if (context.mounted) {
                                                context.pop();
                                                context.read<BankBloc>().add(
                                                    BankResetDialogEvent());
                                                context.read<PortalBloc>().add(
                                                      PortalRefreshEvent(),
                                                    );
                                              }
                                            });
                                          }
                                        },
                                        builder: (context, state) {
                                          return AlertDialog(
                                            scrollable: true,
                                            title: const Text(
                                              'Withdraw SOL',
                                              style: TextStyle(
                                                color: AppPalette.contrastDark,
                                                fontSize: 12,
                                              ),
                                            ),
                                            content: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.8,
                                              child: _buildDialogContent(
                                                context,
                                                state,
                                                amountController,
                                                destinationController,
                                                isTokenWithdrawal: false,
                                              ),
                                            ),
                                            actions: _buildDialogActions(
                                              context,
                                              state,
                                              amountController,
                                              destinationController,
                                              isTokenWithdrawal: false,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text(
                                'Withdraw SOL',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appColors.contrastLight,
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

  Widget _buildDialogContent(
    BuildContext context,
    BankState state,
    TextEditingController amountController,
    TextEditingController destinationController, {
    required bool isTokenWithdrawal,
  }) {
    switch (state.dialogStatus) {
      case DialogStatus.input:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              style: TextStyle(color: context.appColors.contrastDark),
              decoration: InputDecoration(
                hintText: isTokenWithdrawal
                    ? 'Enter amount to withdraw'
                    : 'Enter SOL amount to withdraw',
                hintStyle: const TextStyle(
                    color: AppPalette.contrastDark, fontSize: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: destinationController,
              style: TextStyle(color: context.appColors.contrastDark),
              decoration: const InputDecoration(
                hintText: 'Enter destination address',
                hintStyle:
                    TextStyle(color: AppPalette.contrastDark, fontSize: 12),
              ),
            ),
          ],
        );
      case DialogStatus.loading:
        return const SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppPalette.contrastDark),
            ),
          ),
        );
      case DialogStatus.success:
        return const SizedBox(
          height: 80,
          child: Center(
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
          ),
        );
    }
  }

  List<Widget> _buildDialogActions(
    BuildContext context,
    BankState state,
    TextEditingController amountController,
    TextEditingController destinationController, {
    required bool isTokenWithdrawal,
  }) {
    if (state.dialogStatus != DialogStatus.input) {
      return []; // No actions during loading or success
    }

    return [
      TextButton(
        onPressed: () {
          amountController.clear();
          destinationController.clear();
          context.pop();
        },
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          final amountText =
              amountController.text.isEmpty ? '0' : amountController.text;
          final amount = isTokenWithdrawal
              ? int.tryParse(amountText)
              : double.tryParse(amountText);

          if (amount == null ||
              amount <= 0 ||
              destinationController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Please enter a valid amount and destination address'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          if (isTokenWithdrawal) {
            context.read<BankBloc>().add(BankWithdrawEvent(
                  senderWallet: context
                      .read<PortalBloc>()
                      .state
                      .user!
                      .embeddedSolanaWallets
                      .first,
                  amount: amount.toInt(),
                  destinationAddress: destinationController.text,
                ));
          } else {
            context.read<BankBloc>().add(BankWithdrawSolEvent(
                  senderWallet: context
                      .read<PortalBloc>()
                      .state
                      .user!
                      .embeddedSolanaWallets
                      .first,
                  amount: amount.toDouble(),
                  destinationAddress: destinationController.text,
                ));
          }
        },
        child: const Text('Withdraw'),
      ),
    ];
  }
}
