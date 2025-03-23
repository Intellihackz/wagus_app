import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/ai/ai_tools.dart';
import 'package:wagus/features/bank/bank.dart';
import 'package:wagus/features/bank/bloc/bank_bloc.dart';
import 'package:wagus/features/home/home.dart';
import 'package:wagus/features/lottery/lottery.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/incubator/incubator.dart';
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

    useEffect(() {
      debugPrint('Current Page: ${currentPage.value}');
      debugPrint('Last Page: ${lastPage.value}');
      if (currentPage.value == 0 && lastPage.value != 0) {
        mainContext.read<PortalBloc>().add(PortalRefreshEvent());
        debugPrint('Refreshing Portal');
      }
      return null;
    }, [currentPage.value]);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: CryptoBackgroundPainter()),
        ),
        BlocBuilder<PortalBloc, PortalState>(
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
                    children: [
                      Home(),
                      Incubator(),
                      AITools(),
                      Lottery(),
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
                onPressed: () async {
                  final bankBloc =
                      BlocProvider.of<BankBloc>(mainContext, listen: false);
                  await showModalBottomSheet(
                    backgroundColor: context.appColors.contrastDark,
                    isScrollControlled: true,
                    context: mainContext,
                    builder: (_) => BlocProvider<BankBloc>.value(
                      value: bankBloc,
                      child: Bank(),
                    ),
                  ).whenComplete(() {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                  });
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
                      lastPage.value = currentPage.value;
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
                        // icon that best represnts incubator or launch pad or start up
                        icon: Icon(Icons.rocket_launch),
                        label: 'Incubator',
                      ),
                      BottomNavigationBarItem(
                        // icon that best represnts ai tools
                        icon: Icon(Icons.widgets),
                        label: 'AI Tools',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.casino),
                        label: 'Lottery',
                      ),
                    ],
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
