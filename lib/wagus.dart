import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/betting/betting.dart';
import 'package:wagus/features/home/home.dart';
import 'package:wagus/features/lottery/lottery.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/features/rewards/rewards.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

class Wagus extends HookWidget {
  const Wagus({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPage = useState<int>(0);
    final pageController = usePageController();

    return RepositoryProvider(
      create: (context) => PortalRepository(),
      child: BlocBuilder<PortalBloc, PortalState>(
        builder: (context, state) {
          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                PageView(
                  controller: pageController,
                  children: const [
                    Home(),
                    Betting(),
                    Lottery(),
                    Rewards(),
                  ],
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () async {
                        final result =
                            await context.read<PortalRepository>().disconnect();

                        if (result != null && context.mounted) {
                          context.go(portal);
                        }
                      },
                      child: Text(
                        'Disconnect',
                        style:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                    ),
                  ),
                ),
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
              selectedLabelStyle: TextStyle(fontSize: 8),
              unselectedLabelStyle: TextStyle(fontSize: 8),
              landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
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
        },
      ),
    );
  }
}
