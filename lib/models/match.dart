enum MatchStatus { pending, waitingForApproval, approved, revisionNeeded }

class Match {
  String id;
  final String date;
  final String time;
  final String teamA;
  final String teamB;
  final String teamAId; // YENİ
  final String teamBId; // YENİ
  final int teamAPoint;
  final int teamBPoint;
  final String category;
  final String location;
  final String coachAId;
  final String coachBId;
  String? headRefereeId;
  String? assistantRefereeId;
  String? scorekeeperId;
  String? timekeeperId;
  String? shotClockOperatorId;
  MatchStatus status;

  // YENİ SKOR ALANLARI
  int? teamAScore;
  int? teamBScore;
  bool isScoreEntered;

  int get matchPoint => teamAPoint + teamBPoint;

  Match({
    required this.id,
    required this.date,
    required this.time,
    required this.teamA,
    required this.teamB,
    required this.teamAId,
    required this.teamBId,
    required this.teamAPoint,
    required this.teamBPoint,
    required this.category,
    required this.location,
    required this.coachAId,
    required this.coachBId,
    this.headRefereeId,
    this.assistantRefereeId,
    this.scorekeeperId,
    this.timekeeperId,
    this.shotClockOperatorId,
    this.status = MatchStatus.pending,
    this.teamAScore,
    this.teamBScore,
    this.isScoreEntered = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'teamA': teamA,
      'teamB': teamB,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'teamAPoint': teamAPoint,
      'teamBPoint': teamBPoint,
      'category': category,
      'location': location,
      'coachAId': coachAId,
      'coachBId': coachBId,
      'headRefereeId': headRefereeId,
      'assistantRefereeId': assistantRefereeId,
      'scorekeeperId': scorekeeperId,
      'timekeeperId': timekeeperId,
      'shotClockOperatorId': shotClockOperatorId,
      'status': status.name,
      'teamAScore': teamAScore,
      'teamBScore': teamBScore,
      'isScoreEntered': isScoreEntered,
    };
  }

  factory Match.fromMap(Map<String, dynamic> map, String docId) {
    return Match(
      id: docId,
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      teamA: map['teamA'] ?? '',
      teamB: map['teamB'] ?? '',
      teamAId: map['teamAId'] ?? '',
      teamBId: map['teamBId'] ?? '',
      teamAPoint: map['teamAPoint'] ?? 1,
      teamBPoint: map['teamBPoint'] ?? 1,
      category: map['category'] ?? 'Belirtilmedi',
      location: map['location'] ?? 'Bilinmeyen Salon',
      coachAId: map['coachAId'] ?? '',
      coachBId: map['coachBId'] ?? '',
      headRefereeId: map['headRefereeId'],
      assistantRefereeId: map['assistantRefereeId'],
      scorekeeperId: map['scorekeeperId'],
      timekeeperId: map['timekeeperId'],
      shotClockOperatorId: map['shotClockOperatorId'],
      status: MatchStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => MatchStatus.pending),
      teamAScore: map['teamAScore'],
      teamBScore: map['teamBScore'],
      isScoreEntered: map['isScoreEntered'] ?? false,
    );
  }
}