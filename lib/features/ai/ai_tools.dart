import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

class AITools extends StatelessWidget {
  const AITools({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.only(top: 64.0),
          child: Column(
            children: [
              Text(
                'AI Tools',
                style: TextStyle(
                  color: context.appColors.contrastLight,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 32.0),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    AITile(
                      icon: Icons.analytics,
                      title: 'AI Analysis Prediction',
                      onTap: () {
                        context.push(aiAnalysisPrediction);
                      },
                    ),
                    AITile(
                      icon: Icons.image,
                      title: 'AI Image Generation',
                      onTap: () {
                        context.push(aiImageGeneration);
                      },
                    ),
                    AITile(
                      icon: Icons.description,
                      title: 'AI White Paper Generator',
                      onTap: () {
                        context.push(aiWhitePaperGeneration);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AITile extends StatelessWidget {
  const AITile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppPalette.contrastLight,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: context.appColors.contrastLight,
          fontSize: 12.0,
        ),
      ),
      onTap: onTap,
    );
  }
}
