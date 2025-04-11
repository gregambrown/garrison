import 'package:flutter/material.dart';
import 'choice_record.dart';

class PlayerToken {
  final String id;
  final String displayName;
  final Color color;

  List<String> roles;
  int position;
  bool isAI;
  bool isEliminated;
  bool isSilenced;
  bool isBlocked;
  bool isInspected;
  bool isProtected;
  bool isRevealed;
  bool isGangMember;
  bool isArrested; // ✅ NEW: Babylon mechanic

  int score;
  int goodChoices;
  int badChoices;
  int cooldownTurns;
  int revealCooldown;
  int arrestRoundsLeft;

  bool markedForElimination;
  int hitCountdown;

  String? evolvedRole;
  List<String> visitedZones;
  List<ChoiceRecord> history;

  PlayerToken({
    required this.id,
    required this.displayName,
    required this.color,
    List<String>? roles,
    this.position = 0,
    this.isAI = false,
    this.isEliminated = false,
    this.isSilenced = false,
    this.isBlocked = false,
    this.isInspected = false,
    this.isProtected = false,
    this.isRevealed = false,
    this.isGangMember = false,
    this.isArrested = false, // ✅ NEW
    this.score = 0,
    this.goodChoices = 0,
    this.badChoices = 0,
    this.cooldownTurns = 0,
    this.revealCooldown = 0,
    this.arrestRoundsLeft = 0,
    this.markedForElimination = false,
    this.hitCountdown = 0,
    this.evolvedRole,
    List<String>? visitedZones,
    List<ChoiceRecord>? history,
  })  : roles = roles ?? ['Good Youth'],
        visitedZones = visitedZones ?? [],
        history = history ?? [];

  bool get isEmpty => id.isEmpty;

  factory PlayerToken.empty() => PlayerToken(
    id: '',
    displayName: '',
    color: Colors.transparent,
    roles: [],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'color': color.value,
    'roles': roles,
    'position': position,
    'isAI': isAI,
    'isEliminated': isEliminated,
    'isSilenced': isSilenced,
    'isBlocked': isBlocked,
    'isInspected': isInspected,
    'isProtected': isProtected,
    'isRevealed': isRevealed,
    'isGangMember': isGangMember,
    'isArrested': isArrested, // ✅ Include in map
    'score': score,
    'goodChoices': goodChoices,
    'badChoices': badChoices,
    'cooldownTurns': cooldownTurns,
    'revealCooldown': revealCooldown,
    'arrestRoundsLeft': arrestRoundsLeft,
    'markedForElimination': markedForElimination,
    'hitCountdown': hitCountdown,
    'evolvedRole': evolvedRole,
    'visitedZones': visitedZones,
    'history': history.map((e) => e.toMap()).toList(),
  };

  factory PlayerToken.fromMap(Map<String, dynamic> map) => PlayerToken(
    id: map['id'],
    displayName: map['displayName'] ?? 'Player',
    color: Color(map['color']),
    roles: List<String>.from(map['roles'] ?? ['Good Youth']),
    position: map['position'],
    isAI: map['isAI'] ?? false,
    isEliminated: map['isEliminated'] ?? false,
    isSilenced: map['isSilenced'] ?? false,
    isBlocked: map['isBlocked'] ?? false,
    isInspected: map['isInspected'] ?? false,
    isProtected: map['isProtected'] ?? false,
    isRevealed: map['isRevealed'] ?? false,
    isGangMember: map['isGangMember'] ?? false,
    isArrested: map['isArrested'] ?? false, // ✅ Include in factory
    score: map['score'] ?? 0,
    goodChoices: map['goodChoices'] ?? 0,
    badChoices: map['badChoices'] ?? 0,
    cooldownTurns: map['cooldownTurns'] ?? 0,
    revealCooldown: map['revealCooldown'] ?? 0,
    arrestRoundsLeft: map['arrestRoundsLeft'] ?? 0,
    markedForElimination: map['markedForElimination'] ?? false,
    hitCountdown: map['hitCountdown'] ?? 0,
    evolvedRole: map['evolvedRole'],
    visitedZones: List<String>.from(map['visitedZones'] ?? []),
    history: List<Map<String, dynamic>>.from(map['history'] ?? [])
        .map((e) => ChoiceRecord.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  );
}
