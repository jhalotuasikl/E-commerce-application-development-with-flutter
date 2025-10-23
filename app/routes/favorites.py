from flask import Blueprint, jsonify, request
from app.db import get_db

favorites_bp = Blueprint('favorites', __name__)

# POST /favorites → Tambah ke favorit
@favorites_bp.route('/favorites', methods=['POST'])
def add_favorites():
    db = get_db()
    data = request.get_json()

    if not data or 'id_user' not in data or 'id_item' not in data:
        return jsonify({"message": "Data tidak lengkap"}), 400

    id_user = data['id_user']
    id_item = data['id_item']

    cursor = db.cursor(dictionary=True)  # pakai dictionary biar hasil JSON enak
    try:
        # Cek duplikasi
        cursor.execute(
            "SELECT * FROM favorites WHERE id_user = %s AND id_item = %s",
            (id_user, id_item),
        )
        existing = cursor.fetchone()
        if existing:
            return jsonify({"message": "Item sudah ada di favorit"}), 400

        # Insert favorit baru
        cursor.execute(
            "INSERT INTO favorites (id_user, id_item) VALUES (%s, %s)",
            (id_user, id_item),
        )
        db.commit()

        # Ambil detail item favorit yang baru dimasukkan
        cursor.execute("""
            SELECT f.id_fav, f.id_user, f.id_item,
                   i.nama_item, i.harga, i.gambar,
                   u.nama_user
            FROM favorites f
            JOIN items i ON f.id_item = i.id_item
            JOIN users u ON f.id_user = u.id_user
            WHERE f.id_user = %s AND f.id_item = %s
        """, (id_user, id_item))
        new_fav = cursor.fetchone()

        return jsonify(new_fav), 201

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"message": "Terjadi kesalahan saat menambahkan ke favorit"}), 500
    finally:
        cursor.close()


# GET /favorites/<id_user> → Tampilkan semua favorit user
@favorites_bp.route('/favorites/<int:id_user>', methods=['GET'])
def get_favorites(id_user):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        query = """
                SELECT 
                items.*, 
                users.nama_user
            FROM items
            JOIN favorites ON items.id_item = favorites.id_item
            JOIN users ON items.id_user = users.id_user
            WHERE favorites.id_user = %s

                """

        cursor.execute(query, (id_user,))
        favorites = cursor.fetchall()
        return jsonify(favorites), 200
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"message": "Gagal mengambil data favorit"}), 500
    finally:
        cursor.close()

# DELETE /favorites/<id_user>/<id_item> → Hapus favorit
@favorites_bp.route('/favorites/<int:id_user>/<int:id_item>', methods=['DELETE'])
def delete_favorite(id_user, id_item):
    db = get_db()
    cursor = db.cursor()

    try:
        cursor.execute("DELETE FROM favorites WHERE id_user = %s AND id_item = %s", (id_user, id_item))
        db.commit()
        if cursor.rowcount == 0:
            return jsonify({"message": "Data tidak ditemukan"}), 404
        return jsonify({"message": "Item berhasil dihapus dari favorit"}), 200
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"message": "Gagal menghapus item dari favorit"}), 500
    finally:
        cursor.close()
