import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/bank/bloc/bank_bloc.dart';

import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/shared/token/token.dart';
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

    final isRefreshing =
        context.select((PortalBloc bloc) => bloc.state.isRefreshing);

    useEffect(() {
      if (isRefreshing) {
        rotationController.repeat();
      } else {
        rotationController.reset(); // ✅ this resets the rotation cleanly
      }
      return null;
    }, [isRefreshing]);

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
      child: BlocConsumer<PortalBloc, PortalState>(
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
        builder: (context, portalState) {
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
          }, builder: (context, state) {
            print('Bank State: ${state.status}');

            return Scaffold(
                resizeToAvoidBottomInset: false,
                body: BlocSelector<PortalBloc, PortalState, TierStatus>(
                    selector: (state) {
                  return state.tierStatus;
                }, builder: (context, tierStatus) {
                  final color = switch (tierStatus) {
                    TierStatus.adventurer => TierStatus.adventurer.color,
                    _ => TierStatus.basic.color,
                  };

                  return CustomPaint(
                    painter: CryptoBackgroundPainter(color: color),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              padding:
                                  const EdgeInsets.only(left: 16.0, top: 32.0),
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
                                'Deposit \$SOL or \$${context.read<PortalBloc>().state.selectedToken.ticker} Tokens to this address:',
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
                                      content:
                                          Text('Address copied to clipboard'),
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
                                    border: Border.all(
                                        color: portalState.tierStatus ==
                                                TierStatus.adventurer
                                            ? TierStatus.adventurer.color
                                            : TierStatus.basic.color),
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
                                    style: TextStyle(
                                      color: tierStatus == TierStatus.adventurer
                                          ? TierStatus.adventurer.color
                                          : TierStatus.basic.color,
                                    ),
                                  ),
                                ),
                              ),
                              BlocBuilder<PortalBloc, PortalState>(
                                builder: (context, portalState) {
                                  final selectedToken =
                                      portalState.selectedToken;
                                  final holder = portalState
                                      .holdersMap?[selectedToken.ticker];

                                  return Column(
                                    children: [
                                      TokenSwitcher(
                                          tier: portalState.tierStatus,
                                          selectedToken: selectedToken,
                                          allTokens:
                                              portalState.supportedTokens,
                                          onTokenSelected: (token) {
                                            context.read<PortalBloc>().add(
                                                  PortalSetSelectedTokenEvent(
                                                      token),
                                                );
                                            Future.delayed(
                                                Duration(milliseconds: 100),
                                                () {
                                              final updatedToken = context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .selectedToken;
                                              debugPrint(
                                                  '✅ NEW Mint address: ${updatedToken.address}');
                                              debugPrint(
                                                  '✅ NEW Ticker: ${updatedToken.ticker}');
                                            });
                                          }),
                                      buildBankBalance(
                                        isAdventurer: portalState.tierStatus ==
                                            TierStatus.adventurer,
                                        rotationController: rotationController,
                                        rotationAnimation: rotationAnimation,
                                        solBalance: holder?.solanaAmount ?? 0.0,
                                        tokenBalanceText:
                                            '${(holder?.tokenAmount ?? 0).toCompact()} \$${selectedToken.ticker}',
                                        onRefresh: () {
                                          context
                                              .read<PortalBloc>()
                                              .add(PortalRefreshEvent());
                                        },
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
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (dialogContext) {
                                            return BlocProvider.value(
                                              value: context.read<BankBloc>(),
                                              child: BlocConsumer<BankBloc,
                                                  BankState>(
                                                listener: (context, state) {
                                                  if (state.dialogStatus ==
                                                      DialogStatus.success) {
                                                    Future.delayed(
                                                        const Duration(
                                                            milliseconds: 1500),
                                                        () {
                                                      if (context.mounted) {
                                                        context.pop();
                                                        context
                                                            .read<BankBloc>()
                                                            .add(
                                                                BankResetDialogEvent());
                                                        context
                                                            .read<PortalBloc>()
                                                            .add(
                                                              PortalRefreshEvent(),
                                                            );

                                                        amountController
                                                            .clear();
                                                        destinationController
                                                            .clear();
                                                      }
                                                    });
                                                  }
                                                },
                                                builder: (context, state) {
                                                  return Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)),
                                                    backgroundColor:
                                                        Colors.grey[900],
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Withdraw \$${context.read<PortalBloc>().state.selectedToken.ticker} Tokens',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: context
                                                                  .appColors
                                                                  .contrastLight,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 20),
                                                          _buildDialogContent(
                                                            context,
                                                            state,
                                                            amountController,
                                                            destinationController,
                                                            isTokenWithdrawal:
                                                                true,
                                                          ),
                                                          const SizedBox(
                                                              height: 24),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children:
                                                                _buildDialogActions(
                                                              context,
                                                              state,
                                                              amountController,
                                                              destinationController,
                                                              isTokenWithdrawal:
                                                                  true,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_outward,
                                          size: 20, color: Colors.black),
                                      label: Text(
                                        'Withdraw \$${context.read<PortalBloc>().state.selectedToken.ticker} Tokens',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        backgroundColor:
                                            context.appColors.contrastLight,
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                        shadowColor: context
                                            .appColors.contrastLight
                                            .withOpacity(0.5),
                                      ).copyWith(
                                        overlayColor: WidgetStateProperty.all(
                                            Colors.black.withOpacity(0.1)),
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            16), // Add spacing between buttons
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (dialogContext) {
                                            return BlocProvider.value(
                                              value: context.read<BankBloc>(),
                                              child: BlocConsumer<BankBloc,
                                                  BankState>(
                                                listener: (context, state) {
                                                  if (state.dialogStatus ==
                                                      DialogStatus.success) {
                                                    Future.delayed(
                                                        const Duration(
                                                            milliseconds: 1500),
                                                        () {
                                                      if (context.mounted) {
                                                        context.pop();
                                                        context
                                                            .read<BankBloc>()
                                                            .add(
                                                                BankResetDialogEvent());
                                                        context
                                                            .read<PortalBloc>()
                                                            .add(
                                                              PortalRefreshEvent(),
                                                            );

                                                        amountController
                                                            .clear();
                                                        destinationController
                                                            .clear();
                                                      }
                                                    });
                                                  }
                                                },
                                                builder: (context, state) {
                                                  return Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)),
                                                    backgroundColor:
                                                        Colors.grey[900],
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Text(
                                                            'Withdraw SOL',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppPalette
                                                                  .contrastLight,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 20),
                                                          _buildDialogContent(
                                                            context,
                                                            state,
                                                            amountController,
                                                            destinationController,
                                                            isTokenWithdrawal:
                                                                false,
                                                          ),
                                                          const SizedBox(
                                                              height: 24),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children:
                                                                _buildDialogActions(
                                                              context,
                                                              state,
                                                              amountController,
                                                              destinationController,
                                                              isTokenWithdrawal:
                                                                  false,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
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
                                          color:
                                              context.appColors.contrastLight,
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
                  );
                }));
          });
        },
      ),
    );
  }

  Widget buildBankBalance({
    required bool isAdventurer,
    required AnimationController rotationController,
    required Animation<double> rotationAnimation,
    required double solBalance,
    required String tokenBalanceText,
    required VoidCallback onRefresh,
  }) {
    final borderColor =
        isAdventurer ? TierStatus.adventurer.color : TierStatus.basic.color;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                  child: const Text(
                    'Bank Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRefresh,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RotationTransition(
                      turns: rotationAnimation,
                      child: Icon(Icons.refresh, color: borderColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                '${solBalance.toStringAsFixed(5)} SOL',
                key: ValueKey(solBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                tokenBalanceText,
                key: ValueKey(tokenBalanceText),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
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
                    onTap: () {
                      final portalState = context.read<PortalBloc>().state;

                      final token = portalState.selectedToken;
                      final holdersMap = portalState.holdersMap;

                      final tokenHolder = holdersMap?[token.ticker];

                      amountController.text = isTokenWithdrawal
                          ? tokenHolder?.tokenAmount.toInt().toString() ?? ''
                          : tokenHolder?.solanaAmount.toString() ?? '';
                    },
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
                  token: context.read<PortalBloc>().state.selectedToken,
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

class TokenSwitcher extends HookWidget {
  final Token selectedToken;
  final List<Token> allTokens;
  final ValueChanged<Token> onTokenSelected;
  final TierStatus tier;

  const TokenSwitcher({
    super.key,
    required this.selectedToken,
    required this.allTokens,
    required this.onTokenSelected,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    useEffect(() {
      final selectedIndex =
          allTokens.indexWhere((t) => t.ticker == selectedToken.ticker);
      if (selectedIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final itemWidth = 80 + 12; // token card width + spacing
          final screenWidth = MediaQuery.of(context).size.width;
          final offset =
              (selectedIndex * itemWidth) - (screenWidth - itemWidth) / 2;
          scrollController.animateTo(
            offset.clamp(0, scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
      return null;
    }, [selectedToken]);

    return SizedBox(
      height: 100,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: allTokens.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final token = allTokens[index];
          final isSelected = token.ticker == selectedToken.ticker;
          final imagePath =
              'assets/cards/${token.ticker.toLowerCase()}_card.png';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: isSelected ? 1.08 : 1.0,
              child: GestureDetector(
                onTap: () => onTokenSelected(token),
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? tier == TierStatus.adventurer
                              ? TierStatus.adventurer.color
                              : TierStatus.basic.color
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tier == TierStatus.adventurer
                                  ? TierStatus.adventurer.color.withOpacity(0.5)
                                  : TierStatus.basic.color.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
