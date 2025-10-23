import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:project_application/pages/component/custombottom.dart';
import 'package:project_application/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/mainpage.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class VariantEntry {
  String size;
  int stock;
  int priceAdjustment;

  VariantEntry({this.size = '', required this.stock, this.priceAdjustment = 0});
}

class _AddProductPageState extends State<AddProductPage> {
  File? _image;
  final picker = ImagePicker();
  int? selectedCategoryId;
  String? selectedCategoryName;

  bool hasVariants = false;
  bool _isLoadingUser = true;

  int? _idUser;

  Map<int, String> categories = {};
  bool isLoadingCategories = true;

  final namaController = TextEditingController();
  final deskripsiController = TextEditingController();
  final hargaController = TextEditingController();
  final stokController = TextEditingController();

  final variantSizeController = TextEditingController();
  final variantStockController = TextEditingController();
  final variantPriceAdjustmentController = TextEditingController();

  final List<VariantEntry> variants = [];

  @override
  void initState() {
    super.initState();
    _checkUser();
    fetchCategories();
  }

  Future<void> _checkUser() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user') ?? 0;
    if (idUser == 0) {
      setState(() {
        _isLoadingUser = false;
      });
      return;
    }
    setState(() {
      _idUser = idUser;
      _isLoadingUser = false;
    });
  }

  String formatRupiah(dynamic nominal) {
    final number = int.tryParse(nominal.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  Future<void> fetchCategories() async {
    try {
      final response =
      await http.get(Uri.parse('${ApiService.baseUrl}/categories'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['categories'];
        final Map<int, String> fetchedCategories = {};
        for (var item in data) {
          fetchedCategories[item['id_kategori']] = item['nama_kategori'];
        }
        setState(() {
          categories = fetchedCategories;
          isLoadingCategories = false;
        });
      } else {
        print('Gagal memuat kategori');
      }
    } catch (e) {
      print('Error kategori: $e');
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitItem() async {
    if (_idUser == null || _idUser == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak valid, silakan login ulang')),
      );
      return;
    }

    if (_image == null ||
        namaController.text.isEmpty ||
        deskripsiController.text.isEmpty ||
        hargaController.text.isEmpty ||
        selectedCategoryId == null ||
        (!hasVariants && stokController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data terlebih dahulu')),
      );
      return;
    }

    if (hasVariants && variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 varian produk')),
      );
      return;
    }

    if (hasVariants && selectedCategoryId == 1) {
      bool adaVarianTanpaSize = variants.any((v) => v.size.trim().isEmpty);
      if (adaVarianTanpaSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Semua varian harus memiliki size untuk kategori ini')),
        );
        return;
      }
    } else if (hasVariants) {
      for (var v in variants) {
        if (v.size.trim().isEmpty) v.size = '-';
      }
    }

    final uri = Uri.parse('${ApiService.baseUrl}/items');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('gambar', _image!.path));
    request.fields['nama_item'] = namaController.text.trim();
    request.fields['deskripsi'] = deskripsiController.text.trim();
    request.fields['harga'] = int.parse(hargaController.text.trim()).toString();
    request.fields['id_user'] = _idUser.toString();
    request.fields['id_kategori'] = selectedCategoryId.toString();
    request.fields['status'] = 'tersedia';
    request.fields['stock'] = hasVariants ? '0' : stokController.text.trim();

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal posting produk')),
      );
      return;
    }

    int? createdItemId;
    try {
      final respData = jsonDecode(response.body);
      if (respData != null && respData['id_item'] != null) {
        createdItemId = respData['id_item'];
      }
    } catch (_) {}

    if (createdItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Produk dibuat, tapi gagal dapatkan ID untuk varian')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
      return;
    }

    if (hasVariants) {
      final variantPayload = variants.map((v) {
        String baseSKU = namaController.text
            .trim()
            .toUpperCase()
            .replaceAll(RegExp(r'\s+'), '');
        String sku = v.size.isNotEmpty ? '$baseSKU-${v.size.toUpperCase()}' : baseSKU;
        return {
          'id_item': createdItemId,
          'size': v.size,
          'sku': sku,
          'stock': v.stock,
          'price_adjustment': v.priceAdjustment,
        };
      }).toList();

      final added = await ApiService.addVariants(createdItemId, variantPayload);
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan varian')),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk berhasil diposting')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  void _addVariantFromInput() {
    final size = variantSizeController.text.trim();
    final stock = int.tryParse(variantStockController.text.trim()) ?? -1;
    final adj = int.tryParse(variantPriceAdjustmentController.text.trim()) ?? 0;

    if (stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan stock varian dengan benar')),
      );
      return;
    }

    setState(() {
      variants.add(VariantEntry(size: size, stock: stock, priceAdjustment: adj));
      variantSizeController.clear();
      variantStockController.clear();
      variantPriceAdjustmentController.clear();
    });
  }

  Widget _buildVariantTile(int index) {
    final v = variants[index];
    return ListTile(
      title: Text(
          'Size: ${v.size.isEmpty ? "-" : v.size}  Stock: ${v.stock}  Adj: ${v.priceAdjustment}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.redAccent),
        onPressed: () {
          setState(() {
            variants.removeAt(index);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_idUser == null || _idUser == 0) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Silakan login untuk menambahkan produk',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _getImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blueAccent, width: 1),),

                    child: const Text('+ Tambah Gambar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isLoadingCategories
                        ? null
                        : () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => ListView(
                          children: categories.entries.map((entry) {
                            return ListTile(
                              title: Text(entry.value),
                              onTap: () {
                                setState(() {
                                  selectedCategoryId = entry.key;
                                  selectedCategoryName = entry.value;
                                });
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blueAccent, width: 1),),

                    child: Text(selectedCategoryName ?? 'Pilih Kategori'),
                  ),
                ],
              ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.file(_image!, height: 150),
                ),
              const SizedBox(height: 30),
              const Text('Nama Produk',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: namaController,
                maxLength: 100,
                decoration: _inputDecoration('Masukan Nama Produk'),
              ),
              const SizedBox(height: 20),
              const Text('Deskripsi Produk',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: deskripsiController,
                maxLength: 225,
                maxLines: 3,
                decoration: _inputDecoration('Masukan Deskripsi Produk'),
              ),
              const SizedBox(height: 20),
              const Text('Harga Produk',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Masukan Harga Produk'),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Produk memiliki varian?'),
                value: hasVariants,
                onChanged: (val) {
                  setState(() {
                    hasVariants = val;
                    variants.clear();
                  });
                },
              ),
              if (!hasVariants) ...[
                const Text('Stock Produk',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: stokController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Masukan Stock Produk'),
                ),
                const SizedBox(height: 20),
              ],
              if (hasVariants) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: variantSizeController,
                        decoration: _inputDecoration('Size (optional)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: variantStockController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Stock'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: variantPriceAdjustmentController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Adj'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addVariantFromInput,
                      child: const Text('Tambah Varian'),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Daftar Varian:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (variants.isNotEmpty)
                  Column(
                    children:
                    List.generate(variants.length, (i) => _buildVariantTile(i)),
                  ),
                if (variants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada varian ditambahkan',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
              ],
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: const StadiumBorder(),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                  ),
                  child: const Text(
                    'POST',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }
}
