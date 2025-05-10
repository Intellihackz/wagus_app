import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/domain/chat_command_parser.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/home/widgets/upgrade_dialog.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/utils.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();
    final selectedRoom = useState('General');
    final chatRooms = ['General', 'Support', 'Games', 'Ideas', 'Tier Lounge'];

    useEffect(() {
      final portalState = context.read<PortalBloc>().state;

      if (portalState.user != null &&
          portalState.currentTokenAddress.isNotEmpty) {
        final homeBloc = context.read<HomeBloc>();
        final bankRepo = context.read<BankRepository>();

        getActiveWallet().then((wallet) {
          if (wallet != null) {
            homeBloc.watchGiveaways(
              wallet.address,
              wallet,
              portalState.currentTokenAddress,
              bankRepo,
            );
            homeBloc.add(HomeSetRoomEvent(selectedRoom.value));
          }
        });
      }

      return null;
    }, [context.read<PortalBloc>().state]);

    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Padding(
                padding: const EdgeInsets.only(top: 64.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Chat Room Tabs
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: chatRooms.map((room) {
                                final isSelected = selectedRoom.value == room;
                                return GestureDetector(
                                  onTap: () {
                                    selectedRoom.value = room;
                                    context
                                        .read<HomeBloc>()
                                        .add(HomeSetRoomEvent(room));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white),
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      room,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white12, thickness: 1),
                        // Messages Display
                        // Messages Display

                        Expanded(
                          child: Builder(builder: (context) {
                            final filteredMessages = homeState.messages
                                .where(
                                    (msg) => msg.room == homeState.currentRoom)
                                .toList();

                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: filteredMessages.length,
                              itemBuilder: (context, index) {
                                final message = filteredMessages[index];

                                String getTierPrefix(TierStatus tier) {
                                  if (tier == TierStatus.adventurer)
                                    return '[A]';
                                  if (tier == TierStatus.creator) return '[C]';

                                  if (tier == TierStatus.system) return '[S]';
                                  return '[B]';
                                }

                                String getDisplaySender(Message msg) {
                                  if (msg.tier == TierStatus.system)
                                    return '[System]';
                                  return '${getTierPrefix(msg.tier)}[${msg.sender.substring(0, 3)}..${msg.sender.substring(msg.sender.length - 3)}]';
                                }

                                Color getTierColor(TierStatus tier) {
                                  switch (tier) {
                                    case TierStatus.adventurer:
                                      return Colors.red;
                                    case TierStatus.creator:
                                      return Colors.purple;
                                    case TierStatus.system:
                                      return Colors.cyan;
                                    case TierStatus.elite:
                                      return Colors.green;
                                    case TierStatus.basic:
                                    case TierStatus.none:
                                      return Colors.yellow;
                                  }
                                }

                                return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: SelectableText.rich(
                                            TextSpan(
                                              style: TextStyle(
                                                fontSize: 12,
                                              ),
                                              children: [
                                                WidgetSpan(
                                                  alignment:
                                                      PlaceholderAlignment
                                                          .middle,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) =>
                                                            AlertDialog(
                                                          backgroundColor:
                                                              Colors.black,
                                                          title: Text(
                                                              'Wallet Address',
                                                              style: TextStyle(
                                                                  color: context
                                                                      .appColors
                                                                      .contrastLight)),
                                                          content:
                                                              SelectableText(
                                                            message.sender,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Clipboard.setData(
                                                                    ClipboardData(
                                                                        text: message
                                                                            .sender));
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content: Text(
                                                                          'Copied to clipboard')),
                                                                );
                                                              },
                                                              child: Text(
                                                                  'COPY',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .greenAccent)),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(),
                                                              child: Text(
                                                                  'CLOSE',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                      getDisplaySender(message),
                                                      style: TextStyle(
                                                        color: message.tier ==
                                                                TierStatus
                                                                    .system
                                                            ? Colors
                                                                .lightBlueAccent
                                                            : getTierColor(
                                                                message.tier),
                                                        fontSize: 14,
                                                        fontWeight: message
                                                                    .tier ==
                                                                TierStatus
                                                                    .system
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: message.text,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final docId = message
                                                .id; // Ensure Message class has `id`
                                            final docRef = FirebaseFirestore
                                                .instance
                                                .collection('chat')
                                                .doc(docId);
                                            await docRef.update({
                                              'likes': FieldValue.increment(1)
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.thumb_up,
                                                  size: 14,
                                                  color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('${message.likes}',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ));
                              },
                            );
                          }),
                        ),
                        const Divider(color: Colors.white12, thickness: 1),
                        // Input Bar
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Builder(builder: (context) {
                                  final isTierLounge =
                                      selectedRoom.value == 'Tier Lounge';
                                  final isAllowed = portalState.tierStatus ==
                                          TierStatus.adventurer ||
                                      portalState.tierStatus ==
                                          TierStatus.creator;
                                  final inputDisabled =
                                      isTierLounge && !isAllowed;

                                  return TextField(
                                    enabled: !inputDisabled,
                                    onTapOutside: (_) {
                                      FocusScope.of(context).unfocus();
                                    },
                                    controller: inputController,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                    cursorColor:
                                        context.appColors.contrastLight,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.black,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: context
                                                .appColors.contrastLight),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: context
                                                .appColors.contrastLight),
                                      ),
                                      hintText: 'Type your message...',
                                      hintStyle: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white38,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 10),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final text = inputController.text.trim();
                                  final tier = portalState.tierStatus;

                                  final isTierLounge =
                                      selectedRoom.value == 'Tier Lounge';
                                  final isAllowed =
                                      tier == TierStatus.adventurer ||
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
                                    final user =
                                        context.read<PortalBloc>().state.user;
                                    final wallet =
                                        user?.embeddedSolanaWallets.first;

                                    if (wallet == null) return;

                                    final parsed =
                                        ChatCommandParser.parse(text);

                                    // Handle /upgrade
                                    if (parsed?.action == '/upgrade') {
                                      if (tier == TierStatus.adventurer) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'You are already an Adventurer 🧙‍♂️')),
                                        );
                                        inputController.clear();
                                        FocusScope.of(context).unfocus();
                                        return;
                                      }

                                      inputController.clear();
                                      FocusScope.of(context).unfocus();

                                      showDialog(
                                        context: context,
                                        builder: (_) => UpgradeDialog(
                                            wallet: wallet,
                                            mint: context
                                                .read<PortalBloc>()
                                                .state
                                                .currentTokenAddress,
                                            onSuccess: () async {
                                              try {
                                                print(
                                                    '[UpgradeDialog] onSuccess started');

                                                final treasuryWallet = dotenv
                                                        .env[
                                                    'TREASURY_WALLET_ADDRESS'];
                                                if (treasuryWallet == null) {
                                                  print(
                                                      '[UpgradeDialog] ERROR: TREASURY_WALLET_ADDRESS is null');
                                                  return false;
                                                }

                                                final currentTokenAddress =
                                                    context
                                                        .read<PortalBloc>()
                                                        .state
                                                        .currentTokenAddress;
                                                final wallet = context
                                                    .read<PortalBloc>()
                                                    .state
                                                    .user
                                                    ?.embeddedSolanaWallets
                                                    .first;

                                                if (wallet == null) {
                                                  print(
                                                      '[UpgradeDialog] ERROR: Wallet is null');
                                                  return false;
                                                }

                                                await context
                                                    .read<BankRepository>()
                                                    .withdrawFunds(
                                                      wallet: wallet,
                                                      amount: 1000,
                                                      destinationAddress:
                                                          treasuryWallet,
                                                      wagusMint:
                                                          currentTokenAddress,
                                                    );

                                                final systemMsg = Message(
                                                  text:
                                                      '[UPGRADE] You’ve been upgraded to Adventurer 🧙‍♂️',
                                                  sender: 'System',
                                                  tier: TierStatus.system,
                                                  room: 'General',
                                                );

                                                context.read<HomeBloc>().add(
                                                      HomeSendMessageEvent(
                                                        message: systemMsg,
                                                        currentTokenAddress:
                                                            currentTokenAddress,
                                                      ),
                                                    );

                                                context.read<PortalBloc>().add(
                                                      PortalUpdateTierEvent(
                                                          TierStatus.adventurer,
                                                          wallet.address),
                                                    );

                                                print(
                                                    '[UpgradeDialog] Success');

                                                Navigator.of(context).pop();
                                                return true;
                                              } catch (e, st) {
                                                print(
                                                    '[UpgradeDialog] CRASH: $e');
                                                print(st);
                                                return false;
                                              }
                                            }),
                                      );

                                      return;
                                    }

                                    // Handle /send
                                    if (parsed?.action == '/send' &&
                                        parsed!.args.length >= 2) {
                                      inputController.clear();
                                      FocusScope.of(context).unfocus();

                                      try {
                                        final amount =
                                            int.tryParse(parsed.args[0]) ?? 0;
                                        final recipient = parsed.args[1];
                                        final mint = context
                                            .read<PortalBloc>()
                                            .state
                                            .currentTokenAddress;

                                        context.read<HomeBloc>().add(
                                              HomeSendMessageEvent(
                                                message: Message(
                                                  text:
                                                      '[SEND] ${wallet.address} has sent $amount \$WAGUS to $recipient 📨',
                                                  sender: 'System',
                                                  tier: TierStatus.system,
                                                  room: selectedRoom.value,
                                                ),
                                                currentTokenAddress: mint,
                                              ),
                                            );

                                        await context
                                            .read<BankRepository>()
                                            .withdrawFunds(
                                              wallet: wallet,
                                              amount: amount,
                                              destinationAddress: recipient,
                                              wagusMint: mint,
                                            );
                                      } catch (e) {
                                        debugPrint(
                                            '[ChatCommand] Failed to execute /send: $e');
                                      }
                                      return;
                                    }

                                    // Send as a regular message
                                    context.read<HomeBloc>().add(
                                          HomeSendMessageEvent(
                                            message: Message(
                                              text: text,
                                              sender: wallet.address,
                                              tier: tier,
                                              room: selectedRoom.value,
                                              solBalance: context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .holder
                                                  ?.solanaAmount,
                                              wagBalance: context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .holder
                                                  ?.tokenAmount
                                                  .toInt(),
                                            ),
                                            currentTokenAddress: context
                                                .read<PortalBloc>()
                                                .state
                                                .currentTokenAddress,
                                          ),
                                        );

                                    inputController.clear();
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  child: Text(
                                    'SEND',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
