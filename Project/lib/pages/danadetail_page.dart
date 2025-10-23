import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/upload_bukti.dart';

class DanaDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const DanaDetailPage({Key? key, required this.item}) : super(key: key);

  @override
  _DanaDetailPageState createState() => _DanaDetailPageState();
}

class _DanaDetailPageState extends State<DanaDetailPage> {
  bool isProcessing = false;
  int? idTransaksi;
  int? idAlamat; // 🔹 tambahan idAlamat

  @override
  void initState() {
    super.initState();
    // parsing idAlamat dari widget.item
    idAlamat = widget.item['id_alamat'] is int
        ? widget.item['id_alamat'] as int
        : int.tryParse(widget.item['id_alamat']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final hargaAsli = widget.item['harga'] is int
        ? widget.item['harga'] as int
        : int.tryParse(widget.item['harga'].toString()) ?? 0;

    final int adj = widget.item['adj'] is int
        ? widget.item['adj'] as int
        : int.tryParse(widget.item['adj']?.toString() ?? '0') ?? 0;

    final int jumlah = widget.item['jumlah'] ?? 1;
    const int feeAdmin = 500;

    final int totalHarga = ((hargaAsli + adj) * jumlah) + feeAdmin;

    final String? size = widget.item['size'];
    final int idKategori = widget.item['id_kategori'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran DANA"),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_bag,
                        size: 50, color: Colors.lightBlue),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("082230900302", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Icon(Icons.copy, size: 18),
                      ],
                    ),
                    Text(widget.item['nama_item'] ?? '-',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                        "Rp${totalHarga.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    if (idKategori == 1 && size != null && size.isNotEmpty)
                      Text("Ukuran: $size", style: const TextStyle(fontSize: 16)),
                    Text("Jumlah: $jumlah", style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Icon(Icons.qr_code, size: 100, color: Colors.lightBlue),
                    SizedBox(height: 10),
                    Text(
                      "Scan QR DANA di atas untuk melakukan pembayaran",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isProcessing ? null : _handleTransaksi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text("Konfirmasi & Upload Bukti",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTransaksi() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final int idPembeli = prefs.getInt('id_user') ?? 0;

      int? idItem = widget.item['id_item'] is int
          ? widget.item['id_item'] as int
          : int.tryParse(widget.item['id_item'].toString());

      int? idPenjual = widget.item['id_user'] is int
          ? widget.item['id_user'] as int
          : int.tryParse(widget.item['id_user'].toString());

      final int jumlah = widget.item['jumlah'] ?? 1;
      final String? size = widget.item['size'];
      final int adj = widget.item['adj'] is int
          ? widget.item['adj'] as int
          : int.tryParse(widget.item['adj']?.toString() ?? '0') ?? 0;
      final int idKategori = widget.item['id_kategori'] ?? 0;
      final String? sku = widget.item['sku']?.toString();
      final String pengiriman =
          widget.item['pengiriman']?.toString() ?? 'JNT';

      if (idItem == null || idPenjual == null || idPembeli == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data transaksi tidak lengkap')),
        );
        return;
      }

      if (idKategori == 1 && (sku == null || sku.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SKU varian tidak ditemukan')),
        );
        return;
      }

      final List<Map<String, dynamic>> itemsToSend = (idKategori == 1)
          ? [
        {'sku': sku, 'quantity': jumlah, 'adj': adj}
      ]
          : [
        {'id_item': idItem, 'quantity': jumlah, 'adj': adj}
      ];

      final newIdTransaksi = await ApiService.createTransaksiMulti(
        items: itemsToSend,
        idPenjual: idPenjual,
        idPembeli: idPembeli,
        metodePembayaran: 'dana',
        pengiriman: pengiriman,
        idAlamat: idAlamat ?? 0, // 🔹 tambahan idAlamat
      );

      if (newIdTransaksi != null) {
        setState(() => idTransaksi = newIdTransaksi);
        _goToUpload(idItem, idPenjual, idPembeli, adj, sku, pengiriman);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi')),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _goToUpload(int idItem, int idPenjual, int idPembeli, int adj,
      String? sku, String pengiriman) {
    final hargaAsli = widget.item['harga'] is int
        ? widget.item['harga'] as int
        : int.tryParse(widget.item['harga'].toString()) ?? 0;

    final int jumlah = widget.item['jumlah'] ?? 1;
    final int totalHarga = ((hargaAsli + adj) * jumlah) + 500;

    final String? size = widget.item['size'];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UploadBuktiPage(
          idTransaksi: idTransaksi!,
          item: {
            'id_transaksi': idTransaksi!,
            'id_item': idItem,
            'nama_item': widget.item['nama_item'],
            'harga': totalHarga,
            'adj': adj,
            'metode_pembayaran': 'dana',
            'id_penjual': idPenjual,
            'id_pembeli': idPembeli,
            'jumlah': jumlah,
            'size': size,
            'sku': sku,
            'pengiriman': pengiriman,
            'id_alamat': idAlamat ?? 0, // 🔹 diteruskan
          },
        ),
      ),
    );
  }
}
