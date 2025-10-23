import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'maps_picker.dart';
import 'package:project_application/api_service.dart';

class AddAlamatPage extends StatefulWidget {
  const AddAlamatPage({super.key});

  @override
  State<AddAlamatPage> createState() => _AddAlamatPageState();
}

class _AddAlamatPageState extends State<AddAlamatPage> {
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  double? _latitude;
  double? _longitude;
  int? _idUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');
    setState(() {
      _idUser = idUser;
    });
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapsPicker()),
    );

    if (picked != null && picked is Map<String, double>) {
      setState(() {
        _latitude = picked["lat"];
        _longitude = picked["lng"];
      });
    }
  }

  Future<void> _saveAlamat() async {
    if (_formKey.currentState!.validate()) {
      if (_idUser == null) return;

      final response = await ApiService.tambahAlamat(
        idUser: _idUser!,
        label: _labelController.text.isEmpty ? "Alamat Utama" : _labelController.text,
        namaPenerima: _namaController.text,
        noHp: _hpController.text,
        alamatLengkap: _alamatController.text,
        latitude: _latitude,
        longitude: _longitude,
        isDefault: 1,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Alamat berhasil ditambahkan")),
        );

        // Pastikan 'data' ada di response
        final data = response['data'] ?? {};

        final alamatBaru = {
          'id_alamat': data['id_alamat'] ?? 0, // default 0 jika null
          'alamat': data['alamat'] ?? _alamatController.text,
          'nama': data['nama'] ?? _namaController.text,
          'hp': data['hp'] ?? _hpController.text,
          'label': data['label'] ?? (_labelController.text.isEmpty ? "Alamat Utama" : _labelController.text),
          'lat': data['lat'] ?? _latitude,
          'lng': data['lng'] ?? _longitude,
        };

        Navigator.pop(context, alamatBaru);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Gagal menambahkan alamat")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Alamat")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Penerima"),
                validator: (val) => val!.isEmpty ? "Harus diisi" : null,
              ),
              TextFormField(
                controller: _hpController,
                decoration: const InputDecoration(labelText: "Nomor HP"),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? "Harus diisi" : null,
              ),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: "Alamat Lengkap"),
                maxLines: 2,
                validator: (val) => val!.isEmpty ? "Harus diisi" : null,
              ),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                    labelText: "Label (Opsional, ex: Rumah/Kantor)"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map),
                    label: const Text("Pilih Lokasi di Maps"),
                  ),
                  const SizedBox(width: 10),
                  if (_latitude != null && _longitude != null)
                    Expanded(
                      child: Text(
                        "Lokasi: ($_latitude, $_longitude)",
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAlamat,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Simpan Alamat"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
