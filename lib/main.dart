// main.dart cập nhật
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: unused_import
import 'package:flutter_application_1/mainWrapper.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'main_wrapper.dart' hide MainWrapper; // File mới quản lý 4 tab

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-1g-93ICr8sVJmgcJJOuh7dYnmGL6qN4",
      authDomain: "vfhpsec.firebaseapp.com",
      databaseURL: "https://vfhpsec-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "vfhpsec",
      storageBucket: "vfhpsec.firebasedatabase.app",
      messagingSenderId: "386531823408",
      appId: "1:386531823408:web:9d88407f42a825fcc7c2f5",
      measurementId: "G-5L3WX97T0M",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VFHPSEC MONITORING',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a2a6c)), 
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const MainWrapper(), // Trang chính chứa 4 Tab
      },
    );
  }
}