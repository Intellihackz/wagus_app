import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/lottery/bloc/lottery_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';

class Lottery extends HookWidget {
  const Lottery({super.key});

  @override
  Widget build(BuildContext context) {
    final remainingTime = useState<Duration>(const Duration(hours: 24));
    final timerRef = useRef<Timer?>(null);

    void startTimer(Duration initialDuration) {
      remainingTime.value = initialDuration;
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (context.mounted && remainingTime.value.inSeconds > 0) {
          remainingTime.value -= const Duration(seconds: 1);
        } else {
          timer.cancel();
        }
      });
    }

    useEffect(() {
      void syncTimer() {
        final initialState = context.read<LotteryBloc>().state;
        final currentTimestamp =
            initialState.currentLottery?.timestamp?.toDate();

        DateTime now = DateTime.now();
        DateTime nextReset = DateTime(now.year, now.month, now.day, 18, 0);
        if (now.isAfter(nextReset)) {
          nextReset = nextReset.add(const Duration(days: 1));
        }

        // Use fallback if no timestamp or it's too old
        if (currentTimestamp == null ||
            now.difference(currentTimestamp).inHours >= 24) {
          startTimer(nextReset.difference(now));
        } else {
          final lotteryEndTime =
              currentTimestamp.add(const Duration(hours: 24));
          final diff = lotteryEndTime.difference(now);
          startTimer(diff.isNegative ? nextReset.difference(now) : diff);
        }
      }

      syncTimer();
      return () => timerRef.value?.cancel();
    }, []);

    String formatTime(Duration duration) {
      String sign = duration.isNegative ? '-' : '';
      String hours = duration.inHours.abs().toString().padLeft(2, '0');
      String minutes =
          (duration.inMinutes % 60).abs().toString().padLeft(2, '0');
      String seconds =
          (duration.inSeconds % 60).abs().toString().padLeft(2, '0');
      return '$sign$hours:$minutes:$seconds';
    }

    return BlocConsumer<LotteryBloc, LotteryState>(
      listener: (context, state) {
        final currentTimestamp = state.currentLottery?.timestamp?.toDate();
        DateTime now = DateTime.now();
        DateTime nextReset = DateTime(now.year, now.month, now.day, 18, 0);
        if (now.isAfter(nextReset)) {
          nextReset = nextReset.add(const Duration(days: 1));
        }

        if (currentTimestamp == null ||
            now.difference(currentTimestamp).inHours >= 24) {
          startTimer(nextReset.difference(now));
        } else {
          final lotteryEndTime =
              currentTimestamp.add(const Duration(hours: 24));
          final diff = lotteryEndTime.difference(now);
          startTimer(diff.isNegative ? nextReset.difference(now) : diff);
        }

        if (state.status == LotteryStatus.failure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
                SnackBar(
                  content: Text('Failed to add to pool. Please try again.'),
                  behavior: SnackBarBehavior.floating,
                ),
              )
              .closed
              .then((_) {
            if (context.mounted) {
              context.read<LotteryBloc>().add(LotteryResetStatusEvent());
            }
          });
        }
      },
      builder: (context, state) {
        final isLoading = state.status == LotteryStatus.loading;

        return Scaffold(
          body: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 128.0, left: 32.0, right: 32.0),
                    child: Column(
                      spacing: 12.0,
                      children: [
                        if (state.lastLottery != null) ...[
                          const Text('Last Lottery Amount:'),
                          Text('${state.lastLottery!.amount} \$WAGUS'),
                        ],
                        if (state.currentLottery != null) ...[
                          const Text('Current Lottery Amount:'),
                          Text('${state.currentLottery!.amount} \$WAGUS'),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/background/lottery_logo.png',
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 32.0, right: 32.0),
                    child: Column(
                      spacing: 12.0,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Next Lottery in:'),
                        Text(formatTime(remainingTime.value)),
                        const SizedBox(height: 16.0),
                        const Text('Add Tokens to the Pool:'),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _LotteryButton(
                                amount: 100,
                                isLoading: isLoading,
                                isDisabled:
                                    state.status == LotteryStatus.failure),
                            _LotteryButton(
                                amount: 1000,
                                isLoading: isLoading,
                                isDisabled:
                                    state.status == LotteryStatus.failure),
                            _LotteryButton(
                                amount: 10000,
                                isLoading: isLoading,
                                isDisabled:
                                    state.status == LotteryStatus.failure),
                            _LotteryButton(
                                amount: 100000,
                                isLoading: isLoading,
                                isDisabled:
                                    state.status == LotteryStatus.failure),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LotteryButton extends StatelessWidget {
  final int amount;
  final bool isLoading;
  final bool isDisabled;

  const _LotteryButton(
      {required this.amount,
      required this.isLoading,
      required this.isDisabled});

  @override
  Widget build(BuildContext context) {
    String displayAmount = _formatAmount(amount);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          if (isLoading || isDisabled) return;
          context.read<LotteryBloc>().add(LotteryAddToPoolEvent(
                amount: amount,
                user: context.read<PortalBloc>().state.user!,
                wagusMint: context.read<PortalBloc>().state.currentTokenAddress,
              ));
        },
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.all(context.appColors.contrastLight),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 16,
                width: 16,
                child: const CircularProgressIndicator(),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayAmount,
                    style: TextStyle(color: context.appColors.contrastDark),
                  ),
                  Image.asset(
                    'assets/icons/logo.png',
                    height: 32,
                    width: 32,
                  ),
                ],
              ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount < 1000) {
      return '$amount';
    } else {
      double formattedAmount = amount / 1000.0;
      return '${formattedAmount.toStringAsFixed(0)}k';
    }
  }
}
