import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/pages/logout_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _nama = '';
  String _nomorTelepon = '';
  int? _idUser;
  List<Map<String, dynamic>> _profileItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndLoadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadProfile(); // refresh data saat kembali ke halaman ini
  }

  Future<void> _checkAndLoadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');

    if (idUser == null || idUser == 0) {
      // User belum login
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _idUser = idUser;
      _nama = prefs.getString('nama_user') ?? 'User';
      _nomorTelepon = prefs.getString('nomor_telepon') ?? '-';
    });

    // Ambil postingan user berdasarkan ID
    try {
      final items = await ApiService.getProfileItems(idUser.toString());
      setState(() {
        _profileItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Gagal memuat profile items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_idUser == null || _idUser == 0) {
      return const Center(
        child: Text(
          'Silakan login untuk melihat profil',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 10),
                Text(
                  _nama,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  _nomorTelepon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const LogoutPage(),
                    );
                  },
                  child: const Icon(Icons.settings, size: 24),
                ),
                const SizedBox(height: 20),
                const Text(
                  'My Post',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(_profileItems.length, (index) {
                      final item = _profileItems[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            item['gambar'] != null && item['gambar'] != ''
                                ? Image.network(
                              '${ApiService.baseUrl}${item['gambar']}',
                              height: 80,
                              fit: BoxFit.cover,
                            )
                                : const Icon(Icons.image_not_supported, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              item['nama_item'] ?? '',
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
