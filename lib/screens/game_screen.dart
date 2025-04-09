import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/choice_card.dart';
import '../models/choice_record.dart';
import '../models/player_token.dart';
import '../services/choice_card_service.dart';
import '../services/firebase_service.dart';
import '../services/legacy_service.dart';
import '../services/room_service.dart';
import 'endgame_screen.dart';
import 'gamedashboard_screen.dart';
import 'ludi_board.dart';

class GameScreen extends StatefulWidget {
  final String gameId;
  final PlayerToken playerToken;

  const GameScreen({super.key, required this.gameId, required this.playerToken});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final RoomService _roomService = RoomService();
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
  List<PlayerToken> tokens = [];
  int currentTurnIndex = 0;
  bool isDay = true;
  bool votingActive = false;
  int diceRoll = 1;
  bool rolling = false;
  bool started = false;
  Map<String, int> voteCounts = {};
  Map<String, bool> hasVoted = {};
  String? winner;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _listenToRoom();
  }

  void _listenToRoom() {
    _roomService.listenToRoom(widget.gameId).listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;

      final tokenList = (data['tokens'] as List)
          .map((e) => PlayerToken.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        tokens = tokenList;
        currentTurnIndex = data['currentTurnIndex'] ?? 0;
        isDay = (data['phase'] ?? 'day') == 'day';
        started = data['started'] ?? false;
        voteCounts = Map<String, int>.from(data['votes'] ?? {});
        hasVoted = Map<String, bool>.from(data['hasVoted'] ?? {});
      });

      checkWinCondition(); // <- add this
      // Check win condition
      final alive = tokenList.where((t) => !t.isEliminated).toList();
      if (alive.length == 1 && winner == null) {
        setState(() => winner = alive.first.id);
      }
    });
  }

  bool get isMyTurn =>
      tokens.isNotEmpty &&
          tokens[currentTurnIndex].id == widget.playerToken.id &&
          !widget.playerToken.isEliminated;

  Future<void> rollDice() async {
    if (winner != null) return;
    if (widget.playerToken.isBlocked) {
      showSnackBar("You are blocked and cannot move this turn.");
      return;
    }
    if (!isMyTurn || rolling || widget.playerToken.isEliminated) return;

    setState(() => rolling = true);
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      setState(() => diceRoll = Random().nextInt(6) + 1);
    }

    await _movePlayer(diceRoll);
    setState(() => rolling = false);

  }

  Future<void> _movePlayer(int roll) async {
    final updatedTokens = [...tokens];
    final index = updatedTokens.indexWhere((t) => t.id == widget.playerToken.id);
    if (index == -1) return;

    final player = updatedTokens[index];
    player.position = (player.position + roll) % 100;

    // ✅ Determine tile type based on updated config
    final tileData = tileConfig[player.position];
    final tileType = tileData?['type'] ?? '';
    final allowedPhase = tileData?['phase'] ?? 'both';

    // 🔒 Check phase restriction
    if (allowedPhase != "both" && ((allowedPhase == "day" && !isDay) || (allowedPhase == "night" && isDay))) {
      showSnackBar("$tileType only opens during ${allowedPhase.toUpperCase()}.");
    } else {
      await _triggerTileEffect(player.position, updatedTokens, player.id);
    }

    // 👉 Draw & show card
    final card = await ChoiceCardService.drawRandomCard(tileType: tileType);
    _showChoiceDialog(card, player, tileType);

    final nextTurn = (currentTurnIndex + 1) % updatedTokens.length;

    await _roomService.updateGameState(widget.gameId, {
      'currentTurnIndex': nextTurn,
      'tokens': updatedTokens.map((t) => t.toMap()).toList(),
    });
  }

  Future<void> _triggerTileEffect(int position, List<PlayerToken> updatedTokens, String playerId) async {
    final tileData = tileConfig[position];
    final idx = updatedTokens.indexWhere((t) => t.id == playerId);
    if (idx == -1 || tileData == null) return;

    final player = updatedTokens[idx];
    final type = tileData['type'] as String;
    final allowedPhase = tileData['phase'] as String;
    final visited = player.visitedZones;

    // Lock zone by phase
    if (allowedPhase != "both" && ((allowedPhase == "night" && isDay) || (allowedPhase == "day" && !isDay))) {
      showSnackBar("$type only opens during ${allowedPhase.toUpperCase()}.");
      return;
    }

    switch (type) {
      case "MP Council":
        if (!visited.contains(type)) {
          player.visitedZones.add(type);
        }  if (!player.roles.contains("MP")) {
          player.roles.add("MP");
          _showRoleUnlockModal("MP");
        }
        break;
      case "Don HQ":
        if (!visited.contains(type)) {
          player.visitedZones.add(type);
        }
        if (!player.roles.contains("Don")) {
          player.roles.add("Don");
          _showRoleUnlockModal("Don");
        }
        break;
      case "Babylon Station":
        if (!visited.contains(type)) {
          player.visitedZones.add(type);
        }
        if (!player.roles.contains("Babylon")) {
          player.roles.add("Babylon");
          _showRoleUnlockModal("Babylon");
        }
        break;
      case "Church":
        if (!visited.contains(type)) {
          player.visitedZones.add(type);
        }
        if (!player.roles.contains("JP")) {
          player.roles.add("JP");
          _showRoleUnlockModal("JP");
        }
        break;
      case "Hot Spot":
        final chaos = [-5, -3, -1, 1, 3, 5]..shuffle();
        player.score += chaos.first;
        showSnackBar("🔥 Hot Spot chaos: ${chaos.first > 0 ? '+' : ''}${chaos.first} pts");
        break;
      case "Legacy":
        showSnackBar("${player.displayName} reached the Legacy Tile! Final scores incoming...");
        _handleEndGame(updatedTokens);
        break;
      default:
        return;
    }

    await _roomService.updateTokens(widget.gameId, updatedTokens);
  }

  void useAbility(List<String> roles) {
    HapticFeedback.heavyImpact();

    final descriptions = roles.map((role) => "🟢 $role: ${getAbilityDescription(role)}").join("\n\n");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Your Role Abilities"),
        content: Text(descriptions),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Future<void> handleAbilityTarget(String role, PlayerToken target) async {
    final updatedTokens = [...tokens];
    final targetIndex = updatedTokens.indexWhere((t) => t.id == target.id);

    if (targetIndex == -1) return;

    String message = "";
    if (role == 'JP') {
      updatedTokens[targetIndex].isInspected = true;

      // Show result only to JP
      if (widget.playerToken.roles == 'JP') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Investigation Result"),
            content: Text("${target.id.toUpperCase()} is the ${target.roles}."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      }

      message = "${target.id.toUpperCase()} was investigated.";
    }

    switch (role) {
      case 'Don':
        updatedTokens[targetIndex].isSilenced = true;
        message = "${target.id.toUpperCase()} has been silenced.";
        break;
      case 'Babylon':
        updatedTokens[targetIndex].isBlocked = true;
        message = "${target.id.toUpperCase()} has been blocked.";
        break;
      case 'JP':
        updatedTokens[targetIndex].isInspected = true;
        message = "${target.id.toUpperCase()} is the ${target.roles}.";
        break;
      case 'MP':
        startVotingPhase();
        message = "MP triggered a public vote.";
        break;
      default:
        message = "No ability available.";
        break;
    }

    await _roomService.updateTokens(widget.gameId, updatedTokens);
    showSnackBar(message);
  }

  String getAbilityDescription(String role) {
    switch (role) {
      case 'Don':
        return 'Silence a player for one round.';
      case 'Babylon':
        return 'Arrest a suspicious player.';
      case 'JP':
        return 'Investigate the role of a player.';
      case 'MP':
        return 'Propose a public vote.';
      case 'Good Youth':
      default:
        return 'No special ability, just vibes.';
    }
  }

  void startVotingPhase() {
    final activePlayers = tokens.where((t) => !t.isEliminated);
    final votes = {for (var p in activePlayers) p.id: 0};
    final voted = {for (var p in activePlayers) p.id: false};
    if (winner != null) return;

    _roomService.updateGameState(widget.gameId, {
      'votes': votes,
      'hasVoted': voted,
    });

    setState(() => votingActive = true);
  }

  void _showChoiceDialog(ChoiceCard card, PlayerToken player, String? tileType) {
    final isSynergized = card.tileTypes?.contains(tileType) ?? false;
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
                _applyChoice(player.id, card.goodPoints, card, 'good');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.thumb_down),
              label: Text("Bad: ${card.badAction}"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _applyChoice(player.id, card.badPoints, card, 'bad');
                Navigator.pop(context);
              },            ),
            if (isSynergized)
              Text("💥 Zone Synergy Active!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), ],
        ),
      ),
    );
  }

  void _applyChoice(String playerId, int points, ChoiceCard card, String decisionType) async {
    final updated = [...tokens];
    final idx = updated.indexWhere((p) => p.id == playerId);
    if (idx != -1) {
      final player = updated[idx];
      player.score += points;

      if (points > 0) {
        player.goodChoices += 1;
      } else {
        player.badChoices += 1;
      }

      // Add to history
      player.history.add(ChoiceRecord(
        cardTitle: card.title,
        decision: decisionType,
        description: decisionType == 'good' ? card.goodAction : card.badAction,
        points: points,
        timestamp: DateTime.now(),
      ));

      // 🚨 UNLOCK ROLE if triggered
      final unlockOn = decisionType == 'good' ? 'good' : 'bad';
      final shouldUnlock = card.unlockRole != null &&
          ((unlockOn == 'good' && card.goodPoints == 0) || (unlockOn == 'bad' && card.badPoints == 0));

      if (shouldUnlock && player.roles == "Good Youth") {
        player.roles = card.unlockRole! as List<String>;
        _showRoleUnlockModal(player.roles as String);
      }

      await _roomService.updateTokens(widget.gameId, updated);
      showSnackBar("You chose a $decisionType path: $points pts");
    }
  }

  void _showRoleUnlockModal(String newRole) {
    final player = tokens.firstWhere((t) => t.id == widget.playerToken.id, orElse: () => widget.playerToken);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("🎭 Role Unlocked"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You have unlocked a new role: $newRole",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Icon(
              _getRoleIcon(player.roles),
              size: 48,
              color: _getRoleColor(newRole),
            ),
            const SizedBox(height: 8),
            Text(getAbilityDescription(newRole)),
            const SizedBox(height: 12),
            Text("Your roles: ${player.roles.join(', ')}", style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep it secret"),
          ),
        ],
      ),
    );
  }

  void _handleDonRecruit() {
    final don = tokens.firstWhere((t) => t.id == widget.playerToken.id);

    final candidates = tokens.where((t) =>
    !t.isEliminated &&
        !t.isGangMember &&
        t.id != don.id).toList();

    if (candidates.isEmpty) {
      showSnackBar("No players available to recruit.");
      return;
    }

    _showTargetModal(
      title: "Choose a Garrison Soldier",
      actionLabel: "Recruit",
      onSelect: (target) async {
        final updated = [...tokens];
        final tIndex = updated.indexWhere((t) => t.id == target.id);

        updated[tIndex].isGangMember = true;

        updated[tIndex].history.add(ChoiceRecord(
          cardTitle: "Don Recruit",
          decision: "recruit",
          description: "Brought into di Garrison gang",
          points: 3, // bonus
          timestamp: DateTime.now(),
        ));

        await _roomService.updateTokens(widget.gameId, updated);
        showSnackBar("${target.id} has been recruited to the Don’s crew.");
      },
    );
  }

  void _handlePromoteToHitman() {
    final candidates = tokens.where((t) =>
    t.isGangMember && t.evolvedRole == null && !t.roles.contains("Don")
    ).toList();

    if (candidates.isEmpty) {
      showSnackBar("No soldiers ready fi level up yet.");
      return;
    }

    _showTargetModal(
      title: "Promote to Hitman",
      actionLabel: "Promote",
      onSelect: (target) async {
        final updated = [...tokens];
        final idx = updated.indexWhere((t) => t.id == target.id);
        updated[idx].evolvedRole = "Hitman";

        updated[idx].history.add(ChoiceRecord(
          cardTitle: "Don Promotion",
          decision: "ability",
          description: "Promoted to Hitman",
          points: 5,
          timestamp: DateTime.now(),
        ));

        await _roomService.updateTokens(widget.gameId, updated);
        showSnackBar("${target.id} a now di Hitman!");
      },
    );
  }

  void _handleDonHit() {
    _showTargetModal(
      title: "Send a Hit",
      actionLabel: "Hit",
      onSelect: (target) async {
        if (target.isProtected) {
          showSnackBar("${target.id} was protected! Hit failed.");
          return;
        }

        final updated = [...tokens];
        final idx = updated.indexWhere((t) => t.id == target.id);
        if (idx != -1) {
          updated[idx].isEliminated = true;

          updated[idx].history.add(ChoiceRecord(
            cardTitle: "Don Hit",
            decision: "ability",
            description: "Got hit by Don",
            points: 0,
            timestamp: DateTime.now(),
          ));
        }

        await _roomService.updateTokens(widget.gameId, updated);
        showSnackBar("${target.id} was taken out by di Don.");
      },
    );
  }

  void _handleBabylonArrest() {
    final me = tokens.firstWhere((t) => t.id == widget.playerToken.id);
    if (me.cooldownTurns > 0) {
      showSnackBar("You need to wait ${me.cooldownTurns} more turns to arrest.");
      return;
    }

    _showTargetModal(
      title: "Arrest a Player",
      actionLabel: "Arrest",
      onSelect: (target) async {
        if (target.isProtected) {
          showSnackBar("${target.id} is protected! Arrest failed.");
          return;
        }

        final updated = [...tokens];
        final tIdx = updated.indexWhere((t) => t.id == target.id);
        final meIdx = updated.indexWhere((t) => t.id == me.id);

        updated[tIdx].score -= 10;
        updated[meIdx].cooldownTurns = 2;

        updated[meIdx].history.add(ChoiceRecord(
          cardTitle: "Babylon Arrest",
          decision: "ability",
          description: "Arrested ${target.id}",
          points: 0,
          timestamp: DateTime.now(),
        ));

        await _roomService.updateTokens(widget.gameId, updated);
        showSnackBar("${target.id} arrested (-10 pts).");
      },
    );
  }

  void _handleJPProtect() {
    _showTargetModal(
      title: "Protect a Player",
      actionLabel: "Protect",
      onSelect: (target) async {
        final updated = [...tokens];
        final idx = updated.indexWhere((t) => t.id == target.id);
        if (idx != -1) {
          updated[idx].isProtected = true;

          updated[idx].history.add(ChoiceRecord(
            cardTitle: "JP Protection",
            decision: "ability",
            description: "Received protection from JP",
            points: 0,
            timestamp: DateTime.now(),
          ));

          await _roomService.updateTokens(widget.gameId, updated);
          showSnackBar("${target.id} is protected this round.");
        }
      },
    );
  }

  void _handleRevealRole() async {
    final updated = [...tokens];
    final meIndex = updated.indexWhere((t) => t.id == widget.playerToken.id);

    if (meIndex != -1) {
      updated[meIndex].isRevealed = true;
      updated[meIndex].revealCooldown = 2; // optional cooldown duration

      await _roomService.updateTokens(widget.gameId, updated);
      showSnackBar("You revealed your role(s): ${widget.playerToken.roles.join(', ')}");
    }
  }

  Future<void> togglePhase() async {
    final newPhase = isDay ? "night" : "day";
    final updatedTokens = [...tokens];

    // Reset role effects at the end of each phase
    for (var t in updatedTokens) {
      t.isBlocked = false;
      t.isSilenced = false;
      t.isInspected = false;
    }
    for (var t in updatedTokens) {
      if (t.revealCooldown > 0) {
        t.revealCooldown -= 1;
        if (t.revealCooldown == 0) t.isRevealed = false;
      }
      t.isProtected = false;
    }

    await _roomService.updateGameState(widget.gameId, {
      'phase': newPhase,
      'phaseId': DateTime.now().millisecondsSinceEpoch.toString(),
      'tokens': updatedTokens.map((t) => t.toMap()).toList(),
    });
  }

  void openVoteDialog() {
    final voterId = widget.playerToken.id;

    if (widget.playerToken.isSilenced) {
      showSnackBar("You are silenced and cannot vote.");
      return;
    }
    if (hasVoted[voterId] == true) {
      showSnackBar("You already voted!");
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Vote to Eliminate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ...tokens.where((t) => !t.isEliminated).map((token) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: token.color,
                  child: Text(token.id[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(token.id.toUpperCase()),
                trailing: IconButton(
                  icon: const Icon(Icons.how_to_vote),
                  onPressed: () async {
                    await _roomService.castVote(widget.gameId, token.id, voterId);
                    Navigator.pop(context);
                    showSnackBar("You voted for ${token.id}");
                    if (!hasVoted.containsValue(false)) {
                      _endVotingPhase();
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  void _endVotingPhase() {
    final maxVotes = voteCounts.values.fold<int>(0, max);
    final topVoted = voteCounts.entries
        .where((entry) => entry.value == maxVotes)
        .map((e) => e.key)
        .toList();

    if (topVoted.length == 1) {
      final eliminatedId = topVoted.first;
      final updated = tokens.map((p) {
        if (p.id == eliminatedId) {
          p.isEliminated = true;
        }
        return p;
      }).toList();

      _roomService.updateGameState(widget.gameId, {
        'tokens': updated.map((t) => t.toMap()).toList(),
        'votes': {},
        'hasVoted': {},
      });
      final eliminated = updated.firstWhere((p) => p.id == eliminatedId);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Player Eliminated"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${eliminatedId.toUpperCase()} was the ${eliminated.roles}."),
              const SizedBox(height: 12),
              Icon(_getRoleIcon(eliminated.roles), size: 48, color: eliminated.color),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
    } else {
      showSnackBar("It’s a tie. No one was eliminated.");
    }

    setState(() => votingActive = false);
  }

  void showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  IconData _getRoleIcon(List<String> roles) {
    if (roles.contains("Don")) return Icons.casino;
    if (roles.contains("Babylon")) return Icons.local_police;
    if (roles.contains("MP")) return Icons.account_balance;
    if (roles.contains("JP")) return Icons.gavel;
    return Icons.emoji_people; // Default for Good Youth or any other
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Don':
        return Colors.redAccent;
      case 'Babylon':
        return Colors.blueAccent;
      case 'JP':
        return Colors.orangeAccent;
      case 'MP':
        return Colors.teal;
      case 'Good Youth':
      default:
        return Colors.green;
    }
  }

  void checkWinCondition() {
    final alive = tokens.where((t) => !t.isEliminated).toList();
    final dons = alive.where((t) => t.roles == 'Don').toList();
    final babylons = alive.where((t) => t.roles == 'Babylon').toList();
    final townies = alive.where((t) => t.roles != 'Don' && t.roles != 'Babylon').toList();
    final updatedTokens = [...tokens];
    final gang = alive.where((t) => t.isGangMember || t.roles.contains("Don")).toList();

    for (var t in updatedTokens) {
      t.cooldownTurns = (t.cooldownTurns > 0) ? t.cooldownTurns - 1 : 0;
      t.isProtected = false;
    }

    // Town wins
    if (dons.isEmpty && babylons.isEmpty && alive.length > 1) {
      setState(() => winner = 'TOWN');
      return;
    }

    // Don wins
    if (dons.length == 1 && alive.length <= 2) {
      setState(() => winner = dons.first.id);
      return;
    }

    if (gang.length >= (alive.length / 2).ceil()) {
      setState(() => winner = gang.first.id); // Don wins
      return;
    }
  }

  Future<void> resetGame({bool shuffle = false}) async {
    final updatedTokens = tokens.map((t) {
      return PlayerToken(
        id: t.id,
        displayName: t.displayName,
        color: t.color,
        roles: shuffle ? ['Good Youth'] : t.roles, // or randomize logic
        position: 0,
        isEliminated: false,
        isBlocked: false,
        isSilenced: false,
        isInspected: false,
        isProtected: false,
        score: 0,
        goodChoices: 0,
        badChoices: 0,
        cooldownTurns: 0,
        history: [],
      );
    }).toList();

    await _roomService.updateGameState(widget.gameId, {
      'tokens': updatedTokens.map((t) => t.toMap()).toList(),
      'votes': {},
      'hasVoted': {},
      'winner': null,
      'phase': 'day',
      'phaseId': DateTime.now().millisecondsSinceEpoch.toString(),
      'currentTurnIndex': 0,
      'ended': false,
    });

    setState(() {
      winner = null;
      diceRoll = 1;
      votingActive = false;
    });

    showSnackBar("Game has been reset!");
  }

  void _handleEndGame(List<PlayerToken> allPlayers) async {
    // Sort by score, highest first
    allPlayers.sort((a, b) => b.score.compareTo(a.score));

    // Store winner
    final topPlayer = allPlayers.first;

    // Update game state in Firestore
    await _roomService.updateGameState(widget.gameId, {
      'winner': topPlayer.id,
      'ended': true,
      'tokens': allPlayers.map((p) => p.toMap()).toList(),
    });
    final legacyService = LegacyService();

    for (final player in allPlayers) {
      await legacyService.saveLegacy(widget.gameId, player, player.id == topPlayer.id);
    }

    // Show Endgame Summary
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EndGameScreen(
          players: allPlayers,
          winnerId: topPlayer.id,
        ),
      ),
    );
  }

  String _getVictoryMessageForWinner(String winnerId) {
    final player = tokens.firstWhere((t) => t.id == winnerId, orElse: () => widget.playerToken);
    if (player.roles.contains("Don")) return "The Garrison now run by Don 💀";
    if (player.roles.contains("MP")) return "MP secure di community 🏛️";
    if (player.roles.contains("Babylon")) return "Babylon lock up di ends 🚔";
    return "Clean youth mek it to di top 🙌";
  }

  Future<void> _saveOrShareBirthPaper(String playerName) async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/${playerName}_birth_paper.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath.path)], text: "$playerName's Birth Paper from Garrison 🔥");
    } catch (e) {
      showSnackBar("Failed to export Birth Paper: $e");
    }
  }

  Widget _buildPlayerScroller() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: tokens.length,
        itemBuilder: (context, index) {
          final p = tokens[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: p.isEliminated ? Colors.grey.shade300 : null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: p.color,
                      child: Icon(_getRoleIcon(p.roles), size: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text('Player ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(p.roles.join(', '), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    if (p.isRevealed)
                      Chip(
                        label: Text(p.roles.join(', '), style: const TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: _getRoleColor(p.roles.first),
                      ),
                    if (p.isGangMember)
                      Chip(
                        label: const Text("🔫 Garrison Soldier"),
                        backgroundColor: Colors.black87,
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    Text(p.evolvedRole != null
                        ? "🔫 ${p.evolvedRole}"
                        : p.roles.join(', ')
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionPanel(List<String> roles) {
    final List<Widget> buttons = [];

    if (winner != null) return const SizedBox.shrink();

    // Add Toggle Phase button only for current player
    if (isMyTurn) {
      buttons.add(ElevatedButton.icon(
        onPressed: togglePhase,
        icon: const Icon(Icons.wb_sunny),
        label: const Text("Toggle Phase"),
      ));
    }

    // Show role-specific buttons
    if (roles.contains("Don")) {
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.person_add),
        label: const Text("Recruit"),
        onPressed: _handleDonRecruit,
      ));
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.dangerous),
        label: const Text("Send Hit"),
        onPressed: _handleDonHit,
      ));
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.upgrade),
        label: const Text("Promote Soldier"),
        onPressed: _handlePromoteToHitman,
      )); }

    if (roles.contains("Babylon")) {
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.local_police),
        label: const Text("Arrest"),
        onPressed: _handleBabylonArrest,
      ));
    }

    if (roles.contains("MP")) {
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.campaign),
        label: const Text("Force Vote"),
        onPressed: startVotingPhase,
      ));
    }

    if (roles.contains("JP")) {
      buttons.add(ElevatedButton.icon(
        icon: const Icon(Icons.shield),
        label: const Text("Protect Player"),
        onPressed: _handleJPProtect,
      ));
    }

    // Only show base actions if it's the player's turn
    if (!isMyTurn) return const SizedBox.shrink();
    buttons.add(ElevatedButton.icon(
      onPressed: widget.playerToken.isRevealed
          ? null
          : _handleRevealRole,
      icon: const Icon(Icons.visibility),
      label: const Text("Reveal Role"),
    ));

    return Column(
      children: [
        // Base actions: vote, ability, roll
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: votingActive ? openVoteDialog : startVotingPhase,
              icon: Icon(votingActive ? Icons.how_to_vote : Icons.campaign),
              label: Text(votingActive ? "Cast Vote" : "Start Vote"),
            ),
            ElevatedButton.icon(
              onPressed: () => useAbility(roles),
              icon: const Icon(Icons.flash_on),
              label: const Text('Use Ability'),
            ),
            ElevatedButton.icon(
              onPressed: rollDice,
              icon: const Icon(Icons.casino),
              label: Text(rolling ? "Rolling..." : "Roll Dice ($diceRoll)"),
            ),
          ],
        ),

        // Role-based buttons
        if (buttons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: buttons,
            ),
          ),

        // Show current votes if active
        if (votingActive && voteCounts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 10,
              children: voteCounts.entries
                  .map((e) => Chip(label: Text("${e.key.toUpperCase()}: ${e.value}")))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerInfoColumn(PlayerToken? currentPlayer) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (winner != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${winner!.toUpperCase()} WINS!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  "Current Turn: ${currentPlayer?.id.toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("🏅 Garrison Points: ${widget.playerToken.score}"),
                const SizedBox(height: 16),
                _buildPlayerScroller(),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _buildActionPanel(widget.playerToken.roles),
          ),
        ),
      ],
    );
  }

  void _showBirthPaper() {
    final me = tokens.firstWhere((t) => t.id == widget.playerToken.id, orElse: () => widget.playerToken);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 300,
          height: 550,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            border: Border.all(color: Colors.black),
            image: const DecorationImage(
              image: AssetImage("assets/birth_paper_bg.jpg"), // optional background watermark
              fit: BoxFit.fitHeight,
              opacity: 0.1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("💼 Birth Paper", style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: () => _saveOrShareBirthPaper(me.displayName),
                icon: const Icon(Icons.download),
                label: const Text("Download / Share"),
              ),
              const Divider(),
              Text("Player: ${me.id.toUpperCase()}"),
              const SizedBox(height: 8),
              Text("Role: ${me.roles}"),
              if (me.evolvedRole != null)
                Text("🧬 Promoted Role: ${me.evolvedRole}"),
              const SizedBox(height: 8),
              Text("🏅 Garrison Points: ${me.score}"),
              Text("✅ Good Choices: ${me.goodChoices}"),
              Text("❌ Bad Choices: ${me.badChoices}"),
              Text("📍 Zones Visited: ${me.visitedZones.join(', ')}"),
              const SizedBox(height: 8),
              Text("📜 Decision History", style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              SizedBox(
                height: 180,
                child: ListView(
                  children: me.history.map((entry) {
                    return ListTile(
                      leading: Icon(
                        entry.decision == 'good' ? Icons.check_circle : Icons.warning,
                        color: entry.decision == 'good' ? Colors.green : Colors.red,
                      ),
                      title: Text(entry.cardTitle),
                      subtitle: Text("${entry.description} (${entry.points > 0 ? '+' : ''}${entry.points} pts)"),
                      trailing: Text("${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}"),
                    );
                  }).toList(),
                ),
              ),
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

  void _showTargetModal({
    required String title,
    required String actionLabel,
    required void Function(PlayerToken target) onSelect,
  }) {
    final aliveTargets = tokens.where((t) => !t.isEliminated && t.id != widget.playerToken.id).toList();

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...aliveTargets.map((target) => ListTile(
            leading: CircleAvatar(backgroundColor: target.color),
            title: Text(target.id.toUpperCase()),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onSelect(target);
              },
              child: Text(actionLabel),
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = tokens.isNotEmpty ? tokens[currentTurnIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garrison Game Board'),
        actions: [
          IconButton(
            onPressed: _showBirthPaper,
            icon: const Icon(Icons.description),
            tooltip: "View Birth Paper",
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameDashboardScreen(
                    gameId: widget.gameId,
                    players: tokens,
                    currentTurn: currentTurnIndex,
                    phase: isDay ? 'Day' : 'Night',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
            tooltip: "Game Dashboard",
          ),
        ],
      ),
      body: SafeArea(
        child: tokens.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Builder(
          builder: (context) {
            // Handle end game redirection
            if (winner != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EndGameScreen(
                      players: tokens,
                      winnerId: winner!,
                    ),
                  ),
                );
              });

              return const Center(
                child: Text(
                  "🏁 Game Over. Redirecting...",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            // 👇 Fix: Return the LayoutBuilder properly
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return Column(
                  children: [
                    const SizedBox(height: 8),

                    // Animated Phase Toggle
                    GestureDetector(
                      onTap: () => setState(() => isDay = !isDay),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDay
                              ? Colors.yellow.shade100
                              : Colors.indigo.shade700,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isDay ? "☀️ Day Phase" : "🌙 Night Phase",
                            key: ValueKey(isDay),
                            style: TextStyle(
                              color: isDay ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (currentPlayer != null)
                      Text(
                        "Current Turn: ${currentPlayer.id.toUpperCase()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: isMobile
                          ? Column(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: LudiBoard(
                                tokens: tokens,
                                isDay: isDay,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: _buildPlayerInfoColumn(currentPlayer),
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: LudiBoard(
                                tokens: tokens,
                                isDay: isDay,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildPlayerInfoColumn(currentPlayer),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}