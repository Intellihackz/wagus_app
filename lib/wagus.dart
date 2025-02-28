import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Wagus extends HookWidget {
  const Wagus({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPage = useState<int>(0);
    final pageController = usePageController();

    return Scaffold(
      body: PageView(
        controller: pageController,
        children: const [
          Placeholder(color: Colors.red),
          Placeholder(color: Colors.green),
          Placeholder(color: Colors.blue),
          Placeholder(color: Colors.yellow),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentPage.value,
        onTap: (index) {
          currentPage.value = index;
          pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Betting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: 'Lottery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Rewards',
          ),
        ],
      ),
    );
  }
}
