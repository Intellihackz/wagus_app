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
import 'package:wagus/services/privy_service.dart';

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
                  onPageChanged: (currentIndex) {
                    currentPage.value = currentIndex;
                  },
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
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Holders: ${state.holdersCount}',
                              style: TextStyle(
                                  color: context.appColors.contrastLight),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final result = await PrivyService().logout();

                              if (result && context.mounted) {
                                context.go(login);
                              }
                            },
                            child: Text(
                              'Disconnect',
                              style: TextStyle(
                                  color: context.appColors.contrastLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                backgroundColor: context.appColors.contrastDark,
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
            ),
          );
        },
      ),
    );
  }
}
