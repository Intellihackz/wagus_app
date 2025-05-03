import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/quest/bloc/quest_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/wagus.dart';

class Quest extends HookWidget {
  const Quest({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
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
    }, []);

    final List<Map<String, String>> rewards = [
      {'sol': '\$0.25 in SOL', 'bucks': '100 Buckazoids'},
      {'sol': '\$0.25 in SOL', 'bucks': '250 Buckazoids'},
      {'sol': '\$0.25 in SOL', 'bucks': '500 Buckazoids'},
      {'sol': '\$0.25 in SOL', 'bucks': '1000 Buckazoids'},
      {'sol': '\$0.25 in SOL', 'bucks': '2500 Buckazoids'},
      {'sol': '\$0.25 in SOL', 'bucks': '5000 Buckazoids'},
      {'sol': '\$1.00 in SOL', 'bucks': '10000 Buckazoids'},
    ];

    void openDailyRewardsSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.appColors.contrastDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (bottomSheetContext) {
          // 👈 New context
          return Scaffold(
            body: CustomPaint(
              painter: CryptoBackgroundPainter(),
              child: BlocConsumer<QuestBloc, QuestState>(
                listener: (context, state) async {
                  if (state.claimSuccess) {
                    Navigator.of(bottomSheetContext).pop();

                    // 💥 Force a full refetch here
                    final portalBloc = context.read<PortalBloc>();
                    final questBloc = context.read<QuestBloc>();
                    final userWallet = portalBloc
                        .state.user!.embeddedSolanaWallets.first.address;

                    final latestClaimedDays = await questBloc.questRepository
                        .fetchClaimedDays(userWallet);

                    if (context.mounted) {
                      context.read<QuestBloc>().add(
                            QuestClaimedDaysSetEvent(
                              claimedDays: latestClaimedDays.toSet(),
                            ),
                          );
                    }

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
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32.0, left: 16),
                            child: BackButton(
                              color: context.appColors.contrastLight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 32),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(7, (index) {
                              final day = index + 1;
                              final isClaimed = state.claimedDays.contains(day);
                              final isLoading =
                                  state.currentlyClaimingDay == day;

                              return SizedBox(
                                width:
                                    MediaQuery.of(context).size.width / 2 - 24,
                                child: Card(
                                  color: Colors.grey[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Day $day',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          rewards[index]['sol']!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.lightBlueAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Visibility(
                                          visible: false,
                                          child: Text(
                                            rewards[index]['bucks']!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: isClaimed || isLoading
                                              ? null
                                              : () async {
                                                  final questBloc =
                                                      context.read<QuestBloc>();
                                                  final portalBloc = context
                                                      .read<PortalBloc>();
                                                  final userWallet = portalBloc
                                                      .state
                                                      .user!
                                                      .embeddedSolanaWallets
                                                      .first
                                                      .address;

                                                  // Check if user can claim today
                                                  final canClaim =
                                                      await questBloc
                                                          .questRepository
                                                          .canClaimToday(
                                                              userWallet);
                                                  if (!canClaim) {
                                                    showDialog(
                                                      context:
                                                          bottomSheetContext,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        backgroundColor:
                                                            Colors.grey[900],
                                                        title: const Row(
                                                          children: [
                                                            Icon(Icons.error,
                                                                color:
                                                                    Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Hold Up',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                          ],
                                                        ),
                                                        content: const Text(
                                                          'You can only claim one reward per day!',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white70),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        bottomSheetContext)
                                                                    .pop(),
                                                            child: const Text(
                                                                'OK'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  // Fetch latest claimed days
                                                  final latestClaimedDays =
                                                      await questBloc
                                                          .questRepository
                                                          .fetchClaimedDays(
                                                              userWallet);
                                                  final expectedDay =
                                                      latestClaimedDays.length +
                                                          1;

                                                  if (day != expectedDay) {
                                                    showDialog(
                                                      context:
                                                          bottomSheetContext,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        backgroundColor:
                                                            Colors.grey[900],
                                                        title: const Row(
                                                          children: [
                                                            Icon(Icons.error,
                                                                color:
                                                                    Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Hold Up',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                          ],
                                                        ),
                                                        content: Text(
                                                          'You must claim in order! (Next up: Day $expectedDay)',
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white70),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        bottomSheetContext)
                                                                    .pop(),
                                                            child: const Text(
                                                                'OK'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  questBloc.add(
                                                    QuestClaimDailyRewardEvent(
                                                      day: day,
                                                      userWalletAddress:
                                                          userWallet,
                                                    ),
                                                  );
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isClaimed
                                                ? Colors.grey
                                                : Colors.green,
                                            minimumSize:
                                                const Size(double.infinity, 36),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  isClaimed
                                                      ? 'Claimed'
                                                      : 'Claim',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 64.0),
            child: Text(
              'Quests',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GestureDetector(
                  onTap: openDailyRewardsSheet,
                  child: Card(
                    color: Colors.blueGrey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Daily Reward Challenge',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  collapsedIconColor: Colors.white,
                  iconColor: Colors.white,
                  title: const Text(
                    'Daily Tasks',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  collapsedIconColor: Colors.white,
                  iconColor: Colors.white,
                  title: const Text(
                    'Weekly Tasks',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
