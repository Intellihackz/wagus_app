import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/chat/bloc/chat_bloc.dart';
import 'package:wagus/features/home/chat/data/chat_repository.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (_) => HomeBloc(homeRepository: HomeRepository())
            ..add(HomeInitialEvent()),
        ),
        BlocProvider<PortalBloc>(
          create: (_) => PortalBloc(portalRepository: PortalRepository())
            ..add(PortalInitialEvent()),
        ),
        BlocProvider(
          create: (_) => ChatBloc(chatRepository: ChatRepository())
            ..add(ChatInitialEvent()),
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
          scaffoldBackgroundColor: AppPalette.contrastDark,
          extensions: <ThemeExtension<dynamic>>[
            AppColors(),
          ],
          textTheme: GoogleFonts.pressStart2pTextTheme(
            Theme.of(context).textTheme.apply(
                  bodyColor: AppPalette.contrastLight,
                  displayColor: AppPalette.contrastLight,
                ),
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
