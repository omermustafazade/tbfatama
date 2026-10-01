import '../models/referee.dart';
import '../models/match.dart';
import '../models/availability.dart';

class MockData {
  static const String coachAhmet = "c1";
  static const String coachMehmet = "c2";

  static List<Referee> referees = [
    // Mevcut Test Hakemi (Şifre simülasyonu için maili kullanacağız)
    Referee(
        id: "r1",
        name: "Ozan İnce",
        email: "ozan@mail.com",
        role: RefereeRole.kosu,
        level: 8
    ),
    Referee(
        id: "r98",
        name: "Onaysız Hakem",
        email: "yeni@mail.com",
        role: RefereeRole.aday,
        level: 0,
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
        category: "U18",
        location: "Pau Arena",
        coachAId: coachAhmet,
        coachBId: coachMehmet,
        difficultyLevel: 8
    ),
  ];

  static List<Availability> availabilities = [];
}