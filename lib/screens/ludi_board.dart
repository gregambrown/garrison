import 'package:flutter/material.dart';
import '../models/player_token.dart';

class LudiBoard extends StatelessWidget {
  final List<PlayerToken> tokens;
  final int gridSize;
  final bool isDay;
  final void Function(int index)? onTileTap;

  LudiBoard({
    super.key,
    required this.tokens,
    required this.isDay,
    this.gridSize = 15,
    this.onTileTap,
  });

  final List<int> movementPath = [
    6, 7, 8, 9, 10, 11, 12,
    27, 42, 57,
    72, 73, 74, 75, 76, 77, 78,
    93, 108, 123,
    138, 137, 136, 135, 134, 133, 132,
    117, 102, 87,
    72, 71, 70, 69, 68, 67, 66
  ];

  final List<int> legacyTiles = [112, 113, 114, 127, 128, 129, 142, 143, 144];

  final Map<int, Map<String, dynamic>> tileConfig = {
    50: {'type': "MP Council", 'phase': "day"},
    51: {'type': "Hot Spot", 'phase': "both"},
    52: {'type': "Church", 'phase': "day"},
    53: {'type': "Babylon Station", 'phase': "day"},
    54: {'type': "Don HQ", 'phase': "night"},
    55: {'type': "Clinic", 'phase': "both"},
    56: {'type': "Court House", 'phase': "day"},
    57: {'type': "Peace Rally", 'phase': "day"},
    58: {'type': "Gun Salute", 'phase': "night"},
    112: {'type': "Legacy", 'phase': "both"},
  };

  final Map<String, String> tileEmojis = const {
    "Crossroads": "✴️",
    "MP Council": "🏛️",
    "Hot Spot": "🔥",
    "Church": "⛪",
    "Babylon Station": "🚔",
    "Don HQ": "👑",
    "Clinic": "🏥",
    "Court House": "⚖️",
    "Peace Rally": "🕊️",
    "Gun Salute": "🔫",
    "Legacy": "🌟",
  };

  final Map<String, String> tileDescriptions = const {
    "Crossroads": "The common starting point for all. Nothing happens here.",
    "MP Council": "🏛️ Council Office — Unlocks MP role when visited.",
    "Hot Spot": "🔥 Random chaos! You might gain or lose points.",
    "Church": "⛪ Visit here to unlock the JP role.",
    "Babylon Station": "🚔 Unlocks Babylon — police powers await.",
    "Don HQ": "👑 Become the Don and gain control.",
    "Clinic": "🏥 Heal yourself or reduce penalties (coming soon).",
    "Court House": "⚖️ Prepare for judgment. Role reveals may happen.",
    "Peace Rally": "🕊️ Good vibes. Bonus if you're peaceful.",
    "Gun Salute": "🔫 Risk zone! Might draw a violent choice card.",
    "Legacy": "🌟 Triggers endgame once a player reaches here.",
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.width;
          final tileSize = size / gridSize;

          return Stack(
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridSize * gridSize,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                ),
                itemBuilder: (_, index) {
                  final row = index ~/ gridSize;
                  final col = index % gridSize;

                  String label = '';
                  if (legacyTiles.contains(index)) {
                    label = "Legacy";
                  } else if (tileConfig.containsKey(index)) {
                    label = tileConfig[index]!['type'];
                  }

                  final phase = tileConfig[index]?['phase'] ?? 'both';
                  final isOpen = (phase == 'both') || (phase == 'day' && isDay) || (phase == 'night' && !isDay);

                  final emoji = tileEmojis[label] ?? '';
                  final isPath = movementPath.contains(index);

                  return GestureDetector(
                    onTap: () => onTileTap?.call(index),
                    onLongPress: () {
                      if (label.isNotEmpty) {
                        _showTileInfo(
                          context,
                          label,
                          tileDescriptions[label] ?? "No info available.",
                          phase,
                          isOpen,
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: _getTileColor(index, label, isPath, isDark, isOpen, row, col),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Tokens
              ...tokens.map((token) {
                final index = token.position;
                final row = index ~/ gridSize;
                final col = index % gridSize;

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  top: row * tileSize,
                  left: col * tileSize,
                  child: Opacity(
                    opacity: token.isEliminated ? 0.3 : 1.0,
                    child: SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: Center(
                        child: CircleAvatar(
                          radius: tileSize * 0.3,
                          backgroundColor: token.color,
                          child: Text(
                            token.id[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Color _getTileColor(int index, String zone, bool isPath, bool isDark, bool isOpen, int row, int col) {
    if (!isOpen) return Colors.grey.shade400;
    if (legacyTiles.contains(index)) return Colors.amber.shade800;
    if (row < 6 && col < 6) return Colors.green.shade300;
    if (row < 6 && col > 8) return Colors.yellow.shade300;
    if (row > 8 && col < 6) return Colors.red.shade300;
    if (row > 8 && col > 8) return Colors.blue.shade300;
    if (isPath) return Colors.white;

    switch (zone) {
      case "Hot Spot":
        return Colors.red.shade300;
      case "MP Council":
        return Colors.orange.shade300;
      case "Church":
        return Colors.purple.shade200;
      case "Babylon Station":
        return Colors.blue.shade300;
      case "Don HQ":
        return Colors.black;
      case "Peace Rally":
        return Colors.green.shade200;
      case "Gun Salute":
        return Colors.brown.shade400;
      case "Clinic":
        return Colors.teal.shade300;
      case "Court House":
        return Colors.grey.shade400;
    }

    return isDark ? Colors.grey[850]! : Colors.grey.shade200;
  }

  void _showTileInfo(BuildContext context, String title, String description, String phase, bool isOpen) {
    final status = isOpen ? "✅ OPEN" : "❌ CLOSED";
    final time = (phase == 'both') ? 'All Times' : phase[0].toUpperCase() + phase.substring(1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Text("Active: $time | $status"),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}
