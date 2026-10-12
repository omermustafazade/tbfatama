import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../models/team.dart';
import '../services/assignment_service.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_summary_panel.dart';
import '../widgets/admin_add_match_sheet.dart';
import '../widgets/admin_match_card.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final FirestoreService _firestoreService = FirestoreService();

  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _borderColor = const Color(0xFF1C1C1C);

  String _selectedTimeFilter = "Son 1 Ay";
  String _pastSearchQuery = "";

  bool _isPastMatch(String date, String time) {
    try {
      DateTime matchDate = DateTime.parse("$date $time:00");
      return matchDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleAutoAssign(List<Match> matches, List<Referee> referees, List<Availability> availabilities) async {
    int unresolved = 0;
    for (var m in matches) {
      if (!_isPastMatch(m.date, m.time) && (m.status == MatchStatus.pending || m.status == MatchStatus.revisionNeeded)) {
        _assignmentService.assignRefereesToMatch(m, referees, availabilities, matches);
        await _firestoreService.updateMatch(m);
        if (m.status == MatchStatus.pending || m.status == MatchStatus.revisionNeeded) {
          unresolved++;
        }
      }
    }
    if (mounted) {
      if (unresolved > 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Havuz yetersiz! Bazı maçlarda eksik hakemler var."), backgroundColor: Colors.orange));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tüm atamalar kusursuz şekilde tamamlandı!"), backgroundColor: Colors.green));
      }
    }
  }

  // YENİDEN TASARLANAN PREMIUM ZAMAN FİLTRELERİ
  Widget _buildTimeFilters() {
    final filters = ["Tümü", "Son 1 Hafta", "Son 1 Ay", "Son 3 Ay", "Son 6 Ay"];
    return Container(
      height: 50, // Yükseklik artırıldı, daha tıklanabilir
      margin: const EdgeInsets.only(bottom: 24, top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (ctx, i) {
          bool isSelected = filters[i] == _selectedTimeFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeFilter = filters[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12), // Şık yuvarlak köşeler
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(3, 3))] // Seçiliyse Kehribar Gölge
                      : const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))]    // Seçili değilse hafif gölge
              ),
              alignment: Alignment.center,
              child: Text(
                  filters[i].toUpperCase(),
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5
                  )
              ),
            ),
          );
        },
      ),
    );
  }

  // YENİDEN TASARLANAN PREMIUM BOŞ DURUM (EMPTY STATE)
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]
              ),
              child: Icon(icon, size: 48, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1, color: Colors.black)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey, height: 1.4)),
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
                      return StreamBuilder<List<Team>>(
                          stream: _firestoreService.getTeamsStream(),
                          builder: (context, teamSnap) {
                            if (!matchSnap.hasData || !refSnap.hasData || !availSnap.hasData || !teamSnap.hasData) {
                              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
                            }

                            final matches = matchSnap.data ?? [];
                            final referees = refSnap.data ?? [];
                            final availabilities = availSnap.data ?? [];
                            final teams = teamSnap.data ?? [];

                            final activeMatches = matches.where((m) => !_isPastMatch(m.date, m.time)).toList();
                            activeMatches.sort((a, b) => "${a.date} ${a.time}".compareTo("${b.date} ${b.time}"));

                            Map<String, List<Match>> groupedActive = {};
                            for (var m in activeMatches) {
                              if (!groupedActive.containsKey(m.date)) groupedActive[m.date] = [];
                              groupedActive[m.date]!.add(m);
                            }

                            var pastMatches = matches.where((m) => _isPastMatch(m.date, m.time)).toList();

                            if (_selectedTimeFilter != "Tümü") {
                              DateTime now = DateTime.now();
                              pastMatches = pastMatches.where((m) {
                                try {
                                  DateTime mDate = DateTime.parse(m.date);
                                  int diffDays = now.difference(mDate).inDays;
                                  if (_selectedTimeFilter == "Son 1 Hafta") return diffDays <= 7;
                                  if (_selectedTimeFilter == "Son 1 Ay") return diffDays <= 30;
                                  if (_selectedTimeFilter == "Son 3 Ay") return diffDays <= 90;
                                  if (_selectedTimeFilter == "Son 6 Ay") return diffDays <= 180;
                                  return true;
                                } catch (e) { return true; }
                              }).toList();
                            }

                            if (_pastSearchQuery.isNotEmpty) {
                              pastMatches = pastMatches.where((m) => m.teamA.toLowerCase().contains(_pastSearchQuery.toLowerCase()) || m.teamB.toLowerCase().contains(_pastSearchQuery.toLowerCase()) || m.category.toLowerCase().contains(_pastSearchQuery.toLowerCase())).toList();
                            }

                            pastMatches.sort((a, b) => "${b.date} ${b.time}".compareTo("${a.date} ${a.time}"));

                            return DefaultTabController(
                              length: 2,
                              child: Scaffold(
                                backgroundColor: _bgColor,
                                floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
                                floatingActionButton: Padding(
                                  padding: const EdgeInsets.only(bottom: 100.0),
                                  child: FloatingActionButton.extended(
                                    onPressed: () {
                                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AdminAddMatchSheet(allTeams: teams));
                                    },
                                    backgroundColor: Colors.black,
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    label: const Text("MAÇ EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                                body: SafeArea(
                                  bottom: false,
                                  child: NestedScrollView(
                                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                                      return [
                                        SliverAppBar(
                                          backgroundColor: _bgColor, elevation: 0, floating: true, snap: true, toolbarHeight: 70, titleSpacing: 20,
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("TBF ATAMA MERKEZİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5, color: Colors.black)), Text("Maç ve Hakem Yönetimi", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black54))]),
                                              InkWell(onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2,2))]), child: Icon(Icons.logout, color: Colors.red.shade800))),
                                            ],
                                          ),
                                          bottom: PreferredSize(
                                            preferredSize: const Size.fromHeight(60),
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]),
                                              child: TabBar(
                                                indicator: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 2)), indicatorSize: TabBarIndicatorSize.tab, labelColor: Colors.white, unselectedLabelColor: Colors.black, labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                                tabs: const [Tab(text: "GÜNCEL ATAMALAR"), Tab(text: "GEÇMİŞ & SKOR")],
                                              ),
                                            ),
                                          ),
                                        )
                                      ];
                                    },
                                    body: TabBarView(
                                      children: [
                                        _buildActiveMatchesView(groupedActive, referees, availabilities, matches, activeMatches),
                                        _buildPastMatchesView(pastMatches, referees, availabilities, matches),
                                      ],
                                    ),
                                  ),
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

  Widget _buildActiveMatchesView(Map<String, List<Match>> groupedMatches, List<Referee> referees, List<Availability> availabilities, List<Match> allMatches, List<Match> activeMatches) {
    int pendingCount = activeMatches.where((m) => m.status == MatchStatus.pending || m.status == MatchStatus.revisionNeeded).length;

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      children: [
        AdminSummaryPanel(
          activeMatchesCount: activeMatches.length,
          pendingCount: pendingCount,
          onAutoAssign: () => _handleAutoAssign(allMatches, referees, availabilities),
        ),
        if (groupedMatches.isEmpty)
          _buildEmptyState("GÜNCEL MAÇ YOK", "Bu hafta için planlanan\nherhangi bir maç bulunmuyor.", Icons.sports_basketball)
        else
          ...groupedMatches.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]), child: Text(entry.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1))),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 2, color: Colors.black26)),
                    ],
                  ),
                ),
                ...entry.value.map((match) => AdminMatchCard(match: match, referees: referees, availabilities: availabilities, allMatches: allMatches, isPast: false)).toList(),
              ],
            );
          }).toList(),
      ],
    );
  }

  // YENİDEN TASARLANAN PREMIUM GEÇMİŞ MAÇLAR SEKMESİ
  Widget _buildPastMatchesView(List<Match> pastMatches, List<Referee> referees, List<Availability> availabilities, List<Match> allMatches) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      children: [
        // YENİ: Kalın Çerçeveli ve Gölgeli Arama Çubuğu
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]
          ),
          child: TextField(
            onChanged: (val) => setState(() => _pastSearchQuery = val),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
            decoration: InputDecoration(
                hintText: "TAKIM VEYA KATEGORİ ARA...",
                hintStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade400, fontSize: 13, letterSpacing: 1),
                prefixIcon: const Icon(Icons.search, color: Colors.black, size: 24),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16)
            ),
          ),
        ),

        _buildTimeFilters(),

        if (pastMatches.isEmpty)
          _buildEmptyState("KAYIT BULUNAMADI", "Seçilen tarih aralığında veya aramada\nherhangi bir maç kaydı yok.", Icons.scoreboard_outlined)
        else
          ...pastMatches.map((match) => AdminMatchCard(match: match, referees: referees, availabilities: availabilities, allMatches: allMatches, isPast: true)).toList(),
      ],
    );
  }
}