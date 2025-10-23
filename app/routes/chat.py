# app/routes/chat.py
from flask import Blueprint, request, jsonify
from app.db import get_db
from datetime import datetime

chat_bp = Blueprint('chat', __name__)

# --- Kirim pesan ---
@chat_bp.route('/chat/send', methods=['POST'])
def send_message():
    data = request.get_json()
    required_fields = ['id_pengirim', 'id_penerima', 'pesan']
    if not all(field in data for field in required_fields):
        return jsonify({"message": "Data tidak lengkap"}), 400

    db = get_db()
    cursor = db.cursor()
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    cursor.execute(
        "INSERT INTO chat_messages (id_pengirim, id_penerima, pesan, timestamp, status) "
        "VALUES (%s, %s, %s, %s, %s)",
        (data['id_pengirim'], data['id_penerima'], data['pesan'], now, 'terkirim')
    )
    db.commit()
    return jsonify({"message": "Pesan terkirim"}), 201

# --- Ambil chat antara 2 user ---
@chat_bp.route('/chat/<int:id_pengirim>/<int:id_penerima>', methods=['GET'])
def get_chat(id_pengirim, id_penerima):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT * FROM chat_messages WHERE "
        "(id_pengirim=%s AND id_penerima=%s) OR "
        "(id_pengirim=%s AND id_penerima=%s) "
        "ORDER BY timestamp ASC",
        (id_pengirim, id_penerima, id_penerima, id_pengirim)
    )
    chats = cursor.fetchall()
    print("DEBUG get_chat:", chats)
    return jsonify(chats)

# --- Update status pesan menjadi 'dibaca' ---
@chat_bp.route('/chat/read/<int:id_chat>', methods=['PUT'])
def mark_as_read(id_chat):
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "UPDATE chat_messages SET status='dibaca' WHERE id_chat=%s",
        (id_chat,)
    )
    db.commit()
    return jsonify({"message": "Pesan sudah dibaca"}), 200

# --- Hapus pesan ---
@chat_bp.route('/chat/delete/<int:id_chat>', methods=['DELETE'])
def delete_message(id_chat):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM chat_messages WHERE id_chat=%s", (id_chat,))
    db.commit()
    return jsonify({"message": "Pesan dihapus"}), 200

# --- Tampilkan list chat ---
@chat_bp.route('/chat_list/<int:id_user>', methods=['GET'])
def get_chat_list(id_user):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        # Ambil chat partner dan pesan terakhir dengan nama
        cursor.execute("""
            SELECT
                c.chat_partner,
                u.nama_user AS nama_penerima,
                cm.pesan AS pesan_terakhir
            FROM (
                SELECT DISTINCT
                    CASE
                        WHEN id_pengirim = %s THEN id_penerima
                        ELSE id_pengirim
                    END AS chat_partner
                FROM chat_messages
                WHERE id_pengirim = %s OR id_penerima = %s
            ) AS c
            LEFT JOIN users u ON u.id_user = c.chat_partner
            LEFT JOIN chat_messages cm ON cm.id_chat = (
                SELECT id_chat
                FROM chat_messages
                WHERE (id_pengirim=%s AND id_penerima=c.chat_partner)
                   OR (id_pengirim=c.chat_partner AND id_penerima=%s)
                ORDER BY timestamp DESC
                LIMIT 1
            )
            ORDER BY cm.timestamp DESC
        """, (id_user, id_user, id_user, id_user, id_user))

        chat_list = cursor.fetchall()
        print("DEBUG chat_list:", chat_list)  
    except Exception as e:
        print("ERROR get_chat_list:", e)
        chat_list = []

    return jsonify(chat_list), 200
