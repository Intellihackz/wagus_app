import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/core/theme/app_palette.dart';

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
      // Lock orientation to landscape on enter
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      () async {
        final played = await UserService().hasPlayedSpygus(walletAddress);
        if (played && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You've already played SPYGUS this week."),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (context.canPop()) {
            context.pop();
          }
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

      // Unlock orientation on exit
      return () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      };
    }, [spygusData]);

    final debugMarker = useState<Offset?>(null);

    void handleTap(TapUpDetails details, BuildContext context) async {
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

      await UserService().setSpygusPlayed(walletAddress);

      if (success) {
        final userTier = context.read<PortalBloc>().state.tierStatus;
        final rewardUsd = userTier == TierStatus.adventurer ? 0.25 : 0.05;

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
                Text('Claiming \$$rewardUsd in SOL...',
                    style: TextStyle(color: context.appColors.contrastDark)),
              ],
            ),
          ),
        );

        try {
          if (await context
              .read<GameRepository>()
              .canClaimSpygusToday(walletAddress)) {
            await context
                .read<GameRepository>()
                .claimSpygusReward(walletAddress);

            final message = Message(
              text:
                  '[SPYGUS] ${walletAddress.substring(0, 4)}...${walletAddress.substring(walletAddress.length - 4)} found the hidden symbol and won \$$rewardUsd SOL 👀🎉',
              sender: 'System',
              tier: TierStatus.system,
              room: 'General',
              likedBy: [],
            );

            await context.read<HomeRepository>().sendMessage(message);
          }
        } catch (e) {
          debugPrint('Spygus claim failed: $e');
        }

        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          Navigator.of(context)
            ..pop()
            ..pop();
        }
      } else {
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

    return Scaffold(
      body: isLoading.value || spygusData == null || imageUrl.value == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                constraintsRef.value = constraints;
                return GestureDetector(
                  onTapUp: (details) => handleTap(details, context),
                  child: Stack(
                    children: [
                      if (debugMarker.value != null)
                        Positioned(
                          left:
                              constraints.maxWidth * debugMarker.value!.dx - 10,
                          top: constraints.maxHeight * debugMarker.value!.dy -
                              10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: Image.network(
                          imageUrl.value!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring: true, // allow touches to pass through
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Find the hidden WAGUS symbol 👀 You only get one shot.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(blurRadius: 4, color: Colors.black)
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
