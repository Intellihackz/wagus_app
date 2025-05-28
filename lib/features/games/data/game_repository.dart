import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wagus/features/games/domain/guess_the_drawing/chat_message_entry.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/guess_entry.dart';
import 'package:wagus/features/games/domain/guess_the_drawing/guess_the_drawing_session.dart';
import 'package:wagus/features/games/domain/spygus_game_data.dart';

class GameRepository {
  final _spygusCollection = FirebaseFirestore.instance.collection('spygus');
  final _usersCollection = FirebaseFirestore.instance.collection('users');
  final _guessTheDrawingCollection =
      FirebaseFirestore.instance.collection('guess_the_drawing_sessions');
  final _storage = FirebaseStorage.instance;
  final Dio _dio = Dio();

  /// Get real-time updates of Spygus metadata
  Stream<SpygusGameData> getLatestSpygusInfo() {
    return _spygusCollection.limit(1).snapshots().map((snapshot) {
      final data = snapshot.docs.first.data();
      return SpygusGameData.fromFirestore(data);
    });
  }

  /// Get one-time fetch of Spygus metadata
  Future<SpygusGameData> fetchLatestSpygus() async {
    final snapshot = await _spygusCollection.limit(1).get();
    final data = snapshot.docs.first.data();
    return SpygusGameData.fromFirestore(data);
  }

  /// Get image URL from Firebase Storage
  Future<String> getImageUrl(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    return await ref.getDownloadURL();
  }

  /// Claim Spygus reward (calls server and updates Firestore)
  Future<void> claimSpygusReward(String userWallet) async {
    try {
      final response = await _dio.post(
        'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/claim-spygus',
        data: {
          'userWallet': userWallet,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['INTERNAL_API_KEY']}'
        }),
      );

      if (response.statusCode == 200) {
        // Mark as claimed in Firestore
        await _usersCollection.doc(userWallet).set({
          'spygus_claimed_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        throw Exception('Claim server returned error: ${response.data}');
      }
    } catch (e) {
      throw Exception('Spygus claim failed: $e');
    }
  }

  Future<bool> canClaimSpygusToday(String wallet) async {
    final userDoc = await _usersCollection.doc(wallet).get();
    final lastPlayed =
        (userDoc.data()?['spygus_claimed_at'] as Timestamp?)?.toDate();

    final serverTimeDoc = FirebaseFirestore.instance
        .collection('serverTime')
        .doc(wallet); // or use a generic 'now' doc

    await serverTimeDoc.set({'now': FieldValue.serverTimestamp()});
    final nowSnap = await serverTimeDoc.get();

    final serverNow = (nowSnap.data()?['now'] as Timestamp).toDate();

    if (lastPlayed == null) return true;

    final lastDate =
        DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
    final nowDate = DateTime(serverNow.year, serverNow.month, serverNow.day);

    return lastDate.isBefore(nowDate); // true = can claim
  }

  /// 🎮 Guess the Drawing: Create new session
  Future<void> createGuessDrawingSession(
      String sessionId, GuessTheDrawingSession session) {
    return _guessTheDrawingCollection.doc(sessionId).set(session.toMap());
  }

  /// 🧠 Guess the Drawing: Stream session
  Stream<GuessTheDrawingSession> streamGuessDrawingSession(String sessionId) {
    return _guessTheDrawingCollection
        .doc(sessionId)
        .snapshots()
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) {
      return GuessTheDrawingSession.fromFirestore(doc.id, doc.data()!);
    });
  }

  Stream<List<GuessTheDrawingSession>> streamAllSessions() {
    return _guessTheDrawingCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                GuessTheDrawingSession.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> sendChatMessage({
    required String sessionId,
    required ChatMessageEntry message,
  }) {
    return _guessTheDrawingCollection
        .doc(sessionId)
        .collection('chat_messages')
        .add(message.toMap());
  }

  Stream<List<ChatMessageEntry>> streamChatMessages(String sessionId) {
    return _guessTheDrawingCollection
        .doc(sessionId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessageEntry.fromMap(doc.data()))
            .toList());
  }

  /// 📝 Guess the Drawing: Submit a guess
  Future<bool> submitGuessToSession(
      String sessionId, GuessEntry entry, IO.Socket socket) async {
    final docRef = _guessTheDrawingCollection.doc(sessionId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return false;

    final currentSession =
        GuessTheDrawingSession.fromFirestore(sessionId, snapshot.data()!);

    // Prevent drawer from guessing
    if (entry.wallet == currentSession.drawer) return false;

    // If someone already guessed correctly, skip further processing
    final alreadyGuessedCorrectly = currentSession.guesses
        .any((g) => g.guess.toLowerCase() == currentSession.word.toLowerCase());

    if (alreadyGuessedCorrectly) return false;

    // Add guess to Firestore
    await docRef.update({
      'guesses': FieldValue.arrayUnion([entry.toMap()])
    });

    if (entry.guess.toLowerCase() == currentSession.word.toLowerCase()) {
      await awardPointToGuesser(
        sessionId: sessionId,
        currentSession: currentSession,
        wallet: entry.wallet,
      );

      socket.emit(
          'correct_guess', {'wallet': entry.wallet, 'sessionId': sessionId});

      return true;
    }

    return false;
  }

  /// 🔁 Guess the Drawing: Update full session
  Future<void> updateGuessDrawingSession(
      String sessionId, GuessTheDrawingSession session) {
    return _guessTheDrawingCollection.doc(sessionId).set(session.toMap());
  }

  Future<void> startGuessDrawingGame({
    required String sessionId,
    required List<String> playerWallets,
  }) async {
    final docRef = _guessTheDrawingCollection.doc(sessionId);
    final existing = await docRef.get();

    if (existing.exists) {
      final data = existing.data()!;
      if (data['gameStarted'] == true) {
        print('⛔ Game already started');
        return;
      }

      final existingPlayers = List<String>.from(data['players'] ?? []);
      final mergedPlayers = {...existingPlayers, ...playerWallets}.toList();

      await docRef.update({
        'players': mergedPlayers,
        'gameStarted': true,
        'round': 1,
        'word': pickWord(),
        'currentDrawerIndex': 0,
        'scores': {for (var w in mergedPlayers) w: 0},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final session = GuessTheDrawingSession(
        id: sessionId,
        players: playerWallets,
        scores: {for (var w in playerWallets) w: 0},
        round: 1,
        currentDrawerIndex: 0,
        word: pickWord(),
        guesses: [],
        isComplete: false,
        gameStarted: true,
      );

      final data = session.toMap()..['gameStarted'] = true;

      await docRef.set(data);
    }
  }

  Future<String> createNewGuessDrawingSession({required String wallet}) async {
    final docRef = _guessTheDrawingCollection.doc(); // auto-ID
    final sessionId = docRef.id;

    final session = GuessTheDrawingSession(
      id: sessionId,
      players: [wallet],
      scores: {wallet: 0},
      round: 0,
      currentDrawerIndex: 0,
      word: '',
      guesses: [],
      isComplete: false,
      gameStarted: false,
    );

    await docRef.set({
      ...session.toMap(),
      'drawer': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return sessionId;
  }

  /// Simple hardcoded word list for now
  String pickWord() {
    final words = ['apple', 'sun', 'car', 'house', 'tree', 'phone'];
    words.shuffle();
    return words.first;
  }

  /// 🏆 Award 1 point to the guesser
  Future<void> awardPointToGuesser({
    required String sessionId,
    required GuessTheDrawingSession currentSession,
    required String wallet,
  }) async {
    final updatedScores = Map<String, int>.from(currentSession.scores);
    updatedScores[wallet] = (updatedScores[wallet] ?? 0) + 1;

    final updatedSession = GuessTheDrawingSession(
      id: currentSession.id,
      players: currentSession.players,
      scores: updatedScores,
      round: currentSession.round,
      currentDrawerIndex: currentSession.currentDrawerIndex,
      word: currentSession.word,
      guesses: currentSession.guesses,
      isComplete: currentSession.isComplete,
      gameStarted: currentSession.gameStarted,
    );

    await updateGuessDrawingSession(sessionId, updatedSession);
  }
}
