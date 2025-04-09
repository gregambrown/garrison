import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_token.dart';

class LegacyService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveLegacy(String gameId, PlayerToken player, bool won) async {
    final userId = player.id;
    final ref = _db.collection('users').doc(userId).collection('legacy_games').doc(gameId);

    final data = {
      'gameId': gameId,
      'score': player.score,
      'roles': player.roles,
      'won': won,
      'zonesVisited': player.visitedZones,
      'goodChoices': player.goodChoices,
      'badChoices': player.badChoices,
      'history': player.history.map((e) => e.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await ref.set(data);
  }
}
