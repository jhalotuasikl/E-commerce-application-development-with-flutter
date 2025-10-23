# routes/profilpage.py
from flask import Blueprint, jsonify
from app.db import get_db # sesuaikan dengan nama file Flask utama kamu

profile_page_bp = Blueprint('profile_page', __name__)

@profile_page_bp.route('/get_users_items/<int:id_user>', methods=['GET'])
def get_users_items(id_user):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    query = "SELECT nama_item, gambar FROM items WHERE id_user = %s"
    cursor.execute(query, (id_user,))
    items = cursor.fetchall()
    cursor.close()

    result = [{'gambar': item['gambar'], 'nama_item': item['nama_item']} for item in items]

    return jsonify(result)
