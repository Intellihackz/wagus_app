import 'package:flutter/material.dart';

class Lottery extends StatelessWidget {
  const Lottery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
          child:
              Image.asset('assets/background/lottery.png', fit: BoxFit.cover)),
    );
  }
}
