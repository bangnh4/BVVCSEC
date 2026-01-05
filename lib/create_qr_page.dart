import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:qr_flutter/qr_flutter.dart'; // Thư viện tạo QR

class CreateQRPage extends StatefulWidget {
  final VoidCallback onBack;
  const CreateQRPage({super.key, required this.onBack});

  @override
  State<CreateQRPage> createState() => _CreateQRPageState();
}

class _CreateQRPageState extends State<CreateQRPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isSaving = false;
  String? _generatedQRData; // Dùng để hiển thị QR sau khi tạo thành công

  DatabaseReference get _dbRef => FirebaseDatabase.instanceFor(
        app: Firebase.app(), // Đã sửa lỗi tham số app
        databaseURL: 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

  Future<void> _saveStation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Lỗi: Bạn cần đăng nhập để thực hiện quyền Admin");
      return;
    }

    if (_nameController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập đủ tên trạm và khu vực");
      return;
    }

    setState(() => _isSaving = true);

    try {
      // StationID là dữ liệu sẽ chứa trong mã QR
      String stationId = "ST_${DateTime.now().millisecondsSinceEpoch}";
      String stationName = _nameController.text.trim();
      String workLocation = _locationController.text.trim();

      final Map<String, dynamic> updates = {};
      
      // 1. Tạo dữ liệu trạm
      updates['/stations/$stationId'] = {
        "stationId": stationId,
        "stationName": stationName,
        "location": workLocation,
        "createdAt": ServerValue.timestamp,
        "createdBy": user.email ?? "Unknown Admin",
      };

      // 2. Ghi nhật ký hệ thống
      String logId = _dbRef.child('audit_logs').push().key ?? stationId;
      updates['/audit_logs/$logId'] = {
        "action": "TẠO TRẠM MỚI",
        "detail": "Đã thêm trạm: $stationName tại $workLocation",
        "admin": user.email ?? "Admin",
        "timestamp": ServerValue.timestamp,
      };

      await _dbRef.update(updates);

      setState(() {
        _generatedQRData = stationId; // Lưu ID để hiển thị QR
      });

      _showSnackBar("Đã tạo trạm thành công!");
    } catch (e) {
      _showSnackBar("Lỗi hệ thống: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: widget.onBack,
        ),
        title: const Text("TẠO MÃ QR TRẠM", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1a2a6c),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            if (_generatedQRData == null) ...[
              const Text("Nhập thông tin trạm tuần tra mới", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              _buildInputCard(controller: _nameController, label: "Tên Trạm (VD: Trạm Gửi Xe A)", icon: Icons.business),
              const SizedBox(height: 15),
              _buildInputCard(controller: _locationController, label: "Khu vực / Tòa nhà", icon: Icons.location_on),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveStation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a2a6c),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("TẠO VÀ LƯU TRẠM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              // GIAO DIỆN HIỂN THỊ MÃ QR SAU KHI TẠO
              _buildQRResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRResultSection() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 10),
        const Text("MÃ QR ĐÃ ĐƯỢC TẠO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(
            children: [
              QrImageView(
                data: _generatedQRData!,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 10),
              Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("ID: $_generatedQRData", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _generatedQRData = null;
              _nameController.clear();
              _locationController.clear();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text("Tạo thêm trạm khác"),
        )
      ],
    );
  }

  Widget _buildInputCard({required TextEditingController controller, required String label, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF1a2a6c), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}