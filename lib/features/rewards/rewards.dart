import 'package:flutter/material.dart';

class Rewards extends StatelessWidget {
  const Rewards({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
          child:
              Image.asset('assets/background/rewards.png', fit: BoxFit.cover)),
    );
  }
}
