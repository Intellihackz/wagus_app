import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/games/domain/spygus_game_data.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/theme/app_palette.dart';

class Spygus extends HookWidget {
  const Spygus({super.key, required this.walletAddress});

  final String walletAddress;

  @override
  Widget build(BuildContext context) {
    final hasPlayed = useState(false);
    final isLoading = useState(true);
    final imageUrl = useState<String?>(null);
    final constraintsRef = useRef<BoxConstraints?>(null);

    final spygusData =
        context.select((GameBloc bloc) => bloc.state.spygusGameData);

    useEffect(() {
      () async {
        final played = await UserService().hasPlayedSpygus(walletAddress);
        if (played && context.mounted) {
          Navigator.of(context).pop();
          return;
        }

        if (spygusData != null && imageUrl.value == null) {
          final url = await context
              .read<GameRepository>()
              .getImageUrl(spygusData.imagePath);
          imageUrl.value =
              '$url?t=${DateTime.now().millisecondsSinceEpoch}'; // avoid cache
        }

        isLoading.value = false;
      }();
      return null;
    }, [spygusData]);

    // void handleTap(TapUpDetails details) {
    //   if (constraintsRef.value == null) return;

    //   final constraints = constraintsRef.value!;
    //   final localPos = details.localPosition;
    //   final normalizedX = localPos.dx / constraints.maxWidth;
    //   final normalizedY = localPos.dy / constraints.maxHeight;

    //   // DEBUG
    //   print('Tapped X: ${(normalizedX * 100).toStringAsFixed(0)}%');
    //   print('Tapped Y: ${(normalizedY * 100).toStringAsFixed(0)}%');

    //   showDialog(
    //     context: context,
    //     builder: (_) => AlertDialog(
    //       title: const Text('Debug Tap Location'),
    //       content: Text(
    //         'X: ${(normalizedX * 100).toStringAsFixed(0)}%\nY: ${(normalizedY * 100).toStringAsFixed(0)}%',
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(),
    //           child: const Text('Close'),
    //         )
    //       ],
    //     ),
    //   );
    // }

    void handleTap(
      TapUpDetails details,
      BuildContext context,
    ) async {
      if (hasPlayed.value ||
          constraintsRef.value == null ||
          spygusData == null) {
        return;
      }

      final constraints = constraintsRef.value!;
      final localPos = details.localPosition;
      final normalizedX = localPos.dx / constraints.maxWidth;
      final normalizedY = localPos.dy / constraints.maxHeight;

      final targetX = spygusData.target[0] / 100;
      final targetY = spygusData.target[1] / 100;
      const tolerance = 0.07;

      final success = (normalizedX - targetX).abs() <= tolerance &&
          (normalizedY - targetY).abs() <= tolerance;

      hasPlayed.value = true;

      if (success) {
        // Show feedback immediately
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('You found it!',
                style: TextStyle(color: context.appColors.contrastDark)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text('Claiming \$.10 in SOL...',
                    style: TextStyle(color: context.appColors.contrastDark)),
              ],
            ),
          ),
        );

        // Run claim logic in background
        await UserService().setSpygusPlayed(walletAddress);
        try {
          if (await context
              .read<GameRepository>()
              .canClaimSpygusToday(walletAddress)) {
            await context
                .read<GameRepository>()
                .claimSpygusReward(walletAddress);

            //final user = context.read<PortalBloc>().state.user;
            final homeRepo = context.read<HomeRepository>();

            final message = Message(
              text:
                  '[SPYGUS] walletAddress found the hidden symbol and won \$0.10 SOL 👀🎉',
              sender: 'System',
              tier: TierStatus.system,
              room: 'General',
            );

            await homeRepo.sendMessage(message);
          }
        } catch (e) {
          debugPrint('Spygus claim failed: $e');
          // Optionally show retry/snackbar here
        }

        // Exit flow
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          Navigator.of(context)
            ..pop() // close dialog
            ..pop(); // exit Spygus
        }
      } else {
        // Loss dialog
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: Text('Better luck next time',
                style: TextStyle(color: context.appColors.contrastDark)),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text('Exit',
                    style: TextStyle(color: context.appColors.contrastDark)),
              )
            ],
          ),
        );
      }
    }

    return BlocSelector<GameBloc, GameState, SpygusGameData?>(
      selector: (state) => state.spygusGameData,
      builder: (context, state) {
        return Scaffold(
          body: isLoading.value || state == null || imageUrl.value == null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    constraintsRef.value = constraints;

                    return GestureDetector(
                      onTapUp: (details) {
                        handleTap(details, context);
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 80),
                          Text(
                            'Spygus',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Text(
                                'Find the WAGUS symbol in the image below. You only have one chance!',
                                textAlign: TextAlign.center,
                                style: TextStyle()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.network(
                              imageUrl.value!,
                              fit: BoxFit.fitWidth,
                              width: double.infinity,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
