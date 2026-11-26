import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../models/team.dart';

class DemoSeeder {
  // FIREBASE PERMISSION_DENIED HATASINI ÖNLEYEN OTOMATİK OTURUM AÇICI
  static Future<void> ensureDemoAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return;

    const demoEmail = "sunum_admin@tbfatama.com";
    const demoPass = "TbfSunum2026!";

    try {
      await auth.signInWithEmailAndPassword(email: demoEmail, password: demoPass);
    } catch (_) {
      try {
        await auth.createUserWithEmailAndPassword(email: demoEmail, password: demoPass);
      } catch (_) {
        try {
          await auth.signInAnonymously();
        } catch (_) {}
      }
    }
  }

  static Future<void> seedDemoData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      // 1. Önce Firebase Auth oturumunu garantiye al (Yetki hatasını engeller)
      await ensureDemoAuth();

      final db = FirebaseFirestore.instance;

      // 2. Mevcut verileri güvenli Batch ile temizle
      final collections = ['referees', 'teams', 'matches', 'availabilities'];
      WriteBatch deleteBatch = db.batch();
      int deleteCount = 0;

      for (String coll in collections) {
        var snapshots = await db.collection(coll).get();
        for (var doc in snapshots.docs) {
          if (coll == 'referees' && doc.data()['role'] == 'admin') continue;
          deleteBatch.delete(doc.reference);
          deleteCount++;
          if (deleteCount >= 400) {
            await deleteBatch.commit();
            deleteBatch = db.batch();
            deleteCount = 0;
          }
        }
      }
      if (deleteCount > 0) {
        await deleteBatch.commit();
      }

      // 3. Yeni Kapsamlı Sunum Verilerini Oluştur
      final batch = db.batch();
      final today = DateTime.now();

      String formatDate(DateTime d) =>
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      // Geçmiş Günler
      final String datePast1 = formatDate(today.subtract(const Duration(days: 1)));
      final String datePast2 = formatDate(today.subtract(const Duration(days: 2)));
      final String datePast3 = formatDate(today.subtract(const Duration(days: 3)));
      final String datePast5 = formatDate(today.subtract(const Duration(days: 5)));
      final String datePast7 = formatDate(today.subtract(const Duration(days: 7)));

      // Gelecek 3 Gün (Çok Günlü Atama Şovu İçin)
      final String dateDay1 = formatDate(today.add(const Duration(days: 1))); // 1. Gün (4 Maç)
      final String dateDay2 = formatDate(today.add(const Duration(days: 2))); // 2. Gün (4 Maç)
      final String dateDay3 = formatDate(today.add(const Duration(days: 3))); // 3. Gün (2 Maç - Biri Eksik Uygunluk Senaryosu)

      // =======================================================================
      // 1. 18 HAKEMLİK GENİŞ HAVUZ (10 KOŞU + 6 MASA + 2 ONAY BEKLEYEN)
      // =======================================================================
      final List<Referee> referees = [
        // --- SAHA (KOŞU) HAKEMLERİ (10 KİŞİ) ---
        Referee(id: "demo_kosu_1", name: "Ahmet Yılmaz", email: "ahmet@tbf.com", role: RefereeRole.kosu, level: 5, isApproved: true),
        Referee(id: "demo_kosu_2", name: "Mehmet Demir", email: "mehmet@tbf.com", role: RefereeRole.kosu, level: 5, isApproved: true),
        Referee(id: "demo_kosu_3", name: "Ayşe Kaya", email: "ayse@tbf.com", role: RefereeRole.kosu, level: 4, isApproved: true),
        Referee(id: "demo_kosu_4", name: "Caner Öz", email: "caner@tbf.com", role: RefereeRole.kosu, level: 4, isApproved: true), // 7 Gün Kuralı Cezalısı
        Referee(id: "demo_kosu_5", name: "Sinan Aksoy", email: "sinan@tbf.com", role: RefereeRole.kosu, level: 4, isApproved: true),
        Referee(id: "demo_kosu_6", name: "Burak Taş", email: "burak@tbf.com", role: RefereeRole.kosu, level: 3, isApproved: true),
        Referee(id: "demo_kosu_7", name: "Efe Aydın", email: "efe@tbf.com", role: RefereeRole.kosu, level: 3, isApproved: true),
        Referee(id: "demo_kosu_8", name: "Merve Polat", email: "merve@tbf.com", role: RefereeRole.kosu, level: 3, isApproved: true),
        Referee(id: "demo_kosu_9", name: "Zeynep Çelik", email: "zeynep@tbf.com", role: RefereeRole.kosu, level: 2, isApproved: true),
        Referee(id: "demo_kosu_10", name: "Kerem Yıldız", email: "kerem@tbf.com", role: RefereeRole.kosu, level: 2, isApproved: true),

        // --- MASA GÖREVLİLERİ (6 KİŞİ) ---
        Referee(id: "demo_masa_1", name: "Deniz Ak", email: "deniz@tbf.com", role: RefereeRole.masa, level: 4, isApproved: true),
        Referee(id: "demo_masa_2", name: "Eren Yücel", email: "eren@tbf.com", role: RefereeRole.masa, level: 4, isApproved: true),
        Referee(id: "demo_masa_3", name: "Gizem Şen", email: "gizem@tbf.com", role: RefereeRole.masa, level: 3, isApproved: true),
        Referee(id: "demo_masa_4", name: "Hakan Koç", email: "hakan@tbf.com", role: RefereeRole.masa, level: 3, isApproved: true),
        Referee(id: "demo_masa_5", name: "Irmak Can", email: "irmak@tbf.com", role: RefereeRole.masa, level: 3, isApproved: true),
        Referee(id: "demo_masa_6", name: "Kaan Sönmez", email: "kaan@tbf.com", role: RefereeRole.masa, level: 2, isApproved: true),

        // --- ONAY BEKLEYEN YENİ KAYITLAR (2 KİŞİ) ---
        Referee(id: "demo_pending_1", name: "Emre Demir (Yeni Aday)", email: "emre@aday.com", role: RefereeRole.kosu, level: 2, isApproved: false),
        Referee(id: "demo_pending_2", name: "Selin Yılmaz (Yeni Masa)", email: "selin@aday.com", role: RefereeRole.masa, level: 2, isApproved: false),
      ];

      for (var r in referees) {
        batch.set(db.collection('referees').doc(r.id), r.toMap());
      }

      // =======================================================================
      // 2. 10 TAKIM (4 FARKLI LİG KATEGORİSİ)
      // =======================================================================
      final List<Team> teams = [
        // Büyük Erkekler (Güç: 4 ve 3)
        Team(id: "t_merkez", name: "Merkezefendi Bld", category: "Büyük Erkekler", powerPoint: 4, matchesPlayed: 6, wins: 5, losses: 1),
        Team(id: "t_pau", name: "PAÜ Spor", category: "Büyük Erkekler", powerPoint: 4, matchesPlayed: 6, wins: 4, losses: 2),
        Team(id: "t_pamukkale", name: "Pamukkale Üniversitesi", category: "Büyük Erkekler", powerPoint: 3, matchesPlayed: 5, wins: 2, losses: 3),

        // U18 Erkekler (Güç: 3)
        Team(id: "t_yuksek", name: "Yüksekçıta Koleji", category: "U18 Erkekler", powerPoint: 3, matchesPlayed: 5, wins: 4, losses: 1),
        Team(id: "t_denizli", name: "Denizli Basket", category: "U18 Erkekler", powerPoint: 3, matchesPlayed: 5, wins: 3, losses: 2),
        Team(id: "t_gelisim", name: "Gelişim Koleji", category: "U18 Erkekler", powerPoint: 2, matchesPlayed: 4, wins: 1, losses: 3),

        // U16 Erkekler (Güç: 3 ve 2)
        Team(id: "t_semikler", name: "Şemikler Basket", category: "U16 Erkekler", powerPoint: 3, matchesPlayed: 4, wins: 4, losses: 0),
        Team(id: "t_yesilkoy", name: "Yeşilköy SK", category: "U16 Erkekler", powerPoint: 2, matchesPlayed: 4, wins: 1, losses: 3),

        // U14 Erkekler (Güç: 1)
        Team(id: "t_servergazi", name: "Servergazi SK", category: "U14 Erkekler", powerPoint: 1, matchesPlayed: 4, wins: 3, losses: 1),
        Team(id: "t_camlik", name: "Çamlık BSK", category: "U14 Erkekler", powerPoint: 1, matchesPlayed: 4, wins: 0, losses: 4),
      ];

      for (var t in teams) {
        batch.set(db.collection('teams').doc(t.id), t.toMap());
      }

      // =======================================================================
      // 3. GEÇMİŞ 5 MAÇ (7 GÜN KURALI & SKOR GİRİŞİ TESTLERİ İÇİN)
      // =======================================================================
      final List<Match> pastMatches = [
        // 3 Gün önce: Caner Öz (demo_kosu_4) Merkezefendi maçını yönetti! (7 Gün Kuralı Cezası tetiklenecek)
        Match(
          id: "demo_past_1", date: datePast3, time: "18:00",
          teamA: "Merkezefendi Bld", teamB: "PAÜ Spor", teamAId: "t_merkez", teamBId: "t_pau",
          teamAPoint: 4, teamBPoint: 4, category: "Büyük Erkekler", location: "PAÜ Arena",
          coachAId: "c1", coachBId: "c2", status: MatchStatus.approved,
          teamAScore: 84, teamBScore: 79, isScoreEntered: true,
          headRefereeId: "demo_kosu_4", assistantRefereeId: "demo_kosu_3",
          scorekeeperId: "demo_masa_1", timekeeperId: "demo_masa_2", shotClockOperatorId: "demo_masa_3",
        ),
        // Dün oynandı ama SKORU GİRİLMEDİ! (Ahmet Yılmaz ekranından canlı skor girme şovu için)
        Match(
          id: "demo_past_unscored", date: datePast1, time: "14:00",
          teamA: "Şemikler Basket", teamB: "Yeşilköy SK", teamAId: "t_semikler", teamBId: "t_yesilkoy",
          teamAPoint: 3, teamBPoint: 2, category: "U16 Erkekler", location: "Vali Recep Yazıcıoğlu",
          coachAId: "c5", coachBId: "c6", status: MatchStatus.approved,
          isScoreEntered: false,
          headRefereeId: "demo_kosu_1", assistantRefereeId: "demo_kosu_6",
          scorekeeperId: "demo_masa_1", timekeeperId: "demo_masa_2", shotClockOperatorId: "demo_masa_3",
        ),
        Match(
          id: "demo_past_2", date: datePast2, time: "16:00",
          teamA: "Yüksekçıta Koleji", teamB: "Denizli Basket", teamAId: "t_yuksek", teamBId: "t_denizli",
          teamAPoint: 3, teamBPoint: 3, category: "U18 Erkekler", location: "Hasan Güngör Spor Salonu",
          coachAId: "c3", coachBId: "c4", status: MatchStatus.approved,
          teamAScore: 71, teamBScore: 65, isScoreEntered: true,
          headRefereeId: "demo_kosu_2", assistantRefereeId: "demo_kosu_5",
          scorekeeperId: "demo_masa_4", timekeeperId: "demo_masa_5", shotClockOperatorId: "demo_masa_6",
        ),
        Match(
          id: "demo_past_3", date: datePast5, time: "12:00",
          teamA: "Servergazi SK", teamB: "Çamlık BSK", teamAId: "t_servergazi", teamBId: "t_camlik",
          teamAPoint: 1, teamBPoint: 1, category: "U14 Erkekler", location: "Vali Recep Yazıcıoğlu",
          coachAId: "c7", coachBId: "c8", status: MatchStatus.approved,
          teamAScore: 54, teamBScore: 48, isScoreEntered: true,
          headRefereeId: "demo_kosu_9", assistantRefereeId: "demo_kosu_10",
          scorekeeperId: "demo_masa_1", timekeeperId: "demo_masa_3", shotClockOperatorId: "demo_masa_5",
        ),
        Match(
          id: "demo_past_4", date: datePast7, time: "20:00",
          teamA: "PAÜ Spor", teamB: "Pamukkale Üniversitesi", teamAId: "t_pau", teamBId: "t_pamukkale",
          teamAPoint: 4, teamBPoint: 3, category: "Büyük Erkekler", location: "PAÜ Arena",
          coachAId: "c2", coachBId: "c9", status: MatchStatus.approved,
          teamAScore: 92, teamBScore: 88, isScoreEntered: true,
          headRefereeId: "demo_kosu_1", assistantRefereeId: "demo_kosu_2",
          scorekeeperId: "demo_masa_2", timekeeperId: "demo_masa_4", shotClockOperatorId: "demo_masa_6",
        ),
      ];

      for (var m in pastMatches) {
        batch.set(db.collection('matches').doc(m.id), m.toMap());
      }

      // =======================================================================
      // 4. GELECEK 10 MAÇ (3 FARKLI GÜNE YAYILMIŞ FİKSTÜR)
      // =======================================================================
      final List<Match> futureMatches = [
        // --- 1. GÜN (YARIN - 4 MAÇ) ---
        // MAÇ 1: 14:00 PAÜ Arena | BARAJ: 8 (Derbi - Caner Öz 7 Gün Kuralından Elenir, Ahmet G5 + Mehmet G5 Atanır)
        // * İADE SENARYOSU: Bu maçı onaylayıp bir hakemi sildiğinde Sinan Aksoy (G4) yedekte hazır bekliyor!
        Match(
          id: "m_day1_1", date: dateDay1, time: "14:00",
          teamA: "Merkezefendi Bld", teamB: "PAÜ Spor", teamAId: "t_merkez", teamBId: "t_pau",
          teamAPoint: 4, teamBPoint: 4, category: "Büyük Erkekler", location: "PAÜ Arena",
          coachAId: "c1", coachBId: "c2", status: MatchStatus.pending,
        ),
        // MAÇ 2: 16:00 PAÜ Arena | BARAJ: 6 (Aynı Salon Optimizasyonu +300 Puan!)
        Match(
          id: "m_day1_2", date: dateDay1, time: "16:00",
          teamA: "Yüksekçıta Koleji", teamB: "Denizli Basket", teamAId: "t_yuksek", teamBId: "t_denizli",
          teamAPoint: 3, teamBPoint: 3, category: "U18 Erkekler", location: "PAÜ Arena",
          coachAId: "c3", coachBId: "c4", status: MatchStatus.pending,
        ),
        // MAÇ 3: 15:00 Hasan Güngör | BARAJ: 2 (Mesafe Çakışması Testi + G2 Genç Hakemler Zeynep & Kerem)
        Match(
          id: "m_day1_3", date: dateDay1, time: "15:00",
          teamA: "Servergazi SK", teamB: "Çamlık BSK", teamAId: "t_servergazi", teamBId: "t_camlik",
          teamAPoint: 1, teamBPoint: 1, category: "U14 Erkekler", location: "Hasan Güngör Spor Salonu",
          coachAId: "c7", coachBId: "c8", status: MatchStatus.pending,
        ),
        // MAÇ 4: 18:00 Vali Recep Yazıcıoğlu | BARAJ: 5 (Akşam Maçı)
        Match(
          id: "m_day1_4", date: dateDay1, time: "18:00",
          teamA: "Şemikler Basket", teamB: "Yeşilköy SK", teamAId: "t_semikler", teamBId: "t_yesilkoy",
          teamAPoint: 3, teamBPoint: 2, category: "U16 Erkekler", location: "Vali Recep Yazıcıoğlu",
          coachAId: "c5", coachBId: "c6", status: MatchStatus.pending,
        ),

        // --- 2. GÜN (ERTESİ GÜN - 4 MAÇ) ---
        // MAÇ 5: 12:00 PAÜ Arena | BARAJ: 7
        Match(
          id: "m_day2_1", date: dateDay2, time: "12:00",
          teamA: "PAÜ Spor", teamB: "Pamukkale Üniversitesi", teamAId: "t_pau", teamBId: "t_pamukkale",
          teamAPoint: 4, teamBPoint: 3, category: "Büyük Erkekler", location: "PAÜ Arena",
          coachAId: "c2", coachBId: "c9", status: MatchStatus.pending,
        ),
        // MAÇ 6: 14:00 PAÜ Arena | BARAJ: 5 (Aynı Salon Optimizasyonu)
        Match(
          id: "m_day2_2", date: dateDay2, time: "14:00",
          teamA: "Yüksekçıta Koleji", teamB: "Gelişim Koleji", teamAId: "t_yuksek", teamBId: "t_gelisim",
          teamAPoint: 3, teamBPoint: 2, category: "U18 Erkekler", location: "PAÜ Arena",
          coachAId: "c3", coachBId: "c10", status: MatchStatus.pending,
        ),
        // MAÇ 7: 16:00 Hasan Güngör | BARAJ: 5
        Match(
          id: "m_day2_3", date: dateDay2, time: "16:00",
          teamA: "Denizli Basket", teamB: "Gelişim Koleji", teamAId: "t_denizli", teamBId: "t_gelisim",
          teamAPoint: 3, teamBPoint: 2, category: "U18 Erkekler", location: "Hasan Güngör Spor Salonu",
          coachAId: "c4", coachBId: "c10", status: MatchStatus.pending,
        ),
        // MAÇ 8: 18:00 Vali Recep Yazıcıoğlu | BARAJ: 2 (U14 Rövanş)
        Match(
          id: "m_day2_4", date: dateDay2, time: "18:00",
          teamA: "Çamlık BSK", teamB: "Servergazi SK", teamAId: "t_camlik", teamBId: "t_servergazi",
          teamAPoint: 1, teamBPoint: 1, category: "U14 Erkekler", location: "Vali Recep Yazıcıoğlu",
          coachAId: "c8", coachBId: "c7", status: MatchStatus.pending,
        ),

        // --- 3. GÜN (2 GÜN SONRA - 2 MAÇ) ---
        // MAÇ 9: 18:00 PAÜ Arena | BARAJ: 5
        Match(
          id: "m_day3_1", date: dateDay3, time: "18:00",
          teamA: "Yeşilköy SK", teamB: "Şemikler Basket", teamAId: "t_yesilkoy", teamBId: "t_semikler",
          teamAPoint: 2, teamBPoint: 3, category: "U16 Erkekler", location: "PAÜ Arena",
          coachAId: "c6", coachBId: "c5", status: MatchStatus.pending,
        ),
        // MAÇ 10 (CANLI UYGUNLUK EKLEME ŞOVU MAÇI!): 20:00 PAÜ Arena | BARAJ: 7
        // Bu maça bilerek sadece 1 saha hakemi (Ahmet Yılmaz) uygunluk verdi!
        // Otomatik Ata deyince Yardımcı Hakem BOŞ kalacak. Sunumda Mehmet Demir'in ekranına girip 20:00'ye uygunluk vereceksin!
        Match(
          id: "m_day3_2_eksik", date: dateDay3, time: "20:00",
          teamA: "Merkezefendi Bld", teamB: "Pamukkale Üniversitesi", teamAId: "t_merkez", teamBId: "t_pamukkale",
          teamAPoint: 4, teamBPoint: 3, category: "Büyük Erkekler", location: "PAÜ Arena",
          coachAId: "c1", coachBId: "c9", status: MatchStatus.pending,
        ),
      ];

      for (var m in futureMatches) {
        batch.set(db.collection('matches').doc(m.id), m.toMap());
      }

      // =======================================================================
      // 5. 3 GÜNLÜK UYGUNLUK MATRİSİ (YEDEKLİ & EKSİK SENARYOLU)
      // =======================================================================
      void addAvail(String refId, String date, List<String> times) {
        batch.set(
          db.collection('availabilities').doc("${refId}_$date"),
          Availability(refereeId: refId, date: date, availableTimes: times).toMap(),
        );
      }

      // --- 1. GÜN UYGUNLUKLARI (İade/Değişim için bol yedekli!) ---
      addAvail("demo_kosu_1", dateDay1, ["14:00", "16:00", "18:00"]); // Ahmet (G5)
      addAvail("demo_kosu_2", dateDay1, ["14:00", "16:00"]);          // Mehmet (G5)
      addAvail("demo_kosu_3", dateDay1, ["14:00", "16:00", "18:00"]); // Ayşe (G4 - Yedek/Alternatif)
      addAvail("demo_kosu_4", dateDay1, ["14:00", "16:00"]);          // Caner (G4 - 7 Gün Kuralı Cezalısı)
      addAvail("demo_kosu_5", dateDay1, ["14:00", "16:00", "18:00"]); // Sinan (G4 - İade olursa hemen girecek yedek!)
      addAvail("demo_kosu_6", dateDay1, ["16:00", "18:00"]);          // Burak (G3)
      addAvail("demo_kosu_7", dateDay1, ["18:00"]);                   // Efe (G3)
      addAvail("demo_kosu_8", dateDay1, ["UYGUN DEĞİL"]);             // Merve (G3 - Mazeretli örneği)
      addAvail("demo_kosu_9", dateDay1, ["15:00", "18:00"]);          // Zeynep (G2 - 15:00 U14 maçı)
      addAvail("demo_kosu_10", dateDay1, ["15:00", "18:00"]);         // Kerem (G2 - 15:00 U14 maçı)

      // 1. Gün Masa Görevlileri
      for (var id in ["demo_masa_1", "demo_masa_2", "demo_masa_3", "demo_masa_5"]) {
        addAvail(id, dateDay1, ["14:00", "16:00", "18:00"]);
      }
      for (var id in ["demo_masa_4", "demo_masa_6"]) {
        addAvail(id, dateDay1, ["15:00", "18:00"]);
      }
      // 15:00 maçı için 3. masa görevlisi olarak Irmak Can'a da 15:00 verelim (PAÜ Arena'da 14:00'e atanmazsa oraya geçsin)
      addAvail("demo_masa_5", dateDay1, ["15:00", "18:00"]);

      // --- 2. GÜN UYGUNLUKLARI ---
      addAvail("demo_kosu_1", dateDay2, ["12:00", "14:00"]);
      addAvail("demo_kosu_2", dateDay2, ["12:00", "14:00"]);
      addAvail("demo_kosu_3", dateDay2, ["12:00", "14:00", "16:00"]);
      addAvail("demo_kosu_4", dateDay2, ["14:00", "16:00"]);
      addAvail("demo_kosu_5", dateDay2, ["12:00", "16:00"]);
      addAvail("demo_kosu_6", dateDay2, ["14:00", "16:00", "18:00"]);
      addAvail("demo_kosu_7", dateDay2, ["16:00", "18:00"]);
      addAvail("demo_kosu_8", dateDay2, ["16:00", "18:00"]);
      addAvail("demo_kosu_9", dateDay2, ["18:00"]);
      addAvail("demo_kosu_10", dateDay2, ["18:00"]);

      for (var id in ["demo_masa_1", "demo_masa_2", "demo_masa_3", "demo_masa_4", "demo_masa_5", "demo_masa_6"]) {
        addAvail(id, dateDay2, ["12:00", "14:00", "16:00", "18:00"]);
      }

      // --- 3. GÜN UYGUNLUKLARI (20:00 MAÇINDA BİLEREK EKSİK HAKEM SENARYOSU!) ---
      // 18:00 maçı için yeterli hakem var:
      addAvail("demo_kosu_3", dateDay3, ["18:00"]);
      addAvail("demo_kosu_5", dateDay3, ["18:00"]);
      addAvail("demo_kosu_6", dateDay3, ["18:00"]);
      // AMA 20:00'deki Merkezefendi - Pamukkale maçına SADECE Ahmet Yılmaz (demo_kosu_1) uygunluk vermiş!
      // Mehmet Demir (demo_kosu_2) 3. gün için henüz sadece 18:00'i işaretlemiş (Sunumda girip 20:00'yi ekleyeceksin!)
      addAvail("demo_kosu_1", dateDay3, ["20:00"]);
      addAvail("demo_kosu_2", dateDay3, ["18:00"]);

      for (var id in ["demo_masa_1", "demo_masa_2", "demo_masa_3", "demo_masa_4"]) {
        addAvail(id, dateDay3, ["18:00", "20:00"]);
      }

      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("3 GÜNLÜK 10 MAÇ VE 18 HAKEM YÜKLENDİ! 'OTOMATİK ATA' ile test edebilirsiniz."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Demo verisi yüklenirken hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> clearAllData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      await ensureDemoAuth();
      final db = FirebaseFirestore.instance;
      final collections = ['referees', 'teams', 'matches', 'availabilities'];

      WriteBatch deleteBatch = db.batch();
      int count = 0;

      for (String coll in collections) {
        var snapshots = await db.collection(coll).get();
        for (var doc in snapshots.docs) {
          if (coll == 'referees' && doc.data()['role'] == 'admin') continue;
          deleteBatch.delete(doc.reference);
          count++;
          if (count >= 400) {
            await deleteBatch.commit();
            deleteBatch = db.batch();
            count = 0;
          }
        }
      }
      if (count > 0) await deleteBatch.commit();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SİSTEM SIFIRLANDI! (Tüm demo verileri silindi)"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Temizleme sırasında hata: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}