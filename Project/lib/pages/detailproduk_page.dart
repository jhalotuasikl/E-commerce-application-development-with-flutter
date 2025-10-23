import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'metodepembayaran_page.dart';
import 'package:project_application/pages/chat_page.dart';
import 'package:project_application/pages/profilepenjual_page.dart';
import 'package:project_application/pages/loginregister.dart'; // pastikan path sesuai

class DetailProdukPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const DetailProdukPage({Key? key, required this.item}) : super(key: key);

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage> {
  String? selectedSku;
  String? selectedSize;
  int availableStock = 0;
  int quantity = 1;
  List<dynamic> variants = [];
  bool loadingVariants = true;
  bool showSizeAndQuantity = false;

  int? selectedAdj;

  @override
  void initState() {
    super.initState();
    _loadVariantsAndSetup();
  }

  Future<void> _loadVariantsAndSetup() async {
    final idItem = widget.item['id_item'];
    final data = await ApiService.getVariants(idItem);

    setState(() {
      variants = data;
      loadingVariants = false;

      if (widget.item['id_kategori'].toString() == '1') {
        showSizeAndQuantity = true;

        if (variants.isNotEmpty) {
          selectedSku = variants[0]['sku'];
          selectedSize = variants[0]['size'];
          availableStock = variants[0]['stock'] ?? 0;
          selectedAdj = variants[0]['adj'] ?? 0;
        } else {
          availableStock = 0;
        }
      } else {
        showSizeAndQuantity = false;
        availableStock = _calculateTotalStock(variants);
      }
    });
  }

  int _calculateTotalStock(List<dynamic> variants) {
    int total = 0;
    for (var v in variants) {
      final stock = v['stock'];
      total += (stock is int) ? stock : int.tryParse(stock.toString()) ?? 0;
    }
    return total;
  }

  Future<void> addToFavorite(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');

    if (idUser != null) {
      final success =
      await ApiService.addfavorites(idUser, widget.item['id_item']);
      final snackBar = SnackBar(
        content: Text(success
            ? 'Berhasil ditambahkan ke favorit'
            : 'Item sudah ada di favorit'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _onSizeChanged(String? sku, String? size, int stock, int? adj) {
    setState(() {
      selectedSku = sku;
      selectedSize = size;
      availableStock = stock;
      selectedAdj = adj ?? 0;
      quantity = 1;
    });
  }

  void _increaseQuantity() {
    if (quantity < availableStock) {
      setState(() => quantity++);
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() => quantity--);
    }
  }

  void _proceedPayment() async {
    if (showSizeAndQuantity && (selectedSku == null || selectedSize == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih size terlebih dahulu')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user') ?? 0;

    final hargaRaw = widget.item['harga'];
    final hargaInt = (hargaRaw is int)
        ? hargaRaw
        : double.tryParse(hargaRaw.toString())?.toInt() ?? 0;

    final adjValue = selectedAdj ?? 0;
    final hargaFinal = hargaInt + adjValue;
    final totalHarga = hargaFinal * quantity;

    final updatedItem = {
      'id_item': widget.item['id_item'],
      'id_user': widget.item['id_user'],
      'nama_item': widget.item['nama_item'],
      'harga': hargaFinal,
      'deskripsi': widget.item['deskripsi'] ?? '',
      'gambar': widget.item['gambar'] ?? '',
      'nama_user': widget.item['nama_user'] ?? '',
      'jumlah': quantity,
      'total_harga': totalHarga,
      'sku': selectedSku,
      'size': selectedSize,
      'id_pembeli': idUser,
      'id_kategori': widget.item['id_kategori'],
      'adj': adjValue,
      'variants': widget.item['variants'], // ✅ kirim variants juga
    };



    // ✅ Tambahkan log biar ketahuan sebelum dilempar ke pembayaran
    print("DEBUG SKU: $selectedSku");
    print("DEBUG SIZE: $selectedSize");
    print("DEBUG idKategori: ${widget.item['id_kategori']}");

    if (widget.item['id_kategori'].toString() == '1') {
      // varian → WAJIB ada sku
      if (selectedSku == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SKU tidak boleh kosong, pilih size!')),
        );
        return;
      }
      updatedItem['sku'] = selectedSku;
      updatedItem['size'] = selectedSize;
    } else {
      updatedItem.remove('sku');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetodePembayaranPage(item: updatedItem),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final imageUrl = '${ApiService.baseUrl}${widget.item['gambar']}';

    final hargaRaw = widget.item['harga'];
    final hargaInt = (hargaRaw is int)
        ? hargaRaw
        : double.tryParse(hargaRaw.toString())?.toInt() ?? 0;

    final adjValue = selectedAdj ?? 0;
    final hargaFinal = hargaInt + adjValue;

    final hargaFormatted = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(hargaFinal);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loadingVariants
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(
                  imageUrl,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Penjual
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerProfilePage(
                              sellerId: widget.item['id_user'],
                              sellerName: widget.item['nama_user'] ?? 'Penjual',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.black, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Pemilik: ${widget.item['nama_user']}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Nama Barang
                    Text(
                      widget.item['nama_item'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Deskripsi Barang
                    Text(
                      widget.item['deskripsi'],
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Harga
                    Text(
                      hargaFormatted,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.blueAccent,
                      ),
                    ),

                    // Nilai Adj (jika ada)
                    if (adjValue != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Adj: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(adjValue)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (showSizeAndQuantity) ...[
                _buildSizeSelector(hargaInt),
                const SizedBox(height: 16),
                _buildQuantitySelector(),
              ],

              if (!showSizeAndQuantity) _buildQuantitySelector(),

              const SizedBox(height: 32),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tombol Add to Favorite
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final idUser = prefs.getInt('id_user');

                        if (idUser == null) {
                          // Belum login → lempar ke landing page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyApp()), // LandingPage
                          );
                          return;
                        }

                        addToFavorite(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Add to Favorite', style: TextStyle(color: Colors.white)),
                    ),

                    // Tombol Lanjutkan / Pembayaran
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final idUser = prefs.getInt('id_user');

                        if (idUser == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyApp()),
                          );
                          return;
                        }

                        _proceedPayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
                    ),

                    // Tombol Chat
                    ElevatedButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final idUserLogin = prefs.getInt('id_user');

                        if (idUserLogin == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyApp()),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              idPengirim: idUserLogin,
                              idPenerima: widget.item['id_user'],
                              namaPenerima: widget.item['nama_user'] ?? 'Penjual',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text('Chat', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(int hargaInt) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Ukuran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: variants.map((v) {
                final sku = v['sku'];
                final size = v['size'];
                final stock = v['stock'] ?? 0;
                final adj = v['adj'] ?? 0;
                final isSelected = sku == selectedSku;

                final hargaFinal = hargaInt +
                    (adj is int ? adj : int.tryParse(adj.toString()) ?? 0);

                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(size,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        stock > 0 ? 'Stok: $stock' : 'Habis',
                        style: TextStyle(
                          fontSize: 10,
                          color: stock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0)
                            .format(hargaFinal),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black87),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (sel) {
                    if (stock <= 0) return;
                    _onSizeChanged(sku, size, stock, adj);
                  },
                  padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jumlah',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Stok tersedia: $availableStock',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              children: [
                InkWell(
                  onTap: _decreaseQuantity,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: const Icon(Icons.remove,
                        size: 20, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _increaseQuantity,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: const Icon(Icons.add,
                        size: 20, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
