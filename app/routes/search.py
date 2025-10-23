from flask import Blueprint, jsonify
from app.db import get_db

search_bp = Blueprint('search', __name__)

@search_bp.route('/search/<string:keyword>', methods=['GET'])
def search_items(keyword):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        query = """
            SELECT 
                items.*, 
                users.nama_user
            FROM items
            JOIN users ON items.id_user = users.id_user
            WHERE items.nama_item LIKE %s OR items.deskripsi LIKE %s
        """
        wildcard = f"%{keyword}%"
        cursor.execute(query, (wildcard, wildcard))
        results = cursor.fetchall()

        return jsonify(results), 200
    except Exception as e:
        print(f"Search Error: {e}")
        return jsonify({"message": "Terjadi kesalahan saat mencari"}), 500
    finally:
        cursor.close()
