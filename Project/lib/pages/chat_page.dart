import 'package:flutter/material.dart';
import 'package:project_application/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class ChatPage extends StatefulWidget {
  final int idPengirim;
  final int idPenerima;
  final String namaPenerima;

  const ChatPage({
    Key? key,
    required this.idPengirim,
    required this.idPenerima,
    required this.namaPenerima,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}
String _formatTimestamp(String timestamp) {
  try {
    DateTime dt = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (e) {
    return timestamp; // fallback kalau format DB tidak sesuai
  }
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> messages = [];
  TextEditingController _controller = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }Future<void> fetchMessages() async {
    setState(() => isLoading = true);
    final data = await ApiService.getChat(widget.idPengirim, widget.idPenerima);
    print("DEBUG Chat: $data");
    setState(() {
      messages = data ?? [];
      isLoading = false;
    });
  }Future<void> sendMessage() async {
    if (_controller.text.trim().isNotEmpty) {
      bool success = await ApiService.sendChat(
          widget.idPengirim, widget.idPenerima, _controller.text.trim());
      if (success) {
        _controller.clear();
        fetchMessages();
      }
    }
  }Future<void> markMessageAsRead(int idChat) async {
    await ApiService.markAsRead(idChat);
    fetchMessages();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.namaPenerima),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['id_pengirim'] == widget.idPengirim;
                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (!isMe && msg['status'] != 'dibaca') {
                        markMessageAsRead(msg['id_chat']);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blueAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['pesan'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(msg['timestamp']),
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ketik pesan...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
