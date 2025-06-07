import 'package:flutter/material.dart';

class ScrollToBottom extends StatelessWidget {
  const ScrollToBottom(
      {super.key,
      required this.showScrollToBottom,
      required this.scrollController});

  final ValueNotifier<bool> showScrollToBottom;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100, // Adjust to sit just above your input bar
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: showScrollToBottom.value ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: () {
              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_downward, color: Colors.black, size: 16),
                  SizedBox(width: 4),
                  Text('Scroll to Bottom',
                      style: TextStyle(color: Colors.black, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
