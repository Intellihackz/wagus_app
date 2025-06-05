import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/ai/ai_tools/ai_roadmap.dart';
import 'package:wagus/features/ai/ai_tools/ai_tokenomics.dart';
import 'package:wagus/features/ai/ai_tools/ai_tools.dart';
import 'package:wagus/features/auth/login_screen.dart';
import 'package:wagus/features/games/presentation/widgets/code_navigator.dart';
import 'package:wagus/features/games/presentation/widgets/guess_the_drawing.dart';
import 'package:wagus/features/games/presentation/widgets/guess_the_drawing_session_list.dart';
import 'package:wagus/features/games/presentation/widgets/memory_breach.dart';
import 'package:wagus/features/games/presentation/widgets/spygus.dart';
import 'package:wagus/features/incubator/project_interface.dart';
import 'package:wagus/features/portal/portal.dart';
import 'package:wagus/features/profile/presentation/profile.dart';
import 'package:wagus/presentation/splash_screen.dart';
import 'package:wagus/presentation/wagus.dart';

const String login = '/login';
const String portal = '/portal';
const String home = '/home';
const String spygus = '/spygus';
const String memoryBreach = '/memory-breach';
const String codeNavigator = '/code-navigator';
const String guessTheDrawing = '/guess-the-drawing';
const String aiImageGeneration = '/ai-image-generation';
const String aiAnalysisPrediction = '/ai-analysis-prediction';
const String aiWhitePaperGeneration = '/ai-whitepaper';
const String aiTokenomicsGeneration = '/ai-tokenomics';
const String aiRoadmapGeneration = '/ai-roadmap';
const String projectInterface = '/project-interface';
const String profile = '/profile';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final StreamController<String?> locationControler =
    StreamController<String?>.broadcast();

final StreamController<String?> previousLocationControler =
    StreamController<String?>.broadcast();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '',
  redirect: (_, state) async {
    final location = state.fullPath;

    locationControler.add(location);

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: portal,
      builder: (context, state) => const Portal(),
    ),
    GoRoute(
      path: home,
      builder: (context, state) => const Wagus(),
    ),
    GoRoute(
      path: '$spygus/:walletAddress',
      builder: (context, state) {
        final walletAddress = state.pathParameters['walletAddress']!;
        return Spygus(walletAddress: walletAddress);
      },
    ),
    GoRoute(
      path: '$guessTheDrawing/sessions/:walletAddress',
      builder: (context, state) {
        final walletAddress = state.pathParameters['walletAddress']!;
        return GuessTheDrawingSessionList(walletAddress: walletAddress);
      },
    ),
    GoRoute(
      path: '$guessTheDrawing/:walletAddress/:sessionId',
      builder: (context, state) {
        final walletAddress = state.pathParameters['walletAddress']!;
        final sessionId = state.pathParameters['sessionId']!;
        return GuessTheDrawing(address: walletAddress, sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '$guessTheDrawing/:walletAddress',
      builder: (context, state) {
        final walletAddress = state.pathParameters['walletAddress']!;
        return GuessTheDrawingSessionList(walletAddress: walletAddress);
      },
    ),
    GoRoute(
      path: '$memoryBreach/:walletAddress',
      builder: (context, state) {
        final walletAddress = state.pathParameters['walletAddress']!;
        return MemoryBreach(walletAddress: walletAddress);
      },
    ),
    GoRoute(
      path: '$codeNavigator/:walletAddress',
      builder: (context, state) {
        final walletAddress = state.pathParameters['walletAddress'];
        if (walletAddress == null) {
          return const Center(child: Text('Wallet address is required'));
        }
        return CodeNavigator(walletAddress: walletAddress);
      },
    ),
    GoRoute(
      path: aiImageGeneration,
      builder: (context, state) => const AIImageGeneration(),
    ),
    GoRoute(
      path: aiAnalysisPrediction,
      builder: (context, state) => const AIAnalysisPrediction(),
    ),
    GoRoute(
      path: aiWhitePaperGeneration,
      builder: (context, state) => const AiWhitePaperGenerator(),
    ),
    GoRoute(
      path: aiRoadmapGeneration,
      builder: (context, state) => const AiRoadmapGenerator(),
    ),
    GoRoute(
      path: aiTokenomicsGeneration,
      builder: (context, state) => const AiTokenomicsGenerator(),
    ),
    GoRoute(
      path: projectInterface,
      builder: (context, state) => const ProjectInterface(),
    ),
    GoRoute(
      path: '/profile/:address',
      builder: (context, state) {
        final address = state.pathParameters['address']!;
        return ProfileScreen(address: address);
      },
    ),
  ],
);
