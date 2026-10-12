import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';

class AssignmentService {
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // 7 Gün Kuralı Kontrolü (Sadece bilgilendirme/puan kırma amaçlı)
  bool has7DayConflict(String refId, Match currentMatch, List<Match> allMatches) {
    try {
      DateTime currentDate = DateTime.parse(currentMatch.date);
      for (var m in allMatches) {
        if (m.id == currentMatch.id) continue;
        if (m.headRefereeId != refId && m.assistantRefereeId != refId) continue;

        if (m.teamA == currentMatch.teamA || m.teamB == currentMatch.teamA ||
            m.teamA == currentMatch.teamB || m.teamB == currentMatch.teamB) {
          DateTime pastDate = DateTime.parse(m.date);
          int diffDays = currentDate.difference(pastDate).inDays.abs();
          if (diffDays <= 7) {
            return true;
          }
        }
      }
    } catch (e) {
      return false; // Tarih parse hatası olursa ihlal yok say
    }
    return false;
  }

  void assignRefereesToMatch(Match match, List<Referee> allReferees, List<Availability> availabilities, List<Match> allMatches) {
    int currentMatchMins = _timeToMinutes(match.time);

    // 1. UYGUNLUK VE KONUM FİLTRESİ
    List<Referee> available = allReferees.where((ref) {
      bool isAvailable = availabilities.any((a) => a.refereeId == ref.id && a.date == match.date && a.availableTimes.contains(match.time));
      bool hasTimeConflict = allMatches.any((m) => m.id != match.id && m.date == match.date && m.time == match.time &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id));
      bool noCoachConflict = !ref.conflictCoachIds.contains(match.coachAId) && !ref.conflictCoachIds.contains(match.coachBId);

      bool hasLocationConflict = false;
      var sameDayMatches = allMatches.where((m) => m.date == match.date && m.id != match.id &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id)).toList();
      for (var m in sameDayMatches) {
        int otherMatchMins = _timeToMinutes(m.time);
        int diff = (currentMatchMins - otherMatchMins).abs();
        if (diff < 150 && m.location != match.location) {
          hasLocationConflict = true;
          break;
        }
      }
      return isAvailable && !hasTimeConflict && noCoachConflict && !hasLocationConflict && ref.isApproved;
    }).toList();

    List<String?> assignedIds = [match.headRefereeId, match.assistantRefereeId, match.scorekeeperId, match.timekeeperId, match.shotClockOperatorId];
    available.removeWhere((ref) => assignedIds.contains(ref.id));

    int getLoad(String id) => allMatches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(id)).length;

    // 2. YENİ PUANLAMA SİSTEMİ VE 7 GÜN KURALI
    int calculateScore(Referee ref) {
      int score = 1000;
      score -= getLoad(ref.id) * 100; // Yük dengelemesi
      score += ref.level * 10; // Kategori puanı (5,4,3,2)

      // Salon Optimizasyonu
      var sameDayMatches = allMatches.where((m) => m.date == match.date && m.id != match.id &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id)).toList();
      if (sameDayMatches.any((m) => m.location == match.location)) {
        score += 300;
      }

      // 7 GÜN KURALI (Soft Block: Atamayı yasaklamaz, puanı çok düşürür)
      if (has7DayConflict(ref.id, match, allMatches)) {
        score -= 500;
      }
      return score;
    }

    List<Referee> runningPool = available.where((r) => r.role == RefereeRole.kosu).toList();
    List<Referee> tablePool = available.where((r) => r.role == RefereeRole.masa).toList();

    runningPool.sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));
    tablePool.sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));

    // 3. SAHA HAKEMLERİ (BAŞ VE YARDIMCI) BARAJ KONTROLÜ
    if (match.headRefereeId == null && match.assistantRefereeId == null) {
      // Barajı (Maç Puanı) sağlayan en iyi ikiliyi bulmaya çalış
      Referee? selectedHead;
      Referee? selectedAssistant;

      for (int i = 0; i < runningPool.length; i++) {
        for (int j = i + 1; j < runningPool.length; j++) {
          if ((runningPool[i].level + runningPool[j].level) >= match.matchPoint) {
            selectedHead = runningPool[i];
            selectedAssistant = runningPool[j];
            break;
          }
        }
        if (selectedHead != null) break;
      }

      // Eğer barajı sağlayan ikili yoksa, havuzdaki en iyi 2 kişiyi al (Yönetici manuel müdahale edebilir)
      if (selectedHead == null && runningPool.length >= 2) {
        selectedHead = runningPool[0];
        selectedAssistant = runningPool[1];
      }

      if (selectedHead != null && selectedAssistant != null) {
        match.headRefereeId = selectedHead.id;
        match.assistantRefereeId = selectedAssistant.id;
        runningPool.removeWhere((r) => r.id == match.headRefereeId || r.id == match.assistantRefereeId);
      } else if (runningPool.isNotEmpty) {
        // Sadece 1 hakem kalmışsa
        match.headRefereeId = runningPool.first.id;
        runningPool.removeAt(0);
      }
    } else if (match.headRefereeId == null && runningPool.isNotEmpty) {
      match.headRefereeId = runningPool.first.id;
      runningPool.removeAt(0);
    } else if (match.assistantRefereeId == null && runningPool.isNotEmpty) {
      match.assistantRefereeId = runningPool.first.id;
      runningPool.removeAt(0);
    }

    // 4. MASA HAKEMLERİ
    if (match.scorekeeperId == null && tablePool.isNotEmpty) {
      match.scorekeeperId = tablePool.first.id;
      tablePool.removeAt(0);
    }
    if (match.timekeeperId == null && tablePool.isNotEmpty) {
      match.timekeeperId = tablePool.first.id;
      tablePool.removeAt(0);
    }
    if (match.shotClockOperatorId == null && tablePool.isNotEmpty) {
      match.shotClockOperatorId = tablePool.first.id;
      tablePool.removeAt(0);
    }

    if (match.headRefereeId != null && match.assistantRefereeId != null && match.scorekeeperId != null && match.timekeeperId != null && match.shotClockOperatorId != null) {
      match.status = MatchStatus.waitingForApproval;
    }
  }
}