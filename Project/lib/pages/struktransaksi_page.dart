import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/pages/beranda.dart';
import 'package:project_application/mainpage.dart';

class StrukTransaksiPage extends StatelessWidget {
  final Map<String, dynamic> transaction; // {'header': {...}, 'items': [...]}
  final int fee = 500;

  const StrukTransaksiPage({Key? key, required this.transaction}) : super(key: key);

  String _formatRupiah(dynamic value) {
    int val = 0;
    if (value is String) val = int.tryParse(value) ?? 0;
    else if (value is int) val = value;

    return "Rp" + val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
  }

  String _formatTanggalFull(String input) {
    try {
      final date = DateTime.parse(input);
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return input;
    }
  }

  Widget _button(BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = transaction['header'] ?? {};
    final List<dynamic> items = transaction['items'] ?? [];

    // Hitung subtotal dari items (harga_at_purchase * quantity)
    int subtotal = 0;
    for (var it in items) {
      final qty = int.tryParse(it['quantity'].toString()) ?? 1;
      final pricePer = int.tryParse(it['price_at_purchase'].toString()) ?? 0;
      subtotal += pricePer * qty;
    }

    final int totalWithFee = subtotal + fee;

    final String tanggalRaw = header['tanggal_transaksi']?.toString() ?? '';
    final String tanggal = _formatTanggalFull(tanggalRaw);

    final idTransaksi = header['id_transaksi']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Transaksi Berhasil",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.check, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 12),
              _rowInfo("ID Transaksi:", idTransaksi),
              _rowInfo("Tanggal:", tanggal),
              const SizedBox(height: 8),
              ...items.map((it) {
                final sku = it['sku'] ?? '';
                final size = it['size'] ?? '';
                final qty = int.tryParse(it['quantity'].toString()) ?? 1;
                final pricePer = int.tryParse(it['price_at_purchase'].toString()) ?? 0;
                final itemSubtotal = pricePer * qty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text("SKU: $sku (Size: $size)"),
                    _rowInfo("Jumlah:", qty.toString()),
                    _rowInfo("Harga/unit:", _formatRupiah(pricePer)),
                    _rowInfo("Subtotal:", _formatRupiah(itemSubtotal)),
                  ],
                );
              }).toList(),
              const SizedBox(height: 12),
              _rowInfo("Subtotal:", _formatRupiah(subtotal)),
              _rowInfo("Fee Admin:", _formatRupiah(fee)),
              _rowInfo("Total Bayar:", _formatRupiah(totalWithFee)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _button(context, "Selesai", () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                          (route) => false,
                    );
                  }),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      String nomor = prefs.getString('nomor_telepon') ?? "+62";
                      nomor = nomor.replaceAll(" ", "");
                      if (nomor.startsWith("whatsapp:")) {
                        print("Nomor yang dipakai: $nomor");
                        nomor = nomor.replaceFirst("whatsapp:", "");
                      }

                      // Pesan polos tanpa emoji atau format
                      String pesan = "Struk Transaksi Anda:\n"
                          "ID: $idTransaksi\n"
                          "Tanggal: $tanggal\n\n";
                      for (var it in items) {
                        final sku = it['sku'] ?? '';
                        final size = it['size'] ?? '';
                        final qty = int.tryParse(it['quantity'].toString()) ?? 1;
                        final pricePer = int.tryParse(it['price_at_purchase'].toString()) ?? 0;
                        final itemSubtotal = pricePer * qty;
                        pesan += "$sku (Size: $size) x$qty = ${_formatRupiah(itemSubtotal)}\n";
                      }
                      pesan += "\nFee: ${_formatRupiah(fee)}\n"
                          "Total Bayar: ${_formatRupiah(totalWithFee)}";

                      final response = await ApiService.kirimWhatsapp(nomor, pesan);
                      if (response['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Pesan berhasil dikirim ke WhatsApp")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                              "Gagal kirim pesan: ${response['error'] ?? 'Tidak diketahui'}")),
                        );
                      }
                    },

                    child: const Text("Kirim WhatsApp"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}
