import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/danaberhasilcair_page.dart';

class MenungguVerifikasiDanaPage extends StatefulWidget {
  final int idTransaksi;
  final int idPencairan; // tambahan id_pencairan dari response upload

  const MenungguVerifikasiDanaPage({
    super.key,
    required this.idTransaksi,
    required this.idPencairan,
  });

  @override
  State<MenungguVerifikasiDanaPage> createState() =>
      _MenungguVerifikasiDanaPageState();
}

class _MenungguVerifikasiDanaPageState
    extends State<MenungguVerifikasiDanaPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCairDanaStatus();
  }

  Future<void> _checkCairDanaStatus() async {
    while (true) {
      // Gunakan id_pencairan dari widget
      final status =
      await ApiService.getCairDanaStatus(widget.idPencairan);

      print("[DEBUG] Status pencairan: $status");

      if (status.toLowerCase() == "dicairkan") break;
      await Future.delayed(const Duration(seconds: 5));
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DanaBerhasilPage(transaksiId: widget.idTransaksi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menunggu Verifikasi Admin")),
      body: Center(
        child: _isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Harap tunggu, admin sedang memverifikasi bukti cairkan dana...",
              textAlign: TextAlign.center,
            ),
          ],
        )
            : const SizedBox.shrink(),
      ),
    );
  }
}
