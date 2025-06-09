import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gif_view/gif_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/helpers.dart';
import 'package:wagus/features/home/widgets/chat_input_bar.dart';
import 'package:wagus/features/home/widgets/chat_room_tabs.dart';
import 'package:wagus/features/home/widgets/command_popup_view.dart';
import 'package:wagus/features/home/widgets/profile_popup_view.dart';
import 'package:wagus/features/home/widgets/reply_to_text_box.dart';
import 'package:wagus/features/home/widgets/scroll_to_bottom.dart';
import 'package:wagus/features/home/widgets/system_message_box.dart';
import 'package:wagus/features/home/widgets/whats_new_dialog.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/core/utils/utils.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();

    final scrollController = useScrollController();
    final showScrollToBottom = useState(false);

    final whatsNew = useState<String?>(null);
    final shouldShowWhatsNew = useState(false);

    useEffect(() {
      final prefsFuture = SharedPreferences.getInstance();

      final subscription = FirebaseFirestore.instance
          .collection('whats_new')
          .doc('qWkFgEOENIbgI2eRH62u')
          .snapshots()
          .listen((snapshot) async {
        final data = snapshot.data();
        final newId = data?['id'];
        final message = data?['message'];

        if (newId != null && message != null) {
          final prefs = await prefsFuture;
          final lastSeenId = prefs.getString('last_whats_new_id');

          if (lastSeenId != newId) {
            whatsNew.value = message;
            shouldShowWhatsNew.value = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => WhatsNewDialog(message: message))
                  .then((_) async {
                final snapshot = await FirebaseFirestore.instance
                    .collection('whats_new')
                    .doc('qWkFgEOENIbgI2eRH62u')
                    .get();
                final id = snapshot.data()?['id'];
                if (id != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('last_whats_new_id', id);
                }
                shouldShowWhatsNew.value = false;
              });
            });
          }
        }
      });

      return () => subscription.cancel();
    }, []);

    useAsyncEffect(
        effect: () async {
          void listener() {
            final controller = scrollController;
            if (!controller.hasClients) return;

            final currentOffset = controller.offset;
            // Show button if we're more than 150px away from bottom (which is offset 0 with reverse:true)
            showScrollToBottom.value = currentOffset > 150;
          }

          scrollController.addListener(listener);
          return () => scrollController.removeListener(listener);
        },
        keys: [context.read<PortalBloc>().state]);

    final user = context.select((PortalBloc bloc) => bloc.state.user);
    final hasRun = useRef(false);

    useEffect(() {
      if (user != null && !hasRun.value) {
        context.read<PortalBloc>().add(PortalListenSupportedTokensEvent());
        hasRun.value = true;
      }
      return null;
    }, [user]);

    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return BlocConsumer<HomeBloc, HomeState>(
          listener: (context, homeState) async =>
              handleGiveawayConfetti(context, homeState),
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
                        ChatRoomTabs(
                            chatRooms: homeState.rooms,
                            selectedRoom: homeState.currentRoom),

                        const Divider(color: Colors.white12, thickness: 1),

                        Expanded(
                          child: Builder(builder: (context) {
                            final filteredMessages = homeState.messages
                                .where(
                                    (msg) => msg.room == homeState.currentRoom)
                                .toList();

                            return NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification scrollInfo) {
                                final threshold = 100.0;
                                final offset = scrollInfo.metrics.pixels;
                                final maxExtent =
                                    scrollInfo.metrics.maxScrollExtent;

                                final isNearTopInReverse =
                                    offset >= maxExtent - threshold;

                                bool isFetchingMore = false;

                                if (isNearTopInReverse && !isFetchingMore) {
                                  isFetchingMore = true;

                                  final lastDoc = context
                                      .read<HomeBloc>()
                                      .state
                                      .lastDocs[homeState.currentRoom];
                                  if (lastDoc != null) {
                                    context.read<HomeBloc>().add(
                                          HomeLoadMoreMessagesEvent(
                                              homeState.currentRoom, lastDoc),
                                        );
                                  }
                                }

                                return false;
                              },
                              child: ListView.builder(
                                reverse: true,
                                controller: scrollController,
                                cacheExtent: 1000,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: filteredMessages.length,
                                itemBuilder: (context, index) {
                                  final message = filteredMessages[index];

                                  if (message.sender == 'System') {
                                    return SystemMessageBox(
                                      message: message,
                                    );
                                  }

                                  return Column(
                                    children: [
                                      if (message.replyToText != null)
                                        ReplyToTextBox(
                                          message: message,
                                        ),
                                      GestureDetector(
                                        onHorizontalDragEnd: (details) {
                                          if (details.primaryVelocity != null &&
                                              details.primaryVelocity! > 0) {
                                            // Swiped right
                                            context.read<HomeBloc>().add(
                                                HomeSetReplyMessageEvent(
                                                    message));
                                          }
                                        },
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                        if (message.gifUrl ==
                                                                null ||
                                                            message.gifUrl!
                                                                .isEmpty)
                                                          RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  recognizer:
                                                                      TapGestureRecognizer()
                                                                        ..onTap =
                                                                            () {
                                                                          showDialog(
                                                                              context: context,
                                                                              builder: (_) => ProfilePopupView(message: message, portalState: portalState));
                                                                        },
                                                                  text:
                                                                      '${getDisplaySender(message)} ',
                                                                  style: GoogleFonts
                                                                      .anonymousPro(
                                                                    color: message.tier ==
                                                                            TierStatus
                                                                                .system
                                                                        ? Colors
                                                                            .lightBlueAccent
                                                                        : getTierColor(
                                                                            message.tier),
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight: message.tier ==
                                                                            TierStatus
                                                                                .system
                                                                        ? FontWeight
                                                                            .w600
                                                                        : FontWeight
                                                                            .normal,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: message
                                                                      .text,
                                                                  style: GoogleFonts.anonymousPro(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          14),
                                                                ),
                                                                WidgetSpan(
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        top: 4,
                                                                        left:
                                                                            4),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        GestureDetector(
                                                                          onTap:
                                                                              () async {
                                                                            final docId =
                                                                                message.id;
                                                                            final docRef =
                                                                                FirebaseFirestore.instance.collection('chat').doc(docId);
                                                                            final userWallet =
                                                                                portalState.user!.embeddedSolanaWallets.first.address;

                                                                            try {
                                                                              final snapshot = await docRef.get();
                                                                              final data = snapshot.data();

                                                                              final List likedBy = List.from(data?['likedBy'] ?? []);

                                                                              if (!likedBy.contains(userWallet)) {
                                                                                await docRef.update({
                                                                                  'likes': FieldValue.increment(1),
                                                                                  'likedBy': FieldValue.arrayUnion([
                                                                                    userWallet
                                                                                  ])
                                                                                });
                                                                              } else {
                                                                                await docRef.update({
                                                                                  'likes': FieldValue.increment(-1),
                                                                                  'likedBy': FieldValue.arrayRemove([
                                                                                    userWallet
                                                                                  ])
                                                                                });
                                                                              }
                                                                            } catch (e) {
                                                                              debugPrint('Failed to like message: $e');
                                                                            }
                                                                          },
                                                                          child: Icon(
                                                                              Icons.thumb_up_alt_outlined,
                                                                              size: 14,
                                                                              color: message.likes != null && message.likes! > 0
                                                                                  ? portalState.tierStatus == TierStatus.adventurer
                                                                                      ? TierStatus.adventurer.color
                                                                                      : TierStatus.basic.color
                                                                                  : Colors.white),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Visibility(
                                                                          visible:
                                                                              message.likes != null && message.likes! > 0,
                                                                          child:
                                                                              Text(
                                                                            message.likes.toString(),
                                                                            style:
                                                                                TextStyle(color: portalState.tierStatus == TierStatus.adventurer ? TierStatus.adventurer.color : TierStatus.basic.color, fontSize: 12),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        else ...[
                                                          GestureDetector(
                                                            onTap: () {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (_) =>
                                                                    ProfilePopupView(
                                                                  message:
                                                                      message,
                                                                  portalState:
                                                                      portalState,
                                                                ),
                                                              );
                                                            },
                                                            child: Text(
                                                              getDisplaySender(
                                                                  message),
                                                              style: GoogleFonts
                                                                  .anonymousPro(
                                                                color: message
                                                                            .tier ==
                                                                        TierStatus
                                                                            .system
                                                                    ? Colors
                                                                        .lightBlueAccent
                                                                    : getTierColor(
                                                                        message
                                                                            .tier),
                                                                fontSize: 14,
                                                                fontWeight: message
                                                                            .tier ==
                                                                        TierStatus
                                                                            .system
                                                                    ? FontWeight
                                                                        .w600
                                                                    : FontWeight
                                                                        .normal,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          SizedBox(
                                                            height: 200,
                                                            width: 200,
                                                            child: Stack(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              children: [
                                                                // Loader while image loads
                                                                const CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white24,
                                                                ),
                                                                // GIF with fade-in once loaded
                                                                RepaintBoundary(
                                                                  child: GifView
                                                                      .network(
                                                                    key: ValueKey(
                                                                        message
                                                                            .id),
                                                                    message
                                                                        .gifUrl!,
                                                                    height: 200,
                                                                    width: 200,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorBuilder: (context,
                                                                            error,
                                                                            stackTrace) =>
                                                                        const Icon(
                                                                      Icons
                                                                          .broken_image,
                                                                      color: Colors
                                                                          .redAccent,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (message.text !=
                                                              '[GIF]') // Only show caption if it's meaningful
                                                            Text(
                                                              message.text,
                                                            )
                                                        ]
                                                      ]))
                                                ])),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                        const Divider(color: Colors.white12, thickness: 1),
                        // Input Bar

                        ChatInputBar(
                          controller: inputController,
                          selectedRoom: homeState.currentRoom,
                          portalState: portalState,
                          homeState: homeState,
                        ),
                      ],
                    ),
                    if (showScrollToBottom.value)
                      if (showScrollToBottom.value)
                        ScrollToBottom(
                            showScrollToBottom: showScrollToBottom,
                            scrollController: scrollController),
                    if (homeState.commandSearch != null ||
                        homeState.recentCommand != null)
                      CommandPopupView(
                          homeState: homeState,
                          inputController: inputController),
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
