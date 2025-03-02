import 'package:flutter/material.dart';
import 'package:wagus/theme/app_palette.dart';

class Betting extends StatelessWidget {
  const Betting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.deepMidnightBlue,
      body: Center(
          child: Image.asset(
        'assets/background/betting_logo.png',
        height: 200,
      )),
    );
  }
}
