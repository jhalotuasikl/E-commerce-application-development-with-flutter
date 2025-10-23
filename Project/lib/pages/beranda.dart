import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart' as cs;
import 'package:project_application/pages/chat_list_page.dart';
import 'package:project_application/pages/profile_page.dart';
import 'package:project_application/pages/addproduk_page.dart';
import 'package:project_application/pages/favorites_page.dart';
import 'package:project_application/pages/search_page.dart';
import 'package:project_application/pages/notifikasi_page.dart';
import 'package:project_application/pages/live_page.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/detailproduk_page.dart';
import 'package:project_application/pages/buyproduk_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _selectedIndex = 2;
  List<Map<String, dynamic>> produkList = [];

  @override
  void initState() {
    super.initState();
    _loadProdukDariApi();
  }

  Future<void> _loadProdukDariApi() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user') ?? 0;

    final result = await ApiService.getAllItemsExcludeUser(idUser.toString());
    setState(() {
      produkList = result;
    });
  }

  String formatRupiah(dynamic number) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    if (number == null) return 'Rp 0';
    if (number is int) return formatCurrency.format(number);
    if (number is double) return formatCurrency.format(number.toInt());
    if (number is String) {
      double parsed = double.tryParse(number) ?? 0;
      return formatCurrency.format(parsed.toInt());
    }
    return 'Rp 0';
  }

  Widget _buildBerandaContent() {
    final List<String> promoImages = [
      'assets/e1.jpeg',
      'assets/e2.jpeg',
      'assets/e3.jpeg',
    ];

    final List<Map<String, dynamic>> kategori = [
      {'icon': Icons.shopping_bag_sharp, 'label': 'Fashion'},
      {'icon': Icons.watch, 'label': 'Aksesoris'},
      {'icon': Icons.chair, 'label': 'Furniture'},
      {'icon': Icons.devices, 'label': 'Elektronik'},
      {'icon': Icons.book, 'label': 'Buku'},
      {'icon': Icons.more_horiz, 'label': 'Lainnya'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 Search & Chat
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const SearchPage()));
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
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const ChatListPage()));
                      },
                      child: const Icon(Icons.chat, size: 28, color: Colors.blueAccent),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text('Hai, Selamat Datang!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Temukan inspirasi dan barang keren hari ini 👇',
                    style: TextStyle(fontSize: 16, color: Colors.black54)),

                const SizedBox(height: 20),

                // 🖼️ Carousel Promo
                cs.CarouselSlider(
                  options: cs.CarouselOptions(
                    height: 150,
                    autoPlay: true,
                    enlargeCenterPage: true,
                  ),
                  items: promoImages.map((path) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(path, fit: BoxFit.cover, width: double.infinity),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 25),
                const Text('Kategori Populer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  children: kategori.map((item) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item['icon'], color: Colors.blueAccent, size: 32),
                          const SizedBox(height: 8),
                          Text(item['label'], style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 25),
                const Text('Produk Populer 🔥',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // ✅ Produk dari API
                produkList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                  itemCount: produkList.length > 4 ? 4 : produkList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final produk = produkList[index];
                    final imageUrl = '${ApiService.baseUrl}${produk['gambar']}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailProdukPage(item: produk),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(imageUrl,
                                  fit: BoxFit.cover, height: 100, width: double.infinity),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(produk['nama_item'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(formatRupiah(produk['harga']),
                                      style: const TextStyle(color: Colors.blueAccent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),
                const Text('Rekomendasi Untuk Kamu 💡',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                produkList.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: produkList.length > 6 ? 6 : produkList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = produkList[index];
                      final imageUrl = '${ApiService.baseUrl}${item['gambar']}';
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetailProdukPage(item: item)),
                          );
                        },
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(imageUrl,
                                    width: 80, height: 80, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 8),
                              Text(item['nama_item'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),
                const Text('Tips & Artikel 📚',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                ...List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Artikel ${index + 1}: Tips Belanja Cerdas',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text(
                          'Gunakan fitur pencarian untuk menemukan barang sesuai kebutuhanmu, dan manfaatkan kategori populer untuk inspirasi gaya baru!',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 30),
                Center(
                  child: Text(
                    '© 2025 Thrifting Digital - All Rights Reserved',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const AddProductPage(),
          const BuyProdukPage(),
          _buildBerandaContent(),
          const LivePage(),
          const NotifikasiPage(),
          const FavoritesPage(),
          const ProfilePage(),
        ],
      ),
    );
  }
}
