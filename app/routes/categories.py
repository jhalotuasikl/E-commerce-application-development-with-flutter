# app/routes/categories.py
from flask import Blueprint, jsonify
from app.db import get_db

categories_bp = Blueprint('categories', __name__)

@categories_bp.route('/categories', methods=['GET'])
def get_categories():
    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT id_kategori, nama_kategori FROM categories")
    data = cursor.fetchall()
    result = [{'id_kategori': row[0], 'nama_kategori': row[1]} for row in data]
    return jsonify({'categories': result})
