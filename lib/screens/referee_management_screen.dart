import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/referee.dart';
import '../models/availability.dart';
import '../services/firestore_service.dart';
import '../widgets/referee_dashboard_tab.dart';
import '../widgets/referee_list_tab.dart';
import '../widgets/referee_pending_tab.dart';

class RefereeManagementScreen extends StatefulWidget {
  const RefereeManagementScreen({super.key});

  @override
  State<RefereeManagementScreen> createState() => _RefereeManagementScreenState();
}

class _RefereeManagementScreenState extends State<RefereeManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Color _bgColor = const Color(0xFFF4F6F8);

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
                      if (!matchSnap.hasData || !refSnap.hasData || !availSnap.hasData) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
                      }

                      final matches = matchSnap.data!;
                      final referees = refSnap.data!;
                      final availabilities = availSnap.data!;

                      Set<String> dates = availabilities.map((a) => a.date).toSet();
                      List<String> sortedDates = dates.toList()..sort();
                      List<String> upcomingDates = sortedDates.where((d) => !_isPastDate(d)).toList();

                      return DefaultTabController(
                        length: 3,
                        child: Scaffold(
                          backgroundColor: _bgColor,
                          body: SafeArea(
                            bottom: false,
                            child: NestedScrollView(
                              headerSliverBuilder: (context, innerBoxIsScrolled) {
                                return [
                                  SliverAppBar(
                                    backgroundColor: _bgColor, elevation: 0, floating: true, snap: true, toolbarHeight: 70, titleSpacing: 20,
                                    title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("HAKEM YÖNETİMİ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5, color: Colors.black)), Text("Kadro, Onaylar ve Aktiflik", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black54))]),
                                    bottom: PreferredSize(
                                      preferredSize: const Size.fromHeight(60),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))]),
                                        child: TabBar(
                                          isScrollable: true,
                                          tabAlignment: TabAlignment.start,
                                          labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                                          indicator: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black, width: 2)), indicatorSize: TabBarIndicatorSize.tab, labelColor: Colors.white, unselectedLabelColor: Colors.black, labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                                          tabs: const [Tab(text: "HAFTALIK ÖZET"), Tab(text: "HAKEM KADROSU"), Tab(text: "YENİ KAYITLAR")],
                                        ),
                                      ),
                                    ),
                                  )
                                ];
                              },
                              body: TabBarView(
                                children: [
                                  RefereeDashboardTab(referees: referees, availabilities: availabilities, matches: matches, upcomingDates: upcomingDates),
                                  RefereeListTab(referees: referees, availabilities: availabilities, matches: matches),
                                  RefereePendingTab(referees: referees),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                );
              }
          );
        }
    );
  }
}