import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/games/bloc/game_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      {
        'icon': FontAwesomeIcons.eye,
        'title': 'Spygus',
        'tagline': 'Find hidden symbols in mysterious scenes.',
        'route': spygus,
        'status': 'live',
      },
      {
        'icon': FontAwesomeIcons.skull,
        'title': 'Zombie Apocalypse',
        'tagline': 'Survive waves of the undead.',
        'status': 'coming',
      },
      {
        'icon': FontAwesomeIcons.robot,
        'title': 'Battle Bots',
        'tagline': 'Program your bot and battle others.',
        'status': 'coming',
      },
      {
        'icon': FontAwesomeIcons.puzzlePiece,
        'title': 'Guess the Drawing',
        'tagline': 'Draw and guess with friends.',
        'status': 'coming',
      },
      {
        'icon': FontAwesomeIcons.egg,
        'title': 'WAGUS: The Origins',
        'tagline': 'Uncover the origin story of WAGUS.',
        'status': 'coming',
      },
    ];

    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Padding(
            padding: const EdgeInsets.only(top: 64.0, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Games',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: games.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final isLive = game['status'] == 'live';

                      return InkWell(
                        onTap: () {
                          if (isLive) {
                            final wallet = context
                                .read<PortalBloc>()
                                .state
                                .user!
                                .embeddedSolanaWallets
                                .first
                                .address;
                            context.push('${game['route']}/$wallet');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coming soon!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            border: Border.all(
                              color:
                                  isLive ? Colors.greenAccent : Colors.white24,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(game['icon'] as IconData,
                                  size: 20, color: Colors.greenAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          game['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (!isLive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orangeAccent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Coming Soon',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      game['tagline'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
