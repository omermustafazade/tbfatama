import 'package:flutter/material.dart';

class AdminSummaryPanel extends StatelessWidget {
  final int activeMatchesCount;
  final int pendingCount;
  final VoidCallback onAutoAssign;

  const AdminSummaryPanel({
    super.key,
    required this.activeMatchesCount,
    required this.pendingCount,
    required this.onAutoAssign,
  });

  @override
  Widget build(BuildContext context) {
    bool isComplete = pendingCount == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // Bembeyaz, ferah arkaplan
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                    child: const Text("HAFTANIN ÖZETİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Text("$activeMatchesCount AKTİF MAÇ", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isComplete ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), // Başarılıysa yeşil, eksikse kırmızımsı
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isComplete ? Colors.green.shade800 : Colors.red.shade800, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                ),
                child: Column(
                  children: [
                    Text(pendingCount.toString(), style: TextStyle(color: isComplete ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.w900, fontSize: 22)),
                    const SizedBox(height: 2),
                    Text("BEKLEYEN", style: TextStyle(color: isComplete ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.black12, thickness: 2, height: 1),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("YAPAY ZEKA ASİSTANI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(isComplete ? "TÜM ATAMALAR KUSURSUZ" : "EKSİK ATAMALAR VAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isComplete ? Colors.green.shade700 : Colors.red.shade700)),
                  ],
                ),
              ),
              if (!isComplete)
                InkWell(
                  onTap: onAutoAssign,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Color(0xFFE5A93C), offset: Offset(3, 3))],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFFE5A93C), size: 16),
                        SizedBox(width: 8),
                        Text("OTOMATİK ATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.green.shade700, width: 2)),
                  child: Icon(Icons.check, color: Colors.green.shade700, size: 24),
                ),
            ],
          )
        ],
      ),
    );
  }
}