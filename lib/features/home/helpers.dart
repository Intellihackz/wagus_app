import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

String getTierPrefix(TierStatus tier) {
  if (tier == TierStatus.adventurer) return '[A]';
  if (tier == TierStatus.creator) return '[C]';

  if (tier == TierStatus.system) return '[S]';
  return '[B]';
}

String getDisplaySender(Message msg) {
  if (msg.tier == TierStatus.system) return '[System]';

  final displayName = (msg.username?.trim().isNotEmpty ?? false)
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

final Set<String> _giveawayProcessing = {};

Future<void> handleGiveawayConfetti(
    BuildContext context, HomeState homeState) async {
  if (!homeState.canLaunchConfetti) return;

  final selectedRoom = context.read<HomeBloc>().state.currentRoom;
  final selectedToken = context.read<PortalBloc>().state.selectedToken;
  final wallet =
      context.read<PortalBloc>().state.user?.embeddedSolanaWallets.first;

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

    if (winner != null && amount != null && host == wallet.address) {
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

        debugPrint('[Giveaway] ✅ Sent and announced $amount to $winner');

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          Confetti.launch(
            context,
            options: const ConfettiOptions(
              particleCount: 100,
              spread: 70,
              y: 0.7,
            ),
          );
          context
              .read<HomeBloc>()
              .add(HomeLaunchGiveawayConfettiEvent(canLaunchConfetti: false));
        });
      } catch (e) {
        debugPrint('[Giveaway] ❌ Failed to send reward: $e');
      }
    }
  }
}
