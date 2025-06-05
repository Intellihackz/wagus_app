import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/logo.png',
                height: 200,
                fit: BoxFit.cover,
              ),
              const Text('Please update to continue',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  const androidUrl =
                      'https://play.google.com/store/apps/details?id=com.silnt.wagus';
                  const iosUrl =
                      'https://apps.apple.com/us/app/wagus/id6742799148';

                  final url = Platform.isIOS ? iosUrl : androidUrl;

                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
