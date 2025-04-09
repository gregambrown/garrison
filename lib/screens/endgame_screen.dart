import 'package:flutter/material.dart';
import '../models/player_token.dart';

class EndGameScreen extends StatelessWidget {
  final List<PlayerToken> players;
  final String winnerId;

  const EndGameScreen({
    super.key,
    required this.players,
    required this.winnerId,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...players]..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: const Text("🏁 Garrison Results"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "${winnerId.toUpperCase()} Wins!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final p = sorted[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p.color,
                      child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(p.displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Role(s): ${p.roles.join(', ')}"),
                        Text("Score: ${p.score} pts"),
                        Text("Good: ${p.goodChoices} | Bad: ${p.badChoices}"),
                        Text("Zones: ${p.visitedZones.length} visited"),
                      ],
                    ),
                    trailing: Text(_getTitle(p, winnerId), style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.replay),
                  onPressed: () => Navigator.pop(context), // Or resetGame()
                  label: const Text("Rematch"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  label: const Text("Exit to Lobby"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _getTitle(PlayerToken p, String winnerId) {
    if (p.id == winnerId) return "🏆 Top Dawg";
    if (p.roles.contains("Don")) return "🎭 Garrison Boss";
    if (p.roles.contains("JP")) return "🙏 Bless Up";
    if (p.badChoices > p.goodChoices) return "💀 Corrupt";
    if (p.goodChoices > p.badChoices) return "🧼 Clean Youth";
    return "🎲 Survivor";
  }
}
