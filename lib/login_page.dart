import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart'; // Thêm thư viện

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRememberMe = false; // Trạng thái checkbox

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Tải email đã lưu nếu có
  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email') ?? '';
    if (savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _isRememberMe = true;
      });
    }
  }

  // Lưu hoặc xóa email dựa trên checkbox
  void _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isRememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
    } else {
      await prefs.remove('remembered_email');
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ tài khoản và mật khẩu");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      _saveCredentials(); // Lưu thông tin sau khi đăng nhập thành công

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Lỗi: Tài khoản hoặc mật khẩu không đúng");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a2a6c), Color(0xFFb21f1f), Color(0xFFfdbb2d)], // Đổi sang Gradient VFHPSEC chuyên nghiệp hơn
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 25),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 15,
              shadowColor: Colors.black.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(35),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO - Bo tròn nhẹ cho chuyên nghiệp
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade50,
                      ),
                      child: Image.asset('assets/logo1.png', height: 90),
                    ),
                    const SizedBox(height: 15),
                    Text('VINCOM SECURITY SYSTEM', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1a2a6c), letterSpacing: 1.2)
                    ),
                    const Text('Security & Patrol Management', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 30),

                    // EMAIL
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1a2a6c)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // MẬT KHẨU
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_open_rounded, color: Color(0xFF1a2a6c)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    
                    // GHI NHỚ ĐĂNG NHẬP
                    Row(
                      children: [
                        Checkbox(
                          value: _isRememberMe,
                          onChanged: (v) => setState(() => _isRememberMe = v!),
                          activeColor: const Color(0xFF1a2a6c),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        const Text("Ghi nhớ email", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {}, // Thêm trang quên mật khẩu nếu cần
                          child: const Text("Quên mật khẩu?", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // NÚT ĐĂNG NHẬP
                    _isLoading 
                      ? const CircularProgressIndicator()
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF1a2a6c).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                            ]
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a2a6c),
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: _login, 
                            child: const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          ),
                        ),
                    const SizedBox(height: 15),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Chưa có tài khoản?", style: TextStyle(fontSize: 13)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFb21f1f))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}