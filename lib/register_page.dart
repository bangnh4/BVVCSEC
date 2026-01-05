import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  
  // Khởi tạo giá trị mặc định trùng với mục đầu tiên trong danh sách
  String _selectedArea = 'Phòng BV OceanPark 1'; 
  bool _isLoading = false;

  // Danh sách đầy đủ các vị trí làm việc của VFHPSEC
  final List<String> _locations = [
    'Phòng BV OceanPark 1', 'Phòng BV OceanPark 2', 'Phòng BV OceanPark 3',
    'Phòng BV Smart City', 'Phòng BV Times City', 'Phòng BV Royalcity',
    'Phòng BV Metropolis', 'Tổ BV Bà Triệu - NCT', 'Phòng BV VRH',
    'Phòng BV Greenbay', 'Đội BV WestPoint', 'Phòng BV VFHP',
    'Phòng BV VFHT', 'Phòng BV Royal Island', 'Phòng BV Imepria',
    'Đội BV Marina', 'Đội BV Thăng Long', 'Phòng BV Gadenia', 
    'Đội BV Skylake', 'Đội BV Dcapitale'
  ];

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
      _showError("Vui lòng điền đầy đủ các trường");
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('users').child(userCred.user!.uid).set({
        'displayName': _nameController.text.trim(),
        'workLocation': _selectedArea,
        'email': _emailController.text.trim(),
        'level': 1,      // Đã gán Level 1 mặc định
        'isActive': true, 
        'role': 'user',
        'createdAt': ServerValue.timestamp, 
      });

      if (!mounted) return;
      _showSuccess("Đăng ký thành công!");
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a2a6c), Color(0xFF2193b0)], 
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
            child: Column(
              children: [
                Image.asset('assets/logo1.png', height: 90),
                const SizedBox(height: 15),
                const Text('ĐĂNG KÝ NHÂN SỰ', 
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)]
                  ),
                  child: Column(
                    children: [
                      _buildInput(_nameController, 'Họ và tên', Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildInput(_emailController, 'Email', Icons.email_outlined),
                      const SizedBox(height: 15),
                      _buildInput(_passController, 'Mật khẩu', Icons.lock_outline, isPass: true),
                      const SizedBox(height: 20),

                      // Dropdown Vị trí làm việc
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(" Vị trí làm việc", 
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1a2a6c))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedArea,
                                menuMaxHeight: 350, // Giới hạn chiều cao menu để không tràn màn hình
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                items: _locations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) => setState(() => _selectedArea = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a2a6c),
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _register,
                            child: const Text('TẠO TÀI KHOẢN', 
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1a2a6c)),
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade100,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1a2a6c), width: 2),
        ),
      ),
    );
  }
}