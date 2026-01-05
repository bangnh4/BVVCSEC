import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController cameraController = MobileScannerController();
  final String dbUrl = 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app';
  
  bool _isLocked = false; // Ngăn quét trùng lặp
  bool _isLoading = false;

  // --- 1. TÍNH KHOẢNG CÁCH (Chuẩn xác như Android) ---
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // --- 2. XÁC ĐỊNH CA TRỰC ---
  String _getCurrentShift() {
    int hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return "CA S1";
    if (hour >= 14 && hour < 22) return "CA S2";
    return "CA S3";
  }

  // --- 3. XỬ LÝ QUÉT VÀ TRUY VẤN DỮ LIỆU ---
  Future<void> _processResult(String rawData) async {
    if (_isLocked) return;
    setState(() {
      _isLocked = true;
      _isLoading = true;
    });
    
    await cameraController.stop();

    try {
      // Giải mã JSON để lấy qrId (theo chuẩn Android)
      Map<String, dynamic> qrData = jsonDecode(rawData);
      String qId = qrData['qrId'] ?? "";
      if (qId.isEmpty) throw "Mã QR thiếu ID trạm";

      // Lấy GPS thực tế với độ chính xác cao nhất (PRIORITY_HIGH_ACCURACY)
      Position userPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 5),
      );

      // Truy vấn Firebase qr_configs
      final database = FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app, 
        databaseURL: dbUrl
      );
      
      DataSnapshot snap = await database.ref().child('qr_configs').child(qId).get();

      if (!snap.exists) {
        throw "Mã trạm không tồn tại trên hệ thống";
      }

      final config = Map<dynamic, dynamic>.from(snap.value as Map);
      
      // Ép kiểu tọa độ từ Firebase
      double sLat = double.tryParse(config['lat'].toString()) ?? 0.0;
      double sLon = double.tryParse(config['lon'].toString()) ?? 0.0;
      String locationName = config['locationName'] ?? "N/A";

      // Tính khoảng cách
      double dist = _calculateDistance(userPos.latitude, userPos.longitude, sLat, sLon);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showConfirmDialog(locationName, userPos, dist);

    } catch (e) {
      _showError("Lỗi: $e");
      _resetScanner();
    }
  }

  // --- 4. LƯU BÁO CÁO (Khớp 100% HistoryPage) ---
  Future<void> _uploadData(String loc, Position pos, double dist) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final database = FirebaseDatabase.instanceFor(
        app: FirebaseAuth.instance.app, 
        databaseURL: dbUrl
      );
      
      // Lấy displayName từ profile hoặc node users
      DataSnapshot userSnap = await database.ref().child('users').child(user.uid).get();
      String dName = user.displayName ?? "Cán bộ";
      if (userSnap.exists) {
        final uData = Map<dynamic, dynamic>.from(userSnap.value as Map);
        dName = uData['displayName'] ?? dName;
      }

      await database.ref().child('scan_history').push().set({
        "uid": user.uid,
        "displayName": dName,
        "location": loc, // Tên trạm xuất hiện trong báo cáo
        "gpsVerify": "${pos.latitude}, ${pos.longitude}",
        "distance_error": dist.toInt(),
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "shift": _getCurrentShift(),
        "checkResult": dist > 100 ? "Bất thường" : "Bình thường",
        "project": "VFHPSEC",
        "workLocation": "iOS/Web App"
      });

      if (!mounted) return;
      Navigator.pop(context); // Đóng Dialog
      _showSuccess("Đã lưu báo cáo tuần tra!");
      _resetScanner();
    } catch (e) {
      _showError("Không thể lưu dữ liệu");
      _resetScanner();
    }
  }

  void _resetScanner() {
    if (mounted) {
      setState(() {
        _isLocked = false;
        _isLoading = false;
      });
      cameraController.start();
    }
  }

  // --- GIAO DIỆN DIALOG ---
  void _showConfirmDialog(String name, Position pos, double dist) {
    bool isTooFar = dist > 100;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(name, style: const TextStyle(color: Color(0xFF1a2a6c), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isTooFar ? Icons.warning : Icons.check_circle, color: isTooFar ? Colors.red : Colors.green),
                const SizedBox(width: 10),
                Text("Cách trạm: ${dist.toInt()}m"),
              ],
            ),
            const SizedBox(height: 10),
            Text(isTooFar ? "Cảnh báo: Bạn đang đứng quá xa vị trí quy định!" : "Vị trí hợp lệ. Bạn có muốn gửi báo cáo không?"),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _resetScanner(); }, child: const Text("HỦY")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a2a6c)),
            onPressed: () => _uploadData(name, pos, dist),
            child: const Text("XÁC NHẬN GỬI", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("QUÉT MÃ VFHPSEC", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a2a6c),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null && !_isLocked) {
                _processResult(barcode.rawValue!);
              }
            },
          ),
          // Khung nhắm QR
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        ],
      ),
    );
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _showSuccess(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));
}