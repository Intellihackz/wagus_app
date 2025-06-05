import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/core/theme/app_palette.dart';

class GuessTheDrawingSessionList extends StatelessWidget {
  final String walletAddress;
  const GuessTheDrawingSessionList({super.key, required this.walletAddress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Join a Session'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // info icon to show game rules. show dialog explaining the game
          IconButton(
            icon: const Icon(FontAwesomeIcons.info, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Game Rules',
                        style: TextStyle(
                          color: context.appColors.contrastDark,
                        )),
                    content: Text(
                      'Guess the Drawing is a multiplayer game where one player draws a word and others try to guess it. '
                      'The drawer has 60 seconds to draw while others can submit guesses using the input box. '
                      'Correct guesses earn points, and the player with the most points at the end wins.',
                      style: TextStyle(
                        color: context.appColors.contrastDark,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Got it!'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-session',
        backgroundColor: Colors.blue,
        onPressed: () async {
          final sessionRef = FirebaseFirestore.instance
              .collection('guess_the_drawing_sessions')
              .doc();

          await sessionRef.set({
            'players': [],
            'lastSeen': {},
            'guesses': [],
            'scores': {},
            'round': 0,
            'word': '',
            'currentDrawerIndex': 0,
            'isComplete': false,
            'gameStarted': false,
            'drawer': walletAddress,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          context.push('/guess-the-drawing/$walletAddress/${sessionRef.id}');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Session'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('guess_the_drawing_sessions')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              int priority(DocumentSnapshot doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isComplete'] == true) return 2; // Completed
                if (data['gameStarted'] == true) return 1; // In-Game
                return 0; // Waiting
              }

              return priority(a).compareTo(priority(b));
            });

          if (sortedDocs.isEmpty) {
            return const Center(
              child: Text(
                'No sessions available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: sortedDocs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              final sessionId = sortedDocs[index].id;
              final players = List<String>.from(data['players'] ?? []);
              final isFull =
                  players.length >= 5 && !players.contains(walletAddress);

              return Card(
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.videogame_asset,
                          color: Colors.white70, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session ${sessionId.substring(0, 6)}...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${players.length} player${players.length == 1 ? '' : 's'} joined',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: data['isComplete'] == true
                                    ? Colors.green
                                    : data['gameStarted'] == true
                                        ? Colors.orange
                                        : Colors.grey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data['isComplete'] == true
                                    ? 'Completed'
                                    : data['gameStarted'] == true
                                        ? 'In Game'
                                        : 'Waiting',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            final bool isParticipant =
                                players.contains(walletAddress);
                            final bool canJoin =
                                !data['gameStarted'] && !data['isComplete'];

                            if (isParticipant || canJoin) {
                              context.push(
                                  '/guess-the-drawing/$walletAddress/$sessionId');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('You are not part of this game.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFull ? Colors.grey : Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isFull
                                ? 'Full'
                                : data['isComplete'] == true
                                    ? 'View Results'
                                    : 'Join',
                            style: const TextStyle(fontSize: 14),
                          )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
