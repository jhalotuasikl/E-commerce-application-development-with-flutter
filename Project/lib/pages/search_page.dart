import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/detailproduk_page.dart';
import 'package:intl/intl.dart'; // <-- tambahkan ini

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  void _searchItems(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final results = await ApiService.searchItems(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print("Search error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari barang...',
            border: InputBorder.none,
          ),
          onSubmitted: _searchItems,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchItems(_searchController.text),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? const Center(child: Text("Tidak ada hasil"))
          : Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: _searchResults.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75, // kasih ruang lebih tinggi
                ),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  final imageUrl =
                      '${ApiService.baseUrl}${item['gambar']}';

                  return GestureDetector(
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
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                  Container(
                                    height: 100,
                                    color: Colors.grey,
                                    child: const Center(
                                        child: Icon(Icons.broken_image)),
                                  ),
                            ),
                          ),

                          // Bagian teks dibungkus Expanded biar fleksibel
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama_item'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['deskripsi'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatHarga(item['harga']),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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
    );
  }
}
