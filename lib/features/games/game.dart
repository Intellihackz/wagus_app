import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Scaffold(
          body: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Column(
                children: [
                  Text(
                    'Games',
                    style: TextStyle(
                      color: context.appColors.contrastLight,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        GameTile(
                          icon: FontAwesomeIcons.eye,
                          title: 'Spygus',
                          onTap: () {
                            final wallet = context
                                .read<PortalBloc>()
                                .state
                                .user!
                                .embeddedSolanaWallets
                                .first
                                .address;
                            context.push('$spygus/$wallet');
                          },
                        ),
                        GameTile(
                          icon: FontAwesomeIcons.skull,
                          title: 'Zombie Apocalypse',
                          onTap: () {},
                        ),
                        GameTile(
                          icon: FontAwesomeIcons.robot,
                          title: 'Battle Bots',
                          onTap: () {},
                        ),
                        GameTile(
                          icon: FontAwesomeIcons.puzzlePiece,
                          title: 'Guess the Drawing',
                          onTap: () {},
                        ),
                        GameTile(
                          icon: FontAwesomeIcons.egg,
                          title: 'WAGUS: The Origins',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class GameTile extends StatelessWidget {
  const GameTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppPalette.contrastLight,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: context.appColors.contrastLight,
            fontSize: 12.0,
          ),
        ),
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coming soon!'),
                    duration: const Duration(seconds: 1),
                  ),
                ),
      ),
    );
  }
}
