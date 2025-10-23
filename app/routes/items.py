from flask import Blueprint, request, jsonify
from app.db import get_db
from werkzeug.utils import secure_filename
import os
import traceback

items_bp = Blueprint('items', __name__)

UPLOAD_FOLDER = 'app/static/images'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# ================= ADD ITEM =================
@items_bp.route('/items', methods=['POST'])
def add_item():
    try:
        nama_item = request.form['nama_item']
        deskripsi = request.form['deskripsi']
        harga = request.form['harga']
        id_user = request.form['id_user']
        id_kategori = int(request.form['id_kategori'])
        status = 'tersedia'

        stock = int(request.form.get('stock', 0)) if id_kategori != 1 else 0

        db = get_db()
        cursor = db.cursor()
        print("=== DEBUG ADD ITEM ===")
        print("Request form:", request.form)
        print("Request files:", request.files)

        # Validasi user
        cursor.execute("SELECT id_user FROM users WHERE id_user = %s", (id_user,))
        if cursor.fetchone() is None:
            return jsonify({'error': f'User dengan id {id_user} tidak ditemukan'}), 400

        # Validasi kategori
        cursor.execute("SELECT id_kategori FROM categories WHERE id_kategori = %s", (id_kategori,))
        if cursor.fetchone() is None:
            return jsonify({'error': f'Kategori dengan id {id_kategori} tidak ditemukan'}), 400

        # Simpan gambar jika ada
        gambar = None
        if 'gambar' in request.files:
            gambar_file = request.files['gambar']
            filename = secure_filename(gambar_file.filename)
            filepath = os.path.join(UPLOAD_FOLDER, filename)
            gambar_file.save(filepath)
            gambar = f"/static/images/{filename}"

        # Simpan item
        cursor.execute("""
            INSERT INTO items (nama_item, deskripsi, harga, id_user, id_kategori, status, gambar, stock)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (nama_item, deskripsi, harga, id_user, id_kategori, status, gambar, stock))
        db.commit()
        id_item = cursor.lastrowid
        return jsonify({'message': 'Item berhasil ditambahkan', 'id_item': id_item}), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ================= GET ITEMS BY USER =================
@items_bp.route('/items_by_user/<int:id_user>', methods=['GET'])
def get_items_by_user(id_user):
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)

        query = """
            SELECT 
                i.id_item, i.nama_item, i.deskripsi, i.harga, i.gambar,
                i.id_kategori, i.status, u.nama_user, u.id_user, c.nama_kategori, i.stock
            FROM items i
            JOIN users u ON i.id_user = u.id_user
            JOIN categories c ON i.id_kategori = c.id_kategori
            WHERE i.id_user = %s
        """
        cursor.execute(query, (id_user,))
        items = cursor.fetchall()

        # Ambil varian untuk setiap item
        for item in items:
            if item['id_kategori'] == 1:
                cursor.execute("""
                    SELECT size, sku, stock AS quantity, price_adjustment AS adj
                    FROM item_variants
                    WHERE id_item = %s
                """, (item['id_item'],))
                variants = cursor.fetchall()
                item['items'] = [
                    {
                        'id_item': item['id_item'],
                        'sku': v['sku'],
                        'size': v['size'],
                        'quantity': v['quantity'],
                        'adj': v['adj']
                    } for v in variants
                ] if variants else []
            else:
                # Non-varian
                item['items'] = [{
                    'id_item': item['id_item'],
                    'sku': None,
                    'size': None,
                    'quantity': item.get('stock', 1),
                    'adj': 0
                }]
        cursor.close()
        return jsonify(items), 200
    except Exception as e:
        print(f"Error ambil produk user: {e}")
        return jsonify({"message": "Terjadi kesalahan"}), 500

# ================= GET ITEMS EXCLUDE USER =================
@items_bp.route('/items_exclude_user/<int:id_user>', methods=['GET'])
def get_items_exclude_user(id_user):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT 
            i.id_item, i.nama_item, i.deskripsi, i.harga, i.gambar,
            i.id_kategori, u.nama_user, u.id_user, c.nama_kategori, i.stock
        FROM items i
        JOIN users u ON i.id_user = u.id_user
        JOIN categories c ON i.id_kategori = c.id_kategori
        WHERE i.id_user != %s
    """, (id_user,))
    items = cursor.fetchall()

    # Ambil varian untuk setiap item
    for item in items:
        if item['id_kategori'] == 1:
            cursor.execute("""
                SELECT size, sku, stock AS quantity, price_adjustment AS adj
                FROM item_variants
                WHERE id_item = %s
            """, (item['id_item'],))
            variants = cursor.fetchall()
            item['items'] = [
                {
                    'id_item': item['id_item'],
                    'sku': v['sku'],
                    'size': v['size'],
                    'quantity': v['quantity'],
                    'adj': v['adj']
                } for v in variants
            ] if variants else []
        else:
            # Non-varian
            item['items'] = [{
                'id_item': item['id_item'],
                'sku': None,
                'size': None,
                'quantity': item.get('stock', 1),
                'adj': 0
            }]
    return jsonify(items)

# ================= ADD VARIANTS =================
@items_bp.route('/items/<int:id_item>/variants', methods=['POST'])
def add_variants(id_item):
    data = request.get_json()
    variants = data.get('variants', [])
    db = get_db()
    cursor = db.cursor()

    print("=== DEBUG ADD VARIANTS ===")
    print("Payload:", data)

    try:
        for v in variants:
            size = v.get('size') or ''
            sku = v.get('sku') or ''
            stock = v.get('stock', 0)
            price_adjustment = v.get('price_adjustment', 0)
            cursor.execute("""
                INSERT INTO item_variants (id_item, size, sku, stock, price_adjustment) 
                VALUES (%s, %s, %s, %s, %s)
            """, (id_item, size, sku, stock, price_adjustment))
        db.commit()
        return jsonify({"message": "Variants added"}), 201
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 400

# ================= GET VARIANTS =================
@items_bp.route('/items/<int:id_item>/variants', methods=['GET'])
def get_variants(id_item):
    db = get_db()
    cursor = db.cursor(dictionary=True)

    # Ambil data item
    cursor.execute("SELECT id_kategori, harga, stock FROM items WHERE id_item = %s", (id_item,))
    item_data = cursor.fetchone()
    if not item_data:
        return jsonify({'error': 'Item tidak ditemukan'}), 404

    harga = item_data['harga']
    id_kategori = item_data['id_kategori']
    stock_item = item_data.get('stock', 0)

    if id_kategori != 1:
        return jsonify([{
            'id_variant': None,
            'size': None,
            'sku': None,
            'stock': stock_item,
            'price_adjustment': 0,
            'adj': 0,
            'harga': harga,
            'harga_final': harga
        }]), 200

    cursor.execute("""
        SELECT v.*, i.harga, (i.harga + v.price_adjustment) AS harga_final,
               v.price_adjustment AS adj
        FROM item_variants v
        JOIN items i ON v.id_item = i.id_item
        WHERE v.id_item = %s
    """, (id_item,))
    variants = cursor.fetchall()

    # Tambahkan id_item di setiap varian untuk konsistensi
    for v in variants:
        v['id_item'] = id_item

    return jsonify(variants if variants else []), 200
