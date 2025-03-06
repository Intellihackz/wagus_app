import 'package:flutter/material.dart';
import 'package:wagus/theme/app_palette.dart';

class Rewards extends StatelessWidget {
  const Rewards({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Text('\$WAGUS Rewards Yielded:'),
                    Text('1247 \$WAGUS / 0.128 SOL'),
                    FilledButton(
                      onPressed: () {},
                      style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              context.appColors.contrastLight)),
                      child: Text('Claim',
                          style:
                              TextStyle(color: context.appColors.contrastDark)),
                    )
                  ],
                ),
              ),
            ),
            Image.asset(
              'assets/background/rewards_logo.png',
              height: 200,
              fit: BoxFit.cover,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 32.0, right: 32.0),
                child: Column(
                  spacing: 12.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('How it works')),
                    Text('1. The more you hold, the more you earn'),
                    Text('2. Earn rewards in real time'),
                    Text('3. Rewards are distributed every 5 minutes'),
                    Text('4. Rewards are in \$WAGUS'),
                    Text('5. Claim your rewards anytime'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
