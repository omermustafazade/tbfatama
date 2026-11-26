import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
import '../services/demo_seeder.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final FirestoreService _firestoreService = FirestoreService();
  final Color _bgColor = const Color(0xFFF4F6F8);

  String _selectedTimeFilter = "Son 1 Ay";
  String _pastSearchQuery = "";

  @override
  void initState() {
    super.initState();
    DemoSeeder.ensureDemoAuth();
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$unresolved maçta eksik hakem kaldı! (İlgili saate uygunluk veren hakem yetersiz)"),
            backgroundColor: Colors.orange.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tüm atamalar kusursuz şekilde tamamlandı!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _generateWeeklyBulletinPdf(List<Match> activeMatches, List<Referee> referees) async {
    if (activeMatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bülten oluşturulacak aktif maç bulunmuyor!"), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      final pdf = pw.Document();
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontBlack = await PdfGoogleFonts.robotoBlack();

      String getRefName(String? id) {
        if (id == null) return "EKSİK";
        final r = referees.firstWhere(
              (ref) => ref.id == id,
          orElse: () => Referee(id: "", name: "EKSİK", email: "", role: RefereeRole.kosu, level: 0),
        );
        return r.level > 0 ? "${r.name} (G${r.level})" : r.name;
      }

      // A4 Yatay için genişliği yükseklikten büyük özel sayfa formatı (Zorunlu Yatay)
      const PdfPageFormat customLandscapeA4 = PdfPageFormat(841.89, 595.27, marginAll: 0);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: customLandscapeA4,
          orientation: pw.PageOrientation.landscape,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (pw.Context context) {
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                  border: pw.Border.all(color: PdfColors.black, width: 2.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TÜRKİYE BASKETBOL FEDERASYONU - İL TEMSİLCİLİĞİ', style: pw.TextStyle(font: fontBlack, fontSize: 9, color: PdfColors.grey400)),
                        pw.SizedBox(height: 3),
                        pw.Text('HAFTALIK RESMİ FİKSTÜR VE HAKEM ATAMA BÜLTENİ', style: pw.TextStyle(font: fontBlack, fontSize: 16, color: PdfColors.white)),
                      ],
                    ),
                    pw.Text(
                      'TOPLAM: ${activeMatches.length} MÜSABAKA',
                      style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.amber),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1.2),
                columnWidths: const {
                  0: pw.FixedColumnWidth(75),  // Tarih / Saat
                  1: pw.FixedColumnWidth(85),  // Kategori
                  2: pw.FixedColumnWidth(95),  // Salon
                  3: pw.FlexColumnWidth(1.4),  // Karşılaşma (Esnek)
                  4: pw.FixedColumnWidth(45),  // Baraj
                  5: pw.FlexColumnWidth(1.1),  // Baş Hakem
                  6: pw.FlexColumnWidth(1.1),  // Yardımcı
                  7: pw.FlexColumnWidth(1.3),  // Masa Görevlileri
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.black),
                    children: [
                      _th('TARİH / SAAT', fontBlack),
                      _th('KATEGORİ', fontBlack),
                      _th('SALON', fontBlack),
                      _th('KARŞILAŞMA', fontBlack),
                      _th('BARAJ', fontBlack),
                      _th('BAŞ HAKEM', fontBlack),
                      _th('YARDIMCI', fontBlack),
                      _th('MASA (S / SA / 24)', fontBlack),
                    ],
                  ),
                  ...activeMatches.map((m) {
                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        _td("${m.date}\n${m.time}", fontBold, align: pw.TextAlign.center),
                        _td(m.category, fontRegular),
                        _td(m.location, fontRegular),
                        _td("${m.teamA}\nvs\n${m.teamB}", fontBold),
                        _td("${m.matchPoint} P", fontBold, align: pw.TextAlign.center),
                        _td(getRefName(m.headRefereeId), fontRegular),
                        _td(getRefName(m.assistantRefereeId), fontRegular),
                        _td("${getRefName(m.scorekeeperId)}\n${getRefName(m.timekeeperId)}\n${getRefName(m.shotClockOperatorId)}", fontRegular),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Bu bülten TBF Yapay Zeka Destekli Atama Sistemi tarafından ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} tarihinde otomatik oluşturulmuştur.',
                style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.grey700),
              ),
            ];
          },
        ),
      );

      if (mounted) Navigator.pop(context);

      // Printing.layoutPdf içine format parametresi olarak özel yatay formatımızı veriyoruz
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        format: customLandscapeA4,
        name: 'TBF_Haftalik_Atama_Bulteni.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Hatası: $e"), backgroundColor: Colors.red));
      }
    }
  }

  pw.Widget _th(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.white),
      ),
    );
  }

  pw.Widget _td(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 8),
      ),
    );
  }

  Widget _buildTimeFilters() {
    final filters = ["Tümü", "Son 1 Hafta", "Son 1 Ay", "Son 3 Ay", "Son 6 Ay"];
    return Container(
      height: 50,
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(3, 3))]
                    : const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))],
              ),
              alignment: Alignment.center,
              child: Text(
                filters[i].toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: Icon(icon, size: 48, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1, color: Colors.black)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDataWipe() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text("SİSTEMİ SIFIRLA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Tüm takımlar, hakemler (yöneticiler hariç), maçlar ve uygunluk verileri kalıcı olarak silinecektir. Emin misiniz?",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İPTAL", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black, width: 2)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              DemoSeeder.clearAllData(context);
            },
            child: const Text("SİL", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
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
                    if (matchSnap.hasError || refSnap.hasError || availSnap.hasError || teamSnap.hasError) {
                      return Scaffold(
                        backgroundColor: _bgColor,
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_person, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text(
                                  "VERİTABANI ERİŞİM / YETKİ ENGELİ",
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${matchSnap.error ?? refSnap.error ?? availSnap.error ?? teamSnap.error}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                  onPressed: () async {
                                    await DemoSeeder.ensureDemoAuth();
                                    setState(() {});
                                  },
                                  child: const Text("OTOMATİK YETKİLENDİR VE YENİLE"),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }

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
                        } catch (e) {
                          return true;
                        }
                      }).toList();
                    }

                    if (_pastSearchQuery.isNotEmpty) {
                      pastMatches = pastMatches
                          .where((m) =>
                      m.teamA.toLowerCase().contains(_pastSearchQuery.toLowerCase()) ||
                          m.teamB.toLowerCase().contains(_pastSearchQuery.toLowerCase()) ||
                          m.category.toLowerCase().contains(_pastSearchQuery.toLowerCase()))
                          .toList();
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
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AdminAddMatchSheet(allTeams: teams),
                              );
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
                                  backgroundColor: _bgColor,
                                  elevation: 0,
                                  floating: true,
                                  snap: true,
                                  toolbarHeight: 70,
                                  titleSpacing: 16,
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                "TBF ATAMA MERKEZİ",
                                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5, color: Colors.black),
                                              ),
                                            ),
                                            Text(
                                              "Maç ve Hakem Yönetimi",
                                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _generateWeeklyBulletinPdf(activeMatches, referees),
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: Colors.indigo.shade50,
                                                border: Border.all(color: Colors.black, width: 2),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                                              ),
                                              child: Icon(Icons.picture_as_pdf, color: Colors.indigo.shade900, size: 20),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: _confirmDataWipe,
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                border: Border.all(color: Colors.black, width: 2),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                                              ),
                                              child: Icon(Icons.delete_sweep, color: Colors.orange.shade900, size: 20),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => DemoSeeder.seedDemoData(context),
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                border: Border.all(color: Colors.black, width: 2),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                                              ),
                                              child: Icon(Icons.auto_fix_high, color: Colors.blue.shade800, size: 20),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                                                  (route) => false,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                border: Border.all(color: Colors.black, width: 2),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                                              ),
                                              child: Icon(Icons.logout, color: Colors.red.shade800, size: 20),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  bottom: PreferredSize(
                                    preferredSize: const Size.fromHeight(60),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black, width: 2),
                                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                                      ),
                                      child: TabBar(
                                        indicator: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.black, width: 2),
                                        ),
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        labelColor: Colors.white,
                                        unselectedLabelColor: Colors.black,
                                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                        tabs: const [
                                          Tab(text: "GÜNCEL ATAMALAR"),
                                          Tab(text: "GEÇMİŞ & SKOR"),
                                        ],
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
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActiveMatchesView(
      Map<String, List<Match>> groupedMatches,
      List<Referee> referees,
      List<Availability> availabilities,
      List<Match> allMatches,
      List<Match> activeMatches,
      ) {
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
          _buildEmptyState("GÜNCEL MAÇ YOK", "Üstteki mavi sihirli değnek butonuna basarak\n3 günlük 10 maçlık sunum verisini yükleyin.", Icons.sports_basketball)
        else
          ...groupedMatches.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                        ),
                        child: Text(
                          "${entry.key} (${entry.value.length} MAÇ)",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 2, color: Colors.black26)),
                    ],
                  ),
                ),
                ...entry.value.map(
                      (match) => AdminMatchCard(
                    match: match,
                    referees: referees,
                    availabilities: availabilities,
                    allMatches: allMatches,
                    isPast: false,
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildPastMatchesView(
      List<Match> pastMatches,
      List<Referee> referees,
      List<Availability> availabilities,
      List<Match> allMatches,
      ) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: TextField(
            onChanged: (val) => setState(() => _pastSearchQuery = val),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
            decoration: InputDecoration(
              hintText: "TAKIM VEYA KATEGORİ ARA...",
              hintStyle: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade400, fontSize: 13, letterSpacing: 1),
              prefixIcon: const Icon(Icons.search, color: Colors.black, size: 24),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
        ),
        _buildTimeFilters(),
        if (pastMatches.isEmpty)
          _buildEmptyState("KAYIT BULUNAMADI", "Seçilen tarih aralığında veya aramada\nherhangi bir maç kaydı yok.", Icons.scoreboard_outlined)
        else
          ...pastMatches.map(
                (match) => AdminMatchCard(
              match: match,
              referees: referees,
              availabilities: availabilities,
              allMatches: allMatches,
              isPast: true,
            ),
          ),
      ],
    );
  }
}