import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/team.dart';
import '../services/firestore_service.dart';

class AdminAddMatchSheet extends StatefulWidget {
  final List<Team> allTeams;
  const AdminAddMatchSheet({super.key, required this.allTeams});

  @override
  State<AdminAddMatchSheet> createState() => _AdminAddMatchSheetState();
}

class _AdminAddMatchSheetState extends State<AdminAddMatchSheet> {
  final FirestoreService _firestoreService = FirestoreService();

  int _currentStep = 0;

  final locationController = TextEditingController();
  late TextEditingController dateController;
  late TextEditingController timeController;

  String? selectedCategory;
  Team? selectedTeamA;
  Team? selectedTeamB;

  String _categorySearchQuery = "";
  String _locationSearchQuery = "";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    dateController = TextEditingController(text: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}");
    timeController = TextEditingController(text: "${now.hour.toString().padLeft(2, '0')}:00");

    locationController.addListener(() {
      setState(() {
        _locationSearchQuery = locationController.text.toLowerCase();
      });
    });
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)), child: child!),
    );
    if (picked != null) setState(() => dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)), child: child!),
    );
    if (picked != null) setState(() => timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}");
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.red.shade800));
  }

  void _nextStep() {
    if (_currentStep == 0 && selectedCategory == null) {
      _showError("Lütfen ilerlemek için bir lig kategorisi seçin!");
      return;
    }
    if (_currentStep == 1) {
      if (selectedTeamA == null || selectedTeamB == null) {
        _showError("Lütfen karşılaşacak iki takımı da seçin!");
        return;
      }
      if (selectedTeamA!.id == selectedTeamB!.id) {
        _showError("Bir takım kendisiyle karşılaşamaz!");
        return;
      }
    }
    if (_currentStep == 2 && locationController.text.trim().isEmpty) {
      _showError("Lütfen bir konum veya salon belirtin!");
      return;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _submitMatch();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitMatch() async {
    String finalLocation = locationController.text.trim();

    final newMatch = Match(
      id: "m_${DateTime.now().millisecondsSinceEpoch}",
      category: selectedCategory!,
      location: finalLocation,
      date: dateController.text.trim(),
      time: timeController.text.trim(),
      teamA: selectedTeamA!.name,
      teamB: selectedTeamB!.name,
      teamAId: selectedTeamA!.id,
      teamBId: selectedTeamB!.id,
      teamAPoint: selectedTeamA!.powerPoint,
      teamBPoint: selectedTeamB!.powerPoint,
      coachAId: "c1", coachBId: "c2",
      status: MatchStatus.pending,
    );

    await _firestoreService.addMatch(newMatch);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maç başarıyla fikstüre eklendi!"), backgroundColor: Colors.green));
    }
  }

  void _openTeamSearchModal(String title, List<Team> availableTeams, Function(Team) onSelect) {
    showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (ctx) {
          String modalSearchQuery = "";
          return StatefulBuilder(
              builder: (context, setModalState) {
                List<Team> searchedTeams = availableTeams.where((t) => t.name.toLowerCase().contains(modalSearchQuery.toLowerCase())).toList();
                return Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border(top: BorderSide(color: Colors.black, width: 4), left: BorderSide(color: Colors.black, width: 4), right: BorderSide(color: Colors.black, width: 4))
                    ),
                    child: Column(
                      children: [
                        Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 20),
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 20),

                        TextField(
                          autofocus: true,
                          onChanged: (val) => setModalState(() => modalSearchQuery = val),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Takım Ara...",
                            hintStyle: const TextStyle(color: Colors.black38, fontWeight: FontWeight.bold),
                            filled: true, fillColor: const Color(0xFFF4F6F8),
                            prefixIcon: const Icon(Icons.search, color: Colors.black87),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade800, width: 2), borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: searchedTeams.isEmpty
                              ? const Center(child: Text("Takım bulunamadı.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))
                              : ListView.builder(
                            itemCount: searchedTeams.length,
                            itemBuilder: (context, index) {
                              final team = searchedTeams[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    onSelect(team);
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))]),
                                    child: Row(
                                      children: [
                                        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.black, width: 1.5), shape: BoxShape.circle), child: const Icon(Icons.shield, color: Colors.orange, size: 20)),
                                        const SizedBox(width: 16),
                                        Expanded(child: Text(team.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                                        // GÜÇ yerine KATEGORİ yazısı
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text("KATEGORİ: ${team.powerPoint}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        bool isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8, width: isActive ? 24 : 8,
          decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? suffixIcon, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontWeight: FontWeight.bold),
      filled: true, fillColor: Colors.white,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.black87) : null,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.black87) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade800, width: 2), borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildStep0Category() {
    List<String> availableCategories = widget.allTeams.map((e) => e.category).toSet().toList();
    if(availableCategories.isEmpty) availableCategories = ["Önce Takım Ekleyin"];

    List<String> searchedCategories = availableCategories.where((cat) => cat.toLowerCase().contains(_categorySearchQuery.toLowerCase())).toList();

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ADIM 1", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text("LİG KATEGORİSİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text("Oluşturulacak maçın hangi ligde oynanacağını seçin.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 24),

        TextField(
          onChanged: (val) => setState(() => _categorySearchQuery = val),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          decoration: _inputDecoration("Kategori Ara...", prefixIcon: Icons.search),
        ),
        const SizedBox(height: 24),

        searchedCategories.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Kategori bulunamadı.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))))
            : Wrap(
          spacing: 12, runSpacing: 12,
          children: searchedCategories.map((cat) {
            bool isSelected = selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() { selectedCategory = cat; selectedTeamA = null; selectedTeamB = null; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: isSelected ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(4, 4))] : const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))],
                ),
                child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  // --- ADIM 2: KARŞILAŞACAK TAKIMLAR (KLAS, AYRIK KART TASARIMI) ---
  Widget _buildStep1Teams() {
    List<Team> filteredTeams = widget.allTeams.where((t) => t.category == selectedCategory).toList();

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ADIM 2", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text("${selectedCategory?.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFE5A93C))),
        const Text("KARŞILAŞACAK TAKIMLAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        const SizedBox(height: 32),

        // 1. EV SAHİBİ KARTI
        InkWell(
          onTap: () => _openTeamSearchModal("EV SAHİBİ SEÇ", filteredTeams.where((t) => t.id != selectedTeamB?.id).toList(), (t) => setState(() => selectedTeamA = t)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                  child: const Icon(Icons.home, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("EV SAHİBİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(selectedTeamA?.name.toUpperCase() ?? "Takım Seçin...", style: TextStyle(fontWeight: FontWeight.w900, fontSize: selectedTeamA != null ? 18 : 15, color: selectedTeamA != null ? Colors.black : Colors.black38)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54)
              ],
            ),
          ),
        ),

        // ZARİF VS İKONU
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5A93C), width: 2)),
              child: const Text("VS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
            ),
          ),
        ),

        // 2. DEPLASMAN KARTI
        InkWell(
          onTap: () => _openTeamSearchModal("DEPLASMAN SEÇ", filteredTeams.where((t) => t.id != selectedTeamA?.id).toList(), (t) => setState(() => selectedTeamB = t)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blueGrey.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                  child: const Icon(Icons.flight_takeoff, color: Colors.blueGrey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DEPLASMAN", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(selectedTeamB?.name.toUpperCase() ?? "Takım Seçin...", style: TextStyle(fontWeight: FontWeight.w900, fontSize: selectedTeamB != null ? 18 : 15, color: selectedTeamB != null ? Colors.black : Colors.black38)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54)
              ],
            ),
          ),
        ),

        // ZORLUK BARAJI BİLGİSİ
        if (selectedTeamA != null && selectedTeamB != null)
          Container(
            margin: const EdgeInsets.only(top: 24), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade300, width: 2)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                Text("HESAPLANAN ZORLUK BARAJI: ${selectedTeamA!.powerPoint + selectedTeamB!.powerPoint}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.orange.shade900, letterSpacing: 0.5)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep2Location() {
    // Atatürk ve Gümüşler Çıkarıldı
    final List<String> allQuickLocations = ["Vali Recep Yazıcıoğlu", "PAU Arena", "PAU Çadır Salon", "Hasan Güngör"];
    List<String> filteredLocations = allQuickLocations.where((loc) => loc.toLowerCase().contains(_locationSearchQuery)).toList();

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ADIM 3", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text("SALON VE KONUM", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text("Müsabakanın oynanacağı salonu belirleyin veya listeden arayın.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 32),

        const Text("SALON ARA VEYA YAZ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: locationController,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          decoration: _inputDecoration("Örn: Hasan Güngör...", suffixIcon: Icons.location_on),
        ),
        const SizedBox(height: 20),

        filteredLocations.isEmpty
            ? const Padding(padding: EdgeInsets.only(top: 10), child: Text("Farklı bir konum giriyorsunuz...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))
            : Wrap(
          spacing: 10, runSpacing: 10,
          children: filteredLocations.map((loc) => InkWell(
            onTap: () => setState(() => locationController.text = loc),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: locationController.text == loc ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: locationController.text == loc ? const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(2, 2))] : null),
                child: Text(loc, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: locationController.text == loc ? Colors.white : Colors.black))
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3DateTime() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ADIM 4", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text("TARİH VE SAAT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text("Karşılaşmanın oynanacağı zamanı seçin.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_month, size: 32, color: Colors.black54),
                      const SizedBox(height: 12),
                      const Text("TARİH", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(dateController.text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]),
                  child: Column(
                    children: [
                      const Icon(Icons.schedule, size: 32, color: Colors.black54),
                      const SizedBox(height: 12),
                      const Text("SAAT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(timeController.text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildStep4Preview() {
    int totalPower = (selectedTeamA?.powerPoint ?? 0) + (selectedTeamB?.powerPoint ?? 0);
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SON ADIM", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text("CANLI ÖNİZLEME", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text("Lütfen oluşturduğunuz maç kartını kontrol edin.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 32),

        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFFE082), borderRadius: BorderRadius.vertical(top: Radius.circular(13)), border: Border(bottom: BorderSide(color: Colors.black, width: 3))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text(selectedCategory?.toUpperCase() ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange.shade900, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(6)), child: const Text("BEKLEMEDE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: const BoxDecoration(color: Color(0xFFFFF9E6), border: Border(bottom: BorderSide(color: Colors.black, width: 3))),
                child: Row(
                  children: [
                    Expanded(child: Text(selectedTeamA?.name.toUpperCase() ?? "", textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black))),
                    Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5A93C), width: 2)), child: const Text("VS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white))),
                    Expanded(child: Text(selectedTeamB?.name.toUpperCase() ?? "", textAlign: TextAlign.left, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    _buildInfoChip(Icons.calendar_month, dateController.text, bgColor: const Color(0xFFE3F2FD), textColor: Colors.black87),
                    _buildInfoChip(Icons.schedule, timeController.text, bgColor: const Color(0xFFF3E5F5), textColor: Colors.black87),
                    _buildInfoChip(Icons.location_on, locationController.text, bgColor: const Color(0xFFE0F7FA), textColor: Colors.black87),
                    _buildInfoChip(Icons.shield, "BARAJ: $totalPower", bgColor: const Color(0xFFFFEBEE), textColor: Colors.red.shade900),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(color: Color(0xFFF4F6F8), borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: Colors.black, width: 4))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TBF SİSTEMİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black54, letterSpacing: 1)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black, size: 28))
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildStepIndicator(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation), child: child));
                  },
                  child: () {
                    switch (_currentStep) {
                      case 0: return _buildStep0Category();
                      case 1: return _buildStep1Teams();
                      case 2: return _buildStep2Location();
                      case 3: return _buildStep3DateTime();
                      case 4: return _buildStep4Preview();
                      default: return const SizedBox.shrink();
                    }
                  }(),
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12, width: 1))),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    InkWell(
                      onTap: _prevStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))]),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: InkWell(
                      onTap: _nextStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(color: _currentStep == 4 ? const Color(0xFF2A9D8F) : Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: [BoxShadow(color: _currentStep == 4 ? Colors.black : const Color(0xFFE5A93C), offset: const Offset(4, 4))]),
                        child: Center(
                            child: Text(_currentStep == 4 ? "ONAYLA VE FİKSTÜRE EKLE" : "İLERLE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1))
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}