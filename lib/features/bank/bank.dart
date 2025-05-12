import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/bank/bloc/bank_bloc.dart';

import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/shared/holder/holder.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/utils.dart';
import 'package:wagus/wagus.dart';

class Bank extends HookWidget {
  const Bank({super.key, required this.previousLocation});

  final String? previousLocation;

  @override
  Widget build(BuildContext context) {
    final rotationController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );
    final rotationAnimation =
        Tween<double>(begin: 0, end: 1).animate(rotationController);

    final amountController = useTextEditingController();
    final destinationController = useTextEditingController();

    return PopScope(
      onPopInvokedWithResult: (hasPopped, result) async {
        if (previousLocation != null) {
          locationControler.add(previousLocation);
        } else {
          locationControler.add(home);
        }
      },
      child: BlocListener<PortalBloc, PortalState>(
        listenWhen: (previous, current) =>
            previous.holder != null && current.holder == null,
        listener: (context, portalState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to refresh wallet. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: BlocConsumer<BankBloc, BankState>(
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
              resizeToAvoidBottomInset: false,
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                text: context
                                        .read<PortalBloc>()
                                        .state
                                        .user
                                        ?.embeddedSolanaWallets
                                        .first
                                        .address ??
                                    '',
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[900],
                                border: Border.all(color: Colors.greenAccent),
                              ),
                              child: Text(
                                context
                                        .read<PortalBloc>()
                                        .state
                                        .user
                                        ?.embeddedSolanaWallets
                                        .first
                                        .address ??
                                    '',
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Colors.greenAccent),
                              ),
                            ),
                          ),
                          BlocSelector<PortalBloc, PortalState, Holder?>(
                            selector: (state) => state.holder,
                            builder: (context, portalState) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 32),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                          Colors.greenAccent.withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Bank Balance',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        RotationTransition(
                                          turns: rotationAnimation,
                                          child: GestureDetector(
                                            onTap: () {
                                              rotationController.forward(
                                                  from: 0);
                                              context
                                                  .read<PortalBloc>()
                                                  .add(PortalRefreshEvent());
                                            },
                                            child: const Icon(Icons.refresh,
                                                color: Colors.greenAccent),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${portalState?.solanaAmount.toStringAsFixed(5) ?? '0.00000'} SOL',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(portalState?.tokenAmount ?? 0).toCompact()} \$WAGUS',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
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
                                          child:
                                              BlocConsumer<BankBloc, BankState>(
                                            listener: (context, state) {
                                              if (state.dialogStatus ==
                                                  DialogStatus.success) {
                                                Future.delayed(
                                                    const Duration(
                                                        milliseconds: 1500),
                                                    () {
                                                  if (context.mounted) {
                                                    context.pop();
                                                    context.read<BankBloc>().add(
                                                        BankResetDialogEvent());
                                                    context
                                                        .read<PortalBloc>()
                                                        .add(
                                                          PortalRefreshEvent(),
                                                        );

                                                    amountController.clear();
                                                    destinationController
                                                        .clear();
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
                                                    color:
                                                        AppPalette.contrastDark,
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
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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
                                          child:
                                              BlocConsumer<BankBloc, BankState>(
                                            listener: (context, state) {
                                              if (state.dialogStatus ==
                                                  DialogStatus.success) {
                                                Future.delayed(
                                                    const Duration(
                                                        milliseconds: 1500),
                                                    () {
                                                  if (context.mounted) {
                                                    context.pop();
                                                    context.read<BankBloc>().add(
                                                        BankResetDialogEvent());
                                                    context
                                                        .read<PortalBloc>()
                                                        .add(
                                                          PortalRefreshEvent(),
                                                        );

                                                    amountController.clear();
                                                    destinationController
                                                        .clear();
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
                                                    color:
                                                        AppPalette.contrastDark,
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
        ),
      ),
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
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
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
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => amountController.text = isTokenWithdrawal
                        ? context
                                .read<PortalBloc>()
                                .state
                                .holder
                                ?.tokenAmount
                                .toInt()
                                .toString() ??
                            ''
                        : context
                                .read<PortalBloc>()
                                .state
                                .holder
                                ?.solanaAmount
                                .toString() ??
                            '',
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: context.appColors.contrastLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Max',
                        style: TextStyle(
                          color: context.appColors.contrastDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
            final senderWallet = context
                .read<PortalBloc>()
                .state
                .user
                ?.embeddedSolanaWallets
                .first;

            if (senderWallet == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No sender wallet found'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            context.read<BankBloc>().add(BankWithdrawEvent(
                  senderWallet: senderWallet,
                  amount: amount.toInt(),
                  destinationAddress: destinationController.text,
                  wagusMint:
                      context.read<PortalBloc>().state.currentTokenAddress,
                ));
          } else {
            final senderWallet = context
                .read<PortalBloc>()
                .state
                .user
                ?.embeddedSolanaWallets
                .first;

            if (senderWallet == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No sender wallet found'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            context.read<BankBloc>().add(BankWithdrawSolEvent(
                  senderWallet: senderWallet,
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
