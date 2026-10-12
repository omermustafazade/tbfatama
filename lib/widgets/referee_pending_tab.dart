import 'package:flutter/material.dart';
import '../models/referee.dart';
import '../services/firestore_service.dart';

class RefereePendingTab extends StatefulWidget {
  final List<Referee> referees;

  const RefereePendingTab({super.key, required this.referees});

  @override
  State<RefereePendingTab> createState() => _RefereePendingTabState();
}

class _RefereePendingTabState extends State<RefereePendingTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final Color _borderColor = const Color(0xFF1C1C1C);

  Color _getRoleColor(RefereeRole role) {
    switch (role) {
      case RefereeRole.kosu: return const Color(0xFF4FC3F7);
      case RefereeRole.masa: return const Color(0xFFFFB74D);
      case RefereeRole.admin: return Colors.blueGrey;
    }
  }

  Widget _buildPremiumCard({required Widget child, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor, width: 3), boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(4, 4))]),
      child: child,
    );
  }

  void _showApprovalDialog(Referee referee) {
    RefereeRole tempRole = referee.role;
    double tempLevel = 2;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        bottom: true,
        child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: Colors.black, width: 4), left: BorderSide(color: Colors.black, width: 4), right: BorderSide(color: Colors.black, width: 4))),
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 24),
                    const Text("YENİ KAYIT ONAYI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text(referee.name.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const Divider(color: Colors.black12, thickness: 2, height: 30),
                    const Text("KATEGORİ (ROL)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: RefereeRole.values.where((r) => r != RefereeRole.admin).map((role) {
                        bool isSelected = tempRole == role;
                        return GestureDetector(
                            onTap: () => setModalState(() => tempRole = role),
                            child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), decoration: BoxDecoration(color: isSelected ? _getRoleColor(role) : Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12), boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] : null), child: Text(role.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.black : Colors.black54)))
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("GRUP PUANI (2-5)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black54)), Text("${tempLevel.toInt()} PUAN", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]),
                    Slider(value: tempLevel, min: 2, max: 5, divisions: 3, activeColor: Colors.green.shade700, inactiveColor: Colors.green.shade100, onChanged: (val) => setModalState(() => tempLevel = val)),
                    const SizedBox(height: 30),
                    InkWell(
                      onTap: () async { referee.role = tempRole; referee.level = tempLevel.toInt(); referee.isApproved = true; await _firestoreService.updateReferee(referee); if(mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hakem Onaylandı ve Havuza Eklendi!"), backgroundColor: Colors.green)); } },
                      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: const Color(0xFF2A9D8F), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: const Center(child: Text("ONAYLA VE HAVUZA EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)))),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingReferees = widget.referees.where((r) => !r.isApproved).toList();
    if (pendingReferees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: const Icon(Icons.verified_user_outlined, size: 48, color: Colors.black38)),
            const SizedBox(height: 24),
            const Text("YENİ KAYIT YOK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1, color: Colors.black)),
            const SizedBox(height: 8),
            const Text("Şu anda sistemde onay bekleyen\nyeni bir hakem kaydı bulunmuyor.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey, height: 1.4)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
      itemCount: pendingReferees.length,
      itemBuilder: (context, i) {
        final r = pendingReferees[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildPremiumCard(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_add_alt_1, color: Colors.orange, size: 24)),
              title: Text(r.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              subtitle: const Padding(padding: EdgeInsets.only(top: 6.0), child: Text("ONAY BEKLİYOR", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 11, letterSpacing: 1))),
              trailing: InkWell(
                onTap: () => _showApprovalDialog(r),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))]), child: const Text("İNCELE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
              ),
            ),
          ),
        );
      },
    );
  }
}