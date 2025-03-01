import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/portal.dart';
import 'package:wagus/wagus.dart';

final router = GoRouter(
  initialLocation: portal,
  routes: [
    GoRoute(
      path: home,
      builder: (context, state) => const Wagus(),
    ),
    GoRoute(
      path: portal,
      builder: (context, state) => Portal(),
    ),
  ],
);

const portal = '/portal';
const home = '/';
