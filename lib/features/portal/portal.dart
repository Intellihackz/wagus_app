import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/theme/app_palette.dart';

class Portal extends StatelessWidget {
  const Portal({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    if (!PrivyService().isAuthenticated() && context.mounted) {
      context.go(login);
    }

    return RepositoryProvider(
      create: (context) => PortalRepository(),
      child: BlocBuilder<PortalBloc, PortalState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.appColors.contrastDark,
            body: Stack(
              children: [
                Image.asset(
                  'assets/icons/logo.png',
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final result =
                          await context.read<PortalRepository>().connect();

                      if (result != null && context.mounted) {
                        context.go(home);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.appColors.contrastLight,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '[ Connect Wallet ]',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.appColors.contrastLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
