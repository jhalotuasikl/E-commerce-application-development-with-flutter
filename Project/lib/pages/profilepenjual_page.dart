import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/chat_page.dart';
import 'package:project_application/pages/detailproduk_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SellerProfilePage extends StatefulWidget {
  final int sellerId;
  final String sellerName;

  const SellerProfilePage({
    Key? key,
    required this.sellerId,
    required this.sellerName,
  }) : super(key: key);

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSellerProducts();
  }

  /// Format harga ke dalam Rupiah
  String formatHarga(dynamic value) {
    if (value == null) return "Rp0";
    final formatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(num.tryParse(value.toString()) ?? 0);
  }

  Future<void> _loadSellerProducts() async {
    final items = await ApiService.getProductsByUser(widget.sellerId);
    setState(() {
      _products = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.sellerName,
          style: const TextStyle(color: Colors.black),
        ),
      ),

      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                // Avatar Penjual
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 10),

                // Tombol Chat
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final idUserLogin = prefs.getInt('id_user') ?? 0;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          idPengirim: idUserLogin,
                          idPenerima: widget.sellerId,
                          namaPenerima: widget.sellerName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Chat"),
                ),

                const SizedBox(height: 20),

                // Judul Produk Penjual
                const Text(
                  'Produk Penjual',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat'),
                ),

                const SizedBox(height: 10),

                // Daftar Produk
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _products.isEmpty
                      ? const Center(
                    child: Text("Tidak ada produk"),
                  )
                      : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    children:
                    List.generate(_products.length, (index) {
                      final item = _products[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation,
                                  secondaryAnimation) =>
                                  DetailProdukPage(item: item),
                              transitionsBuilder: (context,
                                  animation,
                                  secondaryAnimation,
                                  child) {
                                const begin =
                                Offset(0.0, 0.2); // dari bawah
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(
                                    begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var fadeTween =
                                Tween<double>(begin: 0, end: 1);

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: FadeTransition(
                                    opacity:
                                    animation.drive(fadeTween),
                                    child: child,
                                  ),
                                );
                              },
                              transitionDuration: const Duration(
                                  milliseconds: 400),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              item['gambar'] != null &&
                                  item['gambar'] != ''
                                  ? Image.network(
                                '${ApiService.baseUrl}${item['gambar']}',
                                height: 80,
                                fit: BoxFit.cover,
                              )
                                  : const Icon(
                                Icons.image_not_supported,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['nama_item'] ?? '',
                                style:
                                const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatHarga(item['harga']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
