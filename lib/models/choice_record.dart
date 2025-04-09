class ChoiceRecord {
  final String cardTitle;
  final String decision; // 'good' | 'bad'
  final String description;
  final int points;
  final DateTime timestamp;

  ChoiceRecord({
    required this.cardTitle,
    required this.decision,
    required this.description,
    required this.points,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'cardTitle': cardTitle,
    'decision': decision,
    'description': description,
    'points': points,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChoiceRecord.fromMap(Map<String, dynamic> map) => ChoiceRecord(
    cardTitle: map['cardTitle'],
    decision: map['decision'],
    description: map['description'],
    points: map['points'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
