class Availability {
  final String refereeId;
  final String date;
  final List<String> availableTimes;

  Availability({
    required this.refereeId,
    required this.date,
    required this.availableTimes,
  });

  // FIREBASE'E YAZMAK İÇİN
  Map<String, dynamic> toMap() {
    return {
      'refereeId': refereeId,
      'date': date,
      'availableTimes': availableTimes,
    };
  }

  // FIREBASE'DEN OKUMAK İÇİN
  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      refereeId: map['refereeId'] ?? '',
      date: map['date'] ?? '',
      availableTimes: List<String>.from(map['availableTimes'] ?? []),
    );
  }
}