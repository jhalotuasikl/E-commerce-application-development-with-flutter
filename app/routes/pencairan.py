from flask import Blueprint, request, jsonify, send_from_directory, abort
from app.db import get_db
from datetime import datetime
import os
from werkzeug.utils import secure_filename

pencairan_bp = Blueprint('pencairan', __name__)

UPLOAD_FOLDER = 'app/bukti'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ================= UPLOAD BUKTI CAIRAN =================
@pencairan_bp.route('/admin/upload_bukti_cairkan', methods=['POST'])
def upload_bukti_cairkan():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        if 'bukti' not in request.files:
            return jsonify({'error': 'File bukti transfer diperlukan'}), 400

        bukti_file = request.files['bukti']
        id_transaksi = request.form.get('id_transaksi')
        keterangan = request.form.get('keterangan', '')
        metode = request.form.get('metode', 'dana')  # default ke 'dana'

        if not id_transaksi:
            return jsonify({'error': 'id_transaksi diperlukan'}), 400

        if not allowed_file(bukti_file.filename):
            return jsonify({'error': f'File harus berekstensi {ALLOWED_EXTENSIONS}'}), 400

        filename = secure_filename(bukti_file.filename)
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        bukti_file.save(file_path)

        # Ambil otomatis id_penjual dari transaksi
        cursor.execute("SELECT id_penjual FROM transaksi WHERE id_transaksi = %s", (id_transaksi,))
        result = cursor.fetchone()
        if not result:
            return jsonify({'error': 'Transaksi tidak ditemukan'}), 404

        id_user = result['id_penjual']  # ambil dari transaksi

        # INSERT pencairan_dana dengan metode_pembayaran
        cursor.execute("""
            INSERT INTO pencairan_dana (id_transaksi, id_user, bukti_file, keterangan, metode_pembayaran, status)
            VALUES (%s, %s, %s, %s, %s, 'menunggu')
        """, (id_transaksi, id_user, filename, keterangan, metode))
        db.commit()

        # Ambil id_pencairan terakhir
        cursor.execute("SELECT LAST_INSERT_ID() as id_pencairan")
        id_pencairan = cursor.fetchone()['id_pencairan']

        return jsonify({
            'message': 'Bukti berhasil diunggah',
            'bukti_file': filename,
            'id_pencairan': id_pencairan,
            'metode_pembayaran': metode,
            'status': 'menunggu'
        }), 200

    except Exception as e:
        db.rollback()
        print(f"[ERROR] upload_bukti_cairkan: {e}")
        return jsonify({'error': str(e)}), 500


# ================= VERIFIKASI PENCairan =================
@pencairan_bp.route('/admin/verifikasi_pencairan', methods=['POST'])
def verifikasi_pencairan():
    data = request.get_json()
    id_pencairan = data.get('id_pencairan')
    id_admin = data.get('id_admin')

    if not id_pencairan or not id_admin:
        return jsonify({'error': 'id_pencairan dan id_admin diperlukan'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)

    # Ambil data pencairan
    cursor.execute("SELECT * FROM pencairan_dana WHERE id_pencairan=%s", (id_pencairan,))
    pencairan = cursor.fetchone()
    if not pencairan:
        return jsonify({'error': 'Pencairan tidak ditemukan'}), 404

    if pencairan['status'] != 'menunggu':
        return jsonify({'error': 'Pencairan sudah diverifikasi atau selesai'}), 400

    # INSERT ke log_pencairan pakai metode_pembayaran dari pencairan_dana
    cursor.execute("""
        INSERT INTO log_pencairan (id_transaksi, jumlah, metode_pembayaran, tanggal_cair, keterangan, id_admin, bukti_file)
        VALUES (%s, %s, %s, NOW(), %s, %s, %s)
    """, (
        pencairan['id_transaksi'],
        pencairan.get('jumlah', 0),
        pencairan['metode_pembayaran'],
        pencairan['keterangan'],
        id_admin,
        pencairan['bukti_file']
    ))
    db.commit()

    # Update status pencairan_dana menjadi dicairkan
    cursor.execute("""
        UPDATE pencairan_dana SET status='dicairkan', tanggal_verifikasi=NOW()
        WHERE id_pencairan=%s
    """, (id_pencairan,))
    db.commit()

    return jsonify({'message': 'Pencairan berhasil diverifikasi', 'status': 'dicairkan'}), 200


# ================= CEK STATUS PENCairan =================
@pencairan_bp.route('/admin/pencairan_status', methods=['GET'])
def pencairan_status():
    id_pencairan = request.args.get('id_pencairan')
    if not id_pencairan:
        return jsonify({'error': 'id_pencairan diperlukan'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT status FROM pencairan_dana WHERE id_pencairan=%s", (id_pencairan,))
    pencairan = cursor.fetchone()
    if not pencairan:
        return jsonify({'error': 'Pencairan tidak ditemukan'}), 404

    return jsonify({'status': pencairan['status']}), 200


# ================= AMBIL FILE BUKTI =================
@pencairan_bp.route('/admin/bukti/<filename>', methods=['GET'])
def get_bukti(filename):
    try:
        return send_from_directory(UPLOAD_FOLDER, filename)
    except Exception as e:
        print(f"[ERROR] get_bukti: {e}")
        abort(404)
