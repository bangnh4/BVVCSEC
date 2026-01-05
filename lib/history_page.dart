// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final String databaseUrl = 'https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app';
  String _searchQuery = "";
  String _filterStatus = "Tất cả";

  // --- HÀM MỞ BẢN ĐỒ ---
  Future<void> _openMap(double lat, double lng) async {
    // Sửa lại URL Google Maps chính xác
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri url = Uri.parse(googleMapsUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Không thể mở bản đồ");
    }
  }

  // --- XỬ LÝ DỮ LIỆU ---
  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  List<double> _parseGps(dynamic gpsString) {
    if (gpsString == null || gpsString.toString().isEmpty) return [0.0, 0.0];
    try {
      List<String> parts = gpsString.toString().split(',');
      if (parts.length == 2) {
        return [double.parse(parts[0].trim()), double.parse(parts[1].trim())];
      }
    } catch (e) { debugPrint("Lỗi GPS: $e"); }
    return [0.0, 0.0];
  }

  double _calculateDistance(dynamic item) {
    if (item['distance'] != null) return _toDouble(item['distance']);
    List<double> currentGps = _parseGps(item['gpsVerify']);
    List<double> targetGps = _parseGps(item['targetGps']); 

    if (currentGps[0] == 0 || targetGps[0] == 0) return 0.0;

    return Geolocator.distanceBetween(
      currentGps[0], currentGps[1], 
      targetGps[0], targetGps[1]
    );
  }

  String _getShiftCode(int ts) {
    if (ts == 0) return "N/A";
    int hour = DateTime.fromMillisecondsSinceEpoch(ts).hour;
    if (hour >= 6 && hour < 14) return "Ca S1";
    if (hour >= 14 && hour < 22) return "Ca S2";
    return "Ca S3";
  }

  @override
  Widget build(BuildContext context) {
    // CHÚ Ý: Đã bỏ Scaffold và BottomNavigationBar ở đây để chạy trong MainWrapper
    return Column(
      children: [
        _buildFilterHeader(),
        Expanded(child: _buildDataStream()),
        const SizedBox(height: 100), // Khoảng trống cho Bottom Bar của MainWrapper
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 60, 15, 15), // Tăng Padding Top để làm Header
      decoration: const BoxDecoration(
        color: Color(0xFF1a2a6c),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text("LỊCH SỬ TUẦN TRA", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Tìm nhân viên, vị trí...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["Tất cả", "Cảnh báo", "Ca S1", "Ca S2", "Ca S3"].map((s) {
                bool isSelected = _filterStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _filterStatus = s),
                    selectedColor: Colors.orangeAccent,
                    backgroundColor: const Color.fromARGB(249, 26, 1, 250).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : const Color.fromARGB(249, 26, 1, 250), 
                      fontSize: 12
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  // ... Các hàm _buildDataStream, _buildCard, _infoTile giữ nguyên như cũ ...
  Widget _buildDataStream() {
    return StreamBuilder(
      stream: FirebaseDatabase.instanceFor(databaseURL: databaseUrl, app: Firebase.app())
          .ref().child('scan_history').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Không có dữ liệu"));

        final rawData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
        List<dynamic> items = rawData.values.toList();

        items = items.where((item) {
          final name = (item['displayName'] ?? "").toString().toLowerCase();
          final loc = (item['location'] ?? "").toString().toLowerCase();
          final res = (item['checkResult'] ?? "").toString();
          final shift = _getShiftCode(item['timestamp'] ?? 0);

          bool matchesSearch = name.contains(_searchQuery) || loc.contains(_searchQuery);
          bool matchesFilter = true;
          if (_filterStatus == "Cảnh báo") {
            matchesFilter = (res != "Bình thường");
          // ignore: curly_braces_in_flow_control_structures
          } else if (_filterStatus.startsWith("Ca")) matchesFilter = (shift == _filterStatus);

          return matchesSearch && matchesFilter;
        }).toList();

        items.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildCard(items[index]),
        );
      },
    );
  }

  Widget _buildCard(dynamic item) {
    List<double> gps = _parseGps(item['gpsVerify']);
    double distance = _calculateDistance(item); 
    bool isWarning = distance > 50; 
    String shift = _getShiftCode(item['timestamp'] ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: isWarning ? Colors.red[50] : Colors.green[50],
              child: Icon(isWarning ? Icons.report_problem : Icons.verified, 
                  color: isWarning ? Colors.red : Colors.green),
            ),
            title: Text(item['location'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item['displayName']} - $shift"),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile(Icons.map_rounded, "Xem bản đồ", "${gps[0].toStringAsFixed(4)}, ${gps[1].toStringAsFixed(4)}", 
                onTap: () => _openMap(gps[0], gps[1])),
              _infoTile(Icons.straighten, "Sai lệch", "${distance.toStringAsFixed(1)}m", 
                color: isWarning ? Colors.red : Colors.black),
              _infoTile(Icons.history, "Thời gian", 
                DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? 0))),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {VoidCallback? onTap, Color color = Colors.black}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 16, color: onTap != null ? Colors.blue : Colors.grey),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onTap != null ? Colors.blue : color)),
        ],
      ),
    );
  }
}