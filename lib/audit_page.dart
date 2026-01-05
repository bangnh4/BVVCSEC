import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AuditPage extends StatelessWidget {
  // 1. Khai báo biến onBack đúng cách
  final VoidCallback onBack;

  // 2. Cập nhật Constructor để gán giá trị vào biến
  const AuditPage({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final databaseRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref().child('audit_logs');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        // 3. Thêm nút quay lại để gọi hàm onBack
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: onBack, 
        ),
        title: const Text("BÁO CÁO NHẬT KÝ HỆ THỐNG", 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1a2a6c),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: databaseRef.orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          List<Map<dynamic, dynamic>> auditItems = [];
          if (snapshot.data?.snapshot.value != null) {
            Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map;
            values.forEach((key, value) {
              auditItems.add(Map<dynamic, dynamic>.from(value));
            });
            auditItems.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
          }

          if (auditItems.isEmpty) return const Center(child: Text("Không có nhật ký hoạt động"));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: auditItems.length,
            itemBuilder: (context, index) => _buildAuditCard(auditItems[index]),
          );
        },
      ),
    );
  }

  Widget _buildAuditCard(Map<dynamic, dynamic> item) {
    String action = item['action'] ?? "UNKNOWN";
    Color actionColor = action.contains("TẠO") ? Colors.green : (action.contains("XÓA") ? Colors.red : Colors.blue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: actionColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.history_edu, color: actionColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(action, style: TextStyle(fontWeight: FontWeight.bold, color: actionColor, fontSize: 13)),
                    Text(_formatTimestamp(item['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 5),
                Text("Nội dung: ${item['detail'] ?? 'N/A'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text("Thực hiện bởi: ${item['admin'] ?? 'Hệ thống'}", 
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return "N/A";
    var date = DateTime.fromMillisecondsSinceEpoch(ts as int);
    return DateFormat('HH:mm - dd/MM/yyyy').format(date);
  }
}