import 'package:flutter/material.dart';
import 'package:project_application/pages/beranda.dart';
import 'package:project_application/mainpage.dart';

class DanaBerhasilPage extends StatelessWidget {
  final int transaksiId;

  const DanaBerhasilPage({super.key, required this.transaksiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mencairkan Dana")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Dana berhasil dicairkan!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("ID Transaksi: $transaksiId"),
            const SizedBox(height: 30),

            // Tombol "Selesai"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainPage()),
                      (route) => false,
                );
              },
              child: const Text(
                "Selesai",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
