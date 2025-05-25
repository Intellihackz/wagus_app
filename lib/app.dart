import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/ai/data/ai_repository.dart';
import 'package:wagus/features/bank/bank.dart';
import 'package:wagus/features/bank/bloc/bank_bloc.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/games/data/game_repository.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/incubator/bloc/incubator_bloc.dart';
import 'package:wagus/features/incubator/data/incubator_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/features/quest/bloc/quest_bloc.dart';
import 'package:wagus/features/quest/data/quest_repository.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/wagus.dart';

class App extends HookWidget {
  final GoRouter router;
  const App({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final isDragging = useState(false);
    var xOffset = useState(154.5);
    var yOffset = useState(46.36);
    final previousLocation = useState<String?>(null);

    final homeRepository =
        useState<HomeRepository>(HomeRepository(useTestCollection: false));

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PortalRepository>(
          create: (_) => PortalRepository(),
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) => homeRepository.value,
        ),
        RepositoryProvider<AIRepository>(
          create: (_) => AIRepository(),
        ),
        RepositoryProvider<IncubatorRepository>(
          create: (_) => IncubatorRepository(),
        ),
        RepositoryProvider<BankRepository>(
          create: (_) => BankRepository(),
        ),
        RepositoryProvider<QuestRepository>(
          create: (_) => QuestRepository(
            homeRepository.value,
          ),
        ),
        RepositoryProvider<GameRepository>(
          create: (_) => GameRepository(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<HomeBloc>(
                  create: (_) => HomeBloc(
                        homeRepository: context.read<HomeRepository>(),
                        bankRepository: context.read<BankRepository>(),
                      )
                        ..add(HomeSetRoomEvent('General'))
                        ..add(HomeWatchOnlineUsersEvent())
                        ..add(HomeListenToRoomsEvent())
                        ..add(HomeListenToGiveawayEvent())),
              BlocProvider<PortalBloc>(
                create: (_) {
                  final bloc = PortalBloc(
                      portalRepository: context.read<PortalRepository>());
                  if (PrivyService().isAuthenticated()) {
                    bloc.add(PortalInitialEvent());
                    bloc.add(PortalListenSupportedTokensEvent());
                    bloc.add(PortalListenTokenAddressEvent());
                  }
                  return bloc;
                },
              ),
              BlocProvider<AiBloc>(
                create: (_) => AiBloc(
                  repository: context.read<AIRepository>(),
                ),
              ),
              BlocProvider<IncubatorBloc>(
                create: (_) => IncubatorBloc(
                  incubatorRepository: context.read<IncubatorRepository>(),
                  homeRepository: context.read<HomeRepository>(),
                ),
              ),
              BlocProvider<BankBloc>(
                create: (_) => BankBloc(
                  bankRepository: context.read<BankRepository>(),
                ),
              ),
              BlocProvider<QuestBloc>(
                create: (_) => QuestBloc(
                  questRepository: context.read<QuestRepository>(),
                ),
              ),
              BlocProvider<GameBloc>(
                create: (_) => GameBloc(
                  gameRepository: context.read<GameRepository>(),
                  homeRepository: context.read<HomeRepository>(),
                )..add(GameSpygusInitializeEvent()),
              ),
            ],
            child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'WAGUS',
                theme: ThemeData(
                  primaryColor: AppPalette.neonPurple,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppPalette.neonPurple,
                  ),
                  scaffoldBackgroundColor: Colors.transparent,
                  extensions: <ThemeExtension<dynamic>>[
                    AppColors(),
                  ],
                  textTheme: GoogleFonts.anonymousProTextTheme().apply(
                    bodyColor: AppPalette.contrastLight,
                    displayColor: AppPalette.contrastLight,
                    decorationColor: AppPalette.contrastLight,
                  ),
                ),
                routerConfig: router,
                builder: (context, child) {
                  final mediaQueryHeight = MediaQuery.sizeOf(context);
                  final mediaQueryPadding = MediaQuery.paddingOf(context);

                  return Overlay(
                    initialEntries: [
                      OverlayEntry(builder: (context) {
                        return StreamBuilder(
                            stream: startupController.stream,
                            builder: (context, startupSnapshot) {
                              return StreamBuilder<String?>(
                                  stream: locationControler.stream,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != '/bank') {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        previousLocation.value = snapshot.data;
                                      });
                                    }

                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        child!,
                                        Visibility(
                                          visible: snapshot.data != login &&
                                              snapshot.data != portal &&
                                              snapshot.data != '/bank' &&
                                              startupSnapshot.hasData &&
                                              !startupSnapshot.data!,
                                          child: Positioned(
                                              bottom: yOffset.value,
                                              right: xOffset.value,
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Draggable<
                                                    FloatingActionButton>(
                                                  onDragStarted: () =>
                                                      isDragging.value = true,
                                                  onDragEnd: (details) =>
                                                      isDragging.value = false,
                                                  onDragUpdate: (details) {
                                                    final newYOffset =
                                                        mediaQueryHeight
                                                                .height -
                                                            details
                                                                .localPosition
                                                                .dy -
                                                            24;

                                                    final newXOffset =
                                                        mediaQueryHeight.width -
                                                            details
                                                                .localPosition
                                                                .dx -
                                                            24;

                                                    yOffset.value =
                                                        newYOffset.clamp(
                                                            0,
                                                            mediaQueryHeight
                                                                    .height -
                                                                48 -
                                                                mediaQueryPadding
                                                                    .top);

                                                    xOffset.value =
                                                        newXOffset.clamp(
                                                            0,
                                                            mediaQueryHeight
                                                                    .width -
                                                                48 -
                                                                mediaQueryPadding
                                                                    .right);
                                                  },
                                                  feedback: SizedBox(
                                                    child: FloatingActionButton(
                                                      mini: true,
                                                      backgroundColor: context
                                                          .appColors
                                                          .contrastLight,
                                                      onPressed: null,
                                                      child: Image.asset(
                                                        'assets/icons/logo.png',
                                                        height: 32,
                                                        width: 32,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Visibility(
                                                    visible: !isDragging.value,
                                                    child: FloatingActionButton(
                                                      mini: true,
                                                      backgroundColor: context
                                                          .appColors
                                                          .contrastLight,
                                                      onPressed: () async {
                                                        locationControler
                                                            .add('/bank');
                                                        final portalBloc =
                                                            BlocProvider.of<
                                                                    PortalBloc>(
                                                                rootNavigatorKey
                                                                    .currentContext!,
                                                                listen: false);
                                                        final bankBloc =
                                                            BlocProvider.of<
                                                                    BankBloc>(
                                                                rootNavigatorKey
                                                                    .currentContext!,
                                                                listen: false);

                                                        await showModalBottomSheet(
                                                          backgroundColor:
                                                              context.appColors
                                                                  .contrastDark,
                                                          isScrollControlled:
                                                              true,
                                                          context: rootNavigatorKey
                                                              .currentContext!,
                                                          builder: (_) =>
                                                              BlocProvider<
                                                                  PortalBloc>.value(
                                                            value: portalBloc,
                                                            child: BlocProvider<
                                                                BankBloc>.value(
                                                              value: bankBloc,
                                                              child: Bank(
                                                                previousLocation:
                                                                    previousLocation
                                                                        .value,
                                                              ),
                                                            ),
                                                          ),
                                                        ).whenComplete(() {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .hideCurrentSnackBar();
                                                          }
                                                        });
                                                      },
                                                      child: Image.asset(
                                                        'assets/icons/logo.png',
                                                        height: 32,
                                                        width: 32,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )),
                                        ),
                                      ],
                                    );
                                  });
                            });
                      }),
                    ],
                  );
                }),
          );
        },
      ),
    );
  }
}
