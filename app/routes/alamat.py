from flask import Blueprint, request, jsonify
from app.db import get_db

alamat_bp = Blueprint('alamat', __name__)

# ========== [POST] Tambah alamat ==========
@alamat_bp.route('/alamat', methods=['POST'])
def tambah_alamat():
    data = request.json
    try:
        db = get_db()
        cursor = db.cursor()

        query = """
        INSERT INTO alamat_users (id_user, label, nama_penerima, no_hp, alamat_lengkap, latitude, longitude, is_default)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        values = (
            data['id_user'],
            data.get('label', 'Alamat Utama'),
            data.get('nama_penerima'),
            data.get('no_hp'),
            data.get('alamat_lengkap'),
            data.get('latitude'),
            data.get('longitude'),
            data.get('is_default', 0)
        )
        cursor.execute(query, values)
        db.commit()

        # response lengkap untuk Flutter
        response_data = {
            "id_alamat": cursor.lastrowid,
            "alamat": data.get('alamat_lengkap'),
            "nama": data.get('nama_penerima'),
            "hp": data.get('no_hp'),
            "label": data.get('label', 'Alamat Utama'),
            "lat": data.get('latitude'),
            "lng": data.get('longitude'),
        }

        return jsonify({
            "success": True,
            "message": "Alamat berhasil ditambahkan",
            "data": response_data
        }), 201

    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# ========== [GET] Ambil semua alamat user ==========
@alamat_bp.route('/alamat/<int:id_user>', methods=['GET'])
def get_alamat_user(id_user):
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)

        cursor.execute("SELECT * FROM alamat_users WHERE id_user = %s", (id_user,))
        result = cursor.fetchall()

        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ========== [PUT] Edit alamat ==========
@alamat_bp.route('/alamat/<int:id_alamat>', methods=['PUT'])
def update_alamat(id_alamat):
    data = request.json
    try:
        db = get_db()
        cursor = db.cursor()

        query = """
        UPDATE alamat_users
        SET label=%s, nama_penerima=%s, no_hp=%s, alamat_lengkap=%s, latitude=%s, longitude=%s, is_default=%s
        WHERE id_alamat=%s
        """
        values = (
            data.get('label'),
            data.get('nama_penerima'),
            data.get('no_hp'),
            data.get('alamat_lengkap'),
            data.get('latitude'),
            data.get('longitude'),
            data.get('is_default', 0),
            id_alamat
        )
        cursor.execute(query, values)
        db.commit()

        return jsonify({"message": "Alamat berhasil diperbarui"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ========== [DELETE] Hapus alamat ==========
@alamat_bp.route('/alamat/<int:id_alamat>', methods=['DELETE'])
def delete_alamat(id_alamat):
    try:
        db = get_db()
        cursor = db.cursor()

        cursor.execute("DELETE FROM alamat_users WHERE id_alamat = %s", (id_alamat,))
        db.commit()

        return jsonify({"message": "Alamat berhasil dihapus"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
