import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:project_application/pages/transferdetail_page.dart';
import 'package:project_application/pages/danadetail_page.dart';
import 'package:project_application/pages/addalamat_page.dart';

class MetodePembayaranPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MetodePembayaranPage({Key? key, required this.item}) : super(key: key);

  @override
  State<MetodePembayaranPage> createState() => _MetodePembayaranPageState();
}

class _MetodePembayaranPageState extends State<MetodePembayaranPage> {
  late String namaItem;
  late int harga;
  String? sku;
  late int adj;
  late String size;
  late int jumlah;
  late int idKategori;

  final _currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late int totalHarga;

  String? selectedPengiriman;
  final List<String> opsiPengiriman = ['JNT', 'JNE'];

  Map<String, dynamic>? alamatPengiriman;

  @override
  void initState() {
    super.initState();
    namaItem = widget.item['nama_item'] ?? '-';

    final totalHargaRaw = widget.item['total_harga'] ?? 0;
    totalHarga = (totalHargaRaw is int)
        ? totalHargaRaw
        : int.tryParse(totalHargaRaw.toString()) ?? 0;

    size = widget.item['size'] ?? '-';
    jumlah = widget.item['jumlah'] ?? 1;
    idKategori = widget.item['id_kategori'] ?? 0;

    final hargaRaw = widget.item['harga'] ?? 0;
    harga = (hargaRaw is int) ? hargaRaw : int.tryParse(hargaRaw.toString()) ?? 0;
    final adjRaw = widget.item['adj'] ?? 0;
    adj = (adjRaw is int) ? adjRaw : int.tryParse(adjRaw.toString()) ?? 0;

    print("Init MetodePembayaranPage");
  }

  Future<void> _handlePaymentMethod(String metode) async {
    // Validasi size untuk barang varian
    if (idKategori == 1) {
      size = widget.item['size'] ?? '-';
      if (size == '-' || size.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih ukuran/varian terlebih dahulu")),
        );
        return;
      }

      // Ambil SKU dari variants jika tersedia
      final variants = widget.item['variants'] as List<dynamic>?;
      if (variants != null && variants.isNotEmpty) {
        final selectedVariant = variants.firstWhere(
              (v) => v['size'] == size,
          orElse: () => variants.first,
        );
        sku = selectedVariant['sku']?.toString() ??
            '${widget.item['nama_item'].toString().toUpperCase()}-${size.toUpperCase()}';
      } else {
        sku ??= '${widget.item['nama_item'].toString().toUpperCase()}-${size.toUpperCase()}';
      }
    }

    // ✅ Tambahkan di sini, di luar if di atas
    if (idKategori != 1) {
      sku ??= ''; // default untuk barang tanpa SKU
    }



    // Validasi jumlah
    if (jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah harus lebih dari 0")),
      );
      return;
    }

    // Validasi alamat
    if (alamatPengiriman == null || alamatPengiriman!['id_alamat'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih alamat pengiriman terlebih dahulu")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final int idPembeli = prefs.getInt('id_user') ?? 0;
    if (idPembeli == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data pembeli")),
      );
      return;
    }

    final List<Map<String, dynamic>> itemsPayload = [];
    if (idKategori == 1) {
      itemsPayload.add({
        "sku": sku ?? '',
        "quantity": jumlah,
      });
    } else {
      final idItem = widget.item['id_item'];
      if (idItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data item tidak valid")),
        );
        return;
      }
      itemsPayload.add({
        "id_item": idItem,
        "quantity": jumlah,
      });
    }

    final updatedItem = {
      "id_pembeli": idPembeli,
      "id_item": widget.item['id_item'],
      "id_user": widget.item['id_user'],
      "id_kategori": idKategori,
      "metode_pembayaran": metode,
      "pengiriman": selectedPengiriman ?? '',
      "items": itemsPayload,
      "nama_item": namaItem,
      "harga": harga,
      "deskripsi": widget.item['deskripsi'] ?? '',
      "gambar": widget.item['gambar'] ?? '',
      "nama_user": widget.item['nama_user'] ?? '',
      "jumlah": jumlah,
      "size": size,
      "total_harga": totalHarga,
      "alamat": alamatPengiriman?['alamat'] ?? '',
      "nama_penerima": alamatPengiriman?['nama'] ?? '',
      "hp_penerima": alamatPengiriman?['hp'] ?? '',
      "label_alamat": alamatPengiriman?['label'] ?? '',
      "lat": alamatPengiriman?['lat'],
      "lng": alamatPengiriman?['lng'],
      "id_alamat": alamatPengiriman?['id_alamat'], // pastikan dikirim
      "sku": sku,
    };

    Widget nextPage;
    if (metode == 'transfer_atm') {
      nextPage = TransferDetailPage(item: updatedItem);
    } else if (metode == 'dana') {
      nextPage = DanaDetailPage(item: updatedItem);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Metode pembayaran tidak dikenali")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("CHECK-OUT", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Detail Produk",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        namaItem,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Harga: ${_currencyFormatter.format(harga)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (adj != 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Adjustment: ${_currencyFormatter.format(adj)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        "Total: ${_currencyFormatter.format(totalHarga)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (idKategori == 1) ...[
                            Column(
                              children: [
                                const Text("Ukuran:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Text(size),
                              ],
                            ),
                            const SizedBox(width: 30),
                          ],
                          Column(
                            children: [
                              const Text("Jumlah:",
                                  style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(jumlah.toString()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final hasil = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddAlamatPage(),
                      ),
                    );
                    if (hasil != null && hasil is Map<String, dynamic>) {
                      setState(() {
                        alamatPengiriman = hasil;
                        print("Alamat terpilih: $alamatPengiriman");
                      });
                    }
                  },
                  icon: const Icon(Icons.location_on, color: Colors.blueAccent),
                  label: const Text(
                    "Tambah Alamat",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ),
              if (alamatPengiriman != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📍 ${alamatPengiriman!['alamat']}",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      Text("👤 ${alamatPengiriman!['nama']}"),
                      Text("📞 ${alamatPengiriman!['hp']}"),
                      if (alamatPengiriman!['label'] != null &&
                          alamatPengiriman!['label'].toString().isNotEmpty)
                        Text("🏷️ Label: ${alamatPengiriman!['label']}"),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Pilih Pengiriman:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white, // Warna background putih
                  border: Border.all(color: Colors.blueAccent, width: 1.5), // Border biru
                  borderRadius: BorderRadius.circular(16), // Sudut membulat
                ),
                child: DropdownButtonHideUnderline( // Hilangkan garis bawah bawaan dropdown
                  child: DropdownButton<String>(
                    value: selectedPengiriman,
                    hint: const Text(
                      "Pilih jasa pengiriman",
                      style: TextStyle(color: Colors.black54),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                    dropdownColor: Colors.white, // warna background menu dropdown
                    items: opsiPengiriman.map((String opsi) {
                      return DropdownMenuItem<String>(
                        value: opsi,
                        child: Text(
                          opsi,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedPengiriman = value;
                        print("Pengiriman terpilih: $selectedPengiriman");
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text("Pilih Metode Pembayaran:",
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _handlePaymentMethod('transfer_atm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Transfer Bank"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _handlePaymentMethod('dana'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("DANA"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
