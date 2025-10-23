import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/struktransaksi_page.dart';

class MenungguVerifikasiPage extends StatefulWidget {
  final int idTransaksi;
  final Map<String, dynamic> item;

  const MenungguVerifikasiPage({
    Key? key,
    required this.idTransaksi,
    required this.item,
  }) : super(key: key);

  @override
  State<MenungguVerifikasiPage> createState() => _MenungguVerifikasiPageState();
}

class _MenungguVerifikasiPageState extends State<MenungguVerifikasiPage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _cekStatus());
  }

  Future<void> _cekStatus() async {
    final status = await ApiService.cekStatusTransaksi(widget.idTransaksi);
    if (status == 'selesai') {
      _timer.cancel();

      // Ambil data lengkap transaksi
      final detail = await ApiService.getDetailTransaksi(widget.idTransaksi);

      if (detail != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StrukTransaksiPage(transaction: detail),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat detail transaksi')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Menunggu verifikasi admin...", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
