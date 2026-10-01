import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../services/assignment_service.dart';
import '../services/firestore_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final FirestoreService _firestoreService = FirestoreService();

  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _primaryColor = Colors.orange.shade800;
  final Color _borderColor = const Color(0xFF1C1C1C);

  Color _getRoleColor(RefereeRole role) {
    switch (role) {
      case RefereeRole.kosu: return const Color(0xFF4FC3F7);
      case RefereeRole.masa: return const Color(0xFFFFB74D);
      case RefereeRole.aday: return const Color(0xFFAED581);
      case RefereeRole.admin: return Colors.blueGrey;
    }
  }

  Future<void> _autoAssign(List<Match> matches, List<Referee> referees, List<Availability> availabilities) async {
    for (var m in matches) {
      if (m.status == MatchStatus.pending || m.status == MatchStatus.revisionNeeded) {
        _assignmentService.assignRefereesToMatch(m, referees, availabilities, matches);
        await _firestoreService.updateMatch(m);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Otomatik atamalar adaletli bir şekilde tamamlandı!"), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildSolidCard({required Widget child, Color color = Colors.white, EdgeInsetsGeometry? padding, double? width, double? height}) {
    return Container(
      width: width, height: height, padding: padding,
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: child,
    );
  }

  void _showAddMatchDialog() {
    final DateTime now = DateTime.now();
    final teamAController = TextEditingController();
    final teamBController = TextEditingController();
    final categoryController = TextEditingController();
    // YENİ: Konum Controller'ı
    final locationController = TextEditingController();

    final dateController = TextEditingController(text: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}");
    final timeController = TextEditingController(text: "${now.hour.toString().padLeft(2, '0')}:00");
    double difficulty = 5;

    final List<String> quickCategories = ["U10", "U12", "U14", "U16", "U18", "Büyükler"];
    // YENİ: Hızlı Seçim Konumları (Kendi şehrine/salonlarına göre burayı güncelleyebilirsin)
    final List<String> quickLocations = ["Vali Recep Yazicioglu", "Pau Arena", "Pau cadir salon", "Hasan GUngor"];

    Future<void> selectDate(BuildContext context) async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: _primaryColor),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      }
    }

    Future<void> selectTime(BuildContext context) async {
      TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: now.hour, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: _primaryColor),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: _borderColor, width: 3),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: List<Widget>.empty().length == 0 ? MainAxisSize.min : MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 20),
                      const Text("YENİ MAÇ EKLE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),

                      _buildInput("KATEGORİ (Elle yazın veya aşağıdan seçin)", categoryController),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: quickCategories.map((cat) => InkWell(
                          onTap: () => setModalState(() => categoryController.text = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: categoryController.text == cat ? _primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: Text(cat, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: categoryController.text == cat ? Colors.white : Colors.black)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),

                      // YENİ: KONUM ALANI VE HIZLI SEÇİM BUTONLARI
                      _buildInput("KONUM / SALON (Elle yazın veya seçin)", locationController),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: quickLocations.map((loc) => InkWell(
                          onTap: () => setModalState(() => locationController.text = loc),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: locationController.text == loc ? Colors.blueGrey : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: Text(loc, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: locationController.text == loc ? Colors.white : Colors.black)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: _buildInput("A TAKIMI", teamAController)),
                          const SizedBox(width: 12),
                          const Text("VS", style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInput("B TAKIMI", teamBController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("TARİH", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: dateController, readOnly: true, onTap: () => selectDate(context),
                                  decoration: InputDecoration(
                                    filled: true, fillColor: Colors.white,
                                    suffixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.black87),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)),
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(6)),
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("SAAT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: timeController, readOnly: true, onTap: () => selectTime(context),
                                  decoration: InputDecoration(
                                    filled: true, fillColor: Colors.white,
                                    suffixIcon: const Icon(Icons.access_time, size: 20, color: Colors.black87),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)),
                                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(6)),
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("ZORLUK SEVİYESİ: ${difficulty.toInt()}/10", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      Slider(
                        value: difficulty, min: 1, max: 10, divisions: 9,
                        activeColor: _primaryColor, inactiveColor: Colors.orange.shade200,
                        onChanged: (val) => setModalState(() => difficulty = val),
                      ),
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () async {
                          if(teamAController.text.isEmpty || teamBController.text.isEmpty) return;

                          String finalCategory = categoryController.text.trim();
                          if(finalCategory.isEmpty) finalCategory = "Belirtilmedi";

                          // Konum boş kalırsa varsayılan değer atıyoruz
                          String finalLocation = locationController.text.trim();
                          if(finalLocation.isEmpty) finalLocation = "Bilinmeyen Salon";

                          final newMatch = Match(
                            id: "m_${DateTime.now().millisecondsSinceEpoch}",
                            category: finalCategory,
                            location: finalLocation, // YENİ EKLENEN ALAN
                            date: dateController.text.trim(),
                            time: timeController.text.trim(),
                            teamA: teamAController.text.trim(),
                            teamB: teamBController.text.trim(),
                            coachAId: "c1",
                            coachBId: "c2",
                            difficultyLevel: difficulty.toInt(),
                            status: MatchStatus.pending,
                          );
                          await _firestoreService.addMatch(newMatch);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maç başarıyla fikstüre eklendi!"), backgroundColor: Colors.green));
                          }
                        },
                        child: _buildSolidCard(
                          color: _primaryColor, width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Center(child: Text("MAÇI FİKSTÜRE EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
      ),
    );
  }

  void _showDeleteConfirmation(Match match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black, width: 2)),
        title: const Text("MAÇI SİL / İPTAL ET", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("${match.teamA} - ${match.teamB} karşılaşmasını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VAZGEÇ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('matches').doc(match.id).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(6)),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showChangeDialog(Match match, String? currentId, String roleName, Future<void> Function(String) onSelect, List<Referee> referees, List<Availability> availabilities, List<Match> allMatches) {
    if (match.status == MatchStatus.approved) return;
    int getRefereeLoad(String refId) {
      return allMatches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(refId)).length;
    }
    List<Referee> availableAlternatives = referees.where((r) {
      if(!r.isApproved || r.role == RefereeRole.admin) return false;
      bool isActuallyAvailable = availabilities.any((a) => a.refereeId == r.id && a.date == match.date && a.availableTimes.contains(match.time));
      bool noCoachConflict = !r.conflictCoachIds.contains(match.coachAId) && !r.conflictCoachIds.contains(match.coachBId);
      bool isNotCurrent = r.id != currentId;
      bool hasTimeConflict = allMatches.any((m) => m.id != match.id && m.date == match.date && m.time == match.time && [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(r.id));
      bool roleCheck = true;
      if (roleName == "BAŞ HAKEM" || roleName == "YARD. HAKEM") {
        roleCheck = (r.role == RefereeRole.kosu || r.role == RefereeRole.aday);
      } else {
        roleCheck = (r.role == RefereeRole.masa || r.role == RefereeRole.aday);
      }
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: _borderColor, width: 3),
        ),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Text("$roleName SEÇİMİ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text("${match.time} seansına uygun alternatifler", style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.black12, thickness: 2, height: 30),
            Expanded(
              child: availableAlternatives.isEmpty
                  ? const Center(child: Text("Uygun alternatif bulunamadı.", style: TextStyle(fontWeight: FontWeight.bold)))
                  : ListView.builder(
                itemCount: availableAlternatives.length,
                itemBuilder: (c, i) {
                  var ref = availableAlternatives[i];
                  int currentLoad = getRefereeLoad(ref.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildSolidCard(
                      color: Colors.grey.shade50,
                      child: ListTile(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await onSelect(ref.id);
                        },
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: _getRoleColor(ref.role).withOpacity(0.5), border: Border.all(color: _borderColor, width: 1.5)),
                          alignment: Alignment.center,
                          child: Text("L${ref.level}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                        title: Text(ref.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ref.role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            Text("BU HAFTA: $currentLoad MAÇ", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w900, fontSize: 10)),
                          ],
                        ),
                        trailing: const Icon(Icons.swap_horiz, color: Colors.black, size: 24),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Match>>(
        stream: _firestoreService.getMatchesStream(),
        builder: (context, matchSnap) {
          return StreamBuilder<List<Referee>>(
              stream: _firestoreService.getRefereesStream(),
              builder: (context, refSnap) {
                return StreamBuilder<List<Availability>>(
                    stream: _firestoreService.getAvailabilitiesStream(),
                    builder: (context, availSnap) {
                      if (matchSnap.connectionState == ConnectionState.waiting ||
                          refSnap.connectionState == ConnectionState.waiting ||
                          availSnap.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
                      }
                      final matches = matchSnap.data ?? [];
                      final referees = refSnap.data ?? [];
                      final availabilities = availSnap.data ?? [];
                      Map<String, List<Match>> groupedMatches = {};
                      for (var m in matches) {
                        if (!groupedMatches.containsKey(m.date)) groupedMatches[m.date] = [];
                        groupedMatches[m.date]!.add(m);
                      }
                      return Scaffold(
                        backgroundColor: _bgColor,
                        appBar: AppBar(
                          title: const Text("HAFTALIK ATAMA", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.black)),
                          backgroundColor: Colors.white, elevation: 0,
                          bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: _borderColor, height: 2)),
                          actions: [
                            IconButton(
                              onPressed: () => _autoAssign(matches, referees, availabilities),
                              icon: const Icon(Icons.auto_awesome, color: Colors.black), tooltip: "Tümünü Otomatik Ata",
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                              },
                              icon: const Icon(Icons.logout, color: Colors.red, size: 28),
                              tooltip: "Çıkış Yap",
                            )
                          ],
                        ),
                        floatingActionButton: FloatingActionButton(
                          onPressed: _showAddMatchDialog,
                          backgroundColor: _borderColor,
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                        body: SafeArea(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: groupedMatches.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 16, left: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                                      ),
                                    ),
                                  ),
                                  ...entry.value.map((match) => _buildEnhancedMatchCard(match, referees, availabilities, matches)).toList(),
                                  const SizedBox(height: 10),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }
                );
              }
          );
        }
    );
  }

  Widget _buildEnhancedMatchCard(Match match, List<Referee> referees, List<Availability> availabilities, List<Match> allMatches) {
    bool isApproved = match.status == MatchStatus.approved;
    bool needsRevision = match.status == MatchStatus.revisionNeeded;
    Color headerColor = needsRevision ? Colors.red.shade50 : (isApproved ? Colors.green.shade50 : Colors.orange.shade50);
    Color statusColor = needsRevision ? Colors.red.shade600 : (isApproved ? Colors.green.shade600 : _primaryColor);
    String statusText = needsRevision ? "İADE / EKSİK!" : (isApproved ? "ONAYLANDI" : "BEKLEMEDE");

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildSolidCard(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(bottom: BorderSide(color: _borderColor, width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(
                                match.category.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("${match.teamA.toUpperCase()} - ${match.teamB.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                          const SizedBox(height: 6),

                          // UI GÜNCELLEMESİ: Konum İkonu ve Text eklendi
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 14, color: Colors.black87),
                              const SizedBox(width: 4),
                              Text(match.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 10),

                              const Icon(Icons.location_on, size: 14, color: Colors.black87),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(match.location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                              ),

                              const SizedBox(width: 10),
                              const Icon(Icons.local_fire_department, size: 14, color: Colors.black87),
                              const SizedBox(width: 4),
                              Text("${match.difficultyLevel}/10", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ]
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                        color: statusColor,
                        border: Border.all(color: _borderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(6)
                    ),
                    child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showDeleteConfirmation(match),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _refRow("BAŞ HAKEM", match.headRefereeId, Icons.sports, (id) async { match.headRefereeId = id; await _firestoreService.updateMatch(match); }, match, "head", referees, availabilities, allMatches),
                  _refRow("YARD. HAKEM", match.assistantRefereeId, Icons.sports_outlined, (id) async { match.assistantRefereeId = id; await _firestoreService.updateMatch(match); }, match, "assistant", referees, availabilities, allMatches),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.black12, thickness: 2)),
                  _refRow("SAYI", match.scorekeeperId, Icons.calculate_outlined, (id) async { match.scorekeeperId = id; await _firestoreService.updateMatch(match); }, match, "score", referees, availabilities, allMatches),
                  _refRow("SAAT", match.timekeeperId, Icons.timer_outlined, (id) async { match.timekeeperId = id; await _firestoreService.updateMatch(match); }, match, "time", referees, availabilities, allMatches),
                  _refRow("24 SN", match.shotClockOperatorId, Icons.av_timer_outlined, (id) async { match.shotClockOperatorId = id; await _firestoreService.updateMatch(match); }, match, "shot", referees, availabilities, allMatches),
                  if (needsRevision) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              _assignmentService.assignRefereesToMatch(match, referees, availabilities, allMatches);
                              await _firestoreService.updateMatch(match);
                            },
                            child: _buildSolidCard(
                              color: Colors.blue.shade600, padding: const EdgeInsets.symmetric(vertical: 14),
                              child: const Center(child: Text("EKSİKLERİ DOLDUR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if(match.headRefereeId == null || match.assistantRefereeId == null || match.scorekeeperId == null || match.timekeeperId == null || match.shotClockOperatorId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eksik kadro ile maç onaylanamaz!"), backgroundColor: Colors.red));
                                return;
                              }
                              match.status = MatchStatus.approved;
                              await _firestoreService.updateMatch(match);
                            },
                            child: _buildSolidCard(
                              color: Colors.green.shade600, padding: const EdgeInsets.symmetric(vertical: 14),
                              child: const Center(child: Text("YENİ KADRO ONAYLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
                            ),
                          ),
                        ),
                      ],
                    )
                  ]
                  else if (!isApproved) ...[
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () async {
                        if(match.headRefereeId == null || match.assistantRefereeId == null || match.scorekeeperId == null || match.timekeeperId == null || match.shotClockOperatorId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eksik kadro ile maç onaylanamaz!"), backgroundColor: Colors.red));
                          return;
                        }
                        match.status = MatchStatus.approved;
                        await _firestoreService.updateMatch(match);
                      },
                      child: _buildSolidCard(
                        color: _primaryColor, width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Center(child: Text("ATAMAYI ONAYLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1))),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _refRow(String label, String? id, IconData icon, Future<void> Function(String) onSelect, Match match, String roleKey, List<Referee> referees, List<Availability> availabilities, List<Match> allMatches) {
    Referee ref = referees.firstWhere((r) => r.id == id, orElse: () => Referee(id: "", name: "EKSİK / İADE", email: "", role: RefereeRole.aday, level: 0));
    bool isAssigned = id != null;
    bool isApproved = match.status == MatchStatus.approved;
    return InkWell(
      onTap: () => _showChangeDialog(match, id, label, onSelect, referees, availabilities, allMatches),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: isAssigned ? _getRoleColor(ref.role).withOpacity(0.2) : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isAssigned ? _getRoleColor(ref.role) : Colors.red, width: 1.5)
              ),
              child: Icon(icon, size: 16, color: isAssigned ? Colors.black87 : Colors.red),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey)),
            ),
            Expanded(
              child: Text(ref.name.toUpperCase(), style: TextStyle(color: isAssigned ? Colors.black : Colors.red.shade700, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            if (isApproved && isAssigned)
              InkWell(
                onTap: () async {
                  if(roleKey == "head") match.headRefereeId = null;
                  if(roleKey == "assistant") match.assistantRefereeId = null;
                  if(roleKey == "score") match.scorekeeperId = null;
                  if(roleKey == "time") match.timekeeperId = null;
                  if(roleKey == "shot") match.shotClockOperatorId = null;
                  match.status = MatchStatus.revisionNeeded;
                  await _firestoreService.updateMatch(match);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade300, width: 1.5)),
                  child: const Icon(Icons.person_remove, size: 16, color: Colors.red),
                ),
              )
            else if (!isApproved && match.status != MatchStatus.revisionNeeded)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.sync_alt, size: 16, color: Colors.black87),
              ),
          ],
        ),
      ),
    );
  }
}