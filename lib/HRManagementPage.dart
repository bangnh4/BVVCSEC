import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class HRManagementPage extends StatefulWidget {
  final VoidCallback onBack;

  const HRManagementPage({
    super.key, 
    required this.onBack, required String managerWorkLocation,
  });

  @override
  State<HRManagementPage> createState() => _HRManagementPageState();
}

class _HRManagementPageState extends State<HRManagementPage> {
  final String dbUrl = 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app';
  final String? myUid = FirebaseAuth.instance.currentUser?.uid;
  
  int myLevel = 0; 
  String myWorkLocation = ""; // Trang sẽ tự lấy dữ liệu này
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyProfileAndData();
  }

  // Tự lấy Profile của mình để biết Level và Vị trí chính xác
  Future<void> _fetchMyProfileAndData() async {
    if (myUid == null) return;
    try {
      final snap = await _getRef().child('users').child(myUid!).get();
      if (snap.exists && mounted) {
        setState(() {
          myLevel = int.tryParse(snap.child('level').value.toString()) ?? 1;
          myWorkLocation = (snap.child('workLocation').value ?? "").toString().trim();
          _isInitialLoading = false;
        });
        debugPrint("XÁC THỰC THÀNH CÔNG: Level $myLevel tại $myWorkLocation");
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo: $e");
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  DatabaseReference _getRef() {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(), 
      databaseURL: dbUrl
    ).ref();
  }

  bool _canIModify(int targetLevel, String targetUid) {
    if (targetUid == myUid) return false;
    if (myLevel >= 5) return true;
    return myLevel > targetLevel;
  }

  // --- LOGIC XỬ LÝ DATABASE ---
  Future<void> _updateStatus(String uid, bool currentStatus, int targetLevel) async {
    if (!_canIModify(targetLevel, uid)) {
      _showWarning("Bạn không có quyền thực hiện thao tác này!");
      return;
    }
    await _getRef().child('users').child(uid).update({'isActive': !currentStatus});
  }

  Future<void> _deleteUser(String uid, int targetLevel) async {
    if (!_canIModify(targetLevel, uid)) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa nhân sự?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("XÓA", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _getRef().child('users').child(uid).remove();
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: const Text("QUẢN LÝ NHÂN SỰ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1a2a6c),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: widget.onBack),
        centerTitle: true,
      ),
      body: _isInitialLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : StreamBuilder(
            stream: _getRef().child('users').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text("Dữ liệu trống"));
              }

              final rawData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
              List<Map<String, dynamic>> staffList = [];
              String searchLoc = myWorkLocation.toLowerCase();

              rawData.forEach((key, value) {
                final user = Map<String, dynamic>.from(value as Map);
                user['uid'] = key;

                // LOGIC LỌC ƯU TIÊN:
                if (myLevel >= 5) {
                  staffList.add(user); // Admin thấy tất cả
                } else if (myLevel >= 3) {
                  // Level 3, 4 chỉ thấy người cùng vị trí (So sánh nới lỏng)
                  String userLoc = (user['workLocation'] ?? "").toString().trim().toLowerCase();
                  if (userLoc == searchLoc && searchLoc.isNotEmpty) {
                    staffList.add(user);
                  }
                }
              });

              if (staffList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("Không thấy nhân viên nào tại $myWorkLocation"),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: staffList.length,
                itemBuilder: (context, index) => _buildUserCard(staffList[index]),
              );
            },
          ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> staff) {
    bool isActive = staff['isActive'] ?? true;
    int targetLv = int.tryParse(staff['level'].toString()) ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? const Color(0xFF1a2a6c) : Colors.red.shade100,
          child: Text(staff['displayName']?[0].toUpperCase() ?? "U", style: const TextStyle(color: Colors.white)),
        ),
        title: Text(staff['displayName'] ?? "Chưa đặt tên", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Level $targetLv • ${staff['workLocation'] ?? 'N/A'}"),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionIcon(Icons.edit, "Sửa Lv", Colors.blue, () {}), // Tích hợp dialog sửa lv ở đây nếu cần
                _actionIcon(isActive ? Icons.lock : Icons.lock_open, isActive ? "Khóa" : "Mở", Colors.orange, 
                  () => _updateStatus(staff['uid'], isActive, targetLv)),
                _actionIcon(Icons.delete, "Xóa", Colors.red, 
                  () => _deleteUser(staff['uid'], targetLv)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}