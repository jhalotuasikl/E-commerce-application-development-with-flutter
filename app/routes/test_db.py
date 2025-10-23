# app/routes/test_db.py
from flask import Blueprint, jsonify
from app.db import get_db

test_db_bp = Blueprint('test_db', __name__)

@test_db_bp.route('/test-db', methods=['GET'])
def test_db():
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("SELECT 1")  # Query sederhana untuk menguji koneksi
        return jsonify({'message': 'Koneksi database berhasil'}), 200
    except Exception as e:
        return jsonify({'message': 'Koneksi gagal', 'error': str(e)}), 500
