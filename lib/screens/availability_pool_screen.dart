import 'package:flutter/material.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../services/firestore_service.dart';

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Uygunluk Havuzu", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade50,
      ),
      body: StreamBuilder<List<Referee>>(
          stream: _firestoreService.getRefereesStream(),
          builder: (context, refSnap) {
            return StreamBuilder<List<Availability>>(
                stream: _firestoreService.getAvailabilitiesStream(),
                builder: (context, availSnap) {
                  if (refSnap.connectionState == ConnectionState.waiting || availSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final referees = refSnap.data ?? [];
                  final availabilities = availSnap.data ?? [];

                  if (availabilities.isEmpty) {
                    return const Center(child: Text("Henüz uygunluk bildirimi yok."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availabilities.length,
                    itemBuilder: (context, index) {
                      final avail = availabilities[index];
                      // ID'ye sahip hakem silindiyse veya bulunamıyorsa default nesne ile engelleme
                      final referee = referees.firstWhere(
                              (r) => r.id == avail.refereeId,
                          orElse: () => Referee(id: "", name: "Bilinmeyen Hakem", email: "", role: RefereeRole.aday, level: 0)
                      );

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(referee.name.isNotEmpty ? referee.name[0].toUpperCase() : '?', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(referee.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text("Tarih: ${avail.date}"),
                          trailing: Wrap(
                            spacing: 4,
                            children: avail.availableTimes.map((time) => Chip(
                              label: Text(time, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.blueGrey.shade50,
                              side: BorderSide.none,
                            )).toList(),
                          ),
                        ),
                      );
                    },
                  );
                }
            );
          }
      ),
    );
  }
}