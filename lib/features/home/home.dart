import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();
    final selectedRoom = useState('General');
    final chatRooms = ['General', 'Support', 'Games', 'Ideas', 'Tier Lounge'];

    useEffect(() {
      context.read<HomeBloc>().add(HomeSetRoomEvent(selectedRoom.value));
      return null;
    }, []);

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
                                        fontSize: 10,
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

                                Color getTierColor(TierStatus tier) {
                                  switch (tier) {
                                    case TierStatus.adventurer:
                                      return Colors.red;
                                    case TierStatus.creator:
                                      return Colors.purple;
                                    case TierStatus.basic:
                                    case TierStatus.none:
                                    default:
                                      return Colors.yellow;
                                  }
                                }

                                String getTierPrefix(TierStatus tier) {
                                  if (tier == TierStatus.adventurer)
                                    return '[A]';
                                  if (tier == TierStatus.creator) return '[C]';
                                  return '[B]';
                                }

                                return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '${getTierPrefix(message.tier)}[${message.sender.substring(0, 3)}..${message.sender.substring(message.sender.length - 3)}] ',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: getTierColor(
                                                        message.tier),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: message.text,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            softWrap: true,
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
                                child: TextField(
                                  onTapOutside: (_) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  controller: inputController,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black,
                                    border: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    hintText: 'Type your message...',
                                    hintStyle: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white38,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  final text = inputController.text.trim();
                                  if (text.isNotEmpty) {
                                    context.read<HomeBloc>().add(
                                          HomeSendMessageEvent(
                                            message: Message(
                                              text: text,
                                              sender: portalState
                                                  .user!
                                                  .embeddedSolanaWallets
                                                  .first
                                                  .address,
                                              tier: portalState.tierStatus ==
                                                      TierStatus.none
                                                  ? TierStatus.basic
                                                  : portalState.tierStatus,
                                              room: selectedRoom.value,
                                            ),
                                          ),
                                        );
                                  }
                                  inputController.clear();
                                  FocusScope.of(context).unfocus();
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
