import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/quest/bloc/quest_bloc.dart';

class Quest extends HookWidget {
  const Quest({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      final address = context
          .read<PortalBloc>()
          .state
          .user
          ?.embeddedSolanaWallets
          .first
          .address;
      if (address != null) {
        context.read<QuestBloc>().add(QuestInitialEvent(address: address));
      }
      return null;
    }, []);

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
            ),
            const SizedBox(height: 16),
            _ComingSoonTile(title: 'Daily Tasks'),
            const SizedBox(height: 8),
            _ComingSoonTile(title: 'Weekly Tasks'),
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
      builder: (_) => const DailyRewardsSheet(),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.green.withOpacity(0.1),
      onTap: onTap,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      trailing: const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(Icons.chevron_right, color: Colors.white),
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
  const DailyRewardsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuestBloc, QuestState>(
      listener: (context, state) {
        if (state.claimSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reward Claimed Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final portalState = context.read<PortalBloc>().state;
        final wallet = portalState.user?.embeddedSolanaWallets.first.address;
        final isAdventurer = portalState.tierStatus == TierStatus.adventurer;

        final List<String> solAmounts = List.generate(
          6,
          (_) => isAdventurer ? '\$0.25 in SOL' : '\$0.05 in SOL',
        )..add(isAdventurer ? '\$1.00 in SOL' : '\$0.15 in SOL');

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
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

                    return Container(
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(
                          color:
                              isClaimed ? Colors.greenAccent : Colors.white12,
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
                                  fontSize: 14, color: Colors.lightBlueAccent)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: isClaimed || isLoading || wallet == null
                                ? null
                                : () async {
                                    final questBloc = context.read<QuestBloc>();
                                    final canClaim = await questBloc
                                        .questRepository
                                        .canClaimToday(wallet);
                                    if (!canClaim ||
                                        state.claimedDays.length + 1 != day) {
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
                                                  Navigator.of(context).pop(),
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
                              backgroundColor:
                                  isClaimed ? Colors.grey : Colors.green,
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
