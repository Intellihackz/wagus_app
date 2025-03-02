import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

class Portal extends StatelessWidget {
  const Portal({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
        create: (context) => PortalRepository(),
        child: BlocBuilder<PortalBloc, PortalState>(
          builder: (context, state) {
            return Scaffold(
              body: Stack(
                children: [
                  Image.asset(
                    'assets/background/logo.png',
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
                      child: Text(
                        '[ Connect Wallet ]',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }
}
