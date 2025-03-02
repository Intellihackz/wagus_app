import 'package:flutter/material.dart';
import 'package:wagus/theme/app_palette.dart';

class Rewards extends StatelessWidget {
  const Rewards({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.deepMidnightBlue,
      body: Center(
          child: Image.asset(
        'assets/background/rewards_logo.png',
        height: 200,
      )),
    );
  }
}
