import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../services/firestore_service.dart';

class RefereeHomeScreen extends StatefulWidget {
  final String refereeId;
  const RefereeHomeScreen({super.key, required this.refereeId});

  @override
  State<RefereeHomeScreen> createState() => _RefereeHomeScreenState();
}

class _RefereeHomeScreenState extends State<RefereeHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _primaryColor = Colors.orange.shade800;
  final Color _borderColor = const Color(0xFF1C1C1C);

  // Genel kart tasarımı
  Widget _buildSolidCard({required Widget child, Color color = Colors.white, EdgeInsetsGeometry? padding, double? width, double? height}) {
    return Container(
      width: width, height: height, padding: padding,
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(4, 4))],
      ),
      child: child,
    );
  }

  // Uygunluk formunu açan fonksiyon, atanmış maçları kendi içinde buluyor.
  void _openAvailabilityForm() {
    _firestoreService.getMatchesStream().first.then((allMatches) {
      _firestoreService.getAvailabilitiesStream().first.then((allAvails) {

        // Hakemin onaylanmış ve atanmış olduğu maçları filtrele
        final myAssignedMatches = allMatches.where((m) =>
        m.status == MatchStatus.approved &&
            [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(widget.refereeId)
        ).toList();

        _showAvailabilityForm(allMatches, allAvails, myAssignedMatches);
      });
    });
  }

  // Uygunluk Bildirme (Kaydetme) Ekranı
  void _showAvailabilityForm(List<Match> allMatches, List<Availability> existingAvails, List<Match> myAssignedMatches) {
    Map<String, Set<String>> matchSlots = {};
    for (var m in allMatches) {
      if (!matchSlots.containsKey(m.date)) matchSlots[m.date] = {};
      matchSlots[m.date]!.add(m.time);
    }

    Map<String, List<String>> mySelections = {};
    for (var a in existingAvails.where((av) => av.refereeId == widget.refereeId)) {
      mySelections[a.date] = List.from(a.availableTimes);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _borderColor, width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Text("HAFTALIK UYGUNLUK BİLDİR", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const Text("Görev alabileceğiniz saatleri veya uygun olmadığınız günleri işaretleyin.", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView(
                      children: matchSlots.entries.map((entry) {
                        String date = entry.key;
                        List<String> times = entry.value.toList()..sort();
                        List<String> selectedTimes = mySelections[date] ?? [];

                        bool isNotAvailable = selectedTimes.contains("UYGUN DEĞİL");
                        bool hasMatchThatDay = myAssignedMatches.any((m) => m.date == date);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildSolidCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event, size: 20, color: _primaryColor),
                                        const SizedBox(width: 8),
                                        Text(date, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (hasMatchThatDay) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu güne atanmış maçınız bulunuyor. Uygunluk durumunuzu değiştiremezsiniz!"), backgroundColor: Colors.red));
                                          return;
                                        }
                                        setModalState(() {
                                          if (isNotAvailable) {
                                            selectedTimes.remove("UYGUN DEĞİL");
                                          } else {
                                            selectedTimes.clear();
                                            selectedTimes.add("UYGUN DEĞİL");
                                          }
                                          mySelections[date] = selectedTimes;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                            color: isNotAvailable ? Colors.red : Colors.white,
                                            border: Border.all(color: isNotAvailable ? Colors.red : Colors.grey.shade400, width: 1.5),
                                            borderRadius: BorderRadius.circular(6)
                                        ),
                                        child: Text(
                                            "UYGUN DEĞİLİM",
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: isNotAvailable ? Colors.white : Colors.grey.shade600)
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const Divider(height: 24, thickness: 1.5),

                                if (isNotAvailable)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text("Bu gün için görev almak istemediğinizi belirttiniz.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                                  )
                                else
                                  Wrap(
                                    spacing: 12, runSpacing: 12,
                                    children: times.map((time) {
                                      bool isSelected = selectedTimes.contains(time);
                                      return GestureDetector(
                                        onTap: () {
                                          if (hasMatchThatDay) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu güne atanmış maçınız bulunuyor. Uygunluk durumunuzu değiştiremezsiniz!"), backgroundColor: Colors.red));
                                            return;
                                          }
                                          setModalState(() {
                                            if (isSelected) {
                                              selectedTimes.remove(time);
                                            } else {
                                              selectedTimes.remove("UYGUN DEĞİL");
                                              selectedTimes.add(time);
                                            }
                                            mySelections[date] = selectedTimes;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                              color: isSelected ? _primaryColor : Colors.white,
                                              border: Border.all(color: _borderColor, width: 2),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : []
                                          ),
                                          child: Text(time, style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.black87, fontSize: 14)),
                                        ),
                                      );
                                    }).toList(),
                                  )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      for (var entry in mySelections.entries) {
                        final availability = Availability(
                          refereeId: widget.refereeId,
                          date: entry.key,
                          availableTimes: entry.value,
                        );
                        await _firestoreService.saveAvailability(availability);
                      }
                      if(mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uygunluk tablonuz güncellendi!"), backgroundColor: Colors.green));
                      }
                    },
                    child: _buildSolidCard(
                      color: _borderColor,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: const Center(child: Text("BİLGİLERİ KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1))),
                    ),
                  )
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _buildSquadRow(String role, String? id, IconData icon, bool isMe, List<Referee> allReferees) {
    if (id == null) return const SizedBox.shrink();

    String name = allReferees.firstWhere((r) => r.id == id, orElse: () => Referee(id: "", name: "EKSİK", email: "", role: RefereeRole.aday, level: 0)).name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isMe ? _primaryColor : Colors.black54),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(role, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isMe ? _primaryColor : Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(name.toUpperCase(), style: TextStyle(fontWeight: isMe ? FontWeight.w900 : FontWeight.bold, fontSize: 13, color: isMe ? Colors.black : Colors.black87)),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: _primaryColor, width: 1)),
              child: Text("SEN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _primaryColor)),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Referee>>(
      stream: _firestoreService.getRefereesStream(),
      builder: (context, refSnapshot) {
        if (!refSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));

        final allReferees = refSnapshot.data!;
        final referee = allReferees.firstWhere((r) => r.id == widget.refereeId, orElse: () => Referee(id: "", name: "Hakem", email: "", role: RefereeRole.aday, level: 0));

        return Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            title: const Text("TBF HAKEM PANELİ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            backgroundColor: Colors.white, elevation: 0,
            bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: _borderColor, height: 2)),
            actions: [
              IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if(mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.red, size: 28),
              )
            ],
          ),
          body: StreamBuilder<List<Match>>(
            stream: _firestoreService.getMatchesStream(),
            builder: (context, matchSnapshot) {
              return StreamBuilder<List<Availability>>(
                  stream: _firestoreService.getAvailabilitiesStream(),
                  builder: (context, availSnapshot) {
                    final matches = matchSnapshot.data ?? [];
                    final avails = availSnapshot.data ?? [];

                    final myAssignedMatches = matches.where((m) =>
                    m.status == MatchStatus.approved &&
                        [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(widget.refereeId)
                    ).toList();

                    int totalLoad = myAssignedMatches.length;
                    int availabilityCount = avails.where((a) => a.refereeId == widget.refereeId && !a.availableTimes.contains("UYGUN DEĞİL")).fold(0, (sum, a) => sum + a.availableTimes.length);

                    Set<String> allMatchDays = matches.map((m) => m.date).toSet();
                    Set<String> filledDays = avails.where((a) => a.refereeId == widget.refereeId && a.availableTimes.isNotEmpty).map((a) => a.date).toSet();
                    int missingDays = allMatchDays.length - filledDays.length;
                    if(missingDays < 0) missingDays = 0;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSolidCard(
                            color: Colors.white,
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30, backgroundColor: _primaryColor,
                                  child: Text(referee.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("AKTİF GÖREVLİ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
                                      Text(referee.name.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: _primaryColor, width: 1.5)),
                                        child: Text("${referee.role.name.toUpperCase()} KATEGORİSİ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _primaryColor)),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                  child: _buildSolidCard(
                                      color: Colors.blue.shade50, padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          const Text("KESİN MAÇ", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blue)),
                                          const SizedBox(height: 4),
                                          Text(totalLoad.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                                        ],
                                      )
                                  )
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _buildSolidCard(
                                      color: Colors.purple.shade50, padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          const Text("UYGUNLUK SAYISI", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.purple)),
                                          const SizedBox(height: 4),
                                          Text(availabilityCount.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                                        ],
                                      )
                                  )
                              ),
                              const SizedBox(width: 10),

                              Expanded(
                                child: GestureDetector(
                                  onTap: _openAvailabilityForm,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      _buildSolidCard(
                                          width: double.infinity,
                                          color: missingDays == 0 ? Colors.green.shade50 : Colors.red.shade50,
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text("BİLDİRİM DURUMU", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: missingDays == 0 ? Colors.green : Colors.red)),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                decoration: BoxDecoration(color: missingDays == 0 ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(4)),
                                                child: Text(missingDays == 0 ? "TAMAM" : "EKSİK GİRİŞ", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                                              )
                                            ],
                                          )
                                      ),
                                      if (missingDays > 0)
                                        Positioned(
                                          top: -8,
                                          right: -8,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                            child: Text(missingDays.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          const Text("YAKLAŞAN GÖREVLERİM", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                          const Divider(color: Colors.black12, thickness: 2, height: 24),

                          if (myAssignedMatches.isEmpty)
                            _buildSolidCard(
                              padding: const EdgeInsets.all(30),
                              child: const Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.calendar_view_day, size: 40, color: Colors.black26),
                                      SizedBox(height: 12),
                                      Text("Şu an için kesinleşmiş bir görev bulunmuyor.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
                                    ],
                                  )
                              ),
                            )
                          else
                            ...myAssignedMatches.map((m) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildSolidCard(
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // --- YENİ BAŞLIK YAPISI (TARİH, SAAT VE KONUM EKLENDİ) ---
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF4F6F8),
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                          border: Border(bottom: BorderSide(color: Color(0xFF1C1C1C), width: 2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.event, size: 16),
                                                    const SizedBox(width: 6),
                                                    Text(m.date, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.schedule, size: 16),
                                                    const SizedBox(width: 6),
                                                    Text(m.time, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                                  ],
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    m.location,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // --- YENİ KATEGORİ ROZETİ ---
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius: BorderRadius.circular(4)
                                              ),
                                              child: Text(
                                                  m.category.toUpperCase(),
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 40, height: 40,
                                                  decoration: BoxDecoration(color: Colors.orange.shade100, border: Border.all(color: _borderColor, width: 1.5), borderRadius: BorderRadius.circular(8)),
                                                  child: const Icon(Icons.sports_basketball, color: Colors.orange, size: 22),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text("${m.teamA} VS ${m.teamB}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              color: _borderColor,
                                              child: const Text("MAÇ KADROSU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                            ),
                                            const SizedBox(height: 12),

                                            _buildSquadRow("BAŞ HAKEM", m.headRefereeId, Icons.sports, m.headRefereeId == widget.refereeId, allReferees),
                                            _buildSquadRow("YARD. HAKEM", m.assistantRefereeId, Icons.sports_outlined, m.assistantRefereeId == widget.refereeId, allReferees),
                                            const Divider(color: Colors.black12, thickness: 1.5),
                                            const SizedBox(height: 6),
                                            _buildSquadRow("SAYI", m.scorekeeperId, Icons.calculate_outlined, m.scorekeeperId == widget.refereeId, allReferees),
                                            _buildSquadRow("SAAT", m.timekeeperId, Icons.timer_outlined, m.timekeeperId == widget.refereeId, allReferees),
                                            _buildSquadRow("24 SN", m.shotClockOperatorId, Icons.av_timer_outlined, m.shotClockOperatorId == widget.refereeId, allReferees),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          const SizedBox(height: 60),
                        ],
                      ),
                    );
                  }
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAvailabilityForm,
            backgroundColor: _borderColor,
            label: const Text("UYGUNLUK GİR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
            icon: const Icon(Icons.edit_calendar, color: Colors.white),
          ),
        );
      },
    );
  }
}