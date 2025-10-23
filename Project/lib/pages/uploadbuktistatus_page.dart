import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_application/api_service.dart';
import 'menungguverifikasidana_page.dart';

class UploadBuktiStatusPage extends StatefulWidget {
  final int idTransaksi;
  final Map<String, dynamic> item;

  const UploadBuktiStatusPage({
    Key? key,
    required this.idTransaksi,
    required this.item,
  }) : super(key: key);

  @override
  State<UploadBuktiStatusPage> createState() => _UploadBuktiStatusPageState();
}

class _UploadBuktiStatusPageState extends State<UploadBuktiStatusPage> {
  File? _image;
  bool _isLoading = false;

  String? _selectedMetode;
  final Map<String, String> _metodePembayaran = {
    "Transfer ATM": "transfer_atm",
    "Dana": "dana",
  };

  final TextEditingController _nomorController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
      print('[UPLOAD STATUS] Gambar dipilih: ${picked.path}');
    } else {
      print('[UPLOAD STATUS] Tidak ada gambar dipilih');
    }
  }

  Future<void> _upload() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar belum dipilih')),
      );
      return;
    }

    if (_selectedMetode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')),
      );
      return;
    }

    if (_nomorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor sesuai metode pembayaran')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // keterangan diisi dengan metode + nomor
    final keterangan =
        "MENCAIRKAN DANA - $_selectedMetode - NOMOR: ${_nomorController.text.trim()}";

    print('[UPLOAD STATUS] Mengirim gambar: ${_image!.path}');
    print('[UPLOAD STATUS] ID Transaksi: ${widget.idTransaksi}');
    print('[UPLOAD STATUS] Keterangan: $keterangan');

    try {
      final response = await ApiService.uploadBuktiCairkanDana(
        idTransaksi: widget.idTransaksi,
        imageFile: _image!,
        keterangan: keterangan,
      );

      setState(() => _isLoading = false);

      if (response != null && response['id_pencairan'] != null) {
        final idPencairan = response['id_pencairan'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti Berhasil Diunggah')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MenungguVerifikasiDanaPage(
              idTransaksi: widget.idTransaksi,
              idPencairan: idPencairan,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan ID pencairan')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('[UPLOAD STATUS] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunggah bukti')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final int jumlah = item['jumlah'] ?? 1;

    return Scaffold(
      backgroundColor: Colors.white54,
      appBar: AppBar(
        title: const Text('Upload Bukti Konfirmasi Pembeli'),
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                Image.file(_image!, height: 250)
              else
                const Text(
                  "Belum ada gambar",
                  style: TextStyle(color: Colors.black),
                ),
              const SizedBox(height: 20),
              Text("Jumlah: $jumlah", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedMetode,
                decoration: InputDecoration(
                  labelText: "Metode Pembayaran",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _metodePembayaran.entries
                    .map((entry) => DropdownMenuItem(
                  value: entry.value,
                  child: Text(entry.key),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMetode = value;
                    _nomorController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),

              // input nomor sesuai metode
              if (_selectedMetode != null)
                TextField(
                  controller: _nomorController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _selectedMetode == "dana"
                        ? "Masukkan Nomor Dana"
                        : "Masukkan Nomor Rekening",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Pilih Gambar"),
              ),
              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Mengajukan Pencairan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
