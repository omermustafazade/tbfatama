import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../models/team.dart';

class DemoSeeder {
  static Future<void> seedDemoData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final random = Random();

      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final dayAfterTomorrow = today.add(const Duration(days: 2));

      String formatDate(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      // 1. KAPSAMLI HAKEM LİSTESİ OLUŞTURMA (20 HAKEM)
      List<String> kosuNames = ["Ali Yılmaz", "Veli Demir", "Ayşe Kaya", "Fatma Çelik", "Can Öz", "Burak Taş", "Efe Aydın", "Kerem Yıldız"];
      List<String> masaNames = ["Deniz Ak", "Eren Yücel", "Gizem Şen", "Hakan Koç", "Irmak Can", "Kaan Sönmez", "Leyla Gül", "Murat Arslan", "Nilay Kurt", "Ozan İnce", "Seda Nur", "Tarık Çam"];

      List<Referee> createdReferees = [];

      for (int i = 0; i < kosuNames.length; i++) {
        final r = Referee(
            id: "demo_kosu_$i", name: kosuNames[i], email: "kosu$i@demo.com",
            role: RefereeRole.kosu, level: random.nextInt(4) + 2, isApproved: true // Seviye 2 ile 5 arası
        );
        createdReferees.add(r);
        batch.set(db.collection('referees').doc(r.id), r.toMap());
      }

      for (int i = 0; i < masaNames.length; i++) {
        final r = Referee(
            id: "demo_masa_$i", name: masaNames[i], email: "masa$i@demo.com",
            role: RefereeRole.masa, level: random.nextInt(4) + 2, isApproved: true
        );
        createdReferees.add(r);
        batch.set(db.collection('referees').doc(r.id), r.toMap());
      }

      // 2. KAPSAMLI TAKIM LİSTESİ OLUŞTURMA (12 TAKIM)
      List<String> teamNames = [
        "Merkezefendi Bld", "PAÜ Spor", "Yüksekçıta", "Şemikler Basketbol",
        "Denizli Basket", "Yeşilköy SK", "Servergazi SK", "Çamlık BSK",
        "İncilipınar", "Uğur Okulları", "Gelişim Koleji", "Bozkurt Spor"
      ];
      List<String> categories = ["U18 Erkekler", "U16 Erkekler", "Büyük Erkekler"];

      Map<String, Team> teamMap = {};

      for (int i = 0; i < teamNames.length; i++) {
        String cat = categories[i % categories.length];
        final t = Team(
            id: "demo_team_$i", name: teamNames[i], category: cat, powerPoint: random.nextInt(4) + 1
        );
        teamMap[t.id] = t;
      }

      // 3. GEÇMİŞ MAÇLARI OLUŞTURMA (İstatistikleri doldurmak için)
      List<String> locations = ["PAU Arena", "Hasan Güngör Spor Salonu", "Vali Recep Yazıcıoğlu", "Gümüşler"];
      List<String> times = ["10:00", "12:00", "14:00", "16:00", "18:00", "20:00"];

      int pastMatchCount = 15;
      for (int i = 0; i < pastMatchCount; i++) {
        Team tA = teamMap.values.elementAt(random.nextInt(teamMap.length));
        Team tB = teamMap.values.elementAt(random.nextInt(teamMap.length));
        while (tB.id == tA.id || tB.category != tA.category) { // Aynı takım veya farklı kategori olmasın
          tB = teamMap.values.elementAt(random.nextInt(teamMap.length));
        }

        int scoreA = random.nextInt(50) + 40;
        int scoreB = random.nextInt(50) + 40;
        if (scoreA == scoreB) scoreA += 1; // Beraberlik olmasın

        // Takım istatistiklerini güncelle (Memory'de)
        tA.matchesPlayed += 1;
        tB.matchesPlayed += 1;
        if (scoreA > scoreB) { tA.wins += 1; tB.losses += 1; }
        else { tB.wins += 1; tA.losses += 1; }

        DateTime pastDate = today.subtract(Duration(days: random.nextInt(10) + 1));

        final m = Match(
          id: "demo_past_match_$i", date: formatDate(pastDate), time: times[random.nextInt(times.length)],
          teamA: tA.name, teamB: tB.name, teamAId: tA.id, teamBId: tB.id,
          teamAPoint: tA.powerPoint, teamBPoint: tB.powerPoint,
          category: tA.category, location: locations[random.nextInt(locations.length)],
          coachAId: "c_A_$i", coachBId: "c_B_$i",
          status: MatchStatus.approved,
          teamAScore: scoreA, teamBScore: scoreB, isScoreEntered: true,
          headRefereeId: createdReferees[0].id, // Geçmiş maçlar için rastgele hakem
          assistantRefereeId: createdReferees[1].id,
          scorekeeperId: createdReferees[8].id,
          timekeeperId: createdReferees[9].id,
          shotClockOperatorId: createdReferees[10].id,
        );
        batch.set(db.collection('matches').doc(m.id), m.toMap());
      }

      // Takımların güncel istatistiklerini DB'ye yaz
      for (var t in teamMap.values) {
        batch.set(db.collection('teams').doc(t.id), t.toMap());
      }

      // 4. GELECEK MAÇLARI OLUŞTURMA (Algoritmanın atama yapması için bekleyen maçlar)
      int futureMatchCount = 10;
      for (int i = 0; i < futureMatchCount; i++) {
        Team tA = teamMap.values.elementAt(random.nextInt(teamMap.length));
        Team tB = teamMap.values.elementAt(random.nextInt(teamMap.length));
        while (tB.id == tA.id || tB.category != tA.category) {
          tB = teamMap.values.elementAt(random.nextInt(teamMap.length));
        }

        DateTime futureDate = (i % 2 == 0) ? tomorrow : dayAfterTomorrow;

        final m = Match(
          id: "demo_future_match_$i", date: formatDate(futureDate), time: times[i % times.length],
          teamA: tA.name, teamB: tB.name, teamAId: tA.id, teamBId: tB.id,
          teamAPoint: tA.powerPoint, teamBPoint: tB.powerPoint,
          category: tA.category, location: locations[i % locations.length],
          coachAId: "fc_A_$i", coachBId: "fc_B_$i",
          status: MatchStatus.pending,
        );
        batch.set(db.collection('matches').doc(m.id), m.toMap());
      }

      // 5. HAKEM UYGUNLUKLARINI EKLE (Tüm hakemler gelecek maç saatlerine uygun olsun ki algoritma sorunsuz çalışsın)
      for (var ref in createdReferees) {
        // Yarın için uygunluk
        final availTomorrow = Availability(
            refereeId: ref.id, date: formatDate(tomorrow), availableTimes: times
        );
        batch.set(db.collection('availabilities').doc("${ref.id}_${formatDate(tomorrow)}"), availTomorrow.toMap());

        // Öbür gün için uygunluk
        final availDayAfter = Availability(
            refereeId: ref.id, date: formatDate(dayAfterTomorrow), availableTimes: times
        );
        batch.set(db.collection('availabilities').doc("${ref.id}_${formatDate(dayAfterTomorrow)}"), availDayAfter.toMap());
      }

      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Yüklenme ekranını kapat
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("TAM SİMÜLASYON YÜKLENDİ! Geçmiş maçlar, istatistikler ve bekleyen atamalar hazır."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Demo verisi yüklenirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}