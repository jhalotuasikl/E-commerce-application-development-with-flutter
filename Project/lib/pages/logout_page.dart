import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/mainpage.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi Logout'),
      content: const Text('Apakah Anda yakin ingin logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => _logout(context),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
