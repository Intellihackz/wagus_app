import 'package:flutter/material.dart';

class Rewards extends StatelessWidget {
  const Rewards({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset(
        'assets/background/rewards_logo.png',
        height: 200,
        fit: BoxFit.cover,
      )),
    );
  }
}
