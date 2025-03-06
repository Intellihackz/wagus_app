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
    final remainingTime = useState<Duration>(Duration(hours: 1));

    useEffect(() {
      final newTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (remainingTime.value.inSeconds > 0) {
          remainingTime.value -= Duration(seconds: 1);
        } else {
          timer.cancel();
        }
      });

      return () {
        newTimer.cancel();
      };
    }, []);

    String formatTime(Duration duration) {
      String hours = duration.inHours.toString().padLeft(2, '0');
      String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }

    return BlocBuilder<LotteryBloc, LotteryState>(
      builder: (context, state) {
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
                        Text('Last Lottery Prize:'),
                        Text('2500 \$WAGUS'),
                        Text('Current Lottery Pool:'),
                        Text('52000 \$WAGUS'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/background/lottery_logo.png', // You can use a different asset for lottery
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
                        Text('Next Lottery in:'),
                        Text(formatTime(remainingTime.value)),
                        SizedBox(height: 16.0),
                        Text('Add Tokens to the Pool:'),
                        Wrap(
                          children: [
                            _LotteryButton(amount: 100),
                            _LotteryButton(amount: 1000),
                            _LotteryButton(amount: 10000),
                            _LotteryButton(amount: 100000),
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

  const _LotteryButton({required this.amount});

  @override
  Widget build(BuildContext context) {
    String displayAmount = _formatAmount(amount);

    return Container(
      margin: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          context.read<LotteryBloc>().add(LotteryAddToPoolEvent(
              amount: amount, user: context.read<PortalBloc>().state.user!));
        },
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.all(context.appColors.contrastLight),
        ),
        child: Row(
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
