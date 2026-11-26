import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';

class RefereeEvaluation {
  final Referee referee;
  final bool isEligible;
  final int totalScore;
  final List<String> reasons;

  RefereeEvaluation({
    required this.referee,
    required this.isEligible,
    required this.totalScore,
    required this.reasons,
  });
}

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

        if (m.teamA == currentMatch.teamA ||
            m.teamB == currentMatch.teamA ||
            m.teamA == currentMatch.teamB ||
            m.teamB == currentMatch.teamB) {
          DateTime pastDate = DateTime.parse(m.date);
          int diffDays = currentDate.difference(pastDate).inDays.abs();
          if (diffDays <= 7) {
            return true;
          }
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // SUNUM İÇİN YENİ: Algoritmanın her hakemi nasıl değerlendirdiğini adım adım raporlar
  List<RefereeEvaluation> evaluateRefereesForMatch(
      Match match,
      List<Referee> allReferees,
      List<Availability> availabilities,
      List<Match> allMatches,
      ) {
    int currentMatchMins = _timeToMinutes(match.time);
    int getLoad(String id) => allMatches
        .where((m) => [
      m.headRefereeId,
      m.assistantRefereeId,
      m.scorekeeperId,
      m.timekeeperId,
      m.shotClockOperatorId
    ].contains(id))
        .length;

    List<RefereeEvaluation> evaluations = [];

    for (var ref in allReferees) {
      if (!ref.isApproved || ref.role == RefereeRole.admin) continue;

      List<String> reasons = [];
      bool isAvailable = availabilities.any(
            (a) => a.refereeId == ref.id && a.date == match.date && a.availableTimes.contains(match.time),
      );
      if (!isAvailable) {
        reasons.add("❌ Bu tarih/saat için uygunluk bildirmedi");
      }

      bool hasTimeConflict = allMatches.any((m) =>
      m.id != match.id &&
          m.date == match.date &&
          m.time == match.time &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id));
      if (hasTimeConflict) {
        reasons.add("❌ Aynı saatte başka bir maçta görevli");
      }

      bool noCoachConflict = !ref.conflictCoachIds.contains(match.coachAId) && !ref.conflictCoachIds.contains(match.coachBId);
      if (!noCoachConflict) {
        reasons.add("❌ Antrenör çakışması (Conflict)");
      }

      bool hasLocationConflict = false;
      var sameDayMatches = allMatches
          .where((m) =>
      m.date == match.date &&
          m.id != match.id &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id))
          .toList();

      for (var m in sameDayMatches) {
        int otherMatchMins = _timeToMinutes(m.time);
        int diff = (currentMatchMins - otherMatchMins).abs();
        if (diff < 150 && m.location != match.location) {
          hasLocationConflict = true;
          reasons.add("❌ Farklı salonda (${m.location}) yakın saatli (${m.time}) maçı var (<150 dk)");
          break;
        }
      }

      bool eligible = isAvailable && !hasTimeConflict && noCoachConflict && !hasLocationConflict;

      int score = 0;
      if (eligible) {
        score = 1000;
        reasons.add("⚡ Baz Puan: +1000");

        int load = getLoad(ref.id);
        if (load > 0) {
          score -= load * 100;
          reasons.add("⚖️ Yük Dengelemesi ($load Maç): -${load * 100}");
        } else {
          reasons.add("⚖️ Yük Dengelemesi (0 Maç): Ceza Yok");
        }

        int levelBonus = ref.level * 10;
        score += levelBonus;
        reasons.add("⭐ Derece Katkısı (G${ref.level}): +$levelBonus");

        if (sameDayMatches.any((m) => m.location == match.location)) {
          score += 300;
          reasons.add("🏟️ Salon Optimizasyonu (Aynı Salon): +300");
        }

        if (has7DayConflict(ref.id, match, allMatches)) {
          score -= 500;
          reasons.add("⚠️ 7 Gün Kuralı İhlali (Aynı Takım): -500");
        }
      }

      evaluations.add(
        RefereeEvaluation(
          referee: ref,
          isEligible: eligible,
          totalScore: score,
          reasons: reasons,
        ),
      );
    }

    evaluations.sort((a, b) {
      if (a.isEligible != b.isEligible) return a.isEligible ? -1 : 1;
      return b.totalScore.compareTo(a.totalScore);
    });

    return evaluations;
  }

  void assignRefereesToMatch(
      Match match,
      List<Referee> allReferees,
      List<Availability> availabilities,
      List<Match> allMatches,
      ) {
    int currentMatchMins = _timeToMinutes(match.time);

    // 1. UYGUNLUK VE KONUM FİLTRESİ
    List<Referee> available = allReferees.where((ref) {
      bool isAvailable = availabilities.any(
            (a) => a.refereeId == ref.id && a.date == match.date && a.availableTimes.contains(match.time),
      );
      bool hasTimeConflict = allMatches.any((m) =>
      m.id != match.id &&
          m.date == match.date &&
          m.time == match.time &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id));
      bool noCoachConflict = !ref.conflictCoachIds.contains(match.coachAId) && !ref.conflictCoachIds.contains(match.coachBId);

      bool hasLocationConflict = false;
      var sameDayMatches = allMatches
          .where((m) =>
      m.date == match.date &&
          m.id != match.id &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id))
          .toList();

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

    List<String?> assignedIds = [
      match.headRefereeId,
      match.assistantRefereeId,
      match.scorekeeperId,
      match.timekeeperId,
      match.shotClockOperatorId
    ];
    available.removeWhere((ref) => assignedIds.contains(ref.id));

    int getLoad(String id) => allMatches
        .where((m) => [
      m.headRefereeId,
      m.assistantRefereeId,
      m.scorekeeperId,
      m.timekeeperId,
      m.shotClockOperatorId
    ].contains(id))
        .length;

    // 2. YENİ PUANLAMA SİSTEMİ VE 7 GÜN KURALI
    int calculateScore(Referee ref) {
      int score = 1000;
      score -= getLoad(ref.id) * 100; // Yük dengelemesi
      score += ref.level * 10; // Kategori puanı (5,4,3,2)

      // Salon Optimizasyonu
      var sameDayMatches = allMatches
          .where((m) =>
      m.date == match.date &&
          m.id != match.id &&
          [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(ref.id))
          .toList();
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

      if (selectedHead == null && runningPool.length >= 2) {
        selectedHead = runningPool[0];
        selectedAssistant = runningPool[1];
      }

      if (selectedHead != null && selectedAssistant != null) {
        match.headRefereeId = selectedHead.id;
        match.assistantRefereeId = selectedAssistant.id;
        runningPool.removeWhere((r) => r.id == match.headRefereeId || r.id == match.assistantRefereeId);
      } else if (runningPool.isNotEmpty) {
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

    if (match.headRefereeId != null &&
        match.assistantRefereeId != null &&
        match.scorekeeperId != null &&
        match.timekeeperId != null &&
        match.shotClockOperatorId != null) {
      match.status = MatchStatus.waitingForApproval;
    }
  }
}