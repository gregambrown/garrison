class ChoiceCard {
  final String id;
  final String title;
  final String goodAction;
  final String badAction;
  final int goodPoints;
  final int badPoints;
  final bool isHotSpot;
  final String? unlockRole; // "Don", "MP", "Babylon", "JP" or null
  final List<String>? tileTypes; // new: which tiles this card applies to
  final bool requiresTileMatch; // new: whether this card must match tile to activate

  ChoiceCard({
    required this.id,
    required this.title,
    required this.goodAction,
    required this.badAction,
    required this.goodPoints,
    required this.badPoints,
    this.isHotSpot = false,
    this.unlockRole,
    this.requiresTileMatch = false,
    this.tileTypes,
  });

  factory ChoiceCard.fromMap(Map<String, dynamic> map) {
    return ChoiceCard(
      id: map['id'],
      title: map['title'],
      goodAction: map['goodAction'],
      badAction: map['badAction'],
      goodPoints: map['goodPoints'],
      badPoints: map['badPoints'],
      isHotSpot: map['isHotSpot'] ?? false,
      unlockRole: map['unlockRole'],
      requiresTileMatch: map['requiresTileMatch'] ?? false,
      tileTypes: List<String>.from(map['tileTypes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'goodAction': goodAction,
      'badAction': badAction,
      'goodPoints': goodPoints,
      'badPoints': badPoints,
      'isHotSpot': isHotSpot,
      'unlockRole': unlockRole,
      'requiresTileMatch': requiresTileMatch,
      'tileTypes': tileTypes,
    };
  }
}
