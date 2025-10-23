import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_application/api_service.dart';
import 'package:project_application/pages/chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  int _idUser = 0;
  List<Map<String, dynamic>> chatList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user') ?? 0;

    // panggil API untuk ambil daftar percakapan
    final data = await ApiService.getChatList(idUser);
    print("DEBUG chat list: $data");

    setState(() {
      _idUser = idUser;
      chatList = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : chatList.isEmpty
            ? const Center(child: Text("Belum ada percakapan"))
            : ListView.builder(
          itemCount: chatList.length,
          itemBuilder: (context, index) {
            final chat = chatList[index];
            if (chat['chat_partner'] == null) return const SizedBox.shrink();

            final idPenerima = chat['chat_partner'] is int
                ? chat['chat_partner']
                : int.parse(chat['chat_partner'].toString());
            final namaPenerima = chat['nama_penerima']?.toString() ?? "Unknown";
            final pesanTerakhir = chat['pesan_terakhir']?.toString() ?? "";

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(namaPenerima),
              subtitle: Text(pesanTerakhir),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      idPengirim: _idUser,
                      idPenerima: idPenerima,
                      namaPenerima: namaPenerima,
                    ),
                  ),
                );
              },
            );
          },
        ),
    );
  }
}
