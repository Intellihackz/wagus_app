import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/ai/data/ai_repository.dart';
import 'package:wagus/features/bank/bloc/bank_bloc.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/incubator/bloc/incubator_bloc.dart';
import 'package:wagus/features/incubator/data/incubator_repository.dart';
import 'package:wagus/features/lottery/bloc/lottery_bloc.dart';
import 'package:wagus/features/lottery/data/lottery_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PortalRepository>(
          create: (_) => PortalRepository(),
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) => HomeRepository(),
        ),
        RepositoryProvider<LotteryRepository>(
          create: (_) => LotteryRepository(),
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
      ],
      child: Builder(
        builder: (context) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<HomeBloc>(
                create: (_) => HomeBloc(
                  homeRepository: context.read<HomeRepository>(),
                )..add(HomeInitialEvent()),
              ),
              BlocProvider<PortalBloc>(
                create: (_) => PortalBloc(
                  portalRepository: context.read<PortalRepository>(),
                )..add(PortalInitialEvent()),
              ),
              BlocProvider<LotteryBloc>(
                create: (_) => LotteryBloc(
                  lotteryRepository: context.read<LotteryRepository>(),
                )..add(LotteryInitialEvent()),
              ),
              BlocProvider<AiBloc>(
                create: (_) => AiBloc(
                  repository: context.read<AIRepository>(),
                ),
              ),
              BlocProvider<IncubatorBloc>(
                create: (_) => IncubatorBloc(
                  incubatorRepository: context.read<IncubatorRepository>(),
                ),
              ),
              BlocProvider<BankBloc>(
                create: (_) => BankBloc(
                  bankRepository: context.read<BankRepository>(),
                ),
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
                textTheme: GoogleFonts.pressStart2pTextTheme().apply(
                  bodyColor: AppPalette.contrastLight,
                  displayColor: AppPalette.contrastLight,
                  decorationColor: AppPalette.contrastLight,
                ),
              ),
              routerConfig: appRouter,
            ),
          );
        },
      ),
    );
  }
}
