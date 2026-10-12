enum RefereeRole { kosu, masa, admin }

class Referee {
  final String id;
  String name; // 'final' kaldırıldı, artık güncellenebilir
  final String email;
  RefereeRole role;
  int level;
  final List<String> conflictCoachIds;
  final List<String> conflictRefereeIds;
  bool isApproved;

  Referee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.level,
    this.conflictCoachIds = const [],
    this.conflictRefereeIds = const [],
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'level': level,
      'isApproved': isApproved,
    };
  }

  factory Referee.fromMap(Map<String, dynamic> map) {
    return Referee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: RefereeRole.values.firstWhere((e) => e.name == map['role'], orElse: () => RefereeRole.kosu),
      level: map['level'] ?? 2,
      isApproved: map['isApproved'] ?? false,
    );
  }
}