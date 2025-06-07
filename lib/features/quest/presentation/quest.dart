import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/quest/bloc/quest_bloc.dart';
import 'package:wagus/features/quest/presentation/daily_reward_sheet.dart';
import 'package:wagus/features/quest/presentation/quest_tile.dart';

class Quest extends HookWidget {
  const Quest({super.key});

  @override
  Widget build(BuildContext context) {
    final sugawBadgeId = 'oXlvZMsWS58OZkjOHjpE';
    final hasSugawBadge = useState(false);
    final earlyBadgeId = 'PoHkntyQUX2fKnAJbPvO';
    final hasEarlyBadge = useState(false);

    final sugawBackgroundImgUrl = useState<String?>(null);
    final earlyBackgroundImgUrl = useState<String?>(null);

    final hasCompletedStep1 = useState(false);
    final hasCompletedCodeStep1 = useState(false);

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

        final codeNavigatorFound = data?['code_navigator_found'] == true;
        hasCompletedCodeStep1.value = codeNavigatorFound == true;

        hasSugawBadge.value = badges.contains(sugawBadgeId);
        hasEarlyBadge.value = badges.contains(earlyBadgeId);

        hasCompletedStep1.value = score >= 10;

        if (badges.contains(sugawBadgeId)) {
          final badgeDoc = await FirebaseFirestore.instance
              .collection('badges')
              .doc(sugawBadgeId)
              .get();
          sugawBackgroundImgUrl.value = badgeDoc.data()?['backgroundImgUrl'];
        }

        if (badges.contains(earlyBadgeId)) {
          final badgeDoc = await FirebaseFirestore.instance
              .collection('badges')
              .doc(earlyBadgeId)
              .get();
          earlyBackgroundImgUrl.value = badgeDoc.data()?['backgroundImgUrl'];
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

    final tierStatus = context.read<PortalBloc>().state.tierStatus;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 64.0, left: 16, right: 16),
        child: SingleChildScrollView(
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
              QuestTile(
                title: 'Daily Reward Challenge',
                onTap: () => _openDailyRewardsSheet(context),
                tierStatus: tierStatus,
              ),
              const SizedBox(height: 32),

              // General Quests
              const Text('General Quests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              const SizedBox(height: 8),

              if (tierStatus == TierStatus.adventurer) ...[
                const SizedBox(height: 32),
                const Text('Adventurer Quests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 32),
              Text('Lore Quests',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              if (hasSugawBadge.value) ...[
                const SizedBox(height: 16),
                QuestTile(
                  title: 'Corrupted Entrypoint',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(
                            0xFF121212), // deep slate instead of true black
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Colors.white24), // subtle border
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
                  backgroundImgUrl: sugawBackgroundImgUrl.value,
                ),
              ],
              if (hasEarlyBadge.value) ...[
                QuestTile(
                  title: 'Early Member Initiation',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF121212),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.white24),
                        ),
                        title: const Text(
                          'Early Member Initiation',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Initiation Overview',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'As one of the earliest believers in WAGUS, your initiation has unlocked hidden lore and early access to uncharted areas of the app.\n\nYou’ve proven your loyalty before the world knew what was coming.',
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
                                    hasCompletedCodeStep1.value
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: hasCompletedCodeStep1.value
                                        ? Colors.green
                                        : Colors.white30,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      hasCompletedCodeStep1.value
                                          ? 'Complete Code Navigator ✅'
                                          : 'Complete Code Navigator',
                                      style: TextStyle(
                                        color: hasCompletedCodeStep1.value
                                            ? Colors.grey
                                            : Colors.white,
                                        decoration: hasCompletedCodeStep1.value
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
                                'Phase II of the Early Member journey will unlock hidden commands and avatar enhancements.\n(Coming Soon)',
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
                  backgroundImgUrl: earlyBackgroundImgUrl.value,
                ),
              ],
            ],
          ),
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
