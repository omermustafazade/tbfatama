import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/firestore_service.dart';
import 'team_detail_screen.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _teamSearchQuery = "";
  String _selectedCategoryFilter = "TÜMÜ";
  String _currentSort = "A-Z";
  bool _isTableView = false;

  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _borderColor = const Color(0xFF1C1C1C);

  final List<String> _sortOptions = [
    "A-Z", "Z-A", "EN ÇOK MAÇ", "EN AZ MAÇ", "EN BAŞARILI", "EN BAŞARISIZ"
  ];

  Color _getTeamColor(int power) {
    switch (power) {
      case 1: return const Color(0xFFB3E5FC);
      case 2: return const Color(0xFFC8E6C9);
      case 3: return const Color(0xFFFFCC80);
      case 4: return const Color(0xFFEF9A9A);
      default: return Colors.grey.shade300;
    }
  }

  Widget _buildPremiumCard({required Widget child, Color color = Colors.white, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 3),
          boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(4, 4))]
      ),
      child: child,
    );
  }

  void _showAddTeamSheet() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    int powerPoint = 2;

    final List<String> quickCategories = ["U10", "U12", "U14", "U16", "U18", "Büyükler", "Masterlar"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          bottom: true,
          child: StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: _borderColor, width: 4), left: BorderSide(color: _borderColor, width: 4), right: BorderSide(color: _borderColor, width: 4))),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shield, color: Colors.white, size: 26)),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("YENİ TAKIM EKLE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  Text("Lige yeni bir ekip dahil et", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black12, thickness: 2, height: 1)),

                        const Text("TAKIM ADI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.black54)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: nameController,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade800, width: 2), borderRadius: BorderRadius.circular(10)))
                        ),

                        const SizedBox(height: 20),

                        const Text("KATEGORİ (LİG)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.black54)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: categoryController,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade800, width: 2), borderRadius: BorderRadius.circular(10)))
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: quickCategories.map((cat) => InkWell(
                            onTap: () => setModalState(() => categoryController.text = cat),
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: categoryController.text == cat ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2), boxShadow: categoryController.text == cat ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))] : null),
                                child: Text(cat, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: categoryController.text == cat ? Colors.white : Colors.black))
                            ),
                          )).toList(),
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12, width: 2)),
                          child: Column(
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("KATEGORİ PUANI (1-4)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 1)), Text("${powerPoint.toInt()} PUAN", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
                              const SizedBox(height: 4),
                              Slider(value: powerPoint.toDouble(), min: 1, max: 4, divisions: 3, activeColor: Colors.orange.shade800, inactiveColor: Colors.orange.shade200, onChanged: (val) => setModalState(() => powerPoint = val.toInt())),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        InkWell(
                          onTap: () async {
                            if(nameController.text.trim().isEmpty || categoryController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Takım adı ve kategori boş bırakılamaz!"), backgroundColor: Colors.red));
                              return;
                            }

                            final newTeam = Team(
                                id: "t_${DateTime.now().millisecondsSinceEpoch}",
                                name: nameController.text.trim(),
                                category: categoryController.text.trim(),
                                powerPoint: powerPoint
                            );
                            await _firestoreService.addTeam(newTeam);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Takım başarıyla eklendi!"), backgroundColor: Colors.green));
                            }
                          },
                          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(4, 4))]), child: const Center(child: Text("TAKIMI SİSTEME EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)))),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              }
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Team>>(
        stream: _firestoreService.getTeamsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));

          final teams = snapshot.data!;

          List<String> availableCategories = ["TÜMÜ"];
          availableCategories.addAll(teams.map((t) => t.category).toSet().toList()..sort());

          var filteredTeams = teams.where((t) => t.name.toLowerCase().contains(_teamSearchQuery.toLowerCase())).toList();
          if (_selectedCategoryFilter != "TÜMÜ") {
            filteredTeams = filteredTeams.where((t) => t.category == _selectedCategoryFilter).toList();
          }

          filteredTeams.sort((a, b) {
            double rateA = a.matchesPlayed > 0 ? (a.wins / a.matchesPlayed) : 0;
            double rateB = b.matchesPlayed > 0 ? (b.wins / b.matchesPlayed) : 0;

            if (_currentSort == "A-Z") {
              return a.name.compareTo(b.name);
            } else if (_currentSort == "Z-A") {
              return b.name.compareTo(a.name);
            } else if (_currentSort == "EN ÇOK MAÇ") {
              return b.matchesPlayed.compareTo(a.matchesPlayed);
            } else if (_currentSort == "EN AZ MAÇ") {
              return a.matchesPlayed.compareTo(b.matchesPlayed);
            } else if (_currentSort == "EN BAŞARILI") {
              if (rateB == rateA) return b.wins.compareTo(a.wins);
              return rateB.compareTo(rateA);
            } else if (_currentSort == "EN BAŞARISIZ") {
              if (rateA == rateB) return a.losses.compareTo(b.losses);
              return rateA.compareTo(rateB);
            }
            return 0;
          });

          return Scaffold(
            backgroundColor: _bgColor,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: FloatingActionButton.extended(
                onPressed: _showAddTeamSheet,
                backgroundColor: Colors.black,
                icon: const Icon(Icons.add_moderator, color: Colors.white),
                label: const Text("TAKIM EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            body: SafeArea(
              bottom: false,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: const Color(0xFFF4F6F8), elevation: 0, floating: true, snap: true, toolbarHeight: 70, titleSpacing: 20,
                      title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("TAKIM YÖNETİMİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5, color: Colors.black)), Text("Ligler, İstatistikler ve Kayıtlar", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black54))]),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: InkWell(
                            onTap: () => setState(() => _isTableView = !_isTableView),
                            child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: _isTableView ? Colors.black : Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]),
                                child: Icon(_isTableView ? Icons.grid_view_rounded : Icons.format_list_numbered, color: _isTableView ? Colors.white : Colors.black, size: 22)
                            ),
                          ),
                        )
                      ],
                    )
                  ];
                },
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildPremiumCard(
                            color: Colors.white,
                            child: TextField(
                              onChanged: (val) => setState(() => _teamSearchQuery = val),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                              decoration: const InputDecoration(hintText: "TAKIM ARA...", hintStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 14, letterSpacing: 1), prefixIcon: Icon(Icons.search, color: Colors.black87, size: 26), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: availableCategories.length,
                              itemBuilder: (context, index) {
                                String cat = availableCategories[index];
                                bool isSelected = _selectedCategoryFilter == cat;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCategoryFilter = cat),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 2), boxShadow: isSelected ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))] : null),
                                    alignment: Alignment.center,
                                    child: Text(cat.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.orange.shade100, border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.sort, size: 16, color: Colors.black)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _sortOptions.map((sortOption) {
                                      bool isSortSelected = _currentSort == sortOption;
                                      return GestureDetector(
                                        onTap: () => setState(() => _currentSort = sortOption),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: isSortSelected ? Colors.orange.shade800 : Colors.white, border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(6)),
                                          child: Text(sortOption, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: isSortSelected ? Colors.white : Colors.black87, letterSpacing: 0.5)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: filteredTeams.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: const Icon(Icons.shield_outlined, size: 48, color: Colors.black38)),
                            const SizedBox(height: 24),
                            const Text("TAKIM BULUNAMADI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1, color: Colors.black)),
                            const SizedBox(height: 8),
                            const Text("Arama veya filtre kriterlerinize\nuygun bir takım yok.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey, height: 1.4)),
                          ],
                        ),
                      )
                          : _isTableView
                          ? _buildTableView(filteredTeams)
                          : _buildCardView(filteredTeams),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildTableView(List<Team> teams) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(13))),
            child: Row(
              children: [
                const SizedBox(width: 30, child: Text("#", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
                const Expanded(child: Text("TAKIM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
                SizedBox(width: 35, child: Text("O", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade200, fontWeight: FontWeight.w900, fontSize: 12))),
                const SizedBox(width: 35, child: Text("G", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12))),
                const SizedBox(width: 35, child: Text("M", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12))),
                const SizedBox(width: 45, child: Text("%", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: teams.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 1, thickness: 1),
              itemBuilder: (context, index) {
                final team = teams[index];
                int winRate = team.matchesPlayed > 0 ? ((team.wins / team.matchesPlayed) * 100).toInt() : 0;

                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team))),
                  child: Container(
                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black54))),
                        Expanded(child: Text(team.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.5))),
                        SizedBox(width: 35, child: Text("${team.matchesPlayed}", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black))),
                        SizedBox(width: 35, child: Text("${team.wins}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.green.shade700))),
                        SizedBox(width: 35, child: Text("${team.losses}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.red.shade700))),
                        SizedBox(width: 45, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: winRate >= 50 ? Colors.orange.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)), child: Text("%$winRate", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: winRate >= 50 ? Colors.orange.shade900 : Colors.black54)))),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardView(List<Team> teams) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 160),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        int winRate = team.matchesPlayed > 0 ? ((team.wins / team.matchesPlayed) * 100).toInt() : 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)));
            },
            child: _buildPremiumCard(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                                color: _getTeamColor(team.powerPoint), border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]
                            ),
                            alignment: Alignment.center,
                            child: Text(team.name.isNotEmpty ? team.name[0].toUpperCase() : "?", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black, height: 1.0))
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(team.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)), child: Text(team.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(6)), child: Row(children: [const Icon(Icons.flash_on, size: 12, color: Colors.orange), const SizedBox(width: 4), Text("KATEGORİ: ${team.powerPoint}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black))])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 20),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(color: Color(0xFFF9FAFB), borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)), border: Border(top: BorderSide(color: Colors.black, width: 2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("OYNANAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blueGrey.shade700.withOpacity(0.15), border: Border.all(color: Colors.blueGrey.shade700, width: 1.5), borderRadius: BorderRadius.circular(8)), child: Text("${team.matchesPlayed}", style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.w900, fontSize: 13))),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("GALİBİYET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade700.withOpacity(0.15), border: Border.all(color: Colors.green.shade700, width: 1.5), borderRadius: BorderRadius.circular(8)), child: Text("${team.wins}", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w900, fontSize: 13))),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("MAĞLUBİYET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade700.withOpacity(0.15), border: Border.all(color: Colors.red.shade700, width: 1.5), borderRadius: BorderRadius.circular(8)), child: Text("${team.losses}", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w900, fontSize: 13))),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("BAŞARI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (winRate >= 50 ? Colors.orange.shade800 : Colors.black54).withOpacity(0.15), border: Border.all(color: winRate >= 50 ? Colors.orange.shade800 : Colors.black54, width: 1.5), borderRadius: BorderRadius.circular(8)), child: Text("%$winRate", style: TextStyle(color: winRate >= 50 ? Colors.orange.shade800 : Colors.black54, fontWeight: FontWeight.w900, fontSize: 13))),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}