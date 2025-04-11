// single_player_game_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/abilities.dart';
import '../models/player_token.dart';
import '../models/choice_card.dart';
import '../models/choice_record.dart';
import '../services/choice_card_service.dart';
import 'ludi_board.dart';

class SinglePlayerGameScreen extends StatefulWidget {
  final PlayerToken player;

  const SinglePlayerGameScreen({super.key, required this.player});

  @override
  State<SinglePlayerGameScreen> createState() => _SinglePlayerGameScreenState();
}

class _SinglePlayerGameScreenState extends State<SinglePlayerGameScreen> {
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
    111, 112 // Center
  ];
  final Map<int, String> tileRoleMap = {
    // 🔶 YELLOW ZONE (Civic / Council)
    50: "MP",           // MP Council
    56: "MP",           // Court House (Alternate civic access)

    // 🔷 BLUE ZONE (Law / Order)
    53: "Babylon",      // Babylon Station
    40: "Babylon",      // Patrol Point (Backup station)

    // 🟣 PURPLE ZONE (Faith / Community)
    52: "JP",           // Church
    36: "JP",           // Mission Hall

    // 🔴 RED ZONE (Underworld)
    54: "Don",          // Don HQ
    182: "Don",         // Alley Back (gang-stronghold)
  };
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

  late List<PlayerToken> players;
  int currentTurn = 0;
  int diceRoll = 1;
  bool rolling = false;
  bool isDay = true;
  bool gameOver = false;
  int turnCount = 0;
  final int maxTurns = 40;
  final int winningScore = 100;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final aiColors = Colors.primaries.where((c) => c != widget.player.color).toList()..shuffle();
    players = [
      widget.player,
      for (int i = 1; i <= 3; i++)
        PlayerToken(
          id: 'AI_$i',
          displayName: 'AI_$i',
          isAI: true,
          color: aiColors[i],
          roles: ['Good Youth'],
          position: spiralPath[0],
        ),
    ];
  }

  bool get isMyTurn => players[currentTurn].id == widget.player.id;

  Future<void> rollDice() async {
    if (!isMyTurn || rolling || gameOver) return;

    setState(() => rolling = true);

    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      setState(() => diceRoll = Random().nextInt(6) + 1);
    }

    await _movePlayer(currentTurn, diceRoll);
  }

  Future<void> _movePlayer(int index, int roll) async {
    final player = players[index];

    final currentSpiralIndex = spiralPath.indexOf(player.position);
    final nextIndex = (currentSpiralIndex + roll) % spiralPath.length;
    player.position = spiralPath[nextIndex];

    // Draw Choice Card
    final card = await ChoiceCardService.drawRandomCard();

    final tile = player.position;
    final tileData = tileConfig[tile];

    if (tileData != null) {
      final type = tileData['type'];
      final phase = tileData['phase'];
      final canActivate = phase == 'both' || (phase == 'day' && isDay) || (phase == 'night' && !isDay);

      if (canActivate) {
        switch (type) {
          case "Don HQ":
            if (player.evolvedRole == null) player.evolvedRole = "Don";
            break;
          case "MP Council":
            if (player.evolvedRole == null) player.evolvedRole = "MP";
            break;
          case "Babylon Station":
            if (player.evolvedRole == null) player.evolvedRole = "Babylon";
            break;
          case "Church":
            if (player.evolvedRole == null) player.evolvedRole = "JP";
            break;
        }
      }
    }

    // ✅ Don Special Power Activation (Player Don only)
    if (player.evolvedRole == 'Don' && !player.isAI) {
      final threatRoll = Random().nextInt(100);
      if (threatRoll < 30) {
        _showDonThreatDialog(player);
        return;
      }
    }

    if (player.isAI) {
      final pickGood = _decideAIChoice(player);
      _applyChoice(player, card, pickGood ? 'good' : 'bad');
      await _advanceToNextPlayer();
    } else {
      _showChoiceDialog(card, player);
    }
  }

  void _showDonThreatDialog(PlayerToken don) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("👑 Don Flex Time"),
        content: const Text("Yuh feel di power rising. Who yuh wan’ recruit or threaten?"),
        actions: [
          ...players.where((p) => p.isAI && !p.isGangMember).map((ai) {
            return TextButton(
              onPressed: () {
                ai.isGangMember = true;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("${ai.displayName} now loyal to di Don."),
                ));
                _advanceToNextPlayer();
              },
              child: Text("Recruit ${ai.displayName}"),
            );
          }),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Don decide fi hold back today..."),
              ));
              _advanceToNextPlayer();
            },
            child: const Text("Nah threaten nobody"),
          ),
        ],
      ),
    );
  }

  bool _decideAIChoice(PlayerToken ai) {
    final don = players.firstWhere(
          (p) => p.evolvedRole == 'Don' && !p.isAI,
      orElse: () => PlayerToken.empty(),
    );

    if (ai.isGangMember) return false; // More likely to do bad
    if (don.id != '' && ai.history.length > 5) return true; // Avoid suspicion
    return Random().nextBool();
  }

  void _applyChoice(PlayerToken player, ChoiceCard card, String decisionType) {
    final points = decisionType == 'good' ? card.goodPoints : card.badPoints;
    final description = decisionType == 'good' ? card.goodAction : card.badAction;

    player.score += points;
    player.history.add(ChoiceRecord(
      cardTitle: card.title,
      decision: decisionType,
      description: description,
      points: points,
      timestamp: DateTime.now(),
    ));

    // Handle role evolution if applicable
    if (card.unlockRole != null) {
      final unlocksDon = card.unlockRole == 'Don' && decisionType == 'bad';
      final unlocksOther = card.unlockRole != 'Don' && decisionType == 'good';

      if ((unlocksDon || unlocksOther) && !player.roles.contains(card.unlockRole)) {
        player.evolvedRole = card.unlockRole;
        player.roles.add(card.unlockRole!);
        _showRoleUnlockDialog(player, card.unlockRole!);
      }
    }
  }

  int calculateRoleBonus(PlayerToken player) {
    final role = player.evolvedRole;

    if (role == null) return 0;

    switch (role) {
      case 'Don':
        return player.score >= 70 ? 10 : 0; // survives with decent score
      case 'MP':
        return player.score >= 50 ? 7 : 0; // did their job
      case 'Babylon':
        return player.history.any((h) => h.description.toLowerCase().contains("arrest")) ? 5 : 0;
      case 'JP':
        return player.history.length >= 5 ? 3 : 0; // helped community
      default:
        return 0;
    }
  }

  void _showRoleUnlockDialog(PlayerToken player, String role) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎭 Role Evolved"),
        content: Text("${player.displayName} unlocked the role: $role!"),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  List<Widget> _buildRoleAbilityButtons(PlayerToken player) {
    final buttons = <Widget>[];

    if (player.evolvedRole == "Don") {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            final target = players.firstWhere((p) => !p.isAI && p.id != player.id);
            RoleAbilities.sendHit(players, target.id);
            setState(() {});
          },
          icon: const Icon(Icons.bolt),
          label: const Text("Send Hit"),
        ),
      );
    }

    if (player.evolvedRole == "JP") {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            final target = players.firstWhere((p) => !p.isAI && p.id != player.id);
            RoleAbilities.protectPlayer(players, target.id);
            setState(() {});
          },
          icon: const Icon(Icons.shield),
          label: const Text("Protect"),
        ),
      );
    }

    if (player.evolvedRole == "MP") {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            final target = players.firstWhere((p) => !p.isAI && p.id != player.id);
            final revealed = RoleAbilities.exposePlayer(players, target.id);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("🕵️‍♂️ Exposed!"),
                content: Text("Player is: $revealed"),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
              ),
            );
          },
          icon: const Icon(Icons.visibility),
          label: const Text("Expose"),
        ),
      );
    }

    if (player.evolvedRole == "Babylon") {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            final target = players.firstWhere((p) => !p.isAI && p.id != player.id);
            RoleAbilities.arrestPlayer(players, target.id);
            setState(() {});
          },
          icon: const Icon(Icons.gavel),
          label: const Text("Arrest"),
        ),
      );
    }

    return buttons;
  }

  void _showRoleActions(PlayerToken player) {
    final role = player.evolvedRole;
    if (role == null) return;

    List<Widget> options = [];

    if (role == "Don") {
      options = [
        ListTile(
          leading: const Icon(Icons.bolt),
          title: const Text("Send Hit"),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement hit logic
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hit sent!")));
          },
        ),
      ];
    } else if (role == "MP") {
      options = [
        ListTile(
          leading: const Icon(Icons.visibility),
          title: const Text("Reveal Role"),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement reveal logic
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You revealed a role!")));
          },
        ),
      ];
    } else if (role == "Babylon") {
      options = [
        ListTile(
          leading: const Icon(Icons.gavel),
          title: const Text("Arrest Player"),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement arrest logic
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Player arrested!")));
          },
        ),
      ];
    } else if (role == "JP") {
      options = [
        ListTile(
          leading: const Icon(Icons.shield_moon),
          title: const Text("Protect Player"),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement protect logic
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Player protected!")));
          },
        ),
      ];
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text("⚡ ${role.toUpperCase()} Actions", style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          ...options,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showChoiceDialog(ChoiceCard card, PlayerToken player) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(card.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Make a decision:"),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.thumb_up),
              label: Text("Good: ${card.goodAction}"),
              onPressed: () {
                Navigator.pop(context); // 👈 Close first
                _applyChoice(player, card, 'good');
                Future.delayed(Duration(milliseconds: 200), _advanceToNextPlayer); // 👈 Smooth handoff
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.thumb_down),
              label: Text("Bad: ${card.badAction}"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context); // 👈 Close first
                _applyChoice(player, card, 'bad');
                Future.delayed(Duration(milliseconds: 200), _advanceToNextPlayer); // 👈 Smooth handoff
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advanceToNextPlayer() async {
    setState(() {
      currentTurn = (currentTurn + 1) % players.length;
      turnCount += 1;
      rolling = false;
    });

    if (_checkForGameOver()) return;

    final current = players[currentTurn];
    if (current.isAI) {
      await Future.delayed(const Duration(milliseconds: 800));
      final roll = Random().nextInt(6) + 1;
      await _movePlayer(currentTurn, roll);
    }
  }

  bool _checkForGameOver() {
    final topScorer = players.firstWhere(
          (p) => p.score >= winningScore,
      orElse: () => PlayerToken(id: '', displayName: '', roles: [], color: Colors.transparent, position: 0),
    );

    if (topScorer.id.isNotEmpty) {
      _showWinner(topScorer.displayName);
      return true;
    }

    if (turnCount >= maxTurns) {
      final sorted = [...players]..sort((a, b) => b.score.compareTo(a.score));
      _showWinner(sorted.first.displayName);
      return true;
    }

    return false;
  }

  void _showWinner(String winnerName) {
    setState(() => gameOver = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🏆 Game Over"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Winner: $winnerName"),
            const SizedBox(height: 12),
            ...(players.toList()
              ..sort((a, b) => (b.score + calculateRoleBonus(b)).compareTo(a.score + calculateRoleBonus(a))))
                .map((p) => ListTile(
              leading: CircleAvatar(backgroundColor: p.color),
              title: Text(p.displayName),
              subtitle: Text(
                p.evolvedRole != null ? "Role: ${p.evolvedRole}" : "Role: ${p.roles.first}",
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${p.score} pts"),
                  if (calculateRoleBonus(p) > 0)
                    Text("+${calculateRoleBonus(p)} bonus", style: const TextStyle(fontSize: 12)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          )
        ],
      ),
    );
  }

  void _showBirthPaper(PlayerToken player) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("📜 Birth Paper: ${player.displayName}",
                  style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              if (player.evolvedRole != null)
                Text("🔓 Evolved Role: ${player.evolvedRole}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("🧬 Starting Role: ${player.roles.first}"),
              const SizedBox(height: 4),
              Text("🏆 Score: ${player.score}"),
              const SizedBox(height: 12),
              const Text("🕹️ Decision History:"),
              const SizedBox(height: 4),
              Expanded(
                child: player.history.isEmpty
                    ? const Text("No choices made yet.")
                    : ListView(
                  children: player.history.map((entry) {
                    return ListTile(
                      leading: Icon(
                        entry.decision == 'good'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: entry.decision == 'good'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(entry.cardTitle),
                      subtitle: Text("${entry.description} (${entry.points} pts)"),
                      trailing: Text(
                          "${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}"),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = players[currentTurn];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Garrison - Solo Mode"),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: "View Birth Paper",
            onPressed: () => _showBirthPaper(players[currentTurn]),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Restart Round",
            onPressed: () {
              setState(() {
                gameOver = false;
                diceRoll = 1;
                currentTurn = 0;
                turnCount = 0;
                _initGame();
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Text("Turn: ${current.displayName}"),
          const SizedBox(height: 8),
          Text("🎲 Dice: $diceRoll"),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LudiBoard(tokens: players, isDay: isDay),
            ),
          ),
          if (!current.isAI &&
              !gameOver &&
              current.evolvedRole != null &&
              _buildRoleAbilityButtons(current).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: _buildRoleAbilityButtons(current),
              ),
            ),
          if (!current.isAI && !gameOver)
            ElevatedButton.icon(
              onPressed: rollDice,
              icon: const Icon(Icons.casino),
              label: Text(rolling ? "Rolling..." : "Roll Dice ($diceRoll)"),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
