import 'package:flutter/material.dart';
import 'admin_panel_screen.dart';
import 'referee_management_screen.dart';
import 'team_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminPanelScreen(),
    const RefereeManagementScreen(),
    const TeamManagementScreen(),
  ];

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 28),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(
          bottom: bottomPadding > 0 ? bottomPadding : 20,
          left: 20,
          right: 20,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF1C1C1C), width: 3),
            boxShadow: const [BoxShadow(color: Color(0xFF1C1C1C), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.sports_basketball_rounded, "ATAMALAR"),
              _buildNavItem(1, Icons.sports, "HAKEMLER"),
              _buildNavItem(2, Icons.shield, "TAKIMLAR"),
            ],
          ),
        ),
      ),
    );
  }
}