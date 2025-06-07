import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:wagus/core/theme/app_palette.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/domain/chat_command_parser.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/home/widgets/upgrade_dialog.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.selectedRoom,
    required this.portalState,
    required this.homeState,
  });

  final TextEditingController controller;
  final String selectedRoom;
  final PortalState portalState;
  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    final isTierLounge = selectedRoom == 'Tier Lounge';
    final isAllowed = portalState.tierStatus == TierStatus.adventurer ||
        portalState.tierStatus == TierStatus.creator;
    final inputDisabled = isTierLounge && !isAllowed;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (homeState.replyingTo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${homeState.replyingTo!.username?.trim().isNotEmpty == true ? homeState.replyingTo!.username : homeState.replyingTo!.sender.substring(0, 4)}: ${homeState.replyingTo!.text}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.white38),
                      onPressed: () {
                        context
                            .read<HomeBloc>()
                            .add(HomeSetReplyMessageEvent(null));
                      },
                    )
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                    enabled: !inputDisabled,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    controller: controller,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    cursorColor: context.appColors.contrastLight,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      hintText: 'Type your message... /send /upgrade',
                      hintStyle:
                          const TextStyle(fontSize: 12, color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: context.appColors.contrastLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: context.appColors.contrastLight),
                      ),
                    ),
                    onChanged: (text) {
                      final trimmed = text.trim();

                      // 🔒 If it's empty or doesn't start with '/', close popup
                      if (trimmed.isEmpty || !trimmed.startsWith('/')) {
                        context.read<HomeBloc>().add(HomeCommandPopupClosed());
                        return;
                      }

                      // ✅ If the user just typed a full command (e.g. "/send ") and added a space or arg, hide the popup
                      if (text.endsWith(' ') && allCommands.contains(trimmed)) {
                        context.read<HomeBloc>().add(HomeCommandPopupClosed());
                        return;
                      }

                      // 🔍 Otherwise, still actively searching
                      context
                          .read<HomeBloc>()
                          .add(HomeCommandPopupTriggered(trimmed));
                    }),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: IconButton(
                  icon: Icon(Icons.gif, color: Colors.white),
                  onPressed: () async {
                    final gif = await GiphyPicker.pickGif(
                      context: context,
                      apiKey: dotenv.env['GIPHY_API_KEY']!,
                      fullScreenDialog: false,
                      title: Text('Select a GIF'),
                      previewType: GiphyPreviewType.previewGif,
                      showPreviewPage: false,
                    );

                    await precacheImage(
                      NetworkImage(gif?.images.original?.url ?? ''),
                      context,
                    );
                    if (gif != null) {
                      final wallet = context
                          .read<PortalBloc>()
                          .state
                          .user
                          ?.embeddedSolanaWallets
                          .first;
                      if (wallet == null) return;

                      final gifUrl = gif.images.original?.url;

                      if (gifUrl == null || gifUrl.isEmpty) {
                        return;
                      }

                      final caption = controller.text.trim();

                      final usernameDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(wallet.address)
                          .get();

                      final rawUsername = usernameDoc.data()?['username'];
                      final username = (rawUsername is String &&
                              rawUsername.trim().isNotEmpty)
                          ? rawUsername.trim()
                          : null;

                      final message = Message(
                        text: caption.isNotEmpty ? caption : '[GIF]',
                        sender: wallet.address,
                        tier: portalState.tierStatus,
                        room: selectedRoom,
                        gifUrl:
                            gifUrl, // <- add this field to your Message model
                        solBalance: context
                            .read<PortalBloc>()
                            .state
                            .holder
                            ?.solanaAmount,
                        wagBalance: context
                            .read<PortalBloc>()
                            .state
                            .holdersMap?[context
                                .read<PortalBloc>()
                                .state
                                .selectedToken
                                .ticker]
                            ?.tokenAmount
                            .toInt(),
                        replyToMessageId: homeState.replyingTo?.id,
                        replyToText: homeState.replyingTo != null
                            ? '${(homeState.replyingTo!.username?.trim().isNotEmpty ?? false) ? homeState.replyingTo!.username : homeState.replyingTo!.sender.substring(0, 4)}: ${homeState.replyingTo!.text}'
                            : null,

                        username: username, likedBy: [],
                      );

                      context.read<HomeBloc>().add(
                            HomeSendMessageEvent(
                              message: message,
                              currentTokenAddress: context
                                  .read<PortalBloc>()
                                  .state
                                  .selectedToken
                                  .address,
                              ticker: context
                                  .read<PortalBloc>()
                                  .state
                                  .selectedToken
                                  .ticker,
                              decimals: context
                                  .read<PortalBloc>()
                                  .state
                                  .selectedToken
                                  .decimals,
                            ),
                          );

                      context
                          .read<HomeBloc>()
                          .add(HomeSetReplyMessageEvent(null));

                      controller.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: TextButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    final tier = portalState.tierStatus;

                    final isTierLounge = selectedRoom == 'Tier Lounge';
                    final isAllowed = tier == TierStatus.adventurer ||
                        tier == TierStatus.creator;

                    if (isTierLounge && !isAllowed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Only Adventurer tier can chat in Tier Lounge')),
                      );
                      return;
                    }

                    if (text.isNotEmpty) {
                      final user = context.read<PortalBloc>().state.user;
                      final wallet = user?.embeddedSolanaWallets.first;

                      if (wallet == null) return;

                      final parsed = ChatCommandParser.parse(text);

                      // Handle /upgrade in UI (because it's a dialog flow)
                      if (parsed?.action == '/upgrade') {
                        if (tier == TierStatus.adventurer) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'You are already an Adventurer 🧙‍♂️')),
                          );
                          controller.clear();
                          FocusScope.of(context).unfocus();
                          return;
                        }

                        controller.clear();
                        FocusScope.of(context).unfocus();

                        final bankRepo = context.read<BankRepository>();
                        final double usdTarget = 9.99; // $9.99 USD
                        final double usdPerToken =
                            portalState.selectedToken.usdPerToken.toDouble();
                        final amount = (usdTarget / usdPerToken).ceil();

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => UpgradeDialog(
                            tokenAmount: amount,
                            tierStatus: tier,
                            wallet: wallet,
                            mint: context
                                .read<PortalBloc>()
                                .state
                                .selectedToken
                                .address,
                            onSuccess: () async {
                              try {
                                final treasuryWallet =
                                    dotenv.env['TREASURY_WALLET_ADDRESS'];
                                if (treasuryWallet == null) return false;

                                final currentTokenAddress = context
                                    .read<PortalBloc>()
                                    .state
                                    .selectedToken
                                    .address;
                                await bankRepo.withdrawFunds(
                                  wallet: wallet,
                                  amount: amount,
                                  destinationAddress: treasuryWallet,
                                  wagusMint: currentTokenAddress,
                                  decimals: context
                                      .read<PortalBloc>()
                                      .state
                                      .selectedToken
                                      .decimals,
                                );

                                final systemMsg = Message(
                                  text:
                                      '[UPGRADE] You’ve been upgraded to Adventurer 🧙‍♂️',
                                  sender: 'System',
                                  tier: TierStatus.system,
                                  room: 'General',
                                  likedBy: [],
                                );

                                context
                                    .read<HomeBloc>()
                                    .add(HomeSendMessageEvent(
                                      message: systemMsg,
                                      currentTokenAddress: currentTokenAddress,
                                      ticker: context
                                          .read<PortalBloc>()
                                          .state
                                          .selectedToken
                                          .ticker,
                                      decimals: context
                                          .read<PortalBloc>()
                                          .state
                                          .selectedToken
                                          .decimals,
                                    ));

                                context.read<PortalBloc>().add(
                                      PortalUpdateTierEvent(
                                          TierStatus.adventurer,
                                          wallet.address),
                                    );

                                await Dio().post(
                                  'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/upgrade',
                                  data: {
                                    'userWallet': wallet.address,
                                    'amount': amount,
                                  },
                                  options: Options(headers: {
                                    'Authorization':
                                        'Bearer ${dotenv.env['INTERNAL_API_KEY']}',
                                  }),
                                );

                                Navigator.of(context).pop();
                                return true;
                              } catch (_) {
                                return false;
                              }
                            },
                          ),
                        );

                        return;
                      }

                      if (text.trim().toLowerCase() == '/silence') {
                        final wallet =
                            portalState.user?.embeddedSolanaWallets.first;
                        if (wallet == null) return;

                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(wallet.address)
                            .get();
                        final badges =
                            (userDoc.data()?['badges'] ?? []) as List<dynamic>;
                        final hasSugawBadge =
                            badges.contains('oXlvZMsWS58OZkjOHjpE');

                        if (!hasSugawBadge) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Only SUGAW holders can use /silence'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          controller.clear();
                          FocusScope.of(context).unfocus();

                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('chat')
                            .add({
                          'message': '/silence',
                          'sender': wallet.address,
                          'tier': portalState.tierStatus.name,
                          'room': selectedRoom,
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        controller.clear();
                        FocusScope.of(context).unfocus();
                        return;
                      }

                      final usernameDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(wallet.address)
                          .get();

                      final rawUsername = usernameDoc.data()?['username'];
                      final username = (rawUsername is String &&
                              rawUsername.trim().isNotEmpty)
                          ? rawUsername.trim()
                          : null;

                      print('[debug] username passed into Message: $username');

                      // ✅ Always send message (regular or command)
                      context.read<HomeBloc>().add(
                            HomeSendMessageEvent(
                              message: Message(
                                text: text,
                                sender: wallet.address,
                                tier: tier,
                                room: selectedRoom,
                                username: username,
                                solBalance: context
                                    .read<PortalBloc>()
                                    .state
                                    .holder
                                    ?.solanaAmount,
                                wagBalance: context
                                    .read<PortalBloc>()
                                    .state
                                    .holdersMap?[context
                                        .read<PortalBloc>()
                                        .state
                                        .selectedToken
                                        .ticker]
                                    ?.tokenAmount
                                    .toInt(),
                                replyToMessageId: homeState.replyingTo?.id,
                                replyToText: homeState.replyingTo != null
                                    ? '${(homeState.replyingTo!.username?.trim().isNotEmpty ?? false) ? homeState.replyingTo!.username : homeState.replyingTo!.sender.substring(0, 4)}: ${homeState.replyingTo!.text}'
                                    : null,
                                likedBy: [],
                              ),
                              currentTokenAddress: context
                                  .read<PortalBloc>()
                                  .state
                                  .selectedToken
                                  .address,
                              ticker: context
                                  .read<PortalBloc>()
                                  .state
                                  .selectedToken
                                  .ticker,
                              decimals: context
                                  .read<PortalBloc>()
                                  .state
                                  .selectedToken
                                  .decimals,
                            ),
                          );

                      context.read<HomeBloc>().add(HomeCommandPopupClosed());
                      context
                          .read<HomeBloc>()
                          .add(HomeSetReplyMessageEvent(null));
                      controller.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: const Text(
                    'SEND',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
