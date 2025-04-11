// abilities.dart

import '../models/player_token.dart';

class RoleAbilities {
  static void sendHit(List<PlayerToken> players, String targetId) {
    final target = players.firstWhere((p) => p.id == targetId, orElse: () => PlayerToken.empty());
    if (!target.isEmpty && !target.isEliminated) {
      target.markedForElimination = true;
      target.hitCountdown = 2;
    }
  }

  static void processHitCountdown(List<PlayerToken> players) {
    for (var player in players) {
      if (player.markedForElimination && !player.isProtected) {
        player.hitCountdown -= 1;
        if (player.hitCountdown <= 0) {
          player.isEliminated = true;
        }
      }
    }
  }

  static void protectPlayer(List<PlayerToken> players, String targetId) {
    final target = players.firstWhere((p) => p.id == targetId, orElse: () => PlayerToken.empty());
    if (!target.isEmpty && !target.isEliminated) {
      target.isProtected = true;
    }
  }

  static void clearProtections(List<PlayerToken> players) {
    for (var player in players) {
      player.isProtected = false;
    }
  }

  static String exposePlayer(List<PlayerToken> players, String targetId) {
    final target = players.firstWhere((p) => p.id == targetId, orElse: () => PlayerToken.empty());
    if (!target.isEmpty && !target.isEliminated) {
      return target.evolvedRole ?? "No role assigned";
    }
    return "Player not found";
  }

  static void arrestPlayer(List<PlayerToken> players, String targetId) {
    final target = players.firstWhere((p) => p.id == targetId, orElse: () => PlayerToken.empty());
    if (!target.isEmpty && !target.isEliminated) {
      target.isArrested = true;
      target.arrestRoundsLeft = 2;
    }
  }

  static void processArrests(List<PlayerToken> players) {
    for (var player in players) {
      if (player.isArrested) {
        player.arrestRoundsLeft -= 1;
        if (player.arrestRoundsLeft <= 0) {
          player.isArrested = false;
        }
      }
    }
  }
}
