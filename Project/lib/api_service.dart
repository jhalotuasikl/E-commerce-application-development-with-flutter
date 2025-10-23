  import 'dart:convert';
  import 'dart:io';
  import 'package:http/http.dart' as http;
  import 'package:path/path.dart';

  class ApiService {
    static const String baseUrl = 'http://10.0.2.2:5000'; // Ganti dengan IP lokal jika perlu
    static const int feeAdmin = 500;

  /// LOGIN USER
  static Future<Map<String, dynamic>?> login(String email,
      String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          print('Login sukses. Data user: ${data['data']}');
          return data['data'];
        } else {
          print('Login gagal: ${data['message']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          print('Error: ${errorData['message']}');
        } catch (e) {
          print('Tidak bisa decode error JSON: $e');
        }
        return null;
      }
    } catch (e) {
      print('Error jaringan saat login: $e');
      return null;
    }
  }

  /// REGISTER USER
  static Future<bool> register(String namaUser, String email,
      String nomorTelepon, String password) async {
    try {
      final url = Uri.parse('$baseUrl/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_user': namaUser.trim(),
          'email': email.trim(),
          'nomor_telepon': nomorTelepon.trim(),
          'password': password.trim(),
          'status': 'aktif',
          'id_admin': 1,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Register sukses: ${data['message']}');
        return true;
      } else {
        final data = jsonDecode(response.body);
        print('Register gagal: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('Error jaringan saat register: $e');
      return false;
    }
  }

  /// GET list Categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final url = Uri.parse('$baseUrl/categories');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List data = responseData['categories'];

        return data
            .map((item) =>
        {
          'id_kategori': item['id_kategori'],
          'nama_kategori': item['nama_kategori'],
        })
            .toList();
      } else {
        print('Gagal mendapatkan kategori. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error saat get kategori: $e');
      return [];
    }
  }

  /// UPLOAD ITEM DENGAN GAMBAR
  static Future<bool> uploadItem({
    required String namaItem,
    required String deskripsi,
    required String harga,
    required String idUser,
    required String idKategori,
    required File foto,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/items');
      final request = http.MultipartRequest('POST', uri);

      request.fields['nama_item'] = namaItem;
      request.fields['deskripsi'] = deskripsi;
      request.fields['harga'] = harga;
      request.fields['id_user'] = idUser;
      request.fields['id_kategori'] = idKategori;
      request.fields['status'] = 'tersedia';

      final fotoStream = await http.MultipartFile.fromPath(
        'gambar',
        foto.path,
        filename: basename(foto.path),
      );
      request.files.add(fotoStream);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Item berhasil diupload: ${response.body}');
        return true;
      } else {
        print('Gagal upload item. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saat upload item: $e');
      return false;
    }
  }

  /// GET ITEMS UNTUK PROFILE PAGE
  static Future<List<Map<String, dynamic>>> getProfileItems(
      String idUser) async {
    try {
      final url = Uri.parse('$baseUrl/get_users_items/$idUser');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);

        return items
            .map((item) =>
        {
          'gambar': item['gambar'],
          'nama_item': item['nama_item'],
        })
            .toList();
      } else {
        print('Gagal ambil item profil. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error saat ambil item profil: $e');
      return [];
    }
  }

  /// GET ALL ITEMS BUY PAGES WITH VARIANTS
  static Future<List<Map<String, dynamic>>> getAllItemsExcludeUser(
      String idUser) async {
    try {
      final url = Uri.parse('$baseUrl/items_exclude_user/$idUser');
      final response = await http.get(url);


      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);

        // Loop semua item, tambahkan fetch varian
        List<Map<String, dynamic>> result = [];
        for (var item in items) {
          // Fetch varian per item
          final idItem = item['id_item'];
          final variants = await getVariants(
              idItem); // pastikan getVariants sudah ada

          result.add({
            'id_item': item['id_item'],
            'nama_item': item['nama_item'],
            'deskripsi': item['deskripsi'],
            'harga': item['harga'],
            'gambar': item['gambar'],
            'id_user': item['id_user'],
            'id_kategori': item['id_kategori'],
            'status': item['status'],
            'nama_user': item['nama_user'],
            'variants': variants, // <-- tambahkan varian
          });
        }

        return result;
      } else {
        print('Gagal ambil semua item kecuali milik user. Status: ${response
            .statusCode}');
        return [];
      }
    } catch (e) {
      print('Error saat ambil semua item: $e');
      return [];
    }
  }


  /// ADD TO FAVORITE
  static Future<bool> addfavorites(int idUser, int idItem) async {
    try {
      final url = Uri.parse('$baseUrl/favorites');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': idUser,
          'id_item': idItem,
        }),
      );

      if (response.statusCode == 201) {
        print('Berhasil menambahkan ke favorit.');
        return true;
      } else if (response.statusCode == 400) {
        print('Item sudah ada di favorit.');
        return false;
      } else {
        print(
            'Gagal menambahkan ke favorit. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error saat add to favorite: $e');
      return false;
    }
  }

  /// GET FAVORITES
  static Future<List<dynamic>> getFavorites(int idUser) async {
    try {
      final url = Uri.parse('$baseUrl/favorites/$idUser');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print(
            'Gagal mendapatkan daftar favorit. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error saat ambil favorit: $e');
      return [];
    }
  }

  /// DELETE FAVORITE
  static Future<bool> deleteFavorite(int idUser, int idItem) async {
    try {
      final url = Uri.parse('$baseUrl/favorites/$idUser/$idItem');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print('Favorit berhasil dihapus.');
        return true;
      } else {
        print('Gagal menghapus favorit. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error saat hapus favorit: $e');
      return false;
    }
  }

  /// CREATE TRANSAKSI / PEMBAYARAN - KEMBALIKAN ID TRANSAKSI (single-item, legacy)
  static Future<int?> createTransaksi({
    required int idItem,
    required int idPenjual,
    required int idPembeli,
    required int hargaAsli,
    required int hargaTotal,
    required String metodePembayaran,
    required String pengiriman, // ✅ ditambah
  }) async {
    try {
      final url = Uri.parse('$baseUrl/transaksi');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_item': idItem,
          'id_penjual': idPenjual,
          'id_pembeli': idPembeli,
          'harga_asli': hargaAsli,
          'harga_total': hargaTotal,
          'metode_pembayaran': metodePembayaran,
          'pengiriman': pengiriman, // ✅ ikut dikirim
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final idTransaksi = data['id_transaksi'];
        print('Transaksi berhasil. ID: $idTransaksi');
        return idTransaksi;
      } else {
        print('Gagal membuat transaksi. Status: ${response.statusCode}');
        print('Respon: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error saat membuat transaksi: $e');
      return null;
    }
  }

    /// CREATE TRANSAKSI MULTI-ITEM - KEMBALIKAN ID TRANSAKSI
    static Future<int?> createTransaksiMulti({
      required List<Map<String, dynamic>> items, // {'sku'/'id_item': '...', 'quantity': n, 'adj': m}
      required int idPenjual,
      required int idPembeli,
      required int idAlamat,
      required String metodePembayaran,
      required String pengiriman,
    }) async {
      try {
        final url = Uri.parse('$baseUrl/transaksi');

        final payload = {
          'items': items.map((item) {
            final Map<String, dynamic> data = {
              'quantity': item['quantity'],
              'adj': item['adj'] ?? 0,
            };
            if (item.containsKey('sku') && item['sku'] != null && item['sku'].toString().isNotEmpty) {
              data['sku'] = item['sku'];
            } else if (item.containsKey('id_item') && item['id_item'] != null) {
              data['id_item'] = item['id_item'];
            }
            return data;
          }).toList(),
          'id_penjual': idPenjual,
          'id_pembeli': idPembeli,
          'id_alamat': idAlamat,
          'metode_pembayaran': metodePembayaran,
          'pengiriman': pengiriman,
        };

        print('DEBUG Payload createTransaksiMulti: $payload'); // debug

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final idTransaksi = data['id_transaksi'];
          print('Transaksi multi-item berhasil. ID: $idTransaksi');
          return idTransaksi;
        } else {
          print('Gagal membuat transaksi. Status: ${response.statusCode}');
          print('Respon: ${response.body}');
          return null;
        }
      } catch (e) {
        print('Error saat membuat transaksi multi-item: $e');
        return null;
      }
    }



    /// Tambah varian ke item
  static Future<bool> addVariants(int idItem,
      List<Map<String, dynamic>> variants) async {
    try {
      final url = Uri.parse('$baseUrl/items/$idItem/variants');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'variants': variants}),
      );

      if (response.statusCode == 201) {
        print('Variants berhasil ditambahkan');
        return true;
      } else {
        print('Gagal tambah variants: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saat tambah variants: $e');
      return false;
    }
  }

  /// Ambil varian untuk suatu item
  static Future<List<dynamic>> getVariants(int idItem) async {
    try {
      final url = Uri.parse('$baseUrl/items/$idItem/variants');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Gagal ambil variants: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error ambil variants: $e');
      return [];
    }
  }

  /// WHATSAPP NOTIFIKASI
  static Future<Map<String, dynamic>> kirimWhatsapp(String nomor,
      String pesan) async {
    final url = Uri.parse('$baseUrl/whatsapp');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nomor": nomor,
        "pesan": pesan,
      }),
    );

    return jsonDecode(response.body);
  }

  /// SEARCH
  static Future<List<dynamic>> searchItems(String keyword) async {
    final response = await http.get(Uri.parse('$baseUrl/search/$keyword'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mencari item');
    }
  }

  /// Upload bukti transfer
  static Future<bool> uploadBuktiTransfer({
    required int idTransaksi,
    required File imageFile,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/upload_bukti'); // ✅ Gunakan baseUrl
      var request = http.MultipartRequest('POST', uri);

      request.fields['id_transaksi'] = idTransaksi.toString();
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_transfer',
        imageFile.path,
        filename: basename(imageFile.path),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[UPLOAD BUKTI] Status Code: ${response.statusCode}');
      print('[UPLOAD BUKTI] Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Upload Error: $e');
      return false;
    }
  }

  /// detail transaksi (menyesuaikan struktur baru: header + items)
  static Future<Map<String, dynamic>?> getDetailTransaksi(
      int idTransaksi) async {
    try {
      final url = Uri.parse('$baseUrl/transaksi/$idTransaksi');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // sekarang ada 'header' dan 'items'
        return data;
      } else {
        print('Gagal ambil detail transaksi: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error ambil detail transaksi: $e');
      return null;
    }
  }

  /// tunggu verivikasi
  static Future<String?> cekStatusTransaksi(int idTransaksi) async {
    final url = Uri.parse('$baseUrl/status_transaksi/$idTransaksi');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      return null;
    }
  }


  // ========== NOTIFIKASI ==========

  // Get notifications untuk pembeli
  static Future<List<dynamic>> getNotificationsForBuyer(int idUser) async {
    final url = Uri.parse('$baseUrl/transaksi/notifikasi/pembeli/$idUser');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'] ?? [];
    } else {
      print('Gagal load notifikasi pembeli: ${response.body}');
      return [];
    }
  }

  // Get notifications untuk penjual
  static Future<List<dynamic>> getNotificationsForSeller(int idUser) async {
    final url = Uri.parse('$baseUrl/transaksi/notifikasi/penjual/$idUser');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'] ?? [];
    } else {
      print('Gagal load notifikasi penjual: ${response.body}');
      return [];
    }
  }

  // Delete notification
  static Future<bool> deleteNotification(int idNotifikasi) async {
    final url = Uri.parse('$baseUrl/transaksi/notifikasi/$idNotifikasi');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Gagal hapus notifikasi: ${response.body}');
      return false;
    }
  }


  static Future<bool> updateStatusPesanan(int idTransaksi,
      String status) async {
    try {
      final url = Uri.parse(
          '$baseUrl/transaksi/$idTransaksi/status'); // sesuaikan dengan Flask
      final response = await http.put(
        url, // gunakan PUT
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "status_pesanan": status, // key harus sama dengan Flask
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            'Gagal update status: ${response.statusCode} => ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error update status: $e');
      return false;
    }
  }


  /// UPLOAD BUKTI STATUS CAIRKAN DANA
  /// UPLOAD BUKTI STATUS CAIRKAN DANA
  static Future<Map<String, dynamic>?> uploadBuktiCairkanDana({
    required int idTransaksi,
    required File imageFile,
    String keterangan = "", // isi dengan metode kalau perlu
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/admin/upload_bukti_cairkan");
      var request = http.MultipartRequest('POST', uri);

      // Field wajib sesuai backend
      request.fields['id_transaksi'] = idTransaksi.toString();
      request.fields['keterangan'] = keterangan;

      // File bukti
      var multipartFile = await http.MultipartFile.fromPath(
        'bukti', // HARUS 'bukti'
        imageFile.path,
        filename: basename(imageFile.path),
      );
      request.files.add(multipartFile);

      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        print("[UPLOAD STATUS] Berhasil: $respStr");
        return jsonDecode(respStr); // kembalikan data JSON
      } else {
        print("[UPLOAD STATUS] Gagal: ${response.statusCode} - $respStr");
        return null;
      }
    } catch (e) {
      print("[UPLOAD STATUS] Error: $e");
      return null;
    }
  }


  /// CEK STATUS PENCAIRAN
  static Future<String> getCairDanaStatus(int idPencairan) async {
    try {
      final uri = Uri.parse("$baseUrl/admin/pencairan_status")
          .replace(queryParameters: {'id_pencairan': idPencairan.toString()});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status']; // misal: menunggu / diverifikasi / dicairkan
      } else {
        print("[STATUS CAIR] Gagal: ${response.statusCode}");
        return "error";
      }
    } catch (e) {
      print("[STATUS CAIR] Error: $e");
      return "error";
    }
  }


  ///CHAT
  static Future<List<dynamic>?> getChat(int idPengirim, int idPenerima) async {
    final response = await http.get(
        Uri.parse("$baseUrl/chat/$idPengirim/$idPenerima"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // --- Kirim pesan ---
  static Future<bool> sendChat(int idPengirim, int idPenerima,
      String pesan) async {
    final response = await http.post(
      Uri.parse("$baseUrl/chat/send"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_pengirim': idPengirim,
        'id_penerima': idPenerima,
        'pesan': pesan,
      }),
    );
    return response.statusCode == 201;
  }

  // --- Tandai pesan sudah dibaca ---
  static Future<bool> markAsRead(int idChat) async {
    final response = await http.put(Uri.parse("$baseUrl/chat/read/$idChat"));
    return response.statusCode == 200;
  }

  // --- Hapus pesan ---
  static Future<bool> deleteChat(int idChat) async {
    final response = await http.delete(
        Uri.parse("$baseUrl/chat/delete/$idChat"));
    return response.statusCode == 200;
  }

  // GET LIST CHAT (percakapan terakhir dengan setiap user)
  static Future<List<Map<String, dynamic>>> getChatList(int idUser) async {
    try {
      final url = Uri.parse('$baseUrl/chat_list/$idUser');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((chat) =>
        {
          'chat_partner': chat['chat_partner'], // <-- pakai ini
          'nama_penerima': chat['nama_penerima'],
          'pesan_terakhir': chat['pesan_terakhir'],
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error getChatList: $e");
      return [];
    }
  }


  /// GET PRODUCTS BY USER
  static Future<List<Map<String, dynamic>>> getProductsByUser(
      int idUser) async {
    try {
      final url = Uri.parse('$baseUrl/items_by_user/$idUser');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        return items.map((item) =>
        {
          'id_item': item['id_item'],
          'nama_item': item['nama_item'],
          'deskripsi': item['deskripsi'],
          'harga': item['harga'],
          'gambar': item['gambar'],
          'id_user': item['id_user'],
          'id_kategori': item['id_kategori'],
          'status': item['status'],
          'nama_user': item['nama_user'],
        }).toList();
      } else {
        print('Gagal ambil produk user. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error saat ambil produk user: $e');
      return [];
    }
  }

  ///ALAMAT
  static Future<Map<String, dynamic>> tambahAlamat({
    required int idUser,
    required String label,
    required String namaPenerima,
    required String noHp,
    required String alamatLengkap,
    double? latitude,
    double? longitude,
    int isDefault = 0,
  }) async {
    final url = Uri.parse("$baseUrl/alamat");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_user": idUser,
          "label": label,
          "nama_penerima": namaPenerima,
          "no_hp": noHp,
          "alamat_lengkap": alamatLengkap,
          "latitude": latitude,
          "longitude": longitude,
          "is_default": isDefault,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // kembalikan data lengkap dari response['data']
        return {
          "success": true,
          "message": data['message'] ?? "Alamat berhasil ditambahkan",
          "data": data['data'] ?? {},
          // <-- penting agar Flutter bisa akses data['id_alamat']
        };
      } else {
        return {
          "success": false,
          "message": "Gagal menambahkan alamat: ${response.body}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Terjadi kesalahan: $e",
      };
    }
  }
}





