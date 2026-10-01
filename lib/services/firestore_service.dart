import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- MAÇ İŞLEMLERİ ----------------
  Stream<List<Match>> getMatchesStream() {
    return _db.collection('matches').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addMatch(Match match) {
    return _db.collection('matches').doc(match.id).set(match.toMap());
  }

  Future<void> updateMatch(Match match) {
    return _db.collection('matches').doc(match.id).update(match.toMap());
  }

  // ---------------- HAKEM İŞLEMLERİ ----------------
  Stream<List<Referee>> getRefereesStream() {
    return _db.collection('referees').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Referee.fromMap(doc.data())).toList());
  }

  Future<void> updateReferee(Referee referee) {
    return _db.collection('referees').doc(referee.id).update(referee.toMap());
  }

  // ---------------- UYGUNLUK (AVAILABILITY) İŞLEMLERİ ----------------
  Stream<List<Availability>> getAvailabilitiesStream() {
    return _db.collection('availabilities').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Availability.fromMap(doc.data())).toList());
  }

  Future<void> saveAvailability(Availability availability) async {
    // Aynı hakemin aynı gündeki önceki uygunluk kaydını ezer (günceller)
    String docId = "${availability.refereeId}_${availability.date}";
    return _db.collection('availabilities').doc(docId).set(availability.toMap());
  }
}