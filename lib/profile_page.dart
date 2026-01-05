import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onNavigateToAudit;
  final VoidCallback onNavigateToReport;
  final VoidCallback onNavigateToCreateQR;
  final VoidCallback onNavigateToHR;

  const ProfilePage({
    super.key,
    required this.onNavigateToAudit,
    required this.onNavigateToReport,
    required this.onNavigateToCreateQR,
    required this.onNavigateToHR,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String displayName = "Đang tải...";
  String workLocation = "Đang tải...";
  int level = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final ref = FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app,
        databaseURL: 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app'
      ).ref();
      
      final snap = await ref.child('users').child(user!.uid).get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        setState(() {
          displayName = data['displayName']?.toString() ?? "Nhân viên";
          workLocation = data['workLocation']?.toString() ?? "Khu vực";
          level = int.tryParse(data['level']?.toString() ?? "1") ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Padding đáy để tránh bị NavBar che
              children: [
                _sectionTitle("THÔNG TIN CÁ NHÂN"),
                _buildInfoTile(Icons.location_on, "Khu vực làm việc", workLocation),
                _buildInfoTile(Icons.email, "Email tài khoản", user?.email ?? "N/A"),
                
                const SizedBox(height: 25),
                _sectionTitle("QUẢN TRỊ HỆ THỐNG"),
                
                if (level >= 3) ...[
                  _buildActionTile(
                    Icons.badge, 
                    "Quản lý nhân sự (HR)", 
                    "Xem danh sách nhân sự tại $workLocation", 
                    onTap: widget.onNavigateToHR, // GỌI CALLBACK ĐỂ CHUYỂN TAB 7
                  ),
                  _buildActionTile(
                    Icons.qr_code_2, 
                    "Tạo mã QR Trạm", 
                    "Thiết lập điểm tuần tra mới", 
                    onTap: widget.onNavigateToCreateQR,
                  ),
                  _buildActionTile(
                    Icons.mark_email_read, 
                    "Xuất báo cáo Email", 
                    "Gửi dữ liệu báo cáo về hòm thư", 
                    onTap: widget.onNavigateToReport,
                  ),
                  _buildActionTile(
                    Icons.analytics, 
                    "Audit Hệ thống", 
                    "Kiểm tra sai lệch GPS & Thời gian", 
                    onTap: widget.onNavigateToAudit,
                  ),
                ],
                
                const SizedBox(height: 20),
                _buildActionTile(
                  Icons.logout, 
                  "Đăng xuất", 
                  "Thoát khỏi hệ thống VFHPSEC", 
                  isRed: true, 
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets con giữ nguyên logic cũ của bạn ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1a2a6c),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 40, color: Colors.white)),
          const SizedBox(height: 12),
          Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text("Cấp độ: $level", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 10),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _buildInfoTile(IconData icon, String label, String value) => Card(
    elevation: 0, margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF1a2a6c)),
      title: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ),
  );

  Widget _buildActionTile(IconData icon, String title, String sub, {bool isRed = false, VoidCallback? onTap}) => Card(
    elevation: 0, margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isRed ? Colors.red : Colors.orange),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black87)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    ),
  );
}