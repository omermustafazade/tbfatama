import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import 'referee_detail_sheet.dart';

class RefereeDashboardTab extends StatefulWidget {
  final List<Referee> referees;
  final List<Availability> availabilities;
  final List<Match> matches;
  final List<String> upcomingDates;

  const RefereeDashboardTab({super.key, required this.referees, required this.availabilities, required this.matches, required this.upcomingDates});

  @override
  State<RefereeDashboardTab> createState() => _RefereeDashboardTabState();
}

class _RefereeDashboardTabState extends State<RefereeDashboardTab> {
  String? _selectedDate;
  final Color _borderColor = const Color(0xFF1C1C1C);

  @override
  void initState() {
    super.initState();
    if (widget.upcomingDates.isNotEmpty) _selectedDate = widget.upcomingDates.first;
  }

  @override
  void didUpdateWidget(covariant RefereeDashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.upcomingDates.isNotEmpty && (_selectedDate == null || !widget.upcomingDates.contains(_selectedDate))) {
      _selectedDate = widget.upcomingDates.first;
    } else if (widget.upcomingDates.isEmpty) {
      _selectedDate = null;
    }
  }

  Color _getRoleColor(RefereeRole role) {
    switch (role) {
      case RefereeRole.kosu: return const Color(0xFF4FC3F7);
      case RefereeRole.masa: return const Color(0xFFFFB74D);
      case RefereeRole.admin: return Colors.blueGrey;
    }
  }

  String _formatDateDay(String fullDate) {
    try { return fullDate.split('-')[2]; } catch (e) { return fullDate; }
  }

  String _formatDateMonth(String fullDate) {
    try {
      List<String> months = ["", "OCA", "ŞUB", "MAR", "NİS", "MAY", "HAZ", "TEM", "AĞU", "EYL", "EKİ", "KAS", "ARA"];
      int m = int.parse(fullDate.split('-')[1]);
      return months[m];
    } catch (e) { return ""; }
  }

  Widget _buildPremiumCard({required Widget child, Color color = Colors.white, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: _borderColor, width: 3), boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(4, 4))]),
      child: child,
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: Icon(icon, size: 48, color: Colors.black38)),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1, color: Colors.black)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, Color highlightColor) {
    return Column(children: [
      Text(count.toString(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: highlightColor)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.black54))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    List<Availability> selectedDayAvails = _selectedDate == null ? [] : widget.availabilities.where((a) => a.date == _selectedDate).toList();
    int kosu = 0, masa = 0, bekleyen = 0;
    bekleyen = widget.referees.where((r) => !r.isApproved).length;

    for (var avail in selectedDayAvails) {
      var ref = widget.referees.firstWhere((r) => r.id == avail.refereeId, orElse: () => Referee(id: "", name: "", email: "", role: RefereeRole.kosu, level: 0));
      if(!ref.isApproved || ref.role == RefereeRole.admin) continue;
      if (ref.role == RefereeRole.kosu) kosu++;
      else if (ref.role == RefereeRole.masa) masa++;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        if (widget.upcomingDates.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 30, bottom: 10), child: Center(child: Text("GELECEK İÇİN UYGUNLUK YOK", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))))
        else
          Container(
            color: Colors.transparent, padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal, clipBehavior: Clip.none, padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.upcomingDates.length,
                itemBuilder: (context, index) {
                  String date = widget.upcomingDates[index];
                  bool isSelected = date == _selectedDate;
                  int total = widget.availabilities.where((a) => a.date == date).length;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 2), boxShadow: isSelected ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(4, 4))] : const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))]),
                      width: 70,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_formatDateDay(date), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, height: 1.1, color: isSelected ? Colors.white : Colors.black)),
                            Text(_formatDateMonth(date), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isSelected ? const Color(0xFFE5A93C) : Colors.black54)),
                            if (total > 0)
                              Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isSelected ? Colors.white24 : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)), child: Text("$total KİŞİ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.black))),
                          ]
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildPremiumCard(
            color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem("KOŞU", kosu, const Color(0xFF0288D1)),
                Container(width: 2, height: 50, color: Colors.black12),
                _statItem("MASA", masa, const Color(0xFFF57C00)),
                Container(width: 2, height: 50, color: Colors.black12),
                _statItem("YENİ", bekleyen, const Color(0xFFD32F2F)),
              ],
            ),
          ),
        ),
        Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child: const Text("SAHAYA İNENLER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black54, letterSpacing: 1))),
        if (selectedDayAvails.isEmpty)
          _buildEmptyState("GÖREVLİ YOK", "Bu tarihte uygunluğunu bildiren\nherhangi bir hakem bulunamadı.", Icons.event_busy)
        else
          ...selectedDayAvails.map((avail) {
            final ref = widget.referees.firstWhere((r) => r.id == avail.refereeId, orElse: () => Referee(id: "", name: "Bilinmeyen", email: "", role: RefereeRole.kosu, level: 0));
            if (!ref.isApproved || ref.role == RefereeRole.admin) return const SizedBox.shrink();
            Color roleColor = _getRoleColor(ref.role);
            Color lightBgColor = ref.role == RefereeRole.kosu ? const Color(0xFFE1F5FE) : const Color(0xFFFFF3E0);
            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20.0),
              child: GestureDetector(
                onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => RefereeDetailSheet(referee: ref, availabilities: widget.availabilities, allMatches: widget.matches)),
                child: _buildPremiumCard(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(width: 50, height: 50, decoration: BoxDecoration(color: lightBgColor, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]), alignment: Alignment.center, child: Icon(Icons.sports, color: roleColor, size: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ref.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6, runSpacing: 6,
                                children: avail.availableTimes.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54)))).toList(),
                              )
                            ],
                          ),
                        ),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: lightBgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderColor, width: 1.5), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))]), child: Text(ref.role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black, letterSpacing: 0.5))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}