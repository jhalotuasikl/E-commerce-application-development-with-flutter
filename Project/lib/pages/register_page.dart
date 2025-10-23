import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nomorTeleponController =
  TextEditingController(text: '+62 ');
  final TextEditingController passwordController = TextEditingController();

  void _register() async {
    final nama = namaController.text.trim();
    final email = emailController.text.trim();
    final nomorTelepon = nomorTeleponController.text.trim();
    final password = passwordController.text.trim();

    if (nama.isEmpty || email.isEmpty || nomorTelepon.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    bool success = await ApiService.register(nama, email, nomorTelepon, password);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nama_user', nama);
      await prefs.setString('nomor_telepon', nomorTelepon);
      await prefs.setString('email', email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran gagal. Coba lagi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
              controller: nomorTeleponController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                labelStyle: TextStyle(color: Colors.black),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                if (!value.startsWith('+62')) {
                  nomorTeleponController.text = '+62 ';
                  nomorTeleponController.selection = TextSelection.fromPosition(
                    TextPosition(offset: nomorTeleponController.text.length),
                  );
                }
              },
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
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
