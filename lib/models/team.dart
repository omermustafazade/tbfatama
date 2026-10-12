class Team {
  String id;
  String name;
  String category;
  int powerPoint; // 1, 2, 3, 4
  int matchesPlayed;
  int wins;
  int losses;

  Team({
    required this.id,
    required this.name,
    required this.category,
    required this.powerPoint,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'powerPoint': powerPoint,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
    };
  }

  factory Team.fromMap(Map<String, dynamic> map, String docId) {
    return Team(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Belirtilmedi',
      powerPoint: map['powerPoint'] ?? 2,
      matchesPlayed: map['matchesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
    );
  }
}