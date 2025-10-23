import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/detailproduk_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/pages/search_page.dart';

class BuyProdukPage extends StatefulWidget {
  const BuyProdukPage({Key? key}) : super(key: key);

  @override
  State<BuyProdukPage> createState() => _BuyProdukPageState();
}

class _BuyProdukPageState extends State<BuyProdukPage> {
  File? _image;
  final picker = ImagePicker();
  int _idUser = 0; // idUser global
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchItems();
  }

  Future<void> _loadUserIdAndFetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user') ?? 0;

    setState(() {
      _idUser = idUser;
    });

    final result = await ApiService.getAllItemsExcludeUser(idUser.toString());
    print("DEBUG items dari API: $result");

    setState(() {
      items = result;
    });
  }

  // ✅ FIX fungsi formatRupiah supaya tidak salah parsing "600000.00" jadi 60000000
  String formatRupiah(dynamic number) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (number == null) return 'Rp 0';

    if (number is int) {
      return formatCurrency.format(number);
    }

    if (number is double) {
      return formatCurrency.format(number.toInt());
    }

    if (number is String) {
      // Coba parsing string jadi double dulu biar aman
      double parsed = double.tryParse(number) ?? 0;
      return formatCurrency.format(parsed.toInt());
    }

    return 'Rp 0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text('Search...', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Expanded supaya GridView tidak overflow
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text("Tidak ada item untuk ditampilkan"))
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85, // sesuaikan agar tidak overflow
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final imageUrl = '${ApiService.baseUrl}${item['gambar']}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailProdukPage(item: item),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blueAccent,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: Image.network(
                                imageUrl,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 100,
                                  color: Colors.grey,
                                  child: const Center(child: Icon(Icons.broken_image)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                              child: Text(
                                item['nama_item'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                              child: Text(
                                item['deskripsi'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Text(
                                formatRupiah(item['harga']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
