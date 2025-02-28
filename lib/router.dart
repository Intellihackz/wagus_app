import 'package:go_router/go_router.dart';
import 'package:wagus/wagus.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Wagus(),
    ),
  ],
);
