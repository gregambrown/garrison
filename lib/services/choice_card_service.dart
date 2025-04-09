import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/choice_card.dart';

class ChoiceCardService {
  static List<ChoiceCard>? _cachedCards;

  /// Load cards from JSON asset (once)
  static Future<List<ChoiceCard>> loadCards() async {
    if (_cachedCards != null) return _cachedCards!;

    final data = await rootBundle.loadString('assets/cards.json');
    final List<dynamic> decoded = json.decode(data);
    _cachedCards = decoded.map((e) => ChoiceCard.fromMap(e)).toList();
    return _cachedCards!;
  }

  /// Draw a random card, optionally using tileType for filtering
  static Future<ChoiceCard> drawRandomCard({String? tileType}) async {
    final cards = await loadCards();

    if (tileType != null) {
      final matching = cards.where((c) =>
      c.tileTypes?.contains(tileType) == true || (c.requiresTileMatch != true)
      ).toList();

      if (matching.isNotEmpty) {
        matching.shuffle();
        return matching.first;
      }
    }

    // fallback to full deck
    cards.shuffle();
    return cards.first;
  }
}
