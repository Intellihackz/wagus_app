import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/betting/betting.dart';
import 'package:wagus/features/home/home.dart';
import 'package:wagus/features/lottery/lottery.dart';
import 'package:wagus/features/rewards/rewards.dart';
import 'package:wagus/theme/app_palette.dart';

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
          Home(),
          Betting(),
          Lottery(),
          Rewards(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: context.appColors.deepMidnightBlue,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentPage.value,
        onTap: (index) {
          currentPage.value = index;
          pageController.jumpToPage(index);
        },
        selectedItemColor: context.appColors.contrastLight,
        unselectedItemColor: context.appColors.slightlyGrey,
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
