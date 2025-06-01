import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/domain/chat_command_parser.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/home/widgets/upgrade_dialog.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/utils.dart';

final Set<String> _giveawayProcessing = {};

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

        print('[WHATS_NEW] Snapshot received: ${snapshot.data()}');

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
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.orange[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
                  title: const Text(
                    '🚀 What’s New',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  content: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop('DISMISSED');
                      },
                      child: const Text('GOT IT'),
                    ),
                  ],
                ),
              ).then((_) async {
                // This runs regardless of dismiss reason
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

    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return BlocConsumer<HomeBloc, HomeState>(
          listener: (context, homeState) async {
            // 🎉 Confetti (visual only)
            if (homeState.canLaunchConfetti) {
              // giveaway payout logic here
              final selectedRoom = context.read<HomeBloc>().state.currentRoom;
              final selectedToken =
                  context.read<PortalBloc>().state.selectedToken;
              final wallet = context
                  .read<PortalBloc>()
                  .state
                  .user
                  ?.embeddedSolanaWallets
                  .first;

              if (wallet == null) return;

              final giveaways = await FirebaseFirestore.instance
                  .collection('giveaways')
                  .where('status', isEqualTo: 'ended')
                  .where('hasSent', isEqualTo: false)
                  .where('announced', isEqualTo: false)
                  .get();

              for (final doc in giveaways.docs) {
                if (_giveawayProcessing.contains(doc.id)) continue;

                _giveawayProcessing.add(doc.id);

                final data = doc.data();
                final winner = data['winner'];
                final amount = data['amount'];
                final host = data['host'];

                if (winner != null &&
                    amount != null &&
                    host == wallet.address) {
                  try {
                    await context.read<BankRepository>().withdrawFunds(
                          wallet: wallet,
                          amount: amount,
                          destinationAddress: winner,
                          wagusMint: selectedToken.address,
                          decimals: selectedToken.decimals,
                        );

                    final announcementText =
                        '[GIVEAWAY] 🎉 $amount \$${selectedToken.ticker} was rewarded! Winner: ${winner.substring(0, 4)}...${winner.substring(winner.length - 4)}';

                    context.read<HomeBloc>().add(HomeSendMessageEvent(
                          message: Message(
                            text: announcementText,
                            sender: 'System',
                            tier: TierStatus.system,
                            room: selectedRoom,
                            likedBy: [],
                          ),
                          currentTokenAddress: '',
                          ticker: selectedToken.ticker,
                          decimals: selectedToken.decimals,
                        ));

                    await doc.reference.update({
                      'hasSent': true,
                      'announced': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    debugPrint(
                        '[Giveaway] ✅ Sent and announced $amount to $winner');

                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      Confetti.launch(
                        context,
                        options: const ConfettiOptions(
                          particleCount: 100,
                          spread: 70,
                          y: 0.7,
                        ),
                      );
                      context.read<HomeBloc>().add(
                            HomeLaunchGiveawayConfettiEvent(
                                canLaunchConfetti: false),
                          );
                    });
                  } catch (e) {
                    debugPrint('[Giveaway] ❌ Failed to send reward: $e');
                  }
                }
              }
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

                                  if (message.sender == 'System') {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 127, 206, 230),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            message.text,
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

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

                                    final displayName = (msg.username
                                                ?.trim()
                                                .isNotEmpty ??
                                            false)
                                        ? '[${msg.username}]'
                                        : '[${msg.sender.substring(0, 3)}..${msg.sender.substring(msg.sender.length - 3)}]';

                                    return '${getTierPrefix(msg.tier)}$displayName';
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
                                                                                        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                                                                          future: FirebaseFirestore.instance.collection('users').doc(message.sender).get(),
                                                                                          builder: (context, initialSnapshot) {
                                                                                            final initialData = initialSnapshot.data?.data();

                                                                                            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                                                                              stream: FirebaseFirestore.instance.collection('users').doc(message.sender).snapshots(),
                                                                                              builder: (context, liveSnapshot) {
                                                                                                final liveData = liveSnapshot.data?.data();
                                                                                                final imageUrl = liveData?['image_url'] ?? initialData?['image_url'];

                                                                                                return CircleAvatar(
                                                                                                  key: ValueKey(imageUrl),
                                                                                                  radius: 14,
                                                                                                  backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                                                                                                  backgroundColor: Colors.transparent,
                                                                                                );
                                                                                              },
                                                                                            );
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  SelectableText(
                                                                                    (message.username?.trim().isNotEmpty ?? false) ? message.username! : '${message.sender.substring(0, 4)}...${message.sender.substring(message.sender.length - 4)}',
                                                                                    style: TextStyle(color: Colors.white),
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
                                                                                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                                                              future: FirebaseFirestore.instance.collection('users').doc(message.sender).get(),
                                                                              builder: (context, initialSnapshot) {
                                                                                final initialData = initialSnapshot.data?.data();

                                                                                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                                                                  stream: FirebaseFirestore.instance.collection('users').doc(message.sender).snapshots(),
                                                                                  builder: (context, liveSnapshot) {
                                                                                    final liveData = liveSnapshot.data?.data();
                                                                                    final imageUrl = liveData?['image_url'] ?? initialData?['image_url'];

                                                                                    return CircleAvatar(
                                                                                      key: ValueKey(imageUrl),
                                                                                      radius: 14,
                                                                                      backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                                                                                      backgroundColor: Colors.transparent,
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
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
                        final user = context.read<PortalBloc>().state.user;
                        final tier =
                            context.read<PortalBloc>().state.tierStatus;
                        await FirebaseFirestore.instance
                            .collection('chat')
                            .add({
                          'message': '/silence',
                          'sender': user!.embeddedSolanaWallets.first.address,
                          'tier': tier,
                          'room': selectedRoom,
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        return; // prevent sending it again
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
