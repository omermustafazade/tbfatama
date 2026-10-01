import 'package:flutter/material.dart';
import 'admin_panel_screen.dart';
import 'management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminPanelScreen(),
    const ManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // Özel tasarımlı alt bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFF1C1C1C), width: 2.5)), // Katı üst çizgi
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Colors.orange.shade800,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 6, top: 4), child: Icon(Icons.sports_basketball_outlined, size: 26)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 6, top: 4), child: Icon(Icons.sports_basketball, size: 28)),
              label: "ATAMALAR",
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 6, top: 4), child: Icon(Icons.analytics_outlined, size: 26)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 6, top: 4), child: Icon(Icons.analytics, size: 28)),
              label: "YÖNETİM",
            ),
          ],
        ),
      ),
    );
  }
}