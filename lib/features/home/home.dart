import 'package:flutter/material.dart';
import 'package:wagus/theme/app_palette.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.deepMidnightBlue,
      body: Center(child: Image.asset('assets/background/image.png')),
    );
  }
}
