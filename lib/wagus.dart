import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/ai/ai_tools.dart';
import 'package:wagus/features/games/game.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/home.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/incubator/incubator.dart';
import 'package:wagus/features/quest/presentation/quest.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/services/privy_service.dart';

class Wagus extends HookWidget {
  const Wagus({super.key});

  @override
  Widget build(BuildContext mainContext) {
    final currentPage = useState<int>(0);
    final lastPage = useState<int>(0);
    final pageController = usePageController();

    // useEffect(() {
    //   debugPrint('Current Page: ${currentPage.value}');
    //   debugPrint('Last Page: ${lastPage.value}');
    //   if (currentPage.value == 0 && lastPage.value != 0) {
    //     mainContext.read<PortalBloc>().add(PortalRefreshEvent());
    //     debugPrint('Refreshing Portal');
    //   }
    //   return null;
    // }, [currentPage.value]);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: CryptoBackgroundPainter()),
        ),
        BlocBuilder<PortalBloc, PortalState>(
          builder: (context, state) {
            return SafeArea(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
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
                      children: [
                        Home(),
                        Incubator(),
                        Game(), // Placeholder for the game page
                        AITools(),
                        Quest(),
                      ],
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: SizedBox(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Holders: ${state.holdersCount}',
                                      style: TextStyle(
                                          color:
                                              context.appColors.contrastLight,
                                          fontSize: 12),
                                    ),
                                    BlocSelector<HomeBloc, HomeState, int>(
                                      selector: (state) {
                                        return state.activeUsersCount;
                                      },
                                      builder: (context, userCount) {
                                        return Text(
                                          'Active Online: $userCount',
                                          style: TextStyle(
                                              color: context
                                                  .appColors.contrastLight,
                                              fontSize: 12),
                                        );
                                      },
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final result =
                                      await PrivyService().logout(context);

                                  if (result && context.mounted) {
                                    context.go(login);
                                  }
                                },
                                icon: Icon(
                                  Icons.logout,
                                  color: context.appColors.contrastLight,
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
                        lastPage.value = currentPage.value;
                        currentPage.value = index;
                        pageController.jumpToPage(index);
                      },
                      selectedLabelStyle: TextStyle(fontSize: 8),
                      unselectedLabelStyle: TextStyle(fontSize: 8),
                      landscapeLayout:
                          BottomNavigationBarLandscapeLayout.spread,
                      selectedItemColor: context.appColors.contrastLight,
                      unselectedItemColor: context.appColors.slightlyGrey,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(top: 24.0, bottom: 4),
                            child: Icon(Icons.home),
                          ),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                              padding: EdgeInsets.only(top: 24.0, bottom: 4),
                              child: Icon(Icons.rocket_launch)),
                          label: 'Incubator',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                              padding: EdgeInsets.only(top: 24.0, bottom: 4),
                              child: Icon(Icons.gamepad)),
                          label: 'Games',
                        ),
                        BottomNavigationBarItem(
                          // icon that best represnts ai tools
                          icon: Padding(
                              padding: EdgeInsets.only(top: 24.0, bottom: 4),
                              child: Icon(Icons.widgets)),
                          label: 'AI Tools',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(top: 24.0, bottom: 4),
                            child: Icon(FontAwesomeIcons.listCheck),
                          ),
                          label: 'Quests', // Name it whatever
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class CryptoBackgroundPainter extends CustomPainter {
  final Color color;
  static const double symbolSize = 30.0; // Size of crypto symbols

  CryptoBackgroundPainter({this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3) // Slightly faded for subtle effect
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final random = Random();
    final List<Offset> symbolPositions = [];

    // Generate random positions for crypto symbols
    for (int i = 0; i < 10; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      symbolPositions.add(Offset(x, y));
    }

    // Draw crypto symbols at those positions
    for (final position in symbolPositions) {
      _drawCryptoSymbol(canvas, paint, position.dx, position.dy, symbolSize);
    }
  }

  // Function to draw a simplified crypto symbol (Bitcoin / Ethereum / Circuit)
  void _drawCryptoSymbol(
      Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();

    // Randomly pick a crypto design
    int design = Random().nextInt(3);

    if (design == 0) {
      // Bitcoin symbol (B inside a circle)
      canvas.drawCircle(Offset(x, y), size / 2, paint);
      path.moveTo(x - size / 4, y - size / 4);
      path.lineTo(x + size / 4, y + size / 4);
      path.moveTo(x + size / 4, y - size / 4);
      path.lineTo(x - size / 4, y + size / 4);
      canvas.drawPath(path, paint);
    } else if (design == 1) {
      // Ethereum Symbol (Diamond shape)
      path.moveTo(x, y - size / 2);
      path.lineTo(x - size / 2, y);
      path.lineTo(x, y + size / 2);
      path.lineTo(x + size / 2, y);
      path.close();
      canvas.drawPath(path, paint);
    } else {
      // Circuit-like design (Techy feel)
      canvas.drawCircle(Offset(x, y), size / 3, paint);
      canvas.drawLine(Offset(x, y - size / 2), Offset(x, y + size / 2), paint);
      canvas.drawLine(Offset(x - size / 2, y), Offset(x + size / 2, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
