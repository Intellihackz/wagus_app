import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/quest/bloc/quest_bloc.dart';

class Quest extends HookWidget {
  const Quest({super.key});

  @override
  Widget build(BuildContext context) {
    final sugawBadgeId = 'oXlvZMsWS58OZkjOHjpE';
    final hasSugawBadge = useState(false);
    final backgroundImgUrl = useState<String?>(null);
    final hasCompletedStep1 = useState(false);

    useEffect(() {
      Future.microtask(() async {
        final address = context
            .read<PortalBloc>()
            .state
            .user!
            .embeddedSolanaWallets
            .first
            .address;

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(address)
            .get();
        final data = doc.data();
        final badges = (data?['badges'] ?? []) as List<dynamic>;
        final score = data?['memory_breach_score'] ?? 0;

        hasSugawBadge.value = badges.contains(sugawBadgeId);
        hasCompletedStep1.value = score >= 10;

        if (badges.contains(sugawBadgeId)) {
          final badgeDoc = await FirebaseFirestore.instance
              .collection('badges')
              .doc(sugawBadgeId)
              .get();
          backgroundImgUrl.value = badgeDoc.data()?['backgroundImgUrl'];
        }
      });

      context.read<QuestBloc>().add(
            QuestInitialEvent(
              address: context
                  .read<PortalBloc>()
                  .state
                  .user!
                  .embeddedSolanaWallets
                  .first
                  .address,
            ),
          );

      return null;
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 64.0, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _QuestTile(
              title: 'Daily Reward Challenge',
              onTap: () => _openDailyRewardsSheet(context),
              tierStatus: context.read<PortalBloc>().state.tierStatus,
            ),
            const SizedBox(height: 16),
            _ComingSoonTile(title: 'Daily Tasks'),
            const SizedBox(height: 8),
            _ComingSoonTile(title: 'Weekly Tasks'),
            if (hasSugawBadge.value) ...[
              const SizedBox(height: 16),
              _QuestTile(
                title: 'Corrupted Entrypoint',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(
                          0xFF121212), // deep slate instead of true black
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side:
                            BorderSide(color: Colors.white24), // subtle border
                      ),
                      title: const Text(
                        'Corrupted Entrypoint',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quest Overview',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'In the ruins of SUGAW’s fractured memory vaults, remnants of corrupted code pulse beneath the interface. These aren’t just bugs—they’re encrypted fragments of a long-lost AI protocol.\n\nOnly the most precise minds can decipher the patterns.',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Task(s)',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  hasCompletedStep1.value
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: hasCompletedStep1.value
                                      ? Colors.green
                                      : Colors.white30,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasCompletedStep1.value
                                        ? 'Achieve a score of 10+ in Memory Breach  ❌'
                                        : 'Achieve a score of 10+ in Memory Breach',
                                    style: TextStyle(
                                      color: hasCompletedStep1.value
                                          ? Colors.grey
                                          : Colors.white,
                                      decoration: hasCompletedStep1.value
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Next Step (Locked)',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Once qualified, the AI Agent of SUGAW will decrypt your credentials and initiate Phase II...\n(Feature coming soon)',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  );
                },
                tierStatus: context.read<PortalBloc>().state.tierStatus,
                backgroundImgUrl: backgroundImgUrl.value,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDailyRewardsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DailyRewardsSheet(sheetContext: sheetContext),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.title,
    required this.onTap,
    required this.tierStatus,
    this.backgroundImgUrl,
  });

  final String title;
  final VoidCallback onTap;
  final TierStatus tierStatus;
  final String? backgroundImgUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundImgUrl == null
            ? (tierStatus == TierStatus.adventurer
                ? TierStatus.adventurer.color.withOpacity(0.1)
                : TierStatus.basic.color.withOpacity(0.1))
            : null,
        image: backgroundImgUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(backgroundImgUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      collapsedIconColor: Colors.white,
      iconColor: Colors.white,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      children: const [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Coming Soon', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

class DailyRewardsSheet extends StatelessWidget {
  const DailyRewardsSheet({super.key, required this.sheetContext});

  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuestBloc, QuestState>(
      listener: (context, state) {
        if (state.claimSuccess || state.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.canPop()) {
              context.pop();
            }

            // Avoid multiple snackbars
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();

            if (state.claimSuccess) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('✅ Reward Claimed Successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '⚠️ Something went wrong.\n\n'),
                        TextSpan(
                          text: 'Check the following:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '• Do you hold at least 1 WAGUS?\n'),
                        TextSpan(
                            text:
                                '• Are you on a different account on same IP?\n'),
                        TextSpan(
                            text:
                                '• Have 24 hours passed since your last claim?\n'),
                        TextSpan(
                            text: '• Is your internet connection stable?\n'),
                        TextSpan(text: '• Has your rent been paid already?\n'),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Clear success/error to prevent repeat snackbar
            context.read<QuestBloc>().add(QuestClearFeedbackEvent());
          });
        }
      },
      builder: (context, state) {
        final portalState = context.read<PortalBloc>().state;
        final wallet = portalState.user?.embeddedSolanaWallets.first.address;
        final lastClaimed = state.lastClaimed?.toDate();
        final serverNow = state.serverNow?.toDate();

        print('[UI] lastClaimed: $lastClaimed');
        print('[UI] serverNow: $serverNow');

        Duration? timeRemaining;
        if (lastClaimed != null && serverNow != null) {
          final nextClaimTime = lastClaimed.add(const Duration(hours: 24));
          timeRemaining = nextClaimTime.difference(serverNow);
          if (timeRemaining.isNegative) timeRemaining = Duration.zero;
        }

        final isAdventurer = portalState.tierStatus == TierStatus.adventurer;

        final List<String> solAmounts = List.generate(
          6,
          (_) => isAdventurer ? '\$0.25 in SOL' : '\$0.05 in SOL',
        )..add(isAdventurer ? '\$1.00 in SOL' : '\$0.15 in SOL');
        print('[UI] timeRemaining: $timeRemaining');

        if (timeRemaining != null && timeRemaining.inSeconds <= 2) {
          timeRemaining = Duration.zero;
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: timeRemaining == null
                        ? const SizedBox.shrink()
                        : timeRemaining > Duration.zero
                            ? TweenAnimationBuilder<Duration>(
                                key: ValueKey(timeRemaining.inSeconds),
                                duration: timeRemaining,
                                tween: Tween(
                                    begin: timeRemaining, end: Duration.zero),
                                onEnd: () {
                                  Future.delayed(const Duration(seconds: 2),
                                      () {
                                    context.read<QuestBloc>().add(
                                          QuestInitialEvent(address: wallet!),
                                        );
                                  });
                                },
                                builder: (_, Duration value, __) {
                                  String twoDigits(int n) =>
                                      n.toString().padLeft(2, '0');
                                  final hours = twoDigits(value.inHours);
                                  final minutes =
                                      twoDigits(value.inMinutes.remainder(60));
                                  final seconds =
                                      twoDigits(value.inSeconds.remainder(60));
                                  return Text(
                                    'Next claim in: $hours:$minutes:$seconds',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  );
                                },
                              )
                            : const Text(
                                '✅ You can now claim your reward!',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 14),
                              ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                    const Text(
                      'Daily Rewards',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isClaimed = state.claimedDays.contains(day);
                    final isLoading = state.currentlyClaimingDay == day;

                    return BlocSelector<PortalBloc, PortalState, TierStatus>(
                      selector: (state) {
                        return state.tierStatus;
                      },
                      builder: (context, tierStatus) {
                        return Container(
                          width: MediaQuery.of(context).size.width / 2 - 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            border: Border.all(
                              color: isClaimed
                                  ? tierStatus == TierStatus.adventurer
                                      ? TierStatus.adventurer.color
                                      : TierStatus.basic.color
                                  : Colors.white12,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Day $day',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 8),
                              Text(solAmounts[index],
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.lightBlueAccent)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: isClaimed ||
                                        isLoading ||
                                        wallet == null
                                    ? null
                                    : () async {
                                        final questBloc =
                                            context.read<QuestBloc>();
                                        final canClaim = await questBloc
                                            .questRepository
                                            .canClaimToday(wallet);
                                        if (!canClaim ||
                                            state.claimedDays.length + 1 !=
                                                day) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor: Colors.grey[900],
                                              title: const Row(
                                                children: [
                                                  Icon(Icons.error,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Hold Up',
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                ],
                                              ),
                                              content: const Text(
                                                'You must claim one reward per day and in order!',
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }

                                        context.read<QuestBloc>().add(
                                              QuestClaimDailyRewardEvent(
                                                day: day,
                                                userWalletAddress: wallet,
                                                tier: portalState.tierStatus,
                                              ),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isClaimed
                                      ? Colors.grey
                                      : tierStatus == TierStatus.adventurer
                                          ? TierStatus.adventurer.color
                                          : TierStatus.basic.color,
                                  minimumSize: const Size(double.infinity, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isClaimed ? 'Claimed' : 'Claim',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
