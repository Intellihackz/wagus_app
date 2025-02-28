import 'package:flutter/material.dart';
import 'package:wagus/theme/app_palette.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAGUS',
      theme: ThemeData(
        primaryColor: AppPalette.neonPurple, // Set primary color
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.neonPurple,
        ),
        extensions: <ThemeExtension<dynamic>>[
          AppColors(),
        ],
      ),
      home: const Scaffold(),
    );
  }
}
