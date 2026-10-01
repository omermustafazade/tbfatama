enum MatchStatus { pending, waitingForApproval, approved, revisionNeeded }

class Match {
  String id;
  final String date;
  final String time;
  final String teamA;
  final String teamB;
  final String category; // EKLENEN KATEGORİ ALANI
  final String location; // YENİ EKLENEN KONUM/SALON ALANI
  final String coachAId;
  final String coachBId;
  final int difficultyLevel;

  String? headRefereeId;
  String? assistantRefereeId;
  String? scorekeeperId;
  String? timekeeperId;
  String? shotClockOperatorId;

  MatchStatus status;

  Match({
    required this.id,
    required this.date,
    required this.time,
    required this.teamA,
    required this.teamB,
    required this.category,
    required this.location, // YENİ EKLENEN KONUM/SALON ALANI
    required this.coachAId,
    required this.coachBId,
    required this.difficultyLevel,
    this.headRefereeId,
    this.assistantRefereeId,
    this.scorekeeperId,
    this.timekeeperId,
    this.shotClockOperatorId,
    this.status = MatchStatus.pending,
  });

  // FIREBASE'E YAZMAK İÇİN
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'teamA': teamA,
      'teamB': teamB,
      'category': category,
      'location': location, // Firebase'e yazıyoruz
      'coachAId': coachAId,
      'coachBId': coachBId,
      'difficultyLevel': difficultyLevel,
      'headRefereeId': headRefereeId,
      'assistantRefereeId': assistantRefereeId,
      'scorekeeperId': scorekeeperId,
      'timekeeperId': timekeeperId,
      'shotClockOperatorId': shotClockOperatorId,
      'status': status.name,
    };
  }

  // FIREBASE'DEN OKUMAK İÇİN
  factory Match.fromMap(Map<String, dynamic> map, String docId) {
    return Match(
      id: docId,
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      teamA: map['teamA'] ?? '',
      teamB: map['teamB'] ?? '',
      category: map['category'] ?? 'Belirtilmedi',
      location: map['location'] ?? 'Bilinmeyen Salon', // Firebase'den okuyoruz
      coachAId: map['coachAId'] ?? '',
      coachBId: map['coachBId'] ?? '',
      difficultyLevel: map['difficultyLevel'] ?? 1,
      headRefereeId: map['headRefereeId'],
      assistantRefereeId: map['assistantRefereeId'],
      scorekeeperId: map['scorekeeperId'],
      timekeeperId: map['timekeeperId'],
      shotClockOperatorId: map['shotClockOperatorId'],
      status: MatchStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => MatchStatus.pending,
      ),
    );
  }
}