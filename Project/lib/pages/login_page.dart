import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/pages/beranda.dart';
import 'package:project_application/mainpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau password tidak boleh kosong')),
      );
      return;
    }

    final userData = await ApiService.login(email, password);

    if (userData != null) {

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('nama_user', userData['nama_user'] ?? '');
      await prefs.setInt('id_user', userData['id_user'] ?? 0);
      await prefs.setString('nomor_telepon', userData['nomor_telepon'] ?? '');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login berhasil')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const  MainPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login gagal. Periksa email atau password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Login'),
            ),
          ],
        ), 
      ),
    );
  }
}
