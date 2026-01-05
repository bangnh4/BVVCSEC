import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; // Thêm import này
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:universal_html/html.dart' as html;

class ReportPage extends StatefulWidget {
  final VoidCallback onBack;
  const ReportPage({super.key, required this.onBack});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime selectedDate = DateTime.now();
  String selectedShift = "Cả ngày";
  bool isExporting = false;

  final List<String> shifts = [
    "Cả ngày",
    "Ca 1 (06:00 - 14:00)",
    "Ca 2 (14:00 - 22:00)",
    "Ca 3 (22:00 - 06:00)"
  ];

  // Logic kiểm tra ca (Giữ nguyên của bạn)
  bool _isInShift(DateTime scanTime, String shift, DateTime selectedDay) {
    String scanDayStr = DateFormat('yyyy-MM-dd').format(scanTime);
    String selectedDayStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    if (shift == "Cả ngày") return scanDayStr == selectedDayStr;
    int hour = scanTime.hour;
    if (shift.contains("Ca 1")) return scanDayStr == selectedDayStr && hour >= 6 && hour < 14;
    if (shift.contains("Ca 2")) return scanDayStr == selectedDayStr && hour >= 14 && hour < 22;
    if (shift.contains("Ca 3")) {
      bool isNightToday = (hour >= 22) && (scanDayStr == selectedDayStr);
      DateTime nextDay = selectedDay.add(const Duration(days: 1));
      bool isMorningNextDay = (hour < 6) && (scanDayStr == DateFormat('yyyy-MM-dd').format(nextDay));
      return isNightToday || isMorningNextDay;
    }
    return false;
  }

  Future<void> handleExport() async {
    setState(() => isExporting = true);
    try {
      // FIX LỖI: Thêm app: Firebase.app()
      final ref = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref().child('scan_history');

      final snapshot = await ref.get();
      if (!snapshot.exists) throw "Không có dữ liệu lịch sử";

      List<List<dynamic>> rows = [
        ["BÁO CÁO TUẦN TRA AN NINH - VFHPSEC"],
        ["Ngày xuất:", DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())],
        ["Ca làm việc:", selectedShift],
        [""],
        ["STT", "NGÀY QUÉT", "GIỜ QUÉT", "TÊN TRẠM", "NHÂN VIÊN", "KHU VỰC", "VỊ TRÍ (LAT, LNG)"]
      ];

      Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      var sortedEntries = data.entries.toList()
        ..sort((a, b) => (b.value['timestamp'] as int).compareTo(a.value['timestamp'] as int));

      int count = 1;
      for (var entry in sortedEntries) {
        var v = entry.value;
        DateTime time = DateTime.fromMillisecondsSinceEpoch(v['timestamp'] ?? 0);
        
        if (_isInShift(time, selectedShift, selectedDate)) {
          String station = v['location'] ?? "N/A";
          String staff = v['displayName'] ?? "N/A";
          String gps = v['gpsVerify'] ?? "0,0";
          
          rows.add([
            count++,
            DateFormat('dd/MM/yyyy').format(time),
            DateFormat('HH:mm:ss').format(time),
            station,
            staff,
            station,
            gps
          ]);
        }
      }

      if (rows.length <= 5) throw "Không tìm thấy lượt quét nào phù hợp";

      String csvData = const ListToCsvConverter().convert(rows);
      String fileName = "BAO_CAO_VFHPSEC_${DateFormat('ddMMyy').format(selectedDate)}.csv";

      if (kIsWeb) {
        final bytes = utf8.encode('\uFEFF$csvData');
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getTemporaryDirectory();
        final file = File("${directory.path}/$fileName");
        await file.writeAsString('\uFEFF$csvData');

        final Email email = Email(
          body: 'Báo cáo tuần tra VFHPSEC ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}.',
          subject: '[VFHPSEC] BÁO CÁO - ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
          attachmentPaths: [file.path],
          isHTML: false,
        );
        await FlutterEmailSender.send(email);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: widget.onBack),
        title: const Text("XUẤT BÁO CÁO", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1a2a6c),
        centerTitle: true,
      ),
      body: SafeArea( // Dùng SafeArea để bảo vệ layout
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Khối chọn thông số
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                ),
                child: Column(
                  children: [
                    _buildSelector(
                      icon: Icons.calendar_month,
                      label: "Ngày báo cáo",
                      value: DateFormat('dd/MM/yyyy').format(selectedDate),
                      onTap: () async {
                        final p = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2025), lastDate: DateTime.now());
                        if (p != null) setState(() => selectedDate = p);
                      },
                    ),
                    const Divider(height: 30),
                    _buildSelector(
                      icon: Icons.access_time_filled, 
                      label: "Chọn ca làm việc", 
                      value: selectedShift, 
                      isDropdown: true
                    ),
                  ],
                ),
              ),
              
              // Image minh họa cho quy trình báo cáo
              const SizedBox(height: 30),
              const Icon(Icons.description_outlined, size: 80, color: Colors.black12),
              const Text("Dữ liệu sẽ được trích xuất thành file CSV\nTương thích với Excel và Google Sheets", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              
              const Spacer(), // Đẩy nút xuống dưới cùng

              // Khối nút bấm
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isExporting ? null : handleExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a2a6c), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: isExporting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(kIsWeb ? "TẢI FILE BÁO CÁO" : "GỬI BÁO CÁO QUA EMAIL", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 30), // Padding đáy
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelector({required IconData icon, required String label, required String value, VoidCallback? onTap, bool isDropdown = false}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF1a2a6c).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF1a2a6c), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                if (!isDropdown) Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (isDropdown) DropdownButton<String>(
                  value: selectedShift,
                  isDense: true,
                  isExpanded: true,
                  underline: Container(),
                  items: shifts.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))).toList(),
                  onChanged: (v) => setState(() => selectedShift = v!),
                )
              ],
            ),
          ),
          if (!isDropdown) const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}