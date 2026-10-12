import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../models/team.dart';

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

  // ---------------- UYGUNLUK (AVAILABILITY) ----------------
  Stream<List<Availability>> getAvailabilitiesStream() {
    return _db.collection('availabilities').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Availability.fromMap(doc.data())).toList());
  }

  Future<void> saveAvailability(Availability availability) async {
    String docId = "${availability.refereeId}_${availability.date}";
    return _db.collection('availabilities').doc(docId).set(availability.toMap());
  }

  // ---------------- TAKIM VE LİG İŞLEMLERİ (YENİ) ----------------
  Stream<List<Team>> getTeamsStream() {
    return _db.collection('teams').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addTeam(Team team) {
    return _db.collection('teams').doc(team.id).set(team.toMap());
  }

  Future<void> updateTeam(Team team) {
    return _db.collection('teams').doc(team.id).update(team.toMap());
  }

  // Hakem skoru girdiğinde hem maçı hem de takımların kazanma/kaybetme durumlarını günceller
  Future<void> saveMatchScoreAndUpdateStandings(Match match, int scoreA, int scoreB, List<Team> allTeams) async {
    match.teamAScore = scoreA;
    match.teamBScore = scoreB;
    match.isScoreEntered = true;

    // Firebase Batch ile tüm işlemleri aynı anda güvenli şekilde yapıyoruz
    WriteBatch batch = _db.batch();

    // 1. Maçı Güncelle
    DocumentReference matchRef = _db.collection('matches').doc(match.id);
    batch.update(matchRef, match.toMap());

    // 2. A Takımını Güncelle
    try {
      Team teamA = allTeams.firstWhere((t) => t.id == match.teamAId);
      teamA.matchesPlayed += 1;
      if (scoreA > scoreB) teamA.wins += 1;
      else if (scoreA < scoreB) teamA.losses += 1;
      DocumentReference teamARef = _db.collection('teams').doc(teamA.id);
      batch.update(teamARef, teamA.toMap());
    } catch (e) { print("A Takımı bulunamadı."); }

    // 3. B Takımını Güncelle
    try {
      Team teamB = allTeams.firstWhere((t) => t.id == match.teamBId);
      teamB.matchesPlayed += 1;
      if (scoreB > scoreA) teamB.wins += 1;
      else if (scoreB < scoreA) teamB.losses += 1;
      DocumentReference teamBRef = _db.collection('teams').doc(teamB.id);
      batch.update(teamBRef, teamB.toMap());
    } catch (e) { print("B Takımı bulunamadı."); }

    // İşlemleri Onayla
    await batch.commit();
  }
}