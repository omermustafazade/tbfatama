import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../models/team.dart';
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

  bool _isPastMatch(String date, String time) {
    try {
      DateTime matchDate = DateTime.parse("$date $time:00");
      return matchDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

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

  void _openAvailabilityForm() {
    _firestoreService.getMatchesStream().first.then((allMatches) {
      _firestoreService.getAvailabilitiesStream().first.then((allAvails) {
        final myAssignedMatches = allMatches.where((m) =>
        m.status == MatchStatus.approved &&
            [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(widget.refereeId) &&
            !_isPastMatch(m.date, m.time)
        ).toList();
        _showAvailabilityForm(allMatches, allAvails, myAssignedMatches);
      });
    });
  }

  void _showAvailabilityForm(List<Match> allMatches, List<Availability> existingAvails, List<Match> myAssignedMatches) {
    Map<String, Set<String>> matchSlots = {};
    for (var m in allMatches) {
      if (!_isPastMatch(m.date, m.time)) {
        if (!matchSlots.containsKey(m.date)) matchSlots[m.date] = {};
        matchSlots[m.date]!.add(m.time);
      }
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
                  Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Text("HAFTALIK UYGUNLUK BİLDİRİMİ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
                                            "UYGUN DEĞİL",
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

  Widget _buildSquadRow(String role, String? id, IconData icon, bool isMe, List<Referee> allReferees, {bool isPast = false}) {
    if (id == null) return const SizedBox.shrink();
    String name = allReferees.firstWhere((r) => r.id == id, orElse: () => Referee(id: "", name: "EKSİK", email: "", role: RefereeRole.kosu, level: 0)).name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isPast ? Colors.black54 : (isMe ? _primaryColor : Colors.black54)),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(role, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isPast ? Colors.grey.shade700 : (isMe ? _primaryColor : Colors.grey.shade700))),
          ),
          Expanded(
            child: Text(name.toUpperCase(), style: TextStyle(fontWeight: isMe ? FontWeight.w900 : FontWeight.bold, fontSize: 13, color: isPast ? Colors.black54 : (isMe ? Colors.black : Colors.black87))),
          ),
          if (isMe && !isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: _primaryColor, width: 1)),
              child: Text("SEN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _primaryColor)),
            )
        ],
      ),
    );
  }

  void _showScoreInputDialog(Match match, List<Team> allTeams) {
    final scoreAController = TextEditingController();
    final scoreBController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: _borderColor, width: 3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              const Text("MAÇ SKORUNU GİR", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 6),
              const Text("Sadece Baş Hakem yetkisindedir. Girilen skor kalıcıdır ve lig verilerini günceller.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(match.teamA.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: scoreAController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("VS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black54))),
                  Expanded(
                    child: Column(
                      children: [
                        Text(match.teamB.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: scoreBController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              InkWell(
                onTap: () async {
                  if (scoreAController.text.isEmpty || scoreBController.text.isEmpty) return;
                  int scoreA = int.parse(scoreAController.text);
                  int scoreB = int.parse(scoreBController.text);

                  await _firestoreService.saveMatchScoreAndUpdateStandings(match, scoreA, scoreB, allTeams);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Skor başarıyla kaydedildi ve lig güncellendi!"), backgroundColor: Colors.green));
                  }
                },
                child: _buildSolidCard(color: Colors.black, width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), child: const Center(child: Text("SKORU ONAYLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)))),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCardForReferee(Match m, List<Referee> allReferees, List<Team> allTeams, {bool isPast = false}) {
    bool isHeadReferee = m.headRefereeId == widget.refereeId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _buildSolidCard(
        color: isPast ? Colors.grey.shade50 : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isPast ? Colors.grey.shade300 : const Color(0xFFF4F6F8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                border: const Border(bottom: BorderSide(color: Color(0xFF1C1C1C), width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isPast ? Colors.black54 : Colors.black87, borderRadius: BorderRadius.circular(6)),
                        child: Text(m.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                      ),
                      Row(
                        children: [
                          Icon(Icons.event, size: 14, color: isPast ? Colors.black54 : Colors.black),
                          const SizedBox(width: 4),
                          Text(m.date, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isPast ? Colors.black54 : Colors.black)),
                          const SizedBox(width: 12),
                          Icon(Icons.schedule, size: 14, color: isPast ? Colors.black54 : Colors.black),
                          const SizedBox(width: 4),
                          Text(m.time, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isPast ? Colors.black54 : Colors.black)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: isPast ? Colors.black54 : Colors.redAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(m.location, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isPast ? Colors.black54 : Colors.black), overflow: TextOverflow.ellipsis),
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
                  if (m.isScoreEntered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2)),
                      child: Row(
                        children: [
                          Expanded(child: Text(m.teamA.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade700)),
                            child: Text("${m.teamAScore} - ${m.teamBScore}", style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          ),
                          Expanded(child: Text(m.teamB.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: Text(m.teamA.toUpperCase(), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isPast ? Colors.black54 : Colors.black))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("VS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isPast ? Colors.grey : Colors.red)),
                        ),
                        Expanded(child: Text(m.teamB.toUpperCase(), textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isPast ? Colors.black54 : Colors.black))),
                      ],
                    ),

                  if (isPast && !m.isScoreEntered && isHeadReferee)
                    InkWell(
                      onTap: () => _showScoreInputDialog(m, allTeams),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderColor, width: 2)),
                        child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit_note, color: Colors.white, size: 20), SizedBox(width: 8), Text("MAÇ SKORUNU GİR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1))])),
                      ),
                    ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: isPast ? Colors.grey : _borderColor,
                    child: const Text("MAÇ KADROSU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  _buildSquadRow("BAŞ HAKEM", m.headRefereeId, Icons.sports, m.headRefereeId == widget.refereeId, allReferees, isPast: isPast),
                  _buildSquadRow("YARD. HAKEM", m.assistantRefereeId, Icons.sports_outlined, m.assistantRefereeId == widget.refereeId, allReferees, isPast: isPast),
                  const Divider(color: Colors.black12, thickness: 1.5),
                  const SizedBox(height: 6),
                  _buildSquadRow("SAYI", m.scorekeeperId, Icons.calculate_outlined, m.scorekeeperId == widget.refereeId, allReferees, isPast: isPast),
                  _buildSquadRow("SAAT", m.timekeeperId, Icons.timer_outlined, m.timekeeperId == widget.refereeId, allReferees, isPast: isPast),
                  _buildSquadRow("24 SN", m.shotClockOperatorId, Icons.av_timer_outlined, m.shotClockOperatorId == widget.refereeId, allReferees, isPast: isPast),
                ],
              ),
            )
          ],
        ),
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
        final referee = allReferees.firstWhere((r) => r.id == widget.refereeId, orElse: () => Referee(id: "", name: "Hakem", email: "", role: RefereeRole.kosu, level: 0));

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
          body: SafeArea(
            child: StreamBuilder<List<Match>>(
              stream: _firestoreService.getMatchesStream(),
              builder: (context, matchSnapshot) {
                return StreamBuilder<List<Availability>>(
                    stream: _firestoreService.getAvailabilitiesStream(),
                    builder: (context, availSnapshot) {
                      return StreamBuilder<List<Team>>( // YENİ: Takımları çekiyoruz
                          stream: _firestoreService.getTeamsStream(),
                          builder: (context, teamSnap) {
                            if (!matchSnapshot.hasData || !availSnapshot.hasData || !teamSnap.hasData) {
                              return const Center(child: CircularProgressIndicator(color: Colors.orange));
                            }

                            final matches = matchSnapshot.data ?? [];
                            final avails = availSnapshot.data ?? [];
                            final allTeams = teamSnap.data ?? [];

                            final myAssignedMatches = matches.where((m) =>
                            m.status == MatchStatus.approved &&
                                [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(widget.refereeId)
                            ).toList();

                            final upcomingMatches = myAssignedMatches.where((m) => !_isPastMatch(m.date, m.time)).toList();
                            final pastMatches = myAssignedMatches.where((m) => _isPastMatch(m.date, m.time)).toList();

                            upcomingMatches.sort((a, b) => "${a.date} ${a.time}".compareTo("${b.date} ${b.time}"));
                            pastMatches.sort((a, b) => "${b.date} ${b.time}".compareTo("${a.date} ${a.time}"));

                            int totalLoad = upcomingMatches.length;
                            int availabilityCount = avails.where((a) => a.refereeId == widget.refereeId && !a.availableTimes.contains("UYGUN DEĞİL")).fold(0, (sum, a) => sum + a.availableTimes.length);

                            Set<String> allMatchDays = matches.where((m) => !_isPastMatch(m.date, m.time)).map((m) => m.date).toSet();
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
                                                        child: Text(missingDays == 0 ? "TAMAM" : "EKSİK", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
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
                                  if (upcomingMatches.isEmpty)
                                    _buildSolidCard(
                                      padding: const EdgeInsets.all(30),
                                      child: const Center(
                                          child: Column(
                                            children: [
                                              Icon(Icons.sports_basketball, size: 40, color: Colors.black26),
                                              SizedBox(height: 12),
                                              Text("Şu an için yaklaşan bir görev bulunmuyor.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
                                            ],
                                          )
                                      ),
                                    )
                                  else
                                    ...upcomingMatches.map((m) => _buildMatchCardForReferee(m, allReferees, allTeams, isPast: false)).toList(),

                                  const SizedBox(height: 30),
                                  const Text("GEÇMİŞ GÖREVLER & SKOR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1, color: Colors.grey)),
                                  const Divider(color: Colors.black12, thickness: 2, height: 24),
                                  if (pastMatches.isEmpty)
                                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Geçmiş bir atama kaydı bulunamadı.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))))
                                  else
                                    ...pastMatches.map((m) => _buildMatchCardForReferee(m, allReferees, allTeams, isPast: true)).toList(),

                                  const SizedBox(height: 60),
                                ],
                              ),
                            );
                          }
                      );
                    }
                );
              },
            ),
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