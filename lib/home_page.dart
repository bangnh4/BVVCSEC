import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  Map<dynamic, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFullUserProfile();
  }

  Future<void> _loadFullUserProfile() async {
    if (user != null) {
      try {
        final database = FirebaseDatabase.instanceFor(
          app: FirebaseAuth.instance.app,
          databaseURL: 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app',
        );
        
        DataSnapshot snapshot = await database.ref().child('users').child(user!.uid).get();
        if (snapshot.exists) {
          setState(() {
            userData = snapshot.value as Map;
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() => isLoading = false);
      }
    }
  }

  // --- LOGIC 1: Quy đổi từ Level sang Chức vụ ---
  String _mapLevelToRole(dynamic level) {
    String lv = level?.toString() ?? "";
    switch (lv) {
      case '1': return "Nhân viên Tuần tra";
      case '2': return "Tổ Trưởng Bảo vệ";
      case '3': return "Đội Trưởng Bảo vệ";
      case '4': return "Trưởng Phòng Bảo vệ";
      case '5': return "Quản trị viên Hệ thống";
      default: return "Chưa xác định";
    }
  }

  // --- LOGIC 2: Lấy phần trước @ của email làm Mã nhân viên ---
  String _getEmployeeCode(String? email) {
    if (email == null || !email.contains('@')) return "N/A";
    return email.split('@')[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    String employeeCode = _getEmployeeCode(user?.email);
    String userLevel = userData?['level']?.toString() ?? "N/A";
    String jobTitle = _mapLevelToRole(userLevel);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: const Text("HỒ SƠ NHÂN VIÊN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1a2a6c),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildTopHeader(jobTitle, userLevel),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoTile("Họ và tên", userData?['displayName'] ?? "Chưa cập nhật", Icons.person),
                      _buildInfoTile("Mã nhân viên", employeeCode, Icons.badge),
                      _buildInfoTile("Chức vụ thực tế", jobTitle, Icons.work),
                      _buildInfoTile("Cấp bậc hệ thống", "Level $userLevel", Icons.trending_up),
                      _buildInfoTile("Email công việc", user?.email ?? "N/A", Icons.alternate_email),
                      _buildInfoTile("Dự án", "BVVC - APP", Icons.assignment_turned_in),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTopHeader(String title, String level) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1a2a6c),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: Text(
              (userData?['displayName'] ?? "U")[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            userData?['displayName'] ?? "Người dùng",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Chip hiển thị Chức vụ thay vì chỉ hiện Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(color: Color(0xFF1a2a6c), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1a2a6c), size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}