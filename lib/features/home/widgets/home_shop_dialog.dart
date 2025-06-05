import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/core/theme/app_palette.dart';

class HomeShopDialog extends HookWidget {
  final Future<void> Function(String tier, int cost) onPurchase;

  const HomeShopDialog({super.key, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading.value)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  Text('Upgrade your tier!',
                      style: TextStyle(color: context.appColors.contrastDark)),
                  const SizedBox(height: 16),
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      isLoading.value = true;
                      try {
                        // Example: Adventure tier and cost 1000
                        await onPurchase('Adventurer', 1000);

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase successful!')),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      } finally {
                        isLoading.value = false;
                      }
                    },
                    child: const Text('Buy Adventure Tier (1000)'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      isLoading.value = true;
                      try {
                        // Example: Explorer tier and cost 2000
                        await onPurchase('Explorer', 5000);

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase successful!')),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      } finally {
                        isLoading.value = false;
                      }
                    },
                    child: const Text('Buy Elite Tier (5000)'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close',
                  style: TextStyle(color: context.appColors.contrastDark)),
            ),
          ],
        ),
      ),
    );
  }
}
