import 'package:go_router/go_router.dart';
import 'package:wagus/features/ai/ai_tools/ai_tools.dart';
import 'package:wagus/features/auth/login_screen.dart';
import 'package:wagus/features/incubator/project_interface.dart';
import 'package:wagus/features/portal/portal.dart';
import 'package:wagus/wagus.dart';

// Routes
const String login = '/login';
const String portal = '/portal';
const String home = '/home';
const String aiImageGeneration = '/ai-image-generation';
const String aiAnalysisPrediction = '/ai-analysis-prediction';
const String aiWhitePaperGeneration = '/ai-whitepaper';
const String projectInterface = '/project-interface';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => login,
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
      path: projectInterface,
      builder: (context, state) => const ProjectInterface(),
    ),
  ],
);
