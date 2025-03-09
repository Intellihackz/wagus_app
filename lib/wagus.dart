import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/ai/ai.dart';
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
    final lastPage = useState<int>(0);
    final pageController = usePageController();

    // Handle page change and actions based on current page
    useEffect(() {
      debugPrint('Current Page: ${currentPage.value}');
      debugPrint('Last Page: ${lastPage.value}');
      if (currentPage.value == 0 && lastPage.value != 0) {
        context.read<PortalBloc>().add(PortalRefreshEvent());
        debugPrint('Refreshing Portal');
      }
      return null;
    }, [currentPage.value]);

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
                    // Only update lastPage when swiping
                    if (currentPage.value != currentIndex) {
                      lastPage.value = currentPage.value;
                      currentPage.value = currentIndex;
                    }
                  },
                  children: const [
                    Home(),
                    AI(),
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
            floatingActionButton: FloatingActionButton(
              mini: true,
              backgroundColor: context.appColors.contrastLight,
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return Container(
                      color: Colors.red,
                    );
                  },
                );
              },
              child: Image.asset(
                'assets/icons/logo.png',
                height: 32,
                width: 32,
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: context.appColors.contrastDark,
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.contrastLight
                          .withValues(alpha: 0.4),
                      blurRadius: 2,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  backgroundColor: context.appColors.contrastDark,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: currentPage.value,
                  onTap: (index) {
                    // Update lastPage only after the page has been changed
                    lastPage.value = currentPage
                        .value; // Update lastPage after page transition
                    currentPage.value = index; // Update currentPage
                    pageController
                        .jumpToPage(index); // Navigate to the selected page
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
                      icon: Icon(Icons.analytics),
                      label: 'Analysis',
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
            ),
          );
        },
      ),
    );
  }
}
