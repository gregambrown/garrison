import 'package:flutter/material.dart';
import '../models/player_token.dart';
import '../services/room_service.dart';

class GameDashboardScreen extends StatelessWidget {
  final String gameId;
  final List<PlayerToken> players;
  final int currentTurn;
  final String phase;

  const GameDashboardScreen({
    super.key,
    required this.gameId,
    required this.players,
    required this.currentTurn,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final alive = players.where((p) => !p.isEliminated).toList();
    final eliminated = players.where((p) => p.isEliminated).toList();
    final sortedPlayers = List<PlayerToken>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(title: const Text("Garrison Game Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("🔄 Phase: ${phase.toUpperCase()}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("🎯 Current Turn: ${players[currentTurn].id.toUpperCase()}"),
            const Divider(),

            Text("🏅 Leaderboard", style: Theme.of(context).textTheme.titleMedium),
            ...sortedPlayers.map((p) => ListTile(
              title: Text(p.id.toUpperCase()),
              subtitle: Text("Score: ${p.score}"),
              trailing: Text(p.roles.join(', ') + (p.evolvedRole != null ? ' → ${p.evolvedRole}' : '')),
              leading: CircleAvatar(backgroundColor: p.color),
            )),

            const Divider(),

            Text("☠️ Eliminated Players", style: Theme.of(context).textTheme.titleMedium),
            ...eliminated.map((p) => ListTile(
              title: Text(p.id.toUpperCase(), style: const TextStyle(color: Colors.red)),
              subtitle: Text("Role: ${p.roles.join(', ')}"),
              trailing: const Icon(Icons.block, color: Colors.red),
            )),
          ],
        ),
      ),
    );
  }
}
