import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:solana_web3/solana_web3.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/chat/bloc/chat_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/shared/holder/holder.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/features/home/chat/domain/message.dart' as chat;

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();
    final carouselController = CarouselSliderController();

    Future<Holder> getTokenAccounts(String address) async {
      final cluster = web3.Cluster.mainnet;
      final connection = web3.Connection(cluster);
      final publicKey = Pubkey.fromBase58(address);

      final splTokenKey =
          Pubkey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

      try {
        final tokenAccounts = await connection.getTokenAccountsByOwner(
          publicKey,
          filter: web3.TokenAccountsFilter.programId(splTokenKey),
        );

        final tokenKey = Pubkey.fromString(tokenAccounts.first.pubkey);

        final tokenAccountBalance = await connection.getTokenAccountBalance(
          tokenKey,
        );

        final tokensInSol =
            tokenAccounts.first.account.lamports / web3.lamportsPerSol;

        return Holder(
          holderType: HolderType.shrimp,
          holdings: tokensInSol,
          tokenAmount: int.parse(tokenAccountBalance.uiAmountString),
        );
      } catch (e) {
        return Holder(
          holderType: HolderType.plankton,
          holdings: 0,
          tokenAmount: 0,
        );
      }
    }

    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return FutureBuilder<Holder>(
                future: getTokenAccounts(
                    portalState.user!.embeddedSolanaWallets.first.address),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return Scaffold(
                    body: Stack(
                      children: [
                        GestureDetector(
                          child: Container(
                            alignment: Alignment.topCenter,
                            margin: EdgeInsets.only(top: 32),
                            width: double.infinity,
                            child: Column(
                              children: [
                                CarouselSlider(
                                  carouselController: carouselController,
                                  options: CarouselOptions(
                                    autoPlay: true,
                                    enableInfiniteScroll: true,
                                    autoPlayInterval:
                                        Duration(milliseconds: 100),
                                    autoPlayAnimationDuration:
                                        Duration(milliseconds: 1000),
                                    viewportFraction: 1,
                                  ),
                                  items: state.groupedTransactions
                                      .map((transactions) => Row(
                                              children: transactions
                                                  .map((transaction) {
                                            return Expanded(
                                                child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                    transaction.holder
                                                        .holderType.asset,
                                                    height: 50,
                                                    fit: BoxFit.cover),
                                                Text(
                                                  '\$ ${transaction.amount.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: AppPalette
                                                        .contrastLight,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ));
                                          }).toList()))
                                      .toList(),
                                ),
                                Text(
                                  'You have ${snapshot.data!.tokenAmount} tokens',
                                  style: TextStyle(
                                    color: AppPalette.contrastLight,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                    'That is worth ${snapshot.data!.holdings.toStringAsFixed(3)} SOL',
                                    style: TextStyle(
                                      color: AppPalette.contrastLight,
                                      fontSize: 12,
                                    )),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Image.asset(
                            'assets/background/home_logo.png',
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: EdgeInsets.only(
                                left: 16, right: 16, bottom: 16),
                            height: MediaQuery.sizeOf(context).height * .3,
                            width: double.infinity,
                            child: Column(
                              children: [
                                Expanded(
                                  child: BlocSelector<ChatBloc, ChatState,
                                      List<chat.Message>>(
                                    selector: (state) {
                                      return state.messages;
                                    },
                                    builder: (context, messages) {
                                      return ListView.builder(
                                        reverse: true,
                                        itemCount: messages.length,
                                        itemBuilder: (context, index) {
                                          return Row(
                                            mainAxisAlignment: messages[index]
                                                        .sender ==
                                                    portalState
                                                        .user!
                                                        .embeddedSolanaWallets
                                                        .first
                                                        .address
                                                ? MainAxisAlignment.end
                                                : MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '[${messages[index].sender.substring(0, 3)}..${messages[index].sender.substring(messages[index].sender.length - 3)}]',
                                                style: TextStyle(
                                                  color:
                                                      AppPalette.contrastLight,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                messages[index].message,
                                                style: TextStyle(
                                                  color:
                                                      AppPalette.contrastLight,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                TextField(
                                  controller: inputController,
                                  onTapOutside: (_) =>
                                      FocusScope.of(context).unfocus(),
                                  style: TextStyle(
                                    color: AppPalette.contrastLight,
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: 'Type here',
                                    hintStyle: TextStyle(
                                      color: AppPalette.contrastLight,
                                      fontSize: 12,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        context.read<ChatBloc>().add(
                                              ChatSendMessageEvent(
                                                message: chat.Message(
                                                  message: inputController.text,
                                                  sender: portalState
                                                      .user!
                                                      .embeddedSolanaWallets
                                                      .first
                                                      .address,
                                                ),
                                              ),
                                            );

                                        inputController.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                      child: Icon(
                                        Icons.send,
                                        color: AppPalette.contrastLight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
        );
      },
    );
  }
}
