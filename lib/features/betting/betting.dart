import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/theme/app_palette.dart';

class Betting extends HookWidget {
  const Betting({super.key});

  @override
  Widget build(BuildContext context) {
    final betAmount = useState<int>(0);
    final selectedBet = useState<String>('');

    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 128.0, left: 32.0, right: 32.0),
                child: Column(
                  spacing: 12.0,
                  children: [
                    Text('Bet:'),
                    Text('Who will win the World Series?'),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BetOption(
                          label: 'Team A',
                          odds: '+200',
                          isSelected: selectedBet.value == 'Team A',
                          onTap: () {
                            selectedBet.value = 'Team A';
                          },
                        ),
                        _BetOption(
                          label: 'Team B',
                          odds: '-150',
                          isSelected: selectedBet.value == 'Team B',
                          onTap: () {
                            selectedBet.value = 'Team B';
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Image.asset(
              'assets/background/betting_logo.png',
              height: 200,
              fit: BoxFit.cover,
            ),
            Expanded(
              child: Column(
                spacing: 12.0,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: Text('Bet Amount in \$WAGUS Tokens:')),
                  Wrap(
                    children: [
                      _BetAmountButton(amount: 100, betAmount: betAmount),
                      _BetAmountButton(amount: 1000, betAmount: betAmount),
                      _BetAmountButton(amount: 10000, betAmount: betAmount),
                      _BetAmountButton(amount: 100000, betAmount: betAmount),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text('Total Bet: ${betAmount.value} \$WAGUS'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Confirm Bet',
                                style: TextStyle(
                                    color: context.appColors.contrastDark)),
                            content: Text(
                              'Are you sure you want to bet ${betAmount.value} \$WAGUS on ${selectedBet.value}?',
                              style: TextStyle(
                                  color: context.appColors.contrastDark),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color: context.appColors.contrastDark)),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Bet Placed',
                                            style: TextStyle(
                                                color: context
                                                    .appColors.contrastDark)),
                                        content: Text(
                                            'You have successfully placed a bet of ${betAmount.value} \$WAGUS on ${selectedBet.value}.',
                                            style: TextStyle(
                                                color: context
                                                    .appColors.contrastDark)),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'OK',
                                              style: TextStyle(
                                                  color: context
                                                      .appColors.contrastDark),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  'Confirm',
                                  style: TextStyle(
                                    color: context.appColors.contrastDark,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(Colors.blueAccent),
                    ),
                    child: Text(
                      'Place Bet',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BetOption extends StatelessWidget {
  final String label;
  final String odds;
  final bool isSelected;
  final VoidCallback onTap;

  const _BetOption({
    required this.label,
    required this.odds,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(odds),
          ],
        ),
      ),
    );
  }
}

class _BetAmountButton extends StatelessWidget {
  final int amount;
  final ValueNotifier<int> betAmount;

  const _BetAmountButton({
    required this.amount,
    required this.betAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          betAmount.value = amount;
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.blueAccent),
        ),
        child: Text(
          '\$$amount',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
