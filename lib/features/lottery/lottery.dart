import 'package:flutter/material.dart';
import 'package:wagus/theme/app_palette.dart';

class Lottery extends StatelessWidget {
  const Lottery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.deepMidnightBlue,
      body: Center(
          child: Image.asset(
        'assets/background/lottery_logo.png',
        height: 200,
      )),
    );
  }
}
