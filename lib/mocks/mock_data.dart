import '../models/referee.dart';
import '../models/match.dart';
import '../models/availability.dart';

class MockData {
  static const String coachAhmet = "c1";
  static const String coachMehmet = "c2";

  static List<Referee> referees = [
    Referee(
        id: "r1",
        name: "Ozan İnce",
        email: "ozan@mail.com",
        role: RefereeRole.kosu,
        level: 4 // Puan (2, 3, 4, 5)
    ),
    Referee(
        id: "r98",
        name: "Onaysız Hakem",
        email: "yeni@mail.com",
        role: RefereeRole.kosu,
        level: 2,
        isApproved: false
    ),
  ];

  static List<Match> matches = [
    Match(
        id: "m1",
        date: "2026-10-05",
        time: "14:00",
        teamA: "Gelişim",
        teamB: "Bahçeşehir",
        teamAPoint: 4,
        teamBPoint: 3,
        category: "U18",
        location: "PAU Arena",
        coachAId: coachAhmet,
        coachBId: coachMehmet
    ),
  ];

  static List<Availability> availabilities = [];
}