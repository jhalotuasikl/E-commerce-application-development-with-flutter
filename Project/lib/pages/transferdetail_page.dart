import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/upload_bukti.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransferDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const TransferDetailPage({Key? key, required this.item}) : super(key: key);

  @override
  State<TransferDetailPage> createState() => _TransferDetailPageState();
}

class _TransferDetailPageState extends State<TransferDetailPage> {
  int? idTransaksi;
  int? idAlamat;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    idAlamat = widget.item['id_alamat'] is int
        ? widget.item['id_alamat']
        : int.tryParse(widget.item['id_alamat']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final int hargaAsli = widget.item['harga'] is int
        ? widget.item['harga'] as int
        : int.tryParse(widget.item['harga'].toString()) ?? 0;

    final int adj = widget.item['adj'] is int
        ? widget.item['adj'] as int
        : int.tryParse(widget.item['adj']?.toString() ?? '0') ?? 0;

    final int jumlah = widget.item['jumlah'] ?? 1;
    final int fee = ApiService.feeAdmin;

    final int totalHargaFinal =
        (widget.item['total_harga'] ?? (hargaAsli * jumlah + adj)) + fee;

    final String? size = widget.item['size'];
    final int idKategori = widget.item['id_kategori'] ?? ((size != null && size.isNotEmpty) ? 1 : 0);

    final String metodePembayaran = widget.item['metode_pembayaran'] ?? 'transfer_atm';

    final Map<String, dynamic>? alamat = widget.item['alamat'] != null
        ? {
      'alamat': widget.item['alamat'],
      'nama': widget.item['nama_penerima'],
      'hp': widget.item['hp_penerima'],
      'label': widget.item['label_alamat']
    }
        : null;

    String formatRupiah(int value) {
      return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/bca.png', height: 50),
            const SizedBox(height: 24),
            Text(widget.item['nama_item'] ?? '-',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (alamat != null) ...[
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Alamat Pengiriman:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent)),
                      const SizedBox(height: 4),
                      Text("📍 ${alamat['alamat']}"),
                      Text("👤 ${alamat['nama']}"),
                      Text("📞 ${alamat['hp']}"),
                      if (alamat['label'] != null && alamat['label'].toString().isNotEmpty)
                        Text("🏷️ Label: ${alamat['label']}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Harga: Rp${formatRupiah(hargaAsli * jumlah)}"),
                    if (adj != 0)
                      Text("Adjustment: Rp${formatRupiah(adj)}",
                          style: const TextStyle(color: Colors.orange)),
                    Text("Fee Admin: Rp${formatRupiah(fee)}",
                        style: const TextStyle(color: Colors.orange)),
                    const Divider(),
                    Text("Total: Rp${formatRupiah(totalHargaFinal)}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (idKategori == 1 && size != null && size.isNotEmpty)
              Text("Ukuran: $size", style: const TextStyle(fontSize: 16)),
            Text("Jumlah: $jumlah", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Metode Pembayaran: ${metodePembayaran.toUpperCase()}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),

            const Spacer(),

            ElevatedButton(
              onPressed: isProcessing ? null : _handleTransaksi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: isProcessing
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "Konfirmasi & Upload Bukti",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
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

      final int? idItem = widget.item['id_item'] is int
          ? widget.item['id_item'] as int
          : int.tryParse(widget.item['id_item']?.toString() ?? '');

      final int? idPenjual = widget.item['id_user'] is int
          ? widget.item['id_user'] as int
          : int.tryParse(widget.item['id_user']?.toString() ?? '');

      final int jumlah = widget.item['jumlah'] ?? 1;
      final int adj = widget.item['adj'] is int
          ? widget.item['adj'] as int
          : int.tryParse(widget.item['adj']?.toString() ?? '0') ?? 0;

      final String? size = widget.item['size'];
      final int idKategori = widget.item['id_kategori'] ?? ((size != null && size.isNotEmpty) ? 1 : 0);

      // SKU logic
      String? sku;
      if (idKategori == 1) {
        sku = widget.item['sku']?.toString();
        if (sku == null || sku.isEmpty) {
          final variants = widget.item['variants'] as List<dynamic>?;
          if (variants != null && variants.isNotEmpty && size != null) {
            final selectedVariant = variants.firstWhere(
                  (v) => v['size'] == size,
              orElse: () => variants.first,
            );
            sku = selectedVariant['sku']?.toString();
          }
        }
      }

      // Debug print
      print("DEBUG idItem: $idItem, idPenjual: $idPenjual, idPembeli: $idPembeli, sku: $sku, idKategori: $idKategori");

      if (idPembeli == 0 || idPenjual == null || (idKategori == 0 && idItem == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data transaksi tidak lengkap')),
        );
        return;
      }

      // Prepare payload
      final List<Map<String, dynamic>> itemsToSend;
      if (idKategori == 1) {
        itemsToSend = [
          {'sku': sku, 'quantity': jumlah, 'adj': adj}
        ];
      } else {
        itemsToSend = [
          {'id_item': idItem, 'quantity': jumlah, 'adj': adj}
        ];
      }

      print("Payload itemsToSend: $itemsToSend");

      final String metode = widget.item['metode_pembayaran']?.toString() ?? 'transfer_atm';
      final String pengiriman = widget.item['pengiriman']?.toString() ?? 'JNT';

      final int newIdTransaksi = await ApiService.createTransaksiMulti(
        items: itemsToSend,
        idPenjual: idPenjual,
        idPembeli: idPembeli,
        idAlamat: idAlamat ?? 0,
        metodePembayaran: metode,
        pengiriman: pengiriman,
      ) ??
          0;

      if (newIdTransaksi != 0) {
        setState(() {
          idTransaksi = newIdTransaksi;
        });
        _goToUpload(idItem!, idPenjual, idPembeli, adj, sku);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi')),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _goToUpload(int idItem, int idPenjual, int idPembeli, int adj, String? sku) {
    final int totalHargaFinal = ((widget.item['total_harga'] ??
        ((widget.item['harga'] ?? 0) * (widget.item['jumlah'] ?? 1) + adj)) +
        ApiService.feeAdmin);

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
            'harga': totalHargaFinal,
            'adj': adj,
            'metode_pembayaran': widget.item['metode_pembayaran'] ?? 'transfer_atm',
            'id_penjual': idPenjual,
            'id_pembeli': idPembeli,
            'jumlah': widget.item['jumlah'],
            'size': size,
            'sku': sku,
            'pengiriman': widget.item['pengiriman'] ?? 'JNT',
            'alamat': widget.item['alamat'] ?? '',
            'nama_penerima': widget.item['nama_penerima'] ?? '',
            'hp_penerima': widget.item['hp_penerima'] ?? '',
            'label_alamat': widget.item['label_alamat'] ?? '',
            'id_alamat': idAlamat ?? 0,
          },
        ),
      ),
    );
  }
}
