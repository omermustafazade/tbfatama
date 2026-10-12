import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../services/assignment_service.dart';
import '../services/firestore_service.dart';

class AdminMatchCard extends StatelessWidget {
  final Match match;
  final List<Referee> referees;
  final List<Availability> availabilities;
  final List<Match> allMatches;
  final bool isPast;

  AdminMatchCard({
    super.key,
    required this.match,
    required this.referees,
    required this.availabilities,
    required this.allMatches,
    this.isPast = false,
  });

  final FirestoreService _firestoreService = FirestoreService();
  final AssignmentService _assignmentService = AssignmentService();

  final Color _darkText = const Color(0xFF1C1C1C);
  final Color _greyText = const Color(0xFF636363);

  Color _getRoleColor(RefereeRole role) {
    switch (role) {
      case RefereeRole.kosu: return const Color(0xFF4FC3F7);
      case RefereeRole.masa: return const Color(0xFFFFB74D);
      case RefereeRole.admin: return Colors.blueGrey;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)),
        title: const Text("MAÇI SİL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        content: Text("${match.teamA} - ${match.teamB}\n\nBu karşılaşmayı sistemden kalıcı olarak silmek istediğinize emin misiniz?", style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VAZGEÇ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('matches').doc(match.id).delete();
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE76F51), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2))),
            child: const Text("SİL", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showChangeDialog(BuildContext context, String? currentId, String roleName, Future<void> Function(String) onSelect) {
    if (match.status == MatchStatus.approved) return;

    int getRefereeLoad(String refId) => allMatches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(refId)).length;

    List<Referee> availableAlternatives = referees.where((r) {
      if (!r.isApproved || r.role == RefereeRole.admin) return false;
      bool isActuallyAvailable = availabilities.any((a) => a.refereeId == r.id && a.date == match.date && a.availableTimes.contains(match.time));
      bool noCoachConflict = !r.conflictCoachIds.contains(match.coachAId) && !r.conflictCoachIds.contains(match.coachBId);
      bool isNotCurrent = r.id != currentId;
      bool hasTimeConflict = allMatches.any((m) => m.id != match.id && m.date == match.date && m.time == match.time && [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(r.id));
      bool roleCheck = (roleName == "BAŞ HAKEM" || roleName == "YARDIMCI") ? r.role == RefereeRole.kosu : r.role == RefereeRole.masa;
      bool isAlreadyInMatch = [match.headRefereeId, match.assistantRefereeId, match.scorekeeperId, match.timekeeperId, match.shotClockOperatorId].contains(r.id);

      return isActuallyAvailable && noCoachConflict && isNotCurrent && roleCheck && !isAlreadyInMatch && !hasTimeConflict;
    }).toList();

    availableAlternatives.sort((a, b) {
      int loadA = getRefereeLoad(a.id);
      int loadB = getRefereeLoad(b.id);
      if (loadA != loadB) return loadA.compareTo(loadB);
      return b.level.compareTo(a.level);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: Colors.black, width: 3), left: BorderSide(color: Colors.black, width: 3), right: BorderSide(color: Colors.black, width: 3))),
        child: Column(
          children: [
            Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text("$roleName SEÇ", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const Divider(color: Colors.black12, thickness: 2, height: 30),
            Expanded(
              child: availableAlternatives.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 40, color: Colors.grey.shade400), const SizedBox(height: 12), const Text("Uygun alternatif bulunamadı.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey))]))
                  : ListView.builder(
                itemCount: availableAlternatives.length,
                itemBuilder: (c, i) {
                  var ref = availableAlternatives[i];
                  int currentLoad = getRefereeLoad(ref.id);
                  bool ruleBroken = _assignmentService.has7DayConflict(ref.id, match, allMatches);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      decoration: BoxDecoration(color: ruleBroken ? Colors.red.shade50 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        onTap: () async { Navigator.pop(ctx); await onSelect(ref.id); },
                        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _getRoleColor(ref.role).withOpacity(0.3), border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text("G${ref.level}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                        title: Text(ref.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${ref.role.name.toUpperCase()} - BU HAFTA: $currentLoad MAÇ", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w900, fontSize: 11)), if (ruleBroken) const Padding(padding: EdgeInsets.only(top: 4.0), child: Text("⚠️ 7 GÜN İHLALİ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11)))]),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: textColor, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // TAŞMA HATASI (OVERFLOW) VE KAZANAN VURGUSU BURADA ÇÖZÜLDÜ
  Widget _buildTeamBlock(String teamName, int powerPoint, TextAlign align, {bool isWinner = false, bool isLoser = false}) {
    CrossAxisAlignment crossAlign = align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    Color textColor = isPast
        ? (isWinner ? Colors.green.shade400 : (isLoser ? Colors.white54 : Colors.white))
        : _darkText;

    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: align == TextAlign.right ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (align == TextAlign.left && isWinner) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 18)),
            Flexible(
              child: Text(
                teamName.toUpperCase(),
                textAlign: align,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, height: 1.1, color: textColor),
              ),
            ),
            if (align == TextAlign.right && isWinner) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 18)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isPast ? (isWinner ? Colors.green.withOpacity(0.15) : Colors.grey.shade800) : const Color(0xFFFFD54F),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isPast ? (isWinner ? Colors.green.shade700 : Colors.white30) : Colors.black, width: 1.5),
            boxShadow: isPast ? [] : const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))],
          ),
          // Darlığı tolere etmek için FittedBox eklendi
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 10, color: isPast ? (isWinner ? Colors.green.shade400 : Colors.white54) : Colors.black87),
                const SizedBox(width: 4),
                Text("KATEGORİ: $powerPoint", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: isPast ? (isWinner ? Colors.green.shade400 : Colors.white) : Colors.black)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _refRow(BuildContext context, String label, String? id, IconData icon, Future<void> Function(String)? onSelect, String roleKey) {
    Referee ref = referees.firstWhere((r) => r.id == id, orElse: () => Referee(id: "", name: "ATAMA BEKLENİYOR", email: "", role: RefereeRole.kosu, level: 0));
    bool isAssigned = id != null;
    bool isApproved = match.status == MatchStatus.approved;

    Color iconBg = isPast ? Colors.grey.shade200 : (isAssigned ? _getRoleColor(ref.role).withOpacity(0.2) : Colors.red.shade50);
    Color iconColor = isPast ? Colors.grey.shade600 : (isAssigned ? _darkText : Colors.red.shade700);
    Color iconBorder = isPast ? Colors.grey.shade400 : (isAssigned ? _darkText : Colors.red.shade700);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: iconBorder, width: 2)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 85,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: _greyText, letterSpacing: 0.5)),
          ),
          Expanded(
            child: Text(
              ref.name.toUpperCase(),
              style: TextStyle(color: isAssigned ? _darkText : Colors.red.shade700, fontWeight: isAssigned ? FontWeight.w900 : FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPast)
            const SizedBox.shrink()
          else if (!isApproved)
            InkWell(
              onTap: onSelect == null ? null : () => _showChangeDialog(context, id, label, onSelect),
              child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300, width: 1.5)), child: Icon(Icons.swap_horiz, size: 16, color: _darkText)),
            )
          else if (isApproved && isAssigned)
              InkWell(
                onTap: () async {
                  if (roleKey == "head") match.headRefereeId = null;
                  if (roleKey == "assistant") match.assistantRefereeId = null;
                  if (roleKey == "score") match.scorekeeperId = null;
                  if (roleKey == "time") match.timekeeperId = null;
                  if (roleKey == "shot") match.shotClockOperatorId = null;
                  match.status = MatchStatus.revisionNeeded;
                  await _firestoreService.updateMatch(match);
                },
                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade200, width: 1.5)), child: Icon(Icons.close, size: 16, color: Colors.red.shade700)),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isApproved = match.status == MatchStatus.approved;
    bool needsRevision = match.status == MatchStatus.revisionNeeded;
    Color topBarColor = isPast ? Colors.grey.shade400 : (needsRevision ? const Color(0xFFEF9A9A) : (isApproved ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80)));
    String statusText = isPast ? (match.isScoreEntered ? "TAMAMLANDI" : "SKOR BEKLİYOR") : (needsRevision ? "İADE / EKSİK" : (isApproved ? "ONAYLANDI" : "BEKLEMEDE"));

    int currentRefereePoints = 0;
    bool hasSoftBlock = false;

    if (match.headRefereeId != null) {
      var r = referees.firstWhere((r) => r.id == match.headRefereeId, orElse: () => Referee(id: "", name: "", email: "", role: RefereeRole.kosu, level: 0));
      currentRefereePoints += r.level;
      if (!isPast && _assignmentService.has7DayConflict(r.id, match, allMatches)) hasSoftBlock = true;
    }
    if (match.assistantRefereeId != null) {
      var r = referees.firstWhere((r) => r.id == match.assistantRefereeId, orElse: () => Referee(id: "", name: "", email: "", role: RefereeRole.kosu, level: 0));
      currentRefereePoints += r.level;
      if (!isPast && _assignmentService.has7DayConflict(r.id, match, allMatches)) hasSoftBlock = true;
    }

    bool isBarajMet = currentRefereePoints >= match.matchPoint;

    // KAZANAN / KAYBEDEN DURUMLARI HESAPLAMASI
    bool teamAWon = match.isScoreEntered && (match.teamAScore ?? 0) > (match.teamBScore ?? 0);
    bool teamBWon = match.isScoreEntered && (match.teamBScore ?? 0) > (match.teamAScore ?? 0);
    bool teamALost = match.isScoreEntered && (match.teamAScore ?? 0) < (match.teamBScore ?? 0);
    bool teamBLost = match.isScoreEntered && (match.teamBScore ?? 0) < (match.teamAScore ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: topBarColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: const Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Colors.white30, offset: Offset(2, 2))]),
                  child: Text(match.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]),
                      child: Text(statusText, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showDeleteConfirmation(context),
                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]), child: const Icon(Icons.delete_outline, color: Color(0xFFE76F51), size: 20)),
                    ),
                  ],
                )
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isPast ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
              border: const Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: isPast && match.isScoreEntered
                ? Row(
              children: [
                Expanded(child: _buildTeamBlock(match.teamA, match.teamAPoint, TextAlign.right, isWinner: teamAWon, isLoser: teamALost)),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5A93C), width: 2), boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(3, 3))]),
                  child: Text("${match.teamAScore} - ${match.teamBScore}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                Expanded(child: _buildTeamBlock(match.teamB, match.teamBPoint, TextAlign.left, isWinner: teamBWon, isLoser: teamBLost)),
              ],
            )
                : Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildTeamBlock(match.teamA, match.teamAPoint, TextAlign.right)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: isPast ? Colors.grey.shade800 : Colors.black, shape: BoxShape.circle, border: Border.all(color: isPast ? Colors.grey : const Color(0xFFE5A93C), width: 2), boxShadow: isPast ? [] : const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))]),
                      child: Text(isPast ? "- : -" : "VS", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
                    ),
                    Expanded(child: _buildTeamBlock(match.teamB, match.teamBPoint, TextAlign.left)),
                  ],
                ),
                if (isPast && !match.isScoreEntered)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange)),
                    child: const Text("SKOR GİRİŞİ BEKLENİYOR", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    _buildInfoChip(Icons.calendar_month, match.date, bgColor: const Color(0xFFE3F2FD), textColor: Colors.black87),
                    _buildInfoChip(Icons.schedule, match.time, bgColor: const Color(0xFFF3E5F5), textColor: Colors.black87),
                    _buildInfoChip(Icons.location_on, match.location, bgColor: const Color(0xFFE0F7FA), textColor: Colors.black87),
                    _buildInfoChip(
                        Icons.shield,
                        "BARAJ: ${match.matchPoint}",
                        bgColor: isPast ? Colors.grey.shade200 : (isBarajMet ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)),
                        textColor: isPast ? Colors.grey.shade700 : (isBarajMet ? Colors.green.shade800 : Colors.red.shade800)
                    ),
                  ],
                ),
                if (hasSoftBlock)
                  Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE76F51), width: 2)), child: const Row(children: [Icon(Icons.warning_amber_rounded, color: Color(0xFFE76F51), size: 20), SizedBox(width: 8), Text("DİKKAT: 7 GÜN KURALI İHLALİ", style: TextStyle(color: Color(0xFFE76F51), fontWeight: FontWeight.w900, fontSize: 12))])),

                const SizedBox(height: 20),
                const Divider(color: Colors.black12, thickness: 2),
                const SizedBox(height: 8),

                _refRow(context, "BAŞ HAKEM", match.headRefereeId, Icons.sports, isPast ? null : (id) async { match.headRefereeId = id; await _firestoreService.updateMatch(match); }, "head"),
                _refRow(context, "YARDIMCI", match.assistantRefereeId, Icons.sports_outlined, isPast ? null : (id) async { match.assistantRefereeId = id; await _firestoreService.updateMatch(match); }, "assistant"),

                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.black12, thickness: 2)),

                _refRow(context, "SAYI", match.scorekeeperId, Icons.calculate_outlined, isPast ? null : (id) async { match.scorekeeperId = id; await _firestoreService.updateMatch(match); }, "score"),
                _refRow(context, "SAAT", match.timekeeperId, Icons.timer_outlined, isPast ? null : (id) async { match.timekeeperId = id; await _firestoreService.updateMatch(match); }, "time"),
                _refRow(context, "24 SN", match.shotClockOperatorId, Icons.av_timer_outlined, isPast ? null : (id) async { match.shotClockOperatorId = id; await _firestoreService.updateMatch(match); }, "shot"),

                if (!isPast && needsRevision) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: InkWell(onTap: () async { _assignmentService.assignRefereesToMatch(match, referees, availabilities, allMatches); await _firestoreService.updateMatch(match); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]), child: const Center(child: Text("OTOMATİK DOLDUR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)))))),
                      const SizedBox(width: 16),
                      Expanded(child: InkWell(onTap: () async { if(match.headRefereeId == null || match.assistantRefereeId == null || match.scorekeeperId == null || match.timekeeperId == null || match.shotClockOperatorId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eksik kadro!"), backgroundColor: Colors.red)); return; } match.status = MatchStatus.approved; await _firestoreService.updateMatch(match); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: const Color(0xFF2A9D8F), border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]), child: const Center(child: Text("KADROYU ONAYLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)))))),
                    ],
                  )
                ]
                else if (!isPast && !isApproved) ...[
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async { if(match.headRefereeId == null || match.assistantRefereeId == null || match.scorekeeperId == null || match.timekeeperId == null || match.shotClockOperatorId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eksik kadro ile maç onaylanamaz!"), backgroundColor: Colors.red)); return; } match.status = MatchStatus.approved; await _firestoreService.updateMatch(match); },
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0xFF2A9D8F), offset: Offset(4, 4))]), child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: Color(0xFF2A9D8F), size: 24), SizedBox(width: 8), Text("TÜM ATAMALARI ONAYLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1))]))),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}