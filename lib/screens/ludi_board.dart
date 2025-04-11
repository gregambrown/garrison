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

  final Map<int, Map<String, dynamic>> tileConfig = {
    36: {'type': "Church", 'phase': "day"},
    40: {'type': "Babylon Station", 'phase': "day"},
    50: {'type': "MP Council", 'phase': "day"},
    51: {'type': "Hot Spot", 'phase': "both"},
    52: {'type': "Church", 'phase': "day"},
    53: {'type': "Babylon Station", 'phase': "day"},
    54: {'type': "Don HQ", 'phase': "night"},
    55: {'type': "Clinic", 'phase': "both"},
    56: {'type': "Court House", 'phase': "day"},
    57: {'type': "Peace Rally", 'phase': "day"},
    58: {'type': "Gun Salute", 'phase': "night"},
    72: {'type': "Hot Spot", 'phase': "both"},
    118: {'type': "Peace Rally", 'phase': "day"},
    147: {'type': "Gun Salute", 'phase': "night"},
    182: {'type': "Don HQ", 'phase': "night"},
    112: {'type': "Final Stage", 'phase': "both"},
  };

  final Map<String, String> tileEmojis = const {
    "MP Council": "🏛️",
    "Hot Spot": "🔥",
    "Church": "⛪",
    "Babylon Station": "🚔",
    "Don HQ": "👑",
    "Clinic": "🏥",
    "Court House": "⚖️",
    "Peace Rally": "🕊️",
    "Gun Salute": "🔫",
    "Final Stage": "🌟",
  };

  final Map<String, String> tileDescriptions = const {
    "MP Council": "🏛️ Council Office — Unlocks MP role when visited.",
    "Hot Spot": "🔥 Random chaos! You might gain or lose points.",
    "Church": "⛪ Visit here to unlock the JP role.",
    "Babylon Station": "🚔 Unlocks Babylon — police powers await.",
    "Don HQ": "👑 Become the Don and gain control.",
    "Clinic": "🏥 Heal yourself or reduce penalties (coming soon).",
    "Court House": "⚖️ Prepare for judgment. Role reveals may happen.",
    "Peace Rally": "🕊️ Good vibes. Bonus if you're peaceful.",
    "Gun Salute": "🔫 Risk zone! Might draw a violent choice card.",
    "Final Stage": "🌟 This is the center of the board. Game ends here.",
  };

  final List<int> spiralPath = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
    29, 44, 59, 74, 89, 104, 119, 134, 149, 164, 179, 194, 209, 224,
    223, 222, 221, 220, 219, 218, 217, 216, 215, 214, 213, 212, 211, 210,
    195, 180, 165, 150, 135, 120, 105, 90, 75, 60, 45, 30, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28,
    43, 58, 73, 88, 103, 118, 133, 148, 163, 178, 193, 208,
    207, 206, 205, 204, 203, 202, 201, 200, 199, 198, 197, 196,
    181, 166, 151, 136, 121, 106, 91, 76, 61, 46, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
    57, 72, 87, 102, 117, 132, 147, 162, 177, 192,
    191, 190, 189, 188, 187, 186, 185, 184, 183, 182,
    167, 152, 137, 122, 107, 92, 77, 62, 47,
    48, 49, 50, 51, 52, 53, 54, 55, 56,
    71, 86, 101, 116, 131, 146, 161, 176,
    175, 174, 173, 172, 171, 170, 169, 168,
    153, 138, 123, 108, 93, 78, 63,
    64, 65, 66, 67, 68, 69, 70,
    85, 100, 115, 130, 145, 160,
    159, 158, 157, 156, 155, 154,
    139, 124, 109, 94, 79,
    80, 81, 82, 83, 84,
    99, 114, 129, 144,
    143, 142, 141, 140,
    125, 110, 95,
    96, 97, 98,
    113, 128,
    127, 126,
    111, 112
  ];

  Color _getTileColor(int index, bool isSpiral, bool isOpen) {
    if (!isOpen) return Colors.grey.shade400;

    if (tileConfig.containsKey(index)) {
      final type = tileConfig[index]!['type'];
      switch (type) {
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
          return Colors.grey.shade500;
        case "Final Stage":
          return Colors.amber.shade800;
      }
    }

    // Spiral Path Zones
    if (isSpiral) {
      final i = spiralPath.indexOf(index);
      if (i < 60) return Colors.green.shade200;
      if (i < 120) return Colors.yellow.shade200;
      if (i < 180) return Colors.blue.shade200;
      return Colors.red.shade200;
    }

    return Colors.grey.shade300;
  }

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
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
                itemBuilder: (_, index) {
                  final row = index ~/ gridSize;
                  final col = index % gridSize;
                  final tileData = tileConfig[index];
                  final phase = tileData?['phase'] ?? 'both';
                  final label = tileData?['type'] ?? '';
                  final emoji = tileEmojis[label] ?? '';
                  final isSpiral = spiralPath.contains(index);
                  final isOpen = (phase == 'both') || (phase == 'day' && isDay) || (phase == 'night' && !isDay);

                  return GestureDetector(
                    onTap: () => onTileTap?.call(index),
                    onLongPress: () {
                      if (label.isNotEmpty) {
                        _showTileInfo(context, label, phase, isOpen);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: _getTileColor(index, isSpiral, isOpen),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
                    ),
                  );
                },
              ),

              ...tokens.map((token) {
                final index = token.position;
                final row = index ~/ gridSize;
                final col = index % gridSize;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
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
                          child: Text(token.id[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showTileInfo(BuildContext context, String title, String phase, bool isOpen) {
    final status = isOpen ? "✅ OPEN" : "❌ CLOSED";
    final time = (phase == 'both') ? 'All Times' : phase[0].toUpperCase() + phase.substring(1);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text("Active: $time | $status"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ]),
      ),
    );
  }
}
