import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/pages/detailproduk_page.dart';
import 'package:intl/intl.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> favorites = [];
  bool _isLoading = true;

  int? _idUser;
  int _notifCount = 0;
  int _favoriteCount = 0;

  @override
  void initState() {
    super.initState();
    _checkAndLoadUser();
  }

  Future<void> _checkAndLoadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');

    if (idUser == null || idUser == 0) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _idUser = idUser;
    });

    await fetchFavorites();
    await _loadCounts();
  }

  Future<void> _loadCounts() async {
    if (_idUser == null) return;

    final pembeliNotif = await ApiService.getNotificationsForBuyer(_idUser!);
    final penjualNotif = await ApiService.getNotificationsForSeller(_idUser!);
    final favs = await ApiService.getFavorites(_idUser!);

    setState(() {
      _notifCount = (pembeliNotif?.length ?? 0) + (penjualNotif?.length ?? 0);
      _favoriteCount = favs?.length ?? 0;
    });
  }

  Future<void> fetchFavorites() async {
    setState(() => _isLoading = true);
    if (_idUser != null) {
      try {
        final data = await ApiService.getFavorites(_idUser!);
        setState(() {
          favorites = data;
          _favoriteCount = data.length;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint("Gagal mengambil data favorit: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> deleteFavorite(int idItem) async {
    if (_idUser != null) {
      bool success = await ApiService.deleteFavorite(_idUser!, idItem);
      if (success) {
        await fetchFavorites();
        await _loadCounts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus item dari favorit")),
        );
      }
    }
  }

  /// Format harga ke dalam Rupiah
  String formatHarga(dynamic value) {
    if (value == null) return "Rp0";
    final formatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(num.tryParse(value.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white54,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Favorit Saya", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await fetchFavorites();
              await _loadCounts();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _idUser == null || _idUser == 0
            ? const Center(
          child: Text(
            "Silakan login untuk melihat favorit",
            style: TextStyle(fontSize: 16),
          ),
        )
            : RefreshIndicator(
          onRefresh: () async {
            await fetchFavorites();
            await _loadCounts();
          },
          child: favorites.isEmpty
              ? const Center(child: Text("Tidak ada item favorit"))
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: favorites.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final item = favorites[index];
                      final imageUrl =
                          '${ApiService.baseUrl}${item['gambar']}';

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailProdukPage(item: item),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.blueAccent,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                          Container(
                                            height: 100,
                                            color: Colors.white,
                                            child: const Center(
                                              child:
                                              Icon(Icons.broken_image),
                                            ),
                                          ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item['nama_item'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      item['deskripsi'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      formatHarga(item['harga']),
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
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 20, color: Colors.red),
                                onPressed: () {
                                  deleteFavorite(item['id_item']);
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
