import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AIImageGeneration extends HookWidget {
  const AIImageGeneration({super.key});

  @override
  Widget build(BuildContext context) {
    final promptController = useTextEditingController();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 100.0, bottom: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            const Text(
              'AI Image Generation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: const Center(
                  child: Text('Generated Image will appear here'),
                ),
              ),
            ),
            TextField(
              controller: promptController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Enter your prompt here',
                border: OutlineInputBorder(),
              ),
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Handle image generation logic here
                final prompt = promptController.text;
                print('Generating image for prompt: $prompt');
              },
              child: const Text('Generate Image'),
            ),
          ],
        ),
      ),
    );
  }
}
