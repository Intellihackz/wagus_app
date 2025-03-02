import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/chat/bloc/chat_bloc.dart';
import 'package:wagus/features/home/chat/data/chat_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/firebase_options.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (_) => HomeBloc(),
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
          extensions: <ThemeExtension<dynamic>>[
            AppColors(),
          ],
          textTheme: GoogleFonts.pressStart2pTextTheme(),
        ),
        routerConfig: router,
      ),
    );
  }
}
