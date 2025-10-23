from flask import Blueprint, request, jsonify
from app.db import get_db
import hashlib

users_bp = Blueprint('users', __name__)

# Jangan otak-atik bagian ini sesuai permintaan
@users_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    if not data.get('nama_user') or not data.get('email') or not data.get('nomor_telepon') or not data.get('password'):
        return jsonify({'message': 'Data tidak lengkap'}), 400

    nama = data['nama_user']
    email = data['email']
    nomor_telepon = data['nomor_telepon']

    password_raw = data['password'].strip()
    print(f"Password plain diterima (register): '{password_raw}'")
    password = hashlib.sha256(password_raw.encode()).hexdigest()

    db = get_db()
    cursor = db.cursor()

    try:
        print(f"Executing query: INSERT INTO users (nama_user, email, nomor_telepon, password, status, id_admin) VALUES ({nama}, {email}, {nomor_telepon}, {password}, 'aktif', 1)")
        cursor.execute('''
            INSERT INTO users (nama_user, email, nomor_telepon, password, status, id_admin)
            VALUES (%s, %s, %s, %s, %s, %s)
        ''', (nama, email, nomor_telepon, password, 'aktif', 1))
        db.commit()

        return jsonify({'message': 'Registrasi berhasil'}), 201
    except Exception as e:
        print('Error:', e)
        return jsonify({'message': 'Registrasi gagal'}), 500


@users_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not data.get('email') or not data.get('password'):
        return jsonify({'success': False, 'message': 'Data tidak lengkap'}), 400

    email = data['email']
    password_raw = data['password'].strip()
    print(f"Password plain diterima (login): '{password_raw}'")
    password = hashlib.sha256(password_raw.encode()).hexdigest()

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute("SELECT id_user, nama_user, email, nomor_telepon, status, id_admin FROM users WHERE email=%s AND password=%s", (email, password))
        user = cursor.fetchone()

        if user:
            return jsonify({'success': True, 'data': user}), 200
        else:
            return jsonify({'success': False, 'message': 'Email atau password salah'}), 401
    except Exception as e:
        print('Error saat login:', e)
        return jsonify({'success': False, 'message': 'Terjadi kesalahan saat login', 'error': str(e)}), 500


@users_bp.route('/test-db', methods=['GET'])
def test_db_connection():
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        if result:
            return jsonify({'message': 'Koneksi ke database berhasil!'}), 200
        else:
            return jsonify({'message': 'Gagal melakukan query.'}), 500
    except Exception as e:
        return jsonify({'error': str(e), 'message': 'Koneksi ke database gagal!'}), 500
