from flask import Blueprint, request, jsonify, send_from_directory, abort
from app.db import get_db
from datetime import datetime
import os
from werkzeug.utils import secure_filename

transaksi_bp = Blueprint('transaksi', __name__)

UPLOAD_FOLDER = 'app/bukti'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# ========== TAMBAH TRANSAKSI ========== 
@transaksi_bp.route('/transaksi', methods=['POST'])
def tambah_transaksi():
    data = request.get_json()
    items = data.get('items', [])
    id_pembeli = data.get('id_pembeli')
    metode_pembayaran = data.get('metode_pembayaran')
    pengiriman = data.get('pengiriman')  # <=== ambil dari request
    id_alamat = data.get('id_alamat')    # <=== ambil id_alamat dari request

    if not items or not isinstance(items, list):
        return jsonify({'error': 'Items (list of sku/id_item + quantity) diperlukan'}), 400
    if not id_pembeli or not metode_pembayaran:
        return jsonify({'error': 'id_pembeli dan metode_pembayaran diperlukan'}), 400
    if not pengiriman:
        return jsonify({'error': 'Opsi pengiriman diperlukan'}), 400
    if not id_alamat:
        return jsonify({'error': 'id_alamat diperlukan'}), 400

    VALID_PAYMENT_METHODS = {"dana", "cod", "transfer_atm"}
    if metode_pembayaran.lower() not in VALID_PAYMENT_METHODS:
        return jsonify({
            'error': f'Metode pembayaran tidak valid. Gunakan salah satu dari: {", ".join(VALID_PAYMENT_METHODS)}'
        }), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        total_price = 0
        total_harga_asli = 0
        order_items_data = []
        id_penjual = None

        # ======== CEK STOK & HITUNG TOTAL ========
        for entry in items:
            print(f"[DEBUG] Entry diterima: {entry}")
            sku = entry.get('sku')
            id_item_nonvarian = entry.get('id_item')
            quantity = entry.get('quantity', 1)
            print(f"[DEBUG] Parsed sku: {sku}, id_item_nonvarian: {id_item_nonvarian}, quantity: {quantity}") 
            if quantity <= 0:
                return jsonify({'error': f'Entry tidak valid: {entry}'}), 400

            if sku:  # VARIAN
                cursor.execute("""
                    SELECT i.id_kategori, i.id_user AS id_penjual, i.harga, 
                           v.id_variant, v.id_item, v.stock, v.price_adjustment
                    FROM item_variants v
                    JOIN items i ON v.id_item = i.id_item
                    WHERE v.sku = %s
                """, (sku,))
                variant = cursor.fetchone()

                if not variant:
                    return jsonify({'error': f'Varian dengan sku {sku} tidak ditemukan'}), 404

                if id_penjual is None:
                    id_penjual = variant['id_penjual']
                elif id_penjual != variant['id_penjual']:
                    return jsonify({'error': 'Semua produk harus dari penjual yang sama'}), 400

                if variant['id_kategori'] != 1:
                    return jsonify({'error': 'Barang ini bukan kategori varian, gunakan id_item'}), 400

                if variant['stock'] < quantity:
                    return jsonify({'error': f'Stok tidak cukup untuk sku {sku}'}), 409

                harga_dasar = variant['harga']
                harga_final_unit = harga_dasar + (variant.get('price_adjustment') or 0)
                subtotal_final = harga_final_unit * quantity
                subtotal_asli = harga_dasar * quantity

                total_price += subtotal_final
                total_harga_asli += subtotal_asli

                order_items_data.append({
                    'id_variant': variant['id_variant'],
                    'id_item': variant['id_item'],
                    'quantity': quantity,
                    'price_at_purchase': harga_dasar + (variant.get('price_adjustment') or 0)
                })

            elif id_item_nonvarian:  # NON-VARIAN
                cursor.execute("""
                    SELECT id_item, id_user AS id_penjual, harga, id_kategori, stock
                    FROM items
                    WHERE id_item = %s
                """, (id_item_nonvarian,))
                item = cursor.fetchone()

                if not item:
                    return jsonify({'error': f'Item dengan id {id_item_nonvarian} tidak ditemukan'}), 404

                if id_penjual is None:
                    id_penjual = item['id_penjual']
                elif id_penjual != item['id_penjual']:
                    return jsonify({'error': 'Semua produk harus dari penjual yang sama'}), 400

                if item['id_kategori'] == 1:
                    return jsonify({'error': 'Barang ini adalah kategori varian, gunakan SKU'}), 400

                if item['stock'] is None or item['stock'] < quantity:
                    return jsonify({'error': f'Stok tidak cukup untuk item {id_item_nonvarian}'}), 409

                harga_dasar = item['harga']
                subtotal_final = harga_dasar * quantity
                subtotal_asli = subtotal_final

                total_price += subtotal_final
                total_harga_asli += subtotal_asli

                order_items_data.append({
                    'id_variant': None,
                    'id_item': id_item_nonvarian,
                    'quantity': quantity,
                    'price_at_purchase': harga_dasar
                })
            else:
                print(f"[DEBUG] Tidak ada sku atau id_item, entry gagal diproses: {entry}") 
                return jsonify({'error': 'Harus ada SKU (varian) atau id_item (non-varian)'}), 400

        if not id_penjual:
            return jsonify({'error': 'Tidak ada penjual terdeteksi dari item'}), 400

        # === MODIF FEE ADMIN ===
        FEE_ADMIN = 5000
        total_price_with_fee = total_price + FEE_ADMIN

        # ======== INSERT TRANSAKSI ========
        first_id_item = order_items_data[0]['id_item']
        cursor.execute("""
            INSERT INTO transaksi (
                id_item, id_penjual, id_pembeli, id_alamat, harga_asli,
                harga_total, tanggal_transaksi, metode_pembayaran,
                pengiriman, status, status_notifikasi, status_pesanan, id_admin, bukti_transfer
            ) VALUES (%s, %s, %s, %s, %s, %s, NOW(), %s, %s, %s, %s, %s, %s, %s)
        """, (
            first_id_item, id_penjual, id_pembeli, id_alamat,
            total_harga_asli, total_price_with_fee, metode_pembayaran, pengiriman,
            'diproses', 'menunggu', 'pending', None, None
        ))
        id_transaksi = cursor.lastrowid

        # ======== INSERT ORDER ITEMS & UPDATE STOK ========
        for oi in order_items_data:
            cursor.execute("""
                INSERT INTO order_items (id_transaksi, id_item, id_variant, quantity, price_at_purchase)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                id_transaksi,
                oi['id_item'],
                oi['id_variant'],
                oi['quantity'],
                oi['price_at_purchase']
            ))

            # UPDATE STOK
            if oi['id_variant']:
                cursor.execute("""
                    UPDATE item_variants SET stock = stock - %s WHERE id_variant = %s AND stock >= %s
                """, (oi['quantity'], oi['id_variant'], oi['quantity']))
                if cursor.rowcount == 0:
                    db.rollback()
                    return jsonify({'error': f'Stok tidak cukup untuk varian {oi["id_variant"]}'}), 409
            else:
                cursor.execute("""
                    UPDATE items SET stock = stock - %s WHERE id_item = %s AND stock >= %s
                """, (oi['quantity'], oi['id_item'], oi['quantity']))
                if cursor.rowcount == 0:
                    db.rollback()
                    return jsonify({'error': f'Stok tidak cukup untuk item {oi["id_item"]}'}), 409

        # ======== INSERT NOTIFIKASI ========
        cursor.execute("SELECT nama_user FROM users WHERE id_user = %s", (id_pembeli,))
        pembeli = cursor.fetchone()
        nama_pembeli = pembeli['nama_user'] if pembeli else "Pembeli"

        cursor.execute("INSERT INTO notifikasi (id_user, id_transaksi, pesan) VALUES (%s, %s, %s)",
                       (id_penjual, id_transaksi, f"Ada pesanan baru dari {nama_pembeli}"))
        cursor.execute("INSERT INTO notifikasi (id_user, id_transaksi, pesan) VALUES (%s, %s, %s)",
                       (id_pembeli, id_transaksi, "Pesanan kamu berhasil dibuat, menunggu konfirmasi penjual"))

        db.commit()
        return jsonify({
            'message': 'Transaksi berhasil ditambahkan',
            'id_transaksi': id_transaksi,
            'id_penjual': id_penjual
        }), 201

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Gagal membuat transaksi multi-item: {e}")
        return jsonify({'error': str(e)}), 500


# ========== UPLOAD BUKTI ==========
@transaksi_bp.route('/upload_bukti', methods=['POST'])
def upload_bukti():
    if 'bukti_transfer' not in request.files:
        return jsonify({'error': 'File tidak ditemukan'}), 400

    file = request.files['bukti_transfer']
    id_transaksi = request.form.get('id_transaksi')

    if not file or file.filename == '':
        return jsonify({'error': 'Nama file tidak valid'}), 400

    if not allowed_file(file.filename):
        return jsonify({'error': 'Format file tidak diizinkan'}), 400

    try:
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        db = get_db()
        cursor = db.cursor()
        query = "UPDATE transaksi SET bukti_transfer = %s WHERE id_transaksi = %s"
        cursor.execute(query, (filename, id_transaksi))
        db.commit()

        return jsonify({'message': 'Bukti berhasil diunggah'}), 200
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Gagal upload bukti: {e}")
        return jsonify({'error': str(e)}), 500


@transaksi_bp.route('/bukti/<filename>')
def get_bukti(filename):
    directory = os.path.join(os.getcwd(), 'app', 'bukti')
    path = os.path.join(directory, filename)

    if not os.path.isfile(path):
        abort(404)

    return send_from_directory(directory, filename)


# ========== DETAIL TRANSAKSI ==========
@transaksi_bp.route('/transaksi/<int:id_transaksi>', methods=['GET'])
def get_detail_transaksi(id_transaksi):
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)

        # Ambil header transaksi + alamat
        cursor.execute("""
            SELECT 
                t.id_transaksi,
                t.id_item,
                t.id_pembeli,
                u1.nama_user AS nama_pembeli,
                t.id_penjual,
                u2.nama_user AS nama_penjual,
                t.harga_asli,
                t.harga_total,
                t.tanggal_transaksi,
                t.metode_pembayaran,
                t.pengiriman,
                t.status,
                t.bukti_transfer,
                a.nama_penerima,
                a.no_hp,
                a.alamat_lengkap
            FROM transaksi t
            JOIN users u1 ON t.id_pembeli = u1.id_user
            JOIN users u2 ON t.id_penjual = u2.id_user
            LEFT JOIN alamat_users a ON t.id_alamat = a.id_alamat
            WHERE t.id_transaksi = %s
        """, (id_transaksi,))
        header = cursor.fetchone()
        if not header:
            return jsonify({'error': 'Transaksi tidak ditemukan'}), 404

        # Ambil detail item/variant
        cursor.execute("""
            SELECT 
                oi.id_order_item,
                oi.id_variant,
                oi.quantity,
                oi.price_at_purchase,
                v.price_adjustment AS adj,
                v.sku,
                v.size,
                COALESCE(v.id_item, t.id_item) AS id_item,
                i.nama_item,
                i.harga AS harga_dasar
            FROM order_items oi
            LEFT JOIN item_variants v ON oi.id_variant = v.id_variant
            LEFT JOIN transaksi t ON t.id_transaksi = oi.id_transaksi
            LEFT JOIN items i ON i.id_item = COALESCE(v.id_item, t.id_item)
            WHERE oi.id_transaksi = %s
        """, (id_transaksi,))

        details = cursor.fetchall()

        # Hitung harga_final untuk tiap item
        for d in details:
            adj = d.get('adj') or 0
            d['harga_final'] = (d['price_at_purchase'] or 0) + adj

        response = {
            'header': header,
            'items': details
        }

        return jsonify(response), 200

    except Exception as e:
        print(f"[ERROR] Gagal ambil detail transaksi: {e}")
        return jsonify({'error': str(e)}), 500


# ========== STATUS TRANSAKSI ==========
@transaksi_bp.route('/status_transaksi/<int:id_transaksi>')
def status_transaksi(id_transaksi):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT status FROM transaksi WHERE id_transaksi = %s", (id_transaksi,))
    data = cursor.fetchone()

    if data:
        return jsonify({'status': data['status']})
    return jsonify({'error': 'Transaksi tidak ditemukan'}), 404


# ========== UPDATE STATUS PESANAN ==========
@transaksi_bp.route('/transaksi/<int:id_transaksi>/status', methods=['PUT'])
def update_status_pesanan(id_transaksi):
    data = request.get_json()
    status_pesanan = data.get('status_pesanan')

    if not status_pesanan:
        return jsonify({'error': 'status_pesanan diperlukan'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        # Ambil transaksi dulu
        cursor.execute("""
            SELECT t.id_transaksi, t.id_pembeli, t.id_penjual, t.status_pesanan, u.nama_user AS nama_pembeli
            FROM transaksi t
            JOIN users u ON t.id_pembeli = u.id_user
            WHERE t.id_transaksi = %s
        """, (id_transaksi,))
        transaksi = cursor.fetchone()
        cursor.fetchall()  # habiskan result set

        if not transaksi:
            return jsonify({'error': 'Transaksi tidak ditemukan'}), 404

        # Update status pesanan
        cursor.execute("""
            UPDATE transaksi SET status_pesanan = %s WHERE id_transaksi = %s
        """, (status_pesanan, id_transaksi))

        # === INSERT NOTIFIKASI ===
        id_pembeli = transaksi['id_pembeli']
        id_penjual = transaksi['id_penjual']
        nama_pembeli = transaksi['nama_pembeli'] or "Pembeli"

        # Pesan notifikasi berdasarkan status
        pesan_pembeli = f"Status pesanan kamu berubah menjadi: {status_pesanan}"
        pesan_penjual = f"Pesanan dari {nama_pembeli} sekarang berstatus: {status_pesanan}"

        # Notifikasi untuk pembeli
        cursor.execute("""
            INSERT INTO notifikasi (id_user, id_transaksi, pesan)
            VALUES (%s, %s, %s)
            ON DUPLICATE KEY UPDATE pesan = VALUES(pesan), created_at = NOW()
        """, (id_pembeli, id_transaksi, pesan_pembeli))

        # Notifikasi untuk penjual
        cursor.execute("""
            INSERT INTO notifikasi (id_user, id_transaksi, pesan)
            VALUES (%s, %s, %s)
            ON DUPLICATE KEY UPDATE pesan = VALUES(pesan), created_at = NOW()
        """, (id_penjual, id_transaksi, pesan_penjual))

        db.commit()

        return jsonify({
            'message': 'Status pesanan berhasil diperbarui',
            'id_transaksi': id_transaksi,
            'status_pesanan': status_pesanan
        }), 200

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Gagal update status pesanan: {e}")
        return jsonify({'error': str(e)}), 500
