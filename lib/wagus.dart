import 'dart:async';
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
import 'package:wagus/services/user_service.dart';
import 'package:wagus/theme/app_palette.dart';

final StreamController<bool> startupController =
    StreamController<bool>.broadcast();

class Wagus extends HookWidget {
  const Wagus({super.key});

  @override
  Widget build(BuildContext mainContext) {
    final currentPage = useState<int>(0);
    final lastPage = useState<int>(0);
    final pageController = usePageController();

    useEffect(() {
      final user = mainContext.read<PortalBloc>().state.user;
      final wallet = user?.embeddedSolanaWallets.firstOrNull?.address;
      Timer? ping;

      if (wallet != null) {
        ping = Timer.periodic(const Duration(seconds: 30), (_) {
          UserService().setUserOnline(wallet);
          debugPrint('🟢 Ping: $wallet online status refreshed');
        });
      }

      return () {
        ping?.cancel();
      };
    }, []);

    return Stack(
      fit: StackFit.expand,
      children: [
        BlocSelector<PortalBloc, PortalState, TierStatus>(
          selector: (state) {
            return state.tierStatus;
          },
          builder: (context, tierStatus) {
            final color = switch (tierStatus) {
              TierStatus.adventurer => TierStatus.adventurer.color,
              _ => TierStatus.basic.color,
            };

            return Positioned.fill(
              child:
                  CustomPaint(painter: CryptoBackgroundPainter(color: color)),
            );
          },
        ),
        BlocBuilder<PortalBloc, PortalState>(
          builder: (context, state) {
            final user = state.user;

            if (user == null) {
              startupController.add(true);

              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white10,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image(
                            image: AssetImage('assets/icon/icon_solana.png'),
                            height: 64,
                            width: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Connecting your wallet...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait a moment',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              startupController.add(false);
            }

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
                        alignment: Alignment.topCenter,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Holders: ${state.holdersCount}',
                                    style: TextStyle(
                                        color: context.appColors.contrastLight,
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
                                            color:
                                                context.appColors.contrastLight,
                                            fontSize: 12),
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                final user =
                                    context.read<PortalBloc>().state.user;
                                final wallet = user?.embeddedSolanaWallets
                                    .firstOrNull?.address;
                                if (wallet != null) {
                                  context.push('/profile/$wallet');
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                  right: 16.0,
                                ),
                                padding: const EdgeInsets.all(
                                    2.5), // border thickness
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: state.tierStatus ==
                                            TierStatus.adventurer
                                        ? TierStatus.adventurer.color
                                        : TierStatus.basic.color,
                                    width: 3, // thick border
                                  ),
                                ),
                                child: Hero(
                                  tag: 'profile',
                                  child: CircleAvatar(
                                    radius: 14, // small & modern
                                    backgroundImage:
                                        AssetImage('assets/icons/avatar.png'),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                      selectedLabelStyle: TextStyle(fontSize: 10),
                      unselectedLabelStyle: TextStyle(fontSize: 10),
                      landscapeLayout:
                          BottomNavigationBarLandscapeLayout.spread,
                      selectedItemColor: context.appColors.contrastLight,
                      unselectedItemColor: context.appColors.slightlyGrey,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(top: 24.0, bottom: 4),
                            child: Icon(FontAwesomeIcons.house),
                          ),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                              padding: EdgeInsets.only(top: 24.0, bottom: 4),
                              child: Icon(FontAwesomeIcons.rocket)),
                          label: 'Incubator',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                              padding: EdgeInsets.only(top: 24.0, bottom: 4),
                              child: Icon(FontAwesomeIcons.gamepad)),
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

  CryptoBackgroundPainter({required this.color});

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
