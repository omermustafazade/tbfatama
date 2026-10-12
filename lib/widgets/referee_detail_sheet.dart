import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';

class RefereeDetailSheet extends StatefulWidget {
  final Referee referee;
  final List<Availability> availabilities;
  final List<Match> allMatches;

  const RefereeDetailSheet({
    super.key,
    required this.referee,
    required this.availabilities,
    required this.allMatches,
  });

  @override
  State<RefereeDetailSheet> createState() => _RefereeDetailSheetState();
}

class _RefereeDetailSheetState extends State<RefereeDetailSheet> {
  bool _showHistory = false;
  String _selectedTimeFilter = "TÜMÜ";
  final Color _borderColor = const Color(0xFF1C1C1C);

  Color _getRoleColor(RefereeRole role) {
    switch (role) {
      case RefereeRole.kosu: return const Color(0xFF4FC3F7);
      case RefereeRole.masa: return const Color(0xFFFFB74D);
      case RefereeRole.admin: return Colors.blueGrey;
    }
  }

  bool _isPastDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      return date.isBefore(today);
    } catch (e) {
      return false;
    }
  }

  bool _isPastMatch(String date, String time) {
    try {
      DateTime matchDate = DateTime.parse("$date $time:00");
      return matchDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Widget _buildPremiumCard({required Widget child, Color color = Colors.white, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 3),
        boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(4, 4))],
      ),
      child: child,
    );
  }

  String _getRoleInMatch(Match m, String refId) {
    if (m.headRefereeId == refId) return "Baş Hakem";
    if (m.assistantRefereeId == refId) return "Yardımcı";
    if (m.scorekeeperId == refId) return "Sayı Hakemi";
    if (m.timekeeperId == refId) return "Süre Hakemi";
    if (m.shotClockOperatorId == refId) return "24 Saniye";
    return "Görevli";
  }

  // --- HAKEM PDF OLUŞTURMA FONKSİYONU ---
  Future<void> _generateAndPrintRefereePdf(int totalAssigned, int totalAvail) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)));

    try {
      final pdf = pw.Document();
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontBlack = await PdfGoogleFonts.robotoBlack();

      var assignedMatches = widget.allMatches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(widget.referee.id)).toList();
      var upcomingMatches = assignedMatches.where((m) => !_isPastMatch(m.date, m.time)).toList();
      var pastMatches = assignedMatches.where((m) => _isPastMatch(m.date, m.time)).toList();

      upcomingMatches.sort((a, b) => "${a.date} ${a.time}".compareTo("${b.date} ${b.time}"));
      pastMatches.sort((a, b) => "${b.date} ${b.time}".compareTo("${a.date} ${a.time}"));

      // GEÇMİŞ MAÇLARI EN GÜNCEL 10 İLE SINIRLANDIRMA (YENİ)
      bool hasMorePast = pastMatches.length > 10;
      if (hasMorePast) pastMatches = pastMatches.take(10).toList();

      int countHead = assignedMatches.where((m) => m.headRefereeId == widget.referee.id).length;
      int countAssistant = assignedMatches.where((m) => m.assistantRefereeId == widget.referee.id).length;
      int countScore = assignedMatches.where((m) => m.scorekeeperId == widget.referee.id).length;
      int countTime = assignedMatches.where((m) => m.timekeeperId == widget.referee.id).length;
      int countShot = assignedMatches.where((m) => m.shotClockOperatorId == widget.referee.id).length;
      int totalTable = countScore + countTime + countShot;

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
                    pw.Text('HAKEM GÖREV RAPORU', style: pw.TextStyle(font: fontBlack, fontSize: 24, color: PdfColors.white, letterSpacing: 1)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 3), color: PdfColors.grey100),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('HAKEM ADI', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                              pw.Text(widget.referee.name.toUpperCase(), style: pw.TextStyle(font: fontBlack, fontSize: 20)),
                            ]
                        ),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('KATEGORİ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                              pw.Text('${widget.referee.role.name.toUpperCase()} | GRUP: ${widget.referee.level}', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                            ]
                        ),
                      ]
                  )
              ),
              pw.SizedBox(height: 24),

              pw.Text(' İSTATİSTİKLER VE GÖREV DAĞILIMI', style: pw.TextStyle(font: fontBlack, fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.black, width: 2),
                headerStyle: pw.TextStyle(font: fontBlack, color: PdfColors.white, fontSize: 11),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
                cellStyle: pw.TextStyle(font: fontBold, fontSize: 12),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.center, 1: pw.Alignment.center,
                  2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.center
                },
                data: [
                  ['TOPLAM MAÇ', 'BAŞ HAKEM', 'YARDIMCI', 'MASA GÖREVİ', 'UYGUNLUK GÜNÜ'],
                  ['$totalAssigned', '$countHead', '$countAssistant', '$totalTable', '$totalAvail'],
                ],
              ),
              pw.SizedBox(height: 32),

              pw.Text(' YAKLAŞAN GÖREVLER', style: pw.TextStyle(font: fontBlack, fontSize: 16)),
              pw.SizedBox(height: 8),
              if (upcomingMatches.isEmpty)
                pw.Text(' Yaklaşan bir görev bulunmuyor.', style: pw.TextStyle(font: fontRegular, color: PdfColors.grey700))
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 2),
                  headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.black),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 11),
                  cellHeight: 25,
                  data: [
                    ['TARİH', 'SAAT', 'KARŞILAŞMA', 'POZİSYON', 'SALON'],
                    ...upcomingMatches.map((m) {
                      return [m.date, m.time, "${m.teamA} - ${m.teamB}", _getRoleInMatch(m, widget.referee.id), m.location];
                    }),
                  ],
                ),
              pw.SizedBox(height: 32),

              // YENİ BAŞLIK VE LİSTE
              pw.Text(hasMorePast ? ' SON 10 TAMAMLANAN GÖREV' : ' TAMAMLANAN GÖREVLER', style: pw.TextStyle(font: fontBlack, fontSize: 16)),
              pw.SizedBox(height: 8),
              if (pastMatches.isEmpty)
                pw.Text(' Geçmiş görev kaydı bulunmuyor.', style: pw.TextStyle(font: fontRegular, color: PdfColors.grey700))
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 2),
                  headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.black),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellStyle: pw.TextStyle(font: fontRegular, fontSize: 11),
                  cellHeight: 25,
                  data: [
                    ['TARİH', 'KARŞILAŞMA', 'POZİSYON', 'SKOR'],
                    ...pastMatches.map((m) {
                      String score = m.isScoreEntered ? "${m.teamAScore} - ${m.teamBScore}" : "Bekliyor";
                      return [m.date, "${m.teamA} - ${m.teamB}", _getRoleInMatch(m, widget.referee.id), score];
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
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: '${widget.referee.name.replaceAll(" ", "_")}_Raporu.pdf');

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Hatası: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildTimeFilters() {
    final filters = ["TÜMÜ", "Son 1 Hafta", "Son 1 Ay", "Son 3 Ay", "Son 6 Ay"];
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: !_showHistory ? const SizedBox.shrink() : Container(
        height: 45,
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (ctx, i) {
            bool isSelected = filters[i] == _selectedTimeFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedTimeFilter = filters[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))] : null,
                ),
                alignment: Alignment.center,
                child: Text(filters[i].toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color roleColor = _getRoleColor(widget.referee.role);
    int totalMatchesAssigned = widget.allMatches.where((m) => [m.headRefereeId, m.assistantRefereeId, m.scorekeeperId, m.timekeeperId, m.shotClockOperatorId].contains(widget.referee.id)).length;
    List<Availability> refAvails = widget.availabilities.where((a) => a.refereeId == widget.referee.id).toList();
    int totalAvailsGiven = refAvails.length;

    List<Availability> displayAvails = [];
    if (!_showHistory) {
      displayAvails = refAvails.where((a) => !_isPastDate(a.date)).toList();
      displayAvails.sort((a, b) => a.date.compareTo(b.date));
    } else {
      displayAvails = refAvails.where((a) => _isPastDate(a.date)).toList();
      if (_selectedTimeFilter != "TÜMÜ") {
        DateTime now = DateTime.now();
        displayAvails = displayAvails.where((a) {
          try {
            DateTime d = DateTime.parse(a.date);
            int diff = now.difference(d).inDays;
            if (_selectedTimeFilter == "Son 1 Hafta") return diff <= 7;
            if (_selectedTimeFilter == "Son 1 Ay") return diff <= 30;
            if (_selectedTimeFilter == "Son 3 Ay") return diff <= 90;
            if (_selectedTimeFilter == "Son 6 Ay") return diff <= 180;
            return true;
          } catch (e) { return true; }
        }).toList();
      }
      displayAvails.sort((a, b) => b.date.compareTo(a.date));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.8, maxChildSize: 0.95, expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: Color(0xFFF4F6F8), borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: Colors.black, width: 4), left: BorderSide(color: Colors.black, width: 4), right: BorderSide(color: Colors.black, width: 4))),
          child: ListView(
            controller: scrollController, padding: const EdgeInsets.all(24.0),
            children: [
              Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),

              Row(
                children: [
                  Container(width: 70, height: 70, decoration: BoxDecoration(color: roleColor.withOpacity(0.3), border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(16)), child: Center(child: Text(widget.referee.name.isNotEmpty ? widget.referee.name[0].toUpperCase() : "?", style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 32, fontWeight: FontWeight.w900)))),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.referee.name.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: roleColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 1.5)), child: Text(widget.referee.role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black87))),
                      ],
                    ),
                  ),
                  Column(children: [Text("G${widget.referee.level}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black)), const Text("GRUP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54))]),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: Column(children: [Text(totalMatchesAssigned.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFE5A93C))), const SizedBox(height: 4), const Text("TOPLAM GÖREV", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54))]))),
                  const SizedBox(width: 16),
                  Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: Column(children: [Text(totalAvailsGiven.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.green.shade600)), const SizedBox(height: 4), const Text("UYGUNLUK BİLDİRİMİ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54))]))),
                ],
              ),
              const SizedBox(height: 24),

              InkWell(
                onTap: () => _generateAndPrintRefereePdf(totalMatchesAssigned, totalAvailsGiven),
                child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: Colors.indigo.shade800, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.picture_as_pdf, color: Colors.white, size: 20), SizedBox(width: 8), Text("📄 HAKEM RAPORUNU PDF YAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1))])),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]),
                child: Row(
                  children: [
                    Expanded(child: InkWell(onTap: () => setState(() { _showHistory = false; _selectedTimeFilter = "TÜMÜ"; }), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: !_showHistory ? Colors.black : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Center(child: Text("GELECEK UYGUNLUK", style: TextStyle(color: !_showHistory ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 12)))))),
                    Expanded(child: InkWell(onTap: () => setState(() => _showHistory = true), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _showHistory ? Colors.black : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Center(child: Text("GEÇMİŞ UYGUNLUK", style: TextStyle(color: _showHistory ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 12)))))),
                  ],
                ),
              ),

              _buildTimeFilters(),

              if (_showHistory)
                Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFE5A93C), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.filter_list, size: 14, color: Colors.black), const SizedBox(width: 6), Text("FİLTRE SONUCU: ${displayAvails.length} KAYIT", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black, letterSpacing: 0.5))]))]))
              else
                const SizedBox(height: 16),

              if (displayAvails.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Column(children: [Icon(_showHistory ? Icons.history : Icons.event_busy, size: 48, color: Colors.black26), const SizedBox(height: 16), Text(_showHistory ? "Geçmiş uygunluk kaydı yok." : "Gelecek için uygunluk bildirmemiş.", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))])) )
              else
                ...displayAvails.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPremiumCard(
                    color: Colors.white, padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _showHistory ? Colors.grey.shade100 : Colors.orange.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)), child: Icon(Icons.bolt, size: 24, color: _showHistory ? Colors.grey : Colors.orange.shade800)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.date, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _showHistory ? Colors.grey.shade700 : Colors.black)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: a.availableTimes.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _showHistory ? Colors.grey.shade50 : Colors.white, border: Border.all(color: _showHistory ? Colors.grey.shade400 : Colors.black, width: _showHistory ? 1 : 1.5), borderRadius: BorderRadius.circular(6)), child: Text(t, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: _showHistory ? Colors.grey : Colors.black)))).toList()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}