import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../models/team.dart';
import '../services/firestore_service.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});
  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedDate;
  List<String> _sortedDates = [];
  String _searchQuery = "";
  String _teamSearchQuery = "";
  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _primaryColor = Colors.orange.shade800;
  final Color _borderColor = const Color(0xFF1C1C1C);

  Color _getRoleColor(RefereeRole role) {
    switch (role) {
      case RefereeRole.kosu: return const Color(0xFF4FC3F7);
      case RefereeRole.masa: return const Color(0xFFFFB74D);
      case RefereeRole.admin: return Colors.blueGrey;
    }
  }

  Widget _buildComicCard({required Widget child, Color color = Colors.white, EdgeInsetsGeometry? padding, double? width, double? height}) {
    return Container(
      width: width, height: height, padding: padding,
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderColor, width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: child,
    );
  }

  void _showAddTeamDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    int powerPoint = 2;
    final List<String> quickCategories = ["U10 Erkekler", "U12 Erkekler", "U14 Erkekler", "U16 Erkekler", "U18 Erkekler", "Büyük Erkekler"];

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
                  color: _bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), border: Border.all(color: _borderColor, width: 3),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 20),
                      const Text("YENİ TAKIM EKLE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      const Text("TAKIM ADI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(6)),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text("KATEGORİ SEÇ VEYA YAZ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(6)),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: quickCategories.map((cat) => InkWell(
                          onTap: () => setModalState(() => categoryController.text = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: categoryController.text == cat ? _primaryColor : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black, width: 1.5)),
                            child: Text(cat, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: categoryController.text == cat ? Colors.white : Colors.black)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TAKIM GÜCÜ (1-4)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          Text("${powerPoint.toInt()} PUAN", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                      Slider(
                        value: powerPoint.toDouble(), min: 1, max: 4, divisions: 3,
                        activeColor: _primaryColor, inactiveColor: Colors.orange.shade200,
                        onChanged: (val) => setModalState(() => powerPoint = val.toInt()),
                      ),
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () async {
                          if(nameController.text.isEmpty || categoryController.text.isEmpty) return;
                          final newTeam = Team(
                            id: "t_${DateTime.now().millisecondsSinceEpoch}",
                            name: nameController.text.trim(),
                            category: categoryController.text.trim(),
                            powerPoint: powerPoint,
                          );
                          await _firestoreService.addTeam(newTeam);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Takım başarıyla lige eklendi!"), backgroundColor: Colors.green));
                          }
                        },
                        child: _buildComicCard(
                          color: _primaryColor, width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Center(child: Text("TAKIMI KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
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

  void _showEditRefereeDialog(Referee referee) {
    double tempLevel = referee.level.toDouble();
    if (tempLevel < 2) tempLevel = 2;
    RefereeRole tempRole = referee.role;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _borderColor, width: 2)),
          title: Text("${referee.name.toUpperCase()} DÜZENLE", style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("GRUP PUANI (2-5)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Slider(
                value: tempLevel, min: 2, max: 5, divisions: 3,
                activeColor: _primaryColor,
                onChanged: (val) => setModalState(() => tempLevel = val),
              ),
              Text("${tempLevel.toInt()} PUAN", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 20),
              const Text("ROLÜ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: _borderColor, width: 2), borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<RefereeRole>(
                  value: tempRole,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: RefereeRole.values.where((r) => r != RefereeRole.admin).map((role) {
                    return DropdownMenuItem(value: role, child: Text(role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)));
                  }).toList(),
                  onChanged: (val) => setModalState(() => tempRole = val!),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İPTAL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
              onPressed: () async {
                referee.level = tempLevel.toInt();
                referee.role = tempRole;
                await _firestoreService.updateReferee(referee);
                if(mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hakem bilgileri güncellendi!"), backgroundColor: Colors.green));
                }
              },
              child: const Text("KAYDET", style: TextStyle(fontWeight: FontWeight.w900)),
            )
          ],
        ),
      ),
    );
  }

  void _showApprovalDialog(Referee referee) {
    RefereeRole tempRole = referee.role;
    double tempLevel = 2; // Varsayılan grup 2
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: _borderColor, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text("HAKEM ONAYI: ${referee.name.toUpperCase()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  const Text("KATEGORİ (ROL)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: RefereeRole.values.where((r) => r != RefereeRole.admin).map((role) {
                      bool isSelected = tempRole == role;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempRole = role),
                        child: _buildComicCard(
                          color: isSelected ? _getRoleColor(role) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(role.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.black87)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("GRUP PUANI (2-5)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Text("${tempLevel.toInt()} PUAN", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                  Slider(
                    value: tempLevel, min: 2, max: 5, divisions: 3,
                    activeColor: _primaryColor, inactiveColor: Colors.orange.shade100,
                    onChanged: (val) => setModalState(() => tempLevel = val),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () async {
                      referee.role = tempRole;
                      referee.level = tempLevel.toInt();
                      referee.isApproved = true;
                      await _firestoreService.updateReferee(referee);
                      if(mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hakem Onaylandı ve Havuza Eklendi!"), backgroundColor: Colors.green));
                      }
                    },
                    child: _buildComicCard(
                      color: Colors.green.shade600,
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Center(child: Text("KAYDI ONAYLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
      ),
    );
  }

  void _showRefereeDetail(Referee referee, List<Availability> allAvailabilities) {
    List<Availability> refAvails = allAvailabilities.where((a) => a.refereeId == referee.id).toList();
    Color roleColor = _getRoleColor(referee.role);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: _borderColor, width: 3),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20.0),
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildComicCard(
                        width: 60, height: 60,
                        color: roleColor,
                        child: Center(child: Text(referee.name[0], style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.w900))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(referee.name.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: roleColor, border: Border.all(color: _borderColor, width: 1.5)),
                              child: Text(referee.role.name.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(referee.level.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                          const Text("PUAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    color: _borderColor,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: const Text("HAFTALIK UYGUNLUK DOSYASI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 16),
                  if (refAvails.isEmpty)
                    const Padding(padding: EdgeInsets.all(12), child: Text("BU HAFTA PASİF!", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)))
                  else
                    ...refAvails.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildComicCard(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, size: 22, color: _primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.date, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6, runSpacing: 6,
                                    children: a.availableTimes.map((t) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _borderColor, width: 1.5)),
                                      child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Text("${a.availableTimes.length}X", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            );
          },
        );
      },
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
                      return StreamBuilder<List<Team>>(
                          stream: _firestoreService.getTeamsStream(),
                          builder: (context, teamSnap) {
                            if (!matchSnap.hasData || !refSnap.hasData || !availSnap.hasData || !teamSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));

                            final matches = matchSnap.data!;
                            final referees = refSnap.data!;
                            final availabilities = availSnap.data!;
                            final teams = teamSnap.data!;

                            Set<String> dates = availabilities.map((a) => a.date).toSet();
                            _sortedDates = dates.toList()..sort();
                            if (_sortedDates.isNotEmpty && (_selectedDate == null || !_sortedDates.contains(_selectedDate))) _selectedDate = _sortedDates.first;

                            return DefaultTabController(
                              length: 4,
                              child: Scaffold(
                                backgroundColor: _bgColor,
                                appBar: AppBar(
                                  title: const Text("TBF YÖNETİM", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.black)),
                                  backgroundColor: Colors.white, elevation: 0,
                                  actions: [IconButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false), icon: const Icon(Icons.logout, color: Colors.red, size: 28))],
                                  bottom: PreferredSize(
                                    preferredSize: const Size.fromHeight(50),
                                    child: Container(
                                      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: _borderColor, width: 2), bottom: BorderSide(color: _borderColor, width: 3))),
                                      child: TabBar(
                                        isScrollable: true,
                                        labelColor: _primaryColor, unselectedLabelColor: Colors.grey.shade600, indicatorColor: _primaryColor, indicatorWeight: 4,
                                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                                        tabs: const [Tab(text: "ÖZET"), Tab(text: "HAKEM KADROSU"), Tab(text: "YENİ KAYITLAR"), Tab(text: "TAKIMLAR")],
                                      ),
                                    ),
                                  ),
                                ),
                                body: SafeArea(
                                  bottom: false, // YENİ: Listenin sayfa sonuna inmesine izin ver
                                  child: TabBarView(
                                    children: [
                                      _buildWeeklyDashboardTab(referees, availabilities),
                                      _buildRefereeListTab(referees, availabilities, matches),
                                      _buildPendingRefereesTab(referees),
                                      _buildTeamsTab(teams),
                                    ],
                                  ),
                                ),
                                floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
                                floatingActionButton: Builder(
                                  builder: (context) {
                                    final TabController tabController = DefaultTabController.of(context);
                                    tabController.addListener(() { setState(() {}); });
                                    if (tabController.index == 3) {
                                      return Container(
                                        margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80), // Dinamik yükseklik
                                        child: FloatingActionButton(
                                          onPressed: _showAddTeamDialog, backgroundColor: _borderColor,
                                          child: const Icon(Icons.add_moderator, color: Colors.white, size: 28),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
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
    );
  }

  Widget _buildTeamsTab(List<Team> teams) {
    final filteredTeams = teams.where((t) => t.name.toLowerCase().contains(_teamSearchQuery.toLowerCase())).toList();
    Map<String, List<Team>> groupedTeams = {};
    for (var t in filteredTeams) {
      if (!groupedTeams.containsKey(t.category)) groupedTeams[t.category] = [];
      groupedTeams[t.category]!.add(t);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildComicCard(
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _teamSearchQuery = val),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              decoration: const InputDecoration(hintText: "TAKIM ARA...", hintStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 14), prefixIcon: Icon(Icons.search, color: Colors.black87, size: 24), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ),
        if (groupedTeams.isEmpty)
          const Expanded(child: Center(child: Text("Sisteme kayıtlı takım bulunmuyor.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))))
        else
          Expanded(
            child: ListView(
              // YENİ: Alt barın altında kalmaması için geniş boşluk eklendi
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 160),
              children: groupedTeams.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                        child: Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                      ),
                    ),
                    ...entry.value.map((team) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildComicCard(
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.orange.shade100, border: Border.all(color: _borderColor, width: 1.5), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: const Icon(Icons.shield, color: Colors.orange)),
                            title: Text(team.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  Text("O: ${team.matchesPlayed}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                                  const SizedBox(width: 12),
                                  Text("G: ${team.wins}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.green)),
                                  const SizedBox(width: 12),
                                  Text("M: ${team.losses}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.red)),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(team.powerPoint.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                                const Text("GÜÇ", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingRefereesTab(List<Referee> referees) {
    final pendingReferees = referees.where((r) => !r.isApproved).toList();
    if (pendingReferees.isEmpty) return const Center(child: Text("Onay bekleyen yeni kayıt yok.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 160), // YENİ PADDING
      itemCount: pendingReferees.length,
      itemBuilder: (context, i) {
        final r = pendingReferees[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildComicCard(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(backgroundColor: Colors.black12, child: Icon(Icons.person_outline, color: Colors.black)),
              title: Text(r.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              subtitle: const Text("ONAY BEKLİYOR", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 11)),
              trailing: ElevatedButton(onPressed: () => _showApprovalDialog(r), style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, elevation: 0), child: const Text("İNCELE", style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyDashboardTab(List<Referee> referees, List<Availability> availabilities) {
    List<Availability> selectedDayAvails = availabilities.where((a) => a.date == _selectedDate).toList();
    int kosu = 0, masa = 0, bekleyen = 0;

    bekleyen = referees.where((r) => !r.isApproved).length;

    for (var avail in selectedDayAvails) {
      var ref = referees.firstWhere((r) => r.id == avail.refereeId, orElse: () => Referee(id: "", name: "", email: "", role: RefereeRole.kosu, level: 0));
      if(!ref.isApproved || ref.role == RefereeRole.admin) continue;
      if (ref.role == RefereeRole.kosu) kosu++;
      else if (ref.role == RefereeRole.masa) masa++;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 160), // YENİ PADDING
      children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, clipBehavior: Clip.none, padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              itemCount: _sortedDates.length,
              itemBuilder: (context, index) {
                String date = _sortedDates[index];
                bool isSelected = date == _selectedDate;
                int total = availabilities.where((a) => a.date == date).length;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildComicCard(
                      width: 65, color: isSelected ? _primaryColor : Colors.white,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(date.substring(5), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isSelected ? Colors.white : Colors.black87)), const SizedBox(height: 2), Text(total.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.black))]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildComicCard(
            color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem("KOŞU", kosu, const Color(0xFF0288D1)),
                Container(width: 2, height: 40, color: Colors.black12),
                _statItem("MASA", masa, const Color(0xFFFFB74D)),
                Container(width: 2, height: 40, color: Colors.black12),
                _statItem("YENİ", bekleyen, const Color(0xFFE53935)),
              ],
            ),
          ),
        ),
        Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 16), child: const Text("SAHAYA İNENLER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black54, letterSpacing: 1))),
        const SizedBox(height: 12),
        ...selectedDayAvails.map((avail) {
          final ref = referees.firstWhere((r) => r.id == avail.refereeId, orElse: () => Referee(id: "", name: "Bilinmeyen", email: "", role: RefereeRole.kosu, level: 0));
          if (!ref.isApproved || ref.role == RefereeRole.admin) return const SizedBox.shrink();
          Color roleColor = _getRoleColor(ref.role);
          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14.0),
            child: GestureDetector(
              onTap: () => _showRefereeDetail(ref, availabilities),
              child: _buildComicCard(
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: roleColor.withOpacity(0.3), border: Border.all(color: _borderColor, width: 1.5)), alignment: Alignment.center, child: Icon(Icons.sports_basketball, color: roleColor.withOpacity(0.9), size: 22)),
                  title: Text(ref.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  subtitle: Text(avail.availableTimes.join(' | '), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 11)),
                  trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: roleColor, border: Border.all(color: _borderColor, width: 1.5)), child: Text(ref.role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black87))),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _statItem(String label, int count, Color highlightColor) {
    return Column(children: [Text(count.toString(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: highlightColor)), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5))]);
  }

  Widget _buildRefereeListTab(List<Referee> referees, List<Availability> availabilities, List<Match> allMatches) {
    final filteredReferees = referees.where((r) => r.isApproved && r.role != RefereeRole.admin && r.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildComicCard(
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              decoration: const InputDecoration(hintText: "HAKEM ARA...", hintStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 14), prefixIcon: Icon(Icons.search, color: Colors.black87, size: 24), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 160), // YENİ PADDING
            itemCount: filteredReferees.length,
            itemBuilder: (context, i) {
              final r = filteredReferees[i];
              Color roleColor = _getRoleColor(r.role);
              int load = allMatches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(r.id)).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () => _showRefereeDetail(r, availabilities),
                  child: _buildComicCard(
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: roleColor.withOpacity(0.8), border: Border.all(color: _borderColor, width: 1.5)), alignment: Alignment.center, child: Text("G${r.level}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87))),
                      title: Text(r.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Text("${r.role.name.toUpperCase()}   BU HAFTA: $load MAÇ", style: TextStyle(fontWeight: FontWeight.w900, color: _primaryColor, fontSize: 11)),
                      trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey), onPressed: () => _showEditRefereeDialog(r)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}