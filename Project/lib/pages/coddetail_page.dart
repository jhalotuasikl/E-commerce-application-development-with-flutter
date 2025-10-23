import 'package:flutter/material.dart';

class CodDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const CodDetailPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String namaItem = item['nama_item'] ?? '-';
    final dynamic harga = item['harga'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("COD - Bayar di Tempat"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Card Informasi Produk
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_cart,
                        size: 50, color: Colors.green),
                    const SizedBox(height: 10),
                    Text(namaItem,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Rp$harga",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card Alamat
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.location_on,
                        size: 50, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text("Barang akan dikirim ke alamat Anda.",
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Alamat Lengkap",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                // TODO: kirim alamat & buat transaksi COD di backend
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("Konfirmasi Pesanan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
