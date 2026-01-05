// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'scan_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'audit_page.dart';
import 'report_page.dart';
import 'create_qr_page.dart';
import 'HRManagementPage.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Hàm chuyển tab tập trung
  void changeTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
Widget build(BuildContext context) {
  final List<Widget> pages = [
    const HomePage(),                             // 0
    const ScanPage(),                             // 1
    const HistoryPage(),                          // 2
    ProfilePage(                                  // 3
      onNavigateToAudit: () => changeTab(4),
      onNavigateToReport: () => changeTab(5),
      onNavigateToCreateQR: () => changeTab(6),
      onNavigateToHR: () => changeTab(7),         // <--- Thêm callback mới
    ), 
    AuditPage(onBack: () => changeTab(3)),        // 4
    ReportPage(onBack: () => changeTab(3)),       // 5
    CreateQRPage(onBack: () => changeTab(3)),     // 6
    HRManagementPage(onBack: () => changeTab(3), managerWorkLocation: '',), // 7 <--- Thêm trang HR vào đây
  ];

  return Scaffold(
    extendBody: true,
    body: IndexedStack(index: _currentIndex, children: pages),
    bottomNavigationBar: _buildNavBar(),
  );
}

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1a2a6c).withOpacity(0.15), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navBtn(0, Icons.grid_view_rounded, "Home"),
          _navBtn(1, Icons.qr_code_scanner, "Scan"),
          _navBtn(2, Icons.history, "History"),
          // Force active nếu index >= 3 (Profile hoặc các trang Admin)
          _navBtn(3, Icons.settings, "Setup", forceActive: _currentIndex >= 3),
        ],
      ),
    );
  }

  Widget _navBtn(int index, IconData icon, String label, {bool forceActive = false}) {
    bool isSel = _currentIndex == index || forceActive;
    
    return GestureDetector(
      onTap: () => changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1a2a6c) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isSel ? Colors.white : Colors.grey.shade400, 
              size: 24
            ),
            if (isSel) ...[
              const SizedBox(width: 8),
              Text(
                label, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13
                )
              ),
            ],
          ],
        ),
      ),
    );
  }
}