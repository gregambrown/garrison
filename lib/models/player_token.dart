import 'package:flutter/material.dart';
import 'choice_record.dart';

class PlayerToken {
  final String id;
  final String displayName;
  final Color color;
  List<String> roles;
  int position;
  bool isEliminated;
  bool isSilenced;
  bool isBlocked;
  bool isInspected;
  bool isProtected;
  int score;
  int goodChoices;
  int badChoices;
  List<ChoiceRecord> history;
  int cooldownTurns;
  bool isRevealed;
  int revealCooldown; // Optional cooldown
  List<String> visitedZones;
  bool isGangMember;
  String? evolvedRole; // e.g., “Hitman”, “Enforcer”

  PlayerToken({
    required this.id,
    required this.displayName,
    required this.color,
    this.roles = const ['Good Youth'],
    this.position = 0,
    this.isEliminated = false,
    this.isBlocked = false,
    this.isSilenced = false,
    this.isInspected = false,
    this.isProtected = false,
    this.score = 0,
    this.goodChoices = 0,
    this.badChoices = 0,
    this.history = const [],
    this.cooldownTurns = 0,
    this.isRevealed = false,
    this.revealCooldown = 0,
    this.visitedZones = const [],
    this.isGangMember = false,
    this.evolvedRole,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'color': color.value,
    'roles': roles,
    'position': position,
    'isEliminated': isEliminated,
    'isBlocked': isBlocked,
    'isSilenced': isSilenced,
    'isInspected': isInspected,
    'isProtected': isProtected,
    'score': score,
    'goodChoices': goodChoices,
    'badChoices': badChoices,
    'cooldownTurns': cooldownTurns,
    'history': history.map((h) => h.toMap()).toList(),
    'isRevealed': isRevealed,
    'revealCooldown': revealCooldown,
    'visitedZones': visitedZones,
    'isGangMember': isGangMember,
    'evolvedRole': evolvedRole,
  };

  factory PlayerToken.fromMap(Map<String, dynamic> map) => PlayerToken(
    id: map['id'],
    displayName: map['displayName'] ?? 'Player',
    color: Color(map['color']),
    roles: List<String>.from(map['roles'] ?? ['Good Youth']),
    position: map['position'],
    isEliminated: map['isEliminated'],
    isBlocked: map['isBlocked'],
    isSilenced: map['isSilenced'],
    isInspected: map['isInspected'],
    isProtected: map['isProtected'],
    score: map['score'] ?? 0,
    goodChoices: map['goodChoices'] ?? 0,
    badChoices: map['badChoices'] ?? 0,
    cooldownTurns: map['cooldownTurns'] ?? 0,
    history: (map['history'] as List? ?? [])
        .map((e) => ChoiceRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    visitedZones: List<String>.from(map['visitedZones'] ?? []),
    isGangMember: map['isGangMember'],
    evolvedRole: map['evolvedRole'],
  );
}
