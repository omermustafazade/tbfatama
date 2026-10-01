import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';

class AssignmentService {

  // Saati (HH:mm) dakikaya çeviren yardımcı fonksiyon (Zaman farklarını hesaplamak için)
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void assignRefereesToMatch(Match match, List<Referee> allReferees, List<Availability> availabilities, List<Match> allMatches) {

    int currentMatchMins = _timeToMinutes(match.time);

    // 1. UYGUNLUK VE KONUM FİLTRESİ (Lojistik Kontrolü)
    List<Referee> available = allReferees.where((ref) {
      // a) Takvim müsaitliği var mı?
      bool isAvailable = availabilities.any((a) => a.refereeId == ref.id && a.date == match.date && a.availableTimes.contains(match.time));

      // b) Aynı saatte başka maçta mı?
      bool hasTimeConflict = allMatches.any((m) => m.id != match.id && m.date == match.date && m.time == match.time &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id));

      // c) Koç ile husumeti var mı?
      bool noCoachConflict = !ref.conflictCoachIds.contains(match.coachAId) && !ref.conflictCoachIds.contains(match.coachBId);

      // d) YENİ: KONUM ÇAKIŞMASI KONTROLÜ (Yetişememe Engeli)
      bool hasLocationConflict = false;
      var sameDayMatches = allMatches.where((m) => m.date == match.date && m.id != match.id &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id)).toList();

      for (var m in sameDayMatches) {
        int otherMatchMins = _timeToMinutes(m.time);
        int diff = (currentMatchMins - otherMatchMins).abs();

        // Eğer iki maç arasında 150 dakikadan (2.5 saat) az zaman varsa, salonlar AYNI OLMAK ZORUNDA.
        // Farklıysa hakem yolda kalır, atanamaz.
        if (diff < 150 && m.location != match.location) {
          hasLocationConflict = true;
          break;
        }
      }

      return isAvailable && !hasTimeConflict && noCoachConflict && !hasLocationConflict && ref.isApproved;
    }).toList();

    // 2. MÜKERRER ATAMAYI ÖNLE (Aynı maça zaten atanmışsa listeden çıkar)
    List<String?> assignedIds = [match.headRefereeId, match.assistantRefereeId, match.scorekeeperId, match.timekeeperId, match.shotClockOperatorId];
    available.removeWhere((ref) => assignedIds.contains(ref.id));

    // Yük hesaplama
    int getLoad(String id) => allMatches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(id)).length;

    // YENİ: AKILLI PUANLAMA SİSTEMİ (Scoring System)
    // Her hakeme bir uygunluk puanı veriyoruz. Puanı en yüksek olan görevi kapar.
    int calculateScore(Referee ref) {
      int score = 1000;

      // a) Adalet: Maç yükü çok olana ceza (Eksi puan)
      score -= getLoad(ref.id) * 100;

      // b) Kıdem: Seviyesi yüksek olana küçük bir avans
      score += ref.level * 10;

      // c) YENİ: SALON OPTİMİZASYONU BONUSU
      // Hakemin o gün o salonda başka bir maçı varsa, devasa bir bonus ver ki salonda kalsın, yorulmasın.
      var sameDayMatches = allMatches.where((m) => m.date == match.date && m.id != match.id &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id)).toList();

      if (sameDayMatches.any((m) => m.location == match.location)) {
        score += 300;
      }

      return score;
    }

    // 3. HAVUZLARI AYIR VE PUANA GÖRE SIRALA (Büyükten Küçüğe)
    List<Referee> runningPool = available.where((r) => r.role == RefereeRole.kosu || r.role == RefereeRole.aday).toList();
    List<Referee> tablePool = available.where((r) => r.role == RefereeRole.masa || r.role == RefereeRole.aday).toList();

    runningPool.sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));
    tablePool.sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));

    // 4. ATAMA SIRASI VE KURALLARI

    // --- BAŞ HAKEM ATAMASI ---
    if (match.headRefereeId == null && runningPool.isNotEmpty) {
      bool isCriticalMatch = match.difficultyLevel >= 8 || match.category.toLowerCase().contains("büyükler");

      // YENİ: ZOR MAÇ KORUMASI
      // Maç kritikse, Aday hakemleri Baş Hakem havuzundan çıkar.
      List<Referee> headCandidates = List.from(runningPool);
      if (isCriticalMatch) {
        headCandidates.removeWhere((r) => r.role == RefereeRole.aday);
      }

      if (headCandidates.isNotEmpty) {
        match.headRefereeId = headCandidates.first.id;
        tablePool.removeWhere((r) => r.id == match.headRefereeId);
        runningPool.removeWhere((r) => r.id == match.headRefereeId);
      } else if (runningPool.isNotEmpty && !isCriticalMatch) {
        // Kriter yoksa en yüksek puanlıyı ata
        match.headRefereeId = runningPool.first.id;
        tablePool.removeWhere((r) => r.id == match.headRefereeId);
        runningPool.removeAt(0);
      }
    }

    // --- YARDIMCI HAKEM ATAMASI ---
    if (match.assistantRefereeId == null && runningPool.isNotEmpty) {

      // Baş Hakemin kim olduğunu bulalım
      Referee? headRef = allReferees.cast<Referee?>().firstWhere((r) => r?.id == match.headRefereeId, orElse: () => null);

      // YENİ: USTA - ÇIRAK DENGESİ
      // Eğer Baş Hakem bir "Aday" ise, Yardımcı kesinlikle "Aday" OLAMAZ.
      if (headRef != null && headRef.role == RefereeRole.aday) {
        int index = runningPool.indexWhere((r) => r.role != RefereeRole.aday);
        if (index != -1) {
          match.assistantRefereeId = runningPool[index].id;
          tablePool.removeWhere((r) => r.id == match.assistantRefereeId);
          runningPool.removeAt(index);
        }
      } else {
        // Standart atama
        match.assistantRefereeId = runningPool.first.id;
        tablePool.removeWhere((r) => r.id == match.assistantRefereeId);
        runningPool.removeAt(0);
      }
    }

    // --- MASA GÖREVLİLERİ ATAMASI (Sayı, Saat, 24 Saniye) ---
    if (match.scorekeeperId == null && tablePool.isNotEmpty) {
      match.scorekeeperId = tablePool.first.id;
      runningPool.removeWhere((r) => r.id == match.scorekeeperId);
      tablePool.removeAt(0);
    }

    if (match.timekeeperId == null && tablePool.isNotEmpty) {
      match.timekeeperId = tablePool.first.id;
      runningPool.removeWhere((r) => r.id == match.timekeeperId);
      tablePool.removeAt(0);
    }

    if (match.shotClockOperatorId == null && tablePool.isNotEmpty) {
      match.shotClockOperatorId = tablePool.first.id;
      tablePool.removeAt(0);
    }

    // 5. ONAY KONTROLÜ
    // Eğer tüm kadro tamamsa durumu "Onay Bekliyor" yap.
    if (match.headRefereeId != null && match.assistantRefereeId != null && match.scorekeeperId != null && match.timekeeperId != null && match.shotClockOperatorId != null) {
      match.status = MatchStatus.waitingForApproval;
    }
  }
}