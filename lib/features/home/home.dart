import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gif_view/gif_view.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final scrollController = useScrollController();
    final showScrollToBottom = useState(false);

    useAsyncEffect(
        effect: () async {
          final portalState = context.read<PortalBloc>().state;

          if (portalState.user != null &&
              portalState.selectedToken.address.isNotEmpty) {
            final homeBloc = context.read<HomeBloc>();
            final bankRepo = context.read<BankRepository>();

            getActiveWallet().then((wallet) async {
              if (wallet != null) {
                homeBloc.add(HomeListenToRoomsEvent());
                await homeBloc.watchGiveaways(
                    wallet.address,
                    wallet,
                    portalState.selectedToken.address,
                    bankRepo,
                    context,
                    portalState.selectedToken.ticker);
                homeBloc.add(HomeSetRoomEvent(homeBloc.state.currentRoom));
              }
            });
          }

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

    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return BlocConsumer<HomeBloc, HomeState>(
          listenWhen: (prev, curr) => prev.messages != curr.messages,
          listener: (context, homeState) {
            if (homeState.canLaunchConfetti) {
              // ignore: unused_local_variable
              final controller = Confetti.launch(
                context,
                options: const ConfettiOptions(
                    particleCount: 100, spread: 70, y: 0.7),
              );

              context.read<HomeBloc>().add(HomeLaunchGiveawayConfettiEvent());
            }
          },
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
                        _ChatRoomTabs(
                            chatRooms: homeState.rooms,
                            selectedRoom: homeState.currentRoom),

                        const Divider(color: Colors.white12, thickness: 1),
                        // Messages Display
                        // Messages Display

                        Expanded(
                          child: Builder(builder: (context) {
                            final filteredMessages = homeState.messages
                                .where(
                                    (msg) => msg.room == homeState.currentRoom)
                                .toList();

                            print(
                                '🔍 Filtered messages for room "${homeState.currentRoom}": ${filteredMessages.length}');

                            return NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification scrollInfo) {
                                final threshold = 100.0;
                                final offset = scrollInfo.metrics.pixels;
                                final maxExtent =
                                    scrollInfo.metrics.maxScrollExtent;

                                print(
                                    '[ScrollCheck] offset: $offset / maxExtent: $maxExtent');

                                final isNearTopInReverse =
                                    offset >= maxExtent - threshold;

                                bool isFetchingMore = false;

                                if (isNearTopInReverse && !isFetchingMore) {
                                  isFetchingMore = true;
                                  print(
                                      '[PaginationTrigger] Near top (in reverse scroll). Checking for more messages...');

                                  final lastDoc = context
                                      .read<HomeBloc>()
                                      .state
                                      .lastDocs[homeState.currentRoom];
                                  if (lastDoc != null) {
                                    print(
                                        '[PaginationTrigger] Last doc found. Dispatching HomeLoadMoreMessagesEvent');
                                    context.read<HomeBloc>().add(
                                          HomeLoadMoreMessagesEvent(
                                              homeState.currentRoom, lastDoc),
                                        );
                                  } else {
                                    print(
                                        '[PaginationTrigger] No lastDoc available. Skipping pagination.');
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

                                  print(
                                      'last message: ${filteredMessages.first.text}');

                                  String getTierPrefix(TierStatus tier) {
                                    if (tier == TierStatus.adventurer)
                                      return '[A]';
                                    if (tier == TierStatus.creator)
                                      return '[C]';

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
                                        return TierStatus.adventurer.color;
                                      case TierStatus.creator:
                                        return Colors.purple;
                                      case TierStatus.system:
                                        return Colors.cyan;
                                      case TierStatus.elite:
                                        return Colors.green;
                                      case TierStatus.basic:
                                      case TierStatus.none:
                                        return TierStatus.basic.color;
                                    }
                                  }

                                  return Column(
                                    children: [
                                      if (message.replyToText != null)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 6),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[850],
                                              border: Border(
                                                left: BorderSide(
                                                    color: Colors.white30,
                                                    width: 3),
                                              ),
                                            ),
                                            child: Text(
                                              message.replyToText!,
                                              style: const TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
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
                                                                            context:
                                                                                context,
                                                                            builder: (_) =>
                                                                                AlertDialog(
                                                                              backgroundColor: Colors.black,
                                                                              title: Text('Wallet Address', style: TextStyle(color: context.appColors.contrastLight)),
                                                                              content: Row(
                                                                                children: [
                                                                                  GestureDetector(
                                                                                    onTap: () => context.push('/profile/${message.sender}'),
                                                                                    child: Container(
                                                                                      margin: const EdgeInsets.only(
                                                                                        right: 16.0,
                                                                                      ),
                                                                                      padding: const EdgeInsets.all(2.5), // border thickness
                                                                                      decoration: BoxDecoration(
                                                                                        shape: BoxShape.circle,
                                                                                        border: Border.all(
                                                                                          color: portalState.tierStatus == TierStatus.adventurer ? TierStatus.adventurer.color : TierStatus.basic.color,
                                                                                          width: 3, // thick border
                                                                                        ),
                                                                                      ),
                                                                                      child: Hero(
                                                                                        tag: 'profile',
                                                                                        child: CircleAvatar(
                                                                                          radius: 14, // small & modern
                                                                                          backgroundImage: AssetImage('assets/icons/avatar.png'),
                                                                                          backgroundColor: Colors.transparent,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  Flexible(
                                                                                    child: SelectableText(
                                                                                      message.sender,
                                                                                      style: TextStyle(color: Colors.white),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    Clipboard.setData(ClipboardData(text: message.sender));
                                                                                    Navigator.of(context).pop();
                                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                                      SnackBar(content: Text('Copied to clipboard')),
                                                                                    );
                                                                                  },
                                                                                  child: Text('COPY', style: TextStyle(color: portalState.tierStatus == TierStatus.adventurer ? Colors.red : Colors.white)),
                                                                                ),
                                                                                TextButton(
                                                                                  onPressed: () => Navigator.of(context).pop(),
                                                                                  child: Text('CLOSE', style: TextStyle(color: Colors.white)),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
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
                                                                                message.id; // Ensure Message class has `id`
                                                                            final docRef =
                                                                                FirebaseFirestore.instance.collection('chat').doc(docId);
                                                                            await docRef.update({
                                                                              'likes': FieldValue.increment(1)
                                                                            });
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
                                                                    AlertDialog(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .black,
                                                                  title: Text(
                                                                      'Wallet Address',
                                                                      style: TextStyle(
                                                                          color: context
                                                                              .appColors
                                                                              .contrastLight)),
                                                                  content: Row(
                                                                    children: [
                                                                      GestureDetector(
                                                                        onTap: () =>
                                                                            context.push('/profile/${message.sender}'),
                                                                        child:
                                                                            Container(
                                                                          margin:
                                                                              const EdgeInsets.only(
                                                                            right:
                                                                                16.0,
                                                                          ),
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              2.5), // border thickness
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            border:
                                                                                Border.all(
                                                                              color: portalState.tierStatus == TierStatus.adventurer ? TierStatus.adventurer.color : TierStatus.basic.color,
                                                                              width: 3, // thick border
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Hero(
                                                                            tag:
                                                                                'profile',
                                                                            child:
                                                                                CircleAvatar(
                                                                              radius: 14, // small & modern
                                                                              backgroundImage: AssetImage('assets/icons/avatar.png'),
                                                                              backgroundColor: Colors.transparent,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Flexible(
                                                                        child:
                                                                            SelectableText(
                                                                          message
                                                                              .sender,
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Clipboard.setData(ClipboardData(
                                                                            text:
                                                                                message.sender));
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                              content: Text('Copied to clipboard')),
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                          'COPY',
                                                                          style:
                                                                              TextStyle(color: portalState.tierStatus == TierStatus.adventurer ? Colors.red : Colors.white)),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(),
                                                                      child: Text(
                                                                          'CLOSE',
                                                                          style:
                                                                              TextStyle(color: Colors.white)),
                                                                    ),
                                                                  ],
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

                        _ChatInputBar(
                          controller: inputController,
                          selectedRoom: homeState.currentRoom,
                          portalState: portalState,
                          homeState: homeState,
                        ),
                      ],
                    ),
                    if (showScrollToBottom.value)
                      if (showScrollToBottom.value)
                        Positioned(
                          bottom:
                              100, // Adjust to sit just above your input bar
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: showScrollToBottom.value ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTap: () {
                                  scrollController.animateTo(
                                    0.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.arrow_downward,
                                          color: Colors.black, size: 16),
                                      SizedBox(width: 4),
                                      Text('Scroll to Bottom',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    if (homeState.commandSearch != null ||
                        homeState.recentCommand != null)
                      Positioned(
                        bottom: 64,
                        left: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: IntrinsicWidth(
                            // ✅ This makes the width wrap content
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (homeState.recentCommand != null)
                                    _CommandOption(
                                      label: homeState.recentCommand!,
                                      onTap: () {
                                        inputController.text =
                                            homeState.recentCommand!;
                                        inputController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset:
                                                  inputController.text.length),
                                        );
                                        context.read<HomeBloc>().add(
                                            HomeCommandPopupClosed()); // ✅ Close it
                                      },
                                    ),
                                  if (homeState.commandSearch != null &&
                                      homeState.commandSearch !=
                                          homeState.recentCommand)
                                    _CommandOption(
                                      label: homeState.commandSearch!,
                                      onTap: () {
                                        inputController.text =
                                            homeState.commandSearch!;
                                        inputController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset:
                                                  inputController.text.length),
                                        );
                                        context.read<HomeBloc>().add(
                                            HomeCommandPopupClosed()); // ✅ Close it
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

class _CommandOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CommandOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
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
                        homeState.replyingTo!.text,
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
                                    .ticker ??
                                'WAGUS']
                            ?.tokenAmount
                            .toInt(),

                        replyToMessageId: homeState.replyingTo?.id,
                        replyToText: homeState.replyingTo?.text,
                      );

                      context.read<HomeBloc>().add(
                            HomeSendMessageEvent(
                              message: message,
                              currentTokenAddress: context
                                      .read<PortalBloc>()
                                      .state
                                      .selectedToken
                                      .address ??
                                  context
                                      .read<PortalBloc>()
                                      .state
                                      .currentTokenAddress,
                              ticker: context
                                      .read<PortalBloc>()
                                      .state
                                      .selectedToken
                                      .ticker ??
                                  'WAGUS',
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

                      // Handle /upgrade
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

                        final portalState = context.read<PortalBloc>().state;

                        final bankRepo = context.read<BankRepository>();

                        final double usdTarget = 3.5;
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
                                  .currentTokenAddress,
                              onSuccess: () async {
                                try {
                                  print('[UpgradeDialog] onSuccess started');

                                  final treasuryWallet =
                                      dotenv.env['TREASURY_WALLET_ADDRESS'];
                                  if (treasuryWallet == null) {
                                    print(
                                        '[UpgradeDialog] ERROR: TREASURY_WALLET_ADDRESS is null');
                                    return false;
                                  }

                                  final currentTokenAddress = context
                                      .read<PortalBloc>()
                                      .state
                                      .selectedToken
                                      .address;
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

                                  await bankRepo.withdrawFunds(
                                    wallet: wallet,
                                    amount: amount,
                                    destinationAddress: treasuryWallet,
                                    wagusMint: currentTokenAddress,
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
                                          currentTokenAddress: context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .selectedToken
                                                  .address ??
                                              context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .currentTokenAddress,
                                          ticker: context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .selectedToken
                                                  .ticker ??
                                              'WAGUS',
                                        ),
                                      );

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

                                  print('[UpgradeDialog] Success');

                                  Navigator.of(context).pop();
                                  return true;
                                } catch (e, st) {
                                  print('[UpgradeDialog] CRASH: $e');
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
                        controller.clear();
                        FocusScope.of(context).unfocus();

                        try {
                          final amount = int.tryParse(parsed.args[0]) ?? 0;
                          final recipient = parsed.args[1];
                          final mint = context
                              .read<PortalBloc>()
                              .state
                              .currentTokenAddress;

                          final ticker = context
                              .read<PortalBloc>()
                              .state
                              .selectedToken
                              .ticker;

                          context.read<HomeBloc>().add(
                                HomeSendMessageEvent(
                                  message: Message(
                                    text:
                                        '[SEND] ${wallet.address} has sent $amount \$$ticker to $recipient 📨',
                                    sender: 'System',
                                    tier: TierStatus.system,
                                    room: selectedRoom,
                                  ),
                                  currentTokenAddress: context
                                          .read<PortalBloc>()
                                          .state
                                          .selectedToken
                                          .address ??
                                      context
                                          .read<PortalBloc>()
                                          .state
                                          .currentTokenAddress,
                                  ticker: context
                                          .read<PortalBloc>()
                                          .state
                                          .selectedToken
                                          .ticker ??
                                      'WAGUS',
                                ),
                              );

                          await context.read<BankRepository>().withdrawFunds(
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
                                room: selectedRoom,
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
                                            .ticker ??
                                        'WAGUS']
                                    ?.tokenAmount
                                    .toInt(),
                                replyToMessageId: homeState.replyingTo?.id,
                                replyToText: homeState.replyingTo?.text,
                              ),
                              currentTokenAddress: context
                                      .read<PortalBloc>()
                                      .state
                                      .selectedToken
                                      .address ??
                                  context
                                      .read<PortalBloc>()
                                      .state
                                      .currentTokenAddress,
                              ticker: context
                                      .read<PortalBloc>()
                                      .state
                                      .selectedToken
                                      .ticker ??
                                  'WAGUS',
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

class _ChatRoomTabs extends StatelessWidget {
  const _ChatRoomTabs({
    required this.chatRooms,
    required this.selectedRoom,
  });

  final List<String> chatRooms;
  final String selectedRoom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chatRooms.map((room) {
            final isSelected = selectedRoom == room;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  context.read<HomeBloc>().add(HomeSetRoomEvent(room));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    room,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
