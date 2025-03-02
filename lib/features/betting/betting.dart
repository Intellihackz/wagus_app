import 'package:flutter/material.dart';

class Betting extends StatelessWidget {
  const Betting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset(
        'assets/background/betting_logo.png',
        height: 200,
        fit: BoxFit.cover,
      )),
    );
  }
}
