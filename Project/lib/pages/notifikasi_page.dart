import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_application/pages/component/custombottom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/uploadbuktistatus_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({Key? key}) : super(key: key);

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  int _selectedIndex = 4; // default Notifikasi
  int? _idUser;

  // simpan jumlah notif & favorit
  int _notifCount = 0;
  int _favoriteCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndLoadUser();
  }

  Future<void> _checkAndLoadUser() async {
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
    });

    await _loadCounts();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCounts() async {
    if (_idUser == null) return;

    final pembeliNotif = await ApiService.getNotificationsForBuyer(_idUser!);
    final penjualNotif = await ApiService.getNotificationsForSeller(_idUser!);
    final favorites = await ApiService.getFavorites(_idUser!);

    setState(() {
      _notifCount = (pembeliNotif?.length ?? 0) + (penjualNotif?.length ?? 0);
      _favoriteCount = favorites?.length ?? 0;
    });
  }

  List<Widget> _actionButtons(dynamic notif, String role) {
    final statusPesanan = notif['status_pesanan'];
    final statusPencairan = notif['status_pencairan']; // dari API join
    final idTransaksi = notif['id_transaksi'];
    List<Widget> buttons = [];

    if (role == "penjual") {
      switch (statusPesanan) {
        case "pending":
          buttons.add(ElevatedButton(
            onPressed: () => _updateStatus(idTransaksi, "diproses"),
            style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // warna teks putih
            backgroundColor: Colors.blueAccent,
            ),// opsional, warna tombol
            child: const Text("Proses"),
          ));
          break;
        case "diproses":
          buttons.add(ElevatedButton(
            onPressed: () => _updateStatus(idTransaksi, "dikirim"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // warna teks putih
              backgroundColor: Colors.blueAccent,
            ),// opsional, warna tombol
            child: const Text("Kirim"),
          ));
          break;
        case "selesai":
          if (statusPencairan == null || statusPencairan == "pending") {
            buttons.add(ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadBuktiStatusPage(
                      idTransaksi: idTransaksi,
                      item: notif,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text(
                "Cairkan Dana",
                style: TextStyle(color: Colors.white),
              ),
            ));
          } else if (statusPencairan == "dicairkan") {
            buttons.add(const Text(
              "Dana berhasil dicairkan",
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ));
          }
          break;
      }
    } else {
      switch (statusPesanan) {
        case "dikirim":
          buttons.add(ElevatedButton(
            onPressed: () => _updateStatus(idTransaksi, "selesai"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // warna teks putih
              backgroundColor: Colors.blueAccent,
            ),// opsional, warna tombol
            child: const Text("Terima"),
          ));
          break;
        case "pending":
          buttons.add(ElevatedButton(
            onPressed: () => _updateStatus(idTransaksi, "dibatalkan"),

            child: const Text("Batalkan"),
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent),

          ));
          break;
      }
    }

    return buttons;
  }

  Future<void> _updateStatus(int idTransaksi, String newStatus) async {
    final success = await ApiService.updateStatusPesanan(idTransaksi, newStatus);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status berhasil diupdate ke $newStatus")),
      );
      _loadCounts();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal update status")),
      );
    }
  }

  Widget _buildNotificationList(String role) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_idUser == null || _idUser == 0) {
      return const Center(
        child: Text(
          'Silakan login untuk melihat notifikasi',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: role == "pembeli"
          ? ApiService.getNotificationsForBuyer(_idUser!)
          : ApiService.getNotificationsForSeller(_idUser!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Belum ada notifikasi"));
        }

        final data = snapshot.data!;

        data.sort((a, b) {
          final aTime = DateTime.tryParse(a['created_at'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = DateTime.tryParse(b['created_at'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        return RefreshIndicator(
          onRefresh: _loadCounts,
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final notif = data[index];
              final namaItem = notif['nama_item'] ?? "";
              final dari = notif['from'] ?? "";
              final status = notif['status_pesanan'];

              final createdAt = notif['created_at'];
              final updatedAt = notif['updated_at'];

              final createdTime = (createdAt != null && createdAt.toString().isNotEmpty)
                  ? DateFormat("dd MMM yyyy, HH:mm")
                  .format(DateTime.tryParse(createdAt) ??
                  DateTime.fromMillisecondsSinceEpoch(0))
                  : "-";

              String? updatedTime;
              if (updatedAt != null &&
                  updatedAt != createdAt &&
                  updatedAt.toString().isNotEmpty) {
                updatedTime = DateFormat("dd MMM yyyy, HH:mm")
                    .format(DateTime.tryParse(updatedAt) ??
                    DateTime.fromMillisecondsSinceEpoch(0));
              }

              return Dismissible(
                key: Key(notif['id_notifikasi'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Konfirmasi"),
                        content: const Text(
                            "Apakah Anda ingin menghapus notifikasi ini?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Tidak"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            child: const Text("Ya"),
                          ),
                        ],
                      );
                    },
                  );
                  return confirm ?? false;
                },
                onDismissed: (direction) async {
                  final success = await ApiService.deleteNotification(
                      notif['id_notifikasi']);
                  if (success) {
                    setState(() {
                      data.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Notifikasi berhasil dihapus")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal menghapus notifikasi")),
                    );
                  }
                },
                child: Card(
                  color: Colors.white,
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blueAccent, width: 0.5)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.notifications,
                              color: Colors.blueAccent),
                          title: Text(
                            role == "pembeli"
                                ? "$namaItem dari $dari → ${status.toUpperCase()}"
                                : "$namaItem kepada $dari → ${status.toUpperCase()}",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Dibuat: $createdTime"),
                              if (updatedTime != null)
                                Text(
                                  "Diupdate: $updatedTime",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.blueGrey),
                                ),
                              if (role == "penjual" && notif['alamat'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Penerima: ${notif['alamat']['nama_penerima']}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        "No HP: ${notif['alamat']['no_hp']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        "Alamat: ${notif['alamat']['alamat_lengkap']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (notif['pengiriman'] != null &&
                                          notif['pengiriman'].toString().isNotEmpty)
                                        Text(
                                          "Pengiriman: ${notif['pengiriman']}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      Text(
                                        "Metode Bayar: ${notif['metode_pembayaran'] ?? '-'}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _actionButtons(notif, role),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Notifikasi",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Pembeli"),
              Tab(text: "Penjual"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList("pembeli"),
            _buildNotificationList("penjual"),
          ],
        ),
      ),
    );
  }
}
