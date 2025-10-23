import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/struktransaksi_page.dart';
import 'package:project_application/pages/menungguVerifikasi_page.dart';

class UploadBuktiPage extends StatefulWidget {
  final int idTransaksi;
  final Map<String, dynamic> item;

  const UploadBuktiPage({
    Key? key,
    required this.idTransaksi,
    required this.item,
  }) : super(key: key);

  @override
  State<UploadBuktiPage> createState() => _UploadBuktiPageState();
}

class _UploadBuktiPageState extends State<UploadBuktiPage> {
  File? _image;

  @override
  void initState() {
    super.initState();
    print('[UPLOAD PAGE] Dibuka. ID Transaksi: ${widget.idTransaksi}');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
      print('[UPLOAD] Gambar dipilih: ${picked.path}');
    } else {
      print('[UPLOAD] Tidak ada gambar dipilih');
    }
  }

  Future<void> _upload() async {
    if (_image == null) {
      print('[UPLOAD] Gambar belum dipilih!');
      return;
    }

    print('[UPLOAD] Mengirim gambar: ${_image!.path}');
    print('[UPLOAD] Untuk ID Transaksi: ${widget.idTransaksi}');

    final success = await ApiService.uploadBuktiTransfer(
      idTransaksi: widget.idTransaksi,
      imageFile: _image!,
    );

    if (success) {
      print('[UPLOAD] Berhasil kirim ke server!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti berhasil diunggah')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenungguVerifikasiPage(
            idTransaksi: widget.idTransaksi,
            item: widget.item,
          ),
        ),
      );
    } else {
      print('[UPLOAD] Gagal kirim ke server!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunggah bukti')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final String? size = item['size'];
    final int jumlah = item['jumlah'] ?? 1;

    return Scaffold(
      backgroundColor: Colors.white54,
      appBar: AppBar(
        title: const Text('Upload Bukti Transfer'),
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
                const Text("Belum ada gambar", style: TextStyle(color: Colors.black)),

              const SizedBox(height: 20),

              if (size != null)
                Text("Ukuran: $size", style: const TextStyle(fontSize: 16)),
              Text("Jumlah: $jumlah", style: const TextStyle(fontSize: 16)),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Pilih Gambar"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Kirim Bukti Transfer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
