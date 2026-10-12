import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../services/firestore_service.dart';
import 'referee_detail_sheet.dart';

class RefereeListTab extends StatefulWidget {
  final List<Referee> referees;
  final List<Availability> availabilities;
  final List<Match> matches;

  const RefereeListTab({super.key, required this.referees, required this.availabilities, required this.matches});

  @override
  State<RefereeListTab> createState() => _RefereeListTabState();
}

class _RefereeListTabState extends State<RefereeListTab> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = "";
  String _selectedRoleFilter = "TÜMÜ";
  final Color _borderColor = const Color(0xFF1C1C1C);

  Color _getRoleColor(RefereeRole role) {
    switch (role) {
      case RefereeRole.kosu: return const Color(0xFF4FC3F7);
      case RefereeRole.masa: return const Color(0xFFFFB74D);
      case RefereeRole.admin: return Colors.blueGrey;
    }
  }

  Widget _buildPremiumCard({required Widget child, Color color = Colors.white, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor, width: 3), boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(4, 4))]),
      child: child,
    );
  }

  void _showActionDialog({required String title, required String content, required String confirmBtnText, required Color confirmBtnColor, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: confirmBtnColor, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5))),
          ],
        ),
        content: Text(content, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İPTAL", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: confirmBtnColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]),
              child: Text(confirmBtnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditRefereeDialog(Referee referee) {
    double tempLevel = referee.level.toDouble();
    if (tempLevel < 2) tempLevel = 2;
    RefereeRole tempRole = referee.role;
    final TextEditingController nameController = TextEditingController(text: referee.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          bottom: true,
          child: StatefulBuilder(
            builder: (context, setModalState) => Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: Colors.black, width: 4), left: BorderSide(color: Colors.black, width: 4), right: BorderSide(color: Colors.black, width: 4))
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.orange.shade100, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.manage_accounts, color: Colors.orange, size: 26)),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("HAKEMİ DÜZENLE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              Text("Kişisel ve sistem bilgilerini güncelle", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black12, thickness: 2, height: 1)),

                    // İSİM DÜZENLEME ALANI
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("HAKEM ADI SOYADI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade800, width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // KATEGORİ VE GRUP PUANI (Kompakt Kutu)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12, width: 2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("KATEGORİ (ROL)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 1)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: RefereeRole.values.where((r) => r != RefereeRole.admin).map((role) {
                              bool isSelected = tempRole == role;
                              return Expanded(
                                child: GestureDetector(
                                    onTap: () => setModalState(() => tempRole = role),
                                    child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(horizontal: 6),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(color: isSelected ? _getRoleColor(role) : Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10), boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : null),
                                        alignment: Alignment.center,
                                        child: Text(role.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isSelected ? Colors.black : Colors.black54))
                                    )
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("GRUP PUANI (2-5)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 1)), Text("${tempLevel.toInt()} PUAN", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
                          const SizedBox(height: 4),
                          Slider(value: tempLevel, min: 2, max: 5, divisions: 3, activeColor: Colors.orange.shade800, inactiveColor: Colors.orange.shade200, onChanged: (val) => setModalState(() => tempLevel = val)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // KAYDET BUTONU
                    InkWell(
                      onTap: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hakem adı boş bırakılamaz!"), backgroundColor: Colors.red));
                          return;
                        }
                        _showActionDialog(
                            title: "DEĞİŞİKLİKLERİ ONAYLA",
                            content: "Hakem bilgileri güncellenecek. Onaylıyor musunuz?",
                            confirmBtnText: "EVET, KAYDET",
                            confirmBtnColor: const Color(0xFF2A9D8F),
                            onConfirm: () async {
                              referee.name = nameController.text.trim();
                              referee.level = tempLevel.toInt();
                              referee.role = tempRole;
                              await _firestoreService.updateReferee(referee);
                              if(mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hakem başarıyla güncellendi!"), backgroundColor: Colors.green));
                              }
                            }
                        );
                      },
                      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(4, 4))]), child: const Center(child: Text("DEĞİŞİKLİKLERİ KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)))),
                    ),

                    const SizedBox(height: 16),

                    // SİL BUTONU
                    InkWell(
                      onTap: () {
                        _showActionDialog(
                            title: "HAKEMİ SİL",
                            content: "${referee.name.toUpperCase()} sistemden kalıcı olarak silinecek. Emin misiniz?",
                            confirmBtnText: "SİL",
                            confirmBtnColor: Colors.red.shade700,
                            onConfirm: () async {
                              await FirebaseFirestore.instance.collection('referees').doc(referee.id).delete();
                              if(mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hakem sistemden silindi!"), backgroundColor: Colors.red));
                              }
                            }
                        );
                      },
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade700, width: 2)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text("HAKEMİ SİSTEMDEN SİL", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16), // SafeArea bottom için ekstra nefes boşluğu
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredReferees = widget.referees.where((r) => r.isApproved && r.role != RefereeRole.admin && r.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (_selectedRoleFilter != "TÜMÜ") {
      filteredReferees = filteredReferees.where((r) => r.role.name.toUpperCase() == _selectedRoleFilter).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildPremiumCard(
                color: Colors.white,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  decoration: const InputDecoration(hintText: "HAKEM ARA...", hintStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 14, letterSpacing: 1), prefixIcon: Icon(Icons.search, color: Colors.black, size: 24), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ["TÜMÜ", "KOSU", "MASA"].map((filter) {
                  bool isSelected = _selectedRoleFilter == filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRoleFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 2), boxShadow: isSelected ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))] : null),
                        alignment: Alignment.center,
                        child: Text(filter, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
        Expanded(
          child: filteredReferees.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 48, color: Colors.black38), const SizedBox(height: 16), const Text("Arama kriterlerinize uygun hakem bulunamadı.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))]))
              : ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
            itemCount: filteredReferees.length,
            itemBuilder: (context, i) {
              final r = filteredReferees[i];
              Color roleColor = _getRoleColor(r.role);
              Color lightBgColor = r.role == RefereeRole.kosu ? const Color(0xFFE1F5FE) : const Color(0xFFFFF3E0);

              int totalAssigned = widget.matches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(r.id)).length;
              int availCount = widget.availabilities.where((a) => a.refereeId == r.id && !a.availableTimes.contains("UYGUN DEĞİL")).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => RefereeDetailSheet(referee: r, availabilities: widget.availabilities, allMatches: widget.matches)),
                  child: _buildPremiumCard(
                    color: Colors.white, padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(width: 56, height: 56, decoration: BoxDecoration(color: lightBgColor, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]), alignment: Alignment.center, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("G${r.level}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black, height: 1.0)), const SizedBox(height: 2), const Text("GRUP", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.black54))])),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: roleColor, border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(6)), child: Text(r.role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black))),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade100, border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.event_available, size: 12, color: Colors.black87), const SizedBox(width: 4), Text("$availCount UYGUNLUK", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black87))])),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.black, width: 1.5), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.sports_basketball, size: 12, color: Colors.black87), const SizedBox(width: 4), Text("$totalAssigned GÖREV", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black87))])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _showEditRefereeDialog(r),
                          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]), child: const Icon(Icons.settings, color: Colors.black, size: 20)),
                        ),
                      ],
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