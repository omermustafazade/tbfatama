import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/team.dart';
import '../models/match.dart';
import '../services/firestore_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Team _currentTeam;
  final Color _bgColor = const Color(0xFFF4F6F8);
  final Color _borderColor = const Color(0xFF1C1C1C);

  @override
  void initState() {
    super.initState();
    _currentTeam = widget.team;
  }

  bool _isPastMatch(String date, String time) {
    try {
      DateTime matchDate = DateTime.parse("$date $time:00");
      return matchDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

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

  Future<void> _generateAndPrintPdf(List<Match> teamMatches) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)));

    try {
      final pdf = pw.Document();
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontBlack = await PdfGoogleFonts.robotoBlack();

      int winRate = _currentTeam.matchesPlayed > 0 ? ((_currentTeam.wins / _currentTeam.matchesPlayed) * 100).toInt() : 0;
      var upcomingMatches = teamMatches.where((m) => !_isPastMatch(m.date, m.time)).toList();
      var pastMatches = teamMatches.where((m) => _isPastMatch(m.date, m.time)).toList();
      upcomingMatches.sort((a, b) => "${a.date} ${a.time}".compareTo("${b.date} ${b.time}"));
      pastMatches.sort((a, b) => "${b.date} ${b.time}".compareTo("${a.date} ${a.time}"));

      bool hasMorePast = pastMatches.length > 10;
      if (hasMorePast) pastMatches = pastMatches.take(10).toList();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          ),
          build: (pw.Context context) {
            return [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                  border: pw.Border.all(color: PdfColors.black, width: 3),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TBF ATAMA SİSTEMİ', style: pw.TextStyle(font: fontBlack, fontSize: 12, color: PdfColors.grey400, letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text('TAKIM RAPORU VE FİKSTÜR', style: pw.TextStyle(font: fontBlack, fontSize: 24, color: PdfColors.white, letterSpacing: 1)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 3),
                      color: PdfColors.grey100
                  ),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('TAKIM ADI', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                              pw.Text(_currentTeam.name.toUpperCase(), style: pw.TextStyle(font: fontBlack, fontSize: 20)),
                            ]
                        ),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('LİG', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                              pw.Text('${_currentTeam.category.toUpperCase()} | KATEGORİ: ${_currentTeam.powerPoint}', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                            ]
                        ),
                      ]
                  )
              ),
              pw.SizedBox(height: 24),

              pw.Text(' SEZON İSTATİSTİKLERİ', style: pw.TextStyle(font: fontBlack, fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.black, width: 2),
                headerStyle: pw.TextStyle(font: fontBlack, color: PdfColors.white, fontSize: 12),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
                cellStyle: pw.TextStyle(font: fontBold, fontSize: 14),
                cellHeight: 30,
                cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center},
                data: [
                  ['OYNANAN', 'GALİBİYET', 'MAĞLUBİYET', 'BAŞARI ORANI'],
                  ['${_currentTeam.matchesPlayed}', '${_currentTeam.wins}', '${_currentTeam.losses}', '%$winRate'],
                ],
              ),
              pw.SizedBox(height: 32),

              pw.Text(' YAKLAŞAN MAÇLAR', style: pw.TextStyle(font: fontBlack, fontSize: 16)),
              pw.SizedBox(height: 8),
              if (upcomingMatches.isEmpty)
                pw.Text(' Planlanmış maç bulunmuyor.', style: pw.TextStyle(font: fontRegular, color: PdfColors.grey700))
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 2),
                  headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.black),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 11),
                  cellHeight: 25,
                  data: [
                    ['TARİH', 'SAAT', 'RAKİP', 'SALON'],
                    ...upcomingMatches.map((m) {
                      String opponent = m.teamAId == _currentTeam.id ? m.teamB : m.teamA;
                      return [m.date, m.time, opponent.toUpperCase(), m.location];
                    }),
                  ],
                ),
              pw.SizedBox(height: 32),

              pw.Text(hasMorePast ? ' SON 10 GEÇMİŞ MAÇ' : ' GEÇMİŞ MAÇLAR', style: pw.TextStyle(font: fontBlack, fontSize: 16)),
              pw.SizedBox(height: 8),
              if (pastMatches.isEmpty)
                pw.Text(' Henüz oynanmış maç bulunmuyor.', style: pw.TextStyle(font: fontRegular, color: PdfColors.grey700))
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 2),
                  headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.black),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 11),
                  cellHeight: 25,
                  data: [
                    ['TARİH', 'RAKİP', 'SKOR', 'DURUM'],
                    ...pastMatches.map((m) {
                      bool isTeamA = m.teamAId == _currentTeam.id;
                      String opponent = isTeamA ? m.teamB : m.teamA;
                      String score = m.isScoreEntered ? (isTeamA ? "${m.teamAScore} - ${m.teamBScore}" : "${m.teamBScore} - ${m.teamAScore}") : "Skor Bekliyor";
                      String status = "-";
                      if (m.isScoreEntered) {
                        int myS = isTeamA ? m.teamAScore! : m.teamBScore!;
                        int opS = isTeamA ? m.teamBScore! : m.teamAScore!;
                        status = myS > opS ? "GALİBİYET" : "MAĞLUBİYET";
                      }
                      return [m.date, opponent.toUpperCase(), score, status];
                    }),
                  ],
                ),

              pw.SizedBox(height: 40),
              pw.Divider(color: PdfColors.black, thickness: 2),
              pw.SizedBox(height: 8),
              pw.Text('TBF Atama Sistemi tarafından ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} tarihinde oluşturuldu.', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700))
            ];
          },
        ),
      );

      if (mounted) Navigator.pop(context);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: '${_currentTeam.name.replaceAll(" ", "_")}_Raporu.pdf');

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Hatası: $e"), backgroundColor: Colors.red));
      }
    }
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İPTAL", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w900, fontSize: 14))),
          InkWell(
            onTap: () { Navigator.pop(ctx); onConfirm(); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: confirmBtnColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]), child: Text(confirmBtnText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
          ),
        ],
      ),
    );
  }

  void _showEditTeamSheet() {
    final nameController = TextEditingController(text: _currentTeam.name);
    final categoryController = TextEditingController(text: _currentTeam.category);
    int powerPoint = _currentTeam.powerPoint;
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
                            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit, color: Colors.white, size: 26)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("TAKIMI DÜZENLE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  Text(_currentTeam.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black12, thickness: 2, height: 1)),
                        const Text("TAKIM ADI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.black54)),
                        const SizedBox(height: 8),
                        TextField(controller: nameController, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade800, width: 2), borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 20),
                        const Text("KATEGORİ (LİG)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.black54)),
                        const SizedBox(height: 8),
                        TextField(controller: categoryController, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade800, width: 2), borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: quickCategories.map((cat) => InkWell(onTap: () => setModalState(() => categoryController.text = cat), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: categoryController.text == cat ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2), boxShadow: categoryController.text == cat ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))] : null), child: Text(cat, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: categoryController.text == cat ? Colors.white : Colors.black))))).toList()),
                        const SizedBox(height: 24),
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12, width: 2)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("KATEGORİ PUANI (1-4)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 1)), Text("${powerPoint.toInt()} PUAN", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]), const SizedBox(height: 4), Slider(value: powerPoint.toDouble(), min: 1, max: 4, divisions: 3, activeColor: Colors.orange.shade800, inactiveColor: Colors.orange.shade200, onChanged: (val) => setModalState(() => powerPoint = val.toInt()))])),
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: () {
                            if(nameController.text.trim().isEmpty || categoryController.text.trim().isEmpty) return;
                            _showActionDialog(
                                title: "DEĞİŞİKLİKLERİ ONAYLA", content: "${_currentTeam.name.toUpperCase()} takımının bilgileri güncellenecek.", confirmBtnText: "EVET, KAYDET", confirmBtnColor: const Color(0xFF2A9D8F),
                                onConfirm: () async {
                                  _currentTeam.name = nameController.text.trim(); _currentTeam.category = categoryController.text.trim(); _currentTeam.powerPoint = powerPoint;
                                  await _firestoreService.updateTeam(_currentTeam);
                                  if (mounted) { setState(() {}); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Takım başarıyla güncellendi!"), backgroundColor: Colors.green)); }
                                }
                            );
                          },
                          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(4, 4))]), child: const Center(child: Text("DEĞİŞİKLİKLERİ KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)))),
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

  Widget _buildMatchRow(Match m, bool isPast) {
    bool isTeamA = m.teamAId == _currentTeam.id;
    String opponentName = isTeamA ? m.teamB : m.teamA;
    String myScore = isTeamA ? (m.teamAScore?.toString() ?? "-") : (m.teamBScore?.toString() ?? "-");
    String opScore = isTeamA ? (m.teamBScore?.toString() ?? "-") : (m.teamAScore?.toString() ?? "-");

    Color resultColor = Colors.grey.shade300;
    String resultText = "-";
    if (isPast && m.isScoreEntered) {
      int myS = int.parse(myScore);
      int opS = int.parse(opScore);
      if (myS > opS) { resultColor = Colors.green.shade100; resultText = "G"; }
      else if (myS < opS) { resultColor = Colors.red.shade100; resultText = "M"; }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(color: isPast ? Colors.grey.shade200 : const Color(0xFFFFF3E0), borderRadius: const BorderRadius.only(topLeft: Radius.circular(9), bottomLeft: Radius.circular(9)), border: const Border(right: BorderSide(color: Colors.black, width: 3))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(m.date.substring(5), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isPast ? Colors.black54 : Colors.orange.shade900, height: 1.0)),
                const SizedBox(height: 4),
                Text(m.time, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isPast ? Colors.black38 : Colors.black87)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Rakip", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(opponentName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(child: Text(m.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: isPast && m.isScoreEntered
                ? Row(
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text("$myScore - $opScore", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1))),
                const SizedBox(width: 8),
                Container(width: 32, height: 32, decoration: BoxDecoration(color: resultColor, border: Border.all(color: Colors.black, width: 2), shape: BoxShape.circle), alignment: Alignment.center, child: Text(resultText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black)))
              ],
            )
                : Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black, width: 1.5)), child: const Text("OYNANMADI", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int winRate = _currentTeam.matchesPlayed > 0 ? ((_currentTeam.wins / _currentTeam.matchesPlayed) * 100).toInt() : 0;

    return StreamBuilder<List<Match>>(
        stream: _firestoreService.getMatchesStream(),
        builder: (context, matchSnapshot) {

          List<Match> teamMatches = [];
          if (matchSnapshot.hasData) {
            teamMatches = matchSnapshot.data!.where((m) => m.teamAId == _currentTeam.id || m.teamBId == _currentTeam.id).toList();
          }

          return Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: _bgColor, elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context)),
              title: const Text("TAKIM PROFİLİ", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1)),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPremiumCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(color: _getTeamColor(_currentTeam.powerPoint), border: Border.all(color: Colors.black, width: 3), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]),
                              alignment: Alignment.center,
                              child: Text(_currentTeam.name.isNotEmpty ? _currentTeam.name[0].toUpperCase() : "?", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black, height: 1.0))
                          ),
                          const SizedBox(height: 20),
                          Text(_currentTeam.name.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5, height: 1.1)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12, alignment: WrapAlignment.center,
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), child: Text(_currentTeam.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.flash_on, size: 14, color: Colors.orange), const SizedBox(width: 4), Text("KATEGORİ: ${_currentTeam.powerPoint}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black))])),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text("İSTATİSTİKLER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black54, letterSpacing: 1)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildPremiumCard(color: const Color(0xFFE1F5FE), padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [const Text("OYNANAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)), const SizedBox(height: 4), Text("${_currentTeam.matchesPlayed}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black))]))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPremiumCard(color: const Color(0xFFE8F5E9), padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [const Text("GALİBİYET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)), const SizedBox(height: 4), Text("${_currentTeam.wins}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green.shade800))]))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildPremiumCard(color: const Color(0xFFFFEBEE), padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [const Text("MAĞLUBİYET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)), const SizedBox(height: 4), Text("${_currentTeam.losses}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red.shade800))]))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPremiumCard(color: winRate >= 50 ? const Color(0xFFFFF3E0) : Colors.grey.shade200, padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [const Text("BAŞARI (%)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)), const SizedBox(height: 4), Text("%$winRate", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: winRate >= 50 ? Colors.orange.shade900 : Colors.black87))]))),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const Text("TAKIM FİKSTÜRÜ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black54, letterSpacing: 1)),
                    const SizedBox(height: 12),

                    Builder(
                        builder: (context) {
                          if (matchSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.black)));
                          }

                          if (teamMatches.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12, width: 2), borderRadius: BorderRadius.circular(12)),
                              child: const Center(child: Text("Takımın atanmış hiçbir maçı yok.", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54))),
                            );
                          }

                          var pastMatches = teamMatches.where((m) => _isPastMatch(m.date, m.time)).toList();
                          var upcomingMatches = teamMatches.where((m) => !_isPastMatch(m.date, m.time)).toList();

                          pastMatches.sort((a, b) => "${b.date} ${b.time}".compareTo("${a.date} ${a.time}"));
                          upcomingMatches.sort((a, b) => "${a.date} ${a.time}".compareTo("${b.date} ${b.time}"));

                          bool hasMorePast = pastMatches.length > 10;
                          if (hasMorePast) pastMatches = pastMatches.take(10).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (upcomingMatches.isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(6)),
                                  child: const Text("GELECEK MAÇLAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                ),
                                ...upcomingMatches.map((m) => _buildMatchRow(m, false)).toList(),
                                const SizedBox(height: 16),
                              ],
                              if (pastMatches.isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                  child: Text(hasMorePast ? "SON 10 GEÇMİŞ MAÇ" : "GEÇMİŞ MAÇLAR", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                ),
                                ...pastMatches.map((m) => _buildMatchRow(m, true)).toList(),
                              ]
                            ],
                          );
                        }
                    ),

                    const SizedBox(height: 40),

                    InkWell(
                      onTap: () {
                        if (teamMatches.isNotEmpty) {
                          _generateAndPrintPdf(teamMatches);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF oluşturulacak maç verisi yok."), backgroundColor: Colors.orange));
                        }
                      },
                      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: Colors.indigo.shade800, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.picture_as_pdf, color: Colors.white, size: 20), SizedBox(width: 8), Text("📄 TAKIM RAPORUNU PDF YAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1))])),
                    ),

                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _showEditTeamSheet,
                      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(4, 4))]), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit, color: Colors.white, size: 20), SizedBox(width: 8), Text("TAKIM BİLGİLERİNİ DÜZENLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1))])),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        _showActionDialog(
                            title: "TAKIMI SİL", content: "${_currentTeam.name.toUpperCase()} takımı sistemden kalıcı olarak silinecek. Emin misiniz?", confirmBtnText: "SİL", confirmBtnColor: Colors.red.shade700,
                            onConfirm: () async {
                              await FirebaseFirestore.instance.collection('teams').doc(_currentTeam.id).delete();
                              if(mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Takım sistemden silindi!"), backgroundColor: Colors.red)); }
                            }
                        );
                      },
                      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade700, width: 3)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20), const SizedBox(width: 8), Text("TAKIMI SİSTEMDEN SİL", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1))])),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}