import 'package:go_router/go_router.dart';
import 'package:wagus/features/auth/login_screen.dart';
import 'package:wagus/features/portal/portal.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/wagus.dart';

// Routes
const String login = '/login';
const String portal = '/portal';
const String home = '/home';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = PrivyService().isAuthenticated();

    // If the user is not authenticated and not on the login page, redirect to login
    if (!isAuthenticated && state.fullPath != login) {
      return login;
    }

    // If the user is authenticated and on the login page, redirect to portal
    if (isAuthenticated && state.fullPath == login) {
      return portal;
    }

    return null;
  },
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
  ],
);
