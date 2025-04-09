import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_token.dart';
import '../screens/ludi_board.dart';
import 'firebase_service.dart';

class RoomService {
  final _games = FirebaseFirestore.instance.collection('games');
  final userId = FirebaseService.currentUserId;

  Future<String> createRoom(String hostId, PlayerToken hostToken) async {
    final docRef = _games.doc();
    if (userId == null) throw Exception("User not logged in");
    await docRef.set({
      'createdBy': hostId,
      'started': false,
      'phase': 'day',
      'currentTurnIndex': 0,
      'tokens': [
        hostToken.toMap(),
      ],
      'votes': {},
      'hasVoted': {},
    });
    return docRef.id;
  }

  Future<void> joinRoom(String gameId, PlayerToken token) async {
    final ref = _games.doc(gameId);
    await ref.update({
      'tokens': FieldValue.arrayUnion([token.toMap()])
    });
  }

  Stream<DocumentSnapshot> listenToRoom(String gameId) {
    return _games.doc(gameId).snapshots();
  }

  Future<void> updateTokens(String gameId, List<PlayerToken> tokens) async {
    await _games.doc(gameId).update({
      'tokens': tokens.map((t) => t.toMap()).toList()
    });
  }

  Future<void> updateGameState(String gameId, Map<String, dynamic> data) async {
    await _games.doc(gameId).update(data);
  }

  Future<void> castVote(String gameId, String targetId, String voterId) async {
    final gameRef = _games.doc(gameId);
    final snapshot = await gameRef.get();

    Map<String, dynamic> votes = Map<String, dynamic>.from(snapshot['votes']);
    Map<String, dynamic> hasVoted = Map<String, dynamic>.from(snapshot['hasVoted']);

    votes[targetId] = (votes[targetId] ?? 0) + 1;
    hasVoted[voterId] = true;

    await gameRef.update({
      'votes': votes,
      'hasVoted': hasVoted,
    });
  }
}
