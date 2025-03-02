import 'package:flutter/material.dart';

class Lottery extends StatelessWidget {
  const Lottery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset(
        'assets/background/lottery_logo.png',
        height: 200,
      )),
    );
  }
}
