from flask import Blueprint, jsonify
from app.db import get_db

notifikasi_bp = Blueprint('notifikasi', __name__)

# === NOTIFIKASI UNTUK PEMBELI ===
@notifikasi_bp.route('/transaksi/notifikasi/pembeli/<int:id_user>', methods=['GET'])
def get_notifikasi_pembeli(id_user):
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                n.id_notifikasi,
                n.id_transaksi,
                t.status_pesanan,
                t.harga_total,
                t.tanggal_transaksi,
                p.status AS status_pencairan,
                u.nama_user AS nama_penjual,
                i.nama_item,
                n.pesan,
                n.created_at,
                n.updated_at
            FROM notifikasi n
            JOIN transaksi t ON n.id_transaksi = t.id_transaksi
            JOIN users u ON t.id_penjual = u.id_user
            JOIN items i ON t.id_item = i.id_item
            LEFT JOIN pencairan_dana p ON t.id_transaksi = p.id_transaksi
            WHERE n.id_user = %s AND t.id_pembeli = %s;
        """, (id_user, id_user))
        rows = cursor.fetchall()

        notifications = []
        for r in rows:
            notif_text = r["pesan"] or f"Pesanan kamu dengan {r['nama_penjual']} sekarang {r['status_pesanan']}"
            notifications.append({
                "id_notifikasi": r["id_notifikasi"],
                "id_transaksi": r["id_transaksi"],
                "from": r["nama_penjual"],
                "nama_item": r["nama_item"],
                "status_pesanan": r["status_pesanan"],
                "status_pencairan": r["status_pencairan"],
                "tanggal": r["tanggal_transaksi"],
                "total": r["harga_total"],
                "message": notif_text,
                "created_at": r["created_at"].strftime("%Y-%m-%d %H:%M:%S") if r["created_at"] else None,
                "updated_at": r["updated_at"].strftime("%Y-%m-%d %H:%M:%S") if r["updated_at"] else None
            })

        # Sorting Python level (biar pasti notif terbaru di atas)
        notifications = sorted(
            notifications,
            key=lambda x: x["created_at"] or "1970-01-01 00:00:00",
            reverse=True
        )

        return jsonify({"notifications": notifications}), 200

    except Exception as e:
        print(f"[ERROR] get_notifikasi_pembeli: {e}")
        return jsonify({"error": str(e)}), 500

# === NOTIFIKASI UNTUK PENJUAL ===
@notifikasi_bp.route('/transaksi/notifikasi/penjual/<int:id_user>', methods=['GET'])
def get_notifikasi_penjual(id_user):
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                n.id_notifikasi,
                n.id_transaksi,
                t.id_pembeli,
                u.nama_user AS nama_pembeli,
                t.status_pesanan,
                t.harga_total,
                t.tanggal_transaksi,
                t.metode_pembayaran,
                p.status AS status_pencairan,
                i.nama_item,
                n.pesan,
                n.created_at,
                n.updated_at,
                a.nama_penerima,
                a.no_hp,
                a.alamat_lengkap,
                a.latitude,
                a.longitude,
                a.is_default
            FROM notifikasi n
            JOIN transaksi t ON n.id_transaksi = t.id_transaksi
            JOIN users u ON t.id_pembeli = u.id_user
            JOIN items i ON t.id_item = i.id_item
            LEFT JOIN pencairan_dana p ON t.id_transaksi = p.id_transaksi
            LEFT JOIN alamat_users a ON t.id_alamat = a.id_alamat   -- 🔥 join ke alamat berdasarkan transaksi
            WHERE t.id_penjual = %s AND n.id_user = %s;
        """, (id_user, id_user))
        rows = cursor.fetchall()

        notifications = []
        for r in rows:
            notif_text = r["pesan"] or f"Ada pesanan baru dari {r['nama_pembeli']}, status sekarang {r['status_pesanan']}"
            
            alamat_data = None
            if r["nama_penerima"]:
                alamat_data = {
                    "nama_penerima": r["nama_penerima"],
                    "no_hp": r["no_hp"],
                    "alamat_lengkap": r["alamat_lengkap"],
                    "latitude": r["latitude"],
                    "longitude": r["longitude"],
                    "is_default": r["is_default"]
                }
            
            notifications.append({
                "id_notifikasi": r["id_notifikasi"],
                "id_transaksi": r["id_transaksi"],
                "from": r["nama_pembeli"],
                "nama_item": r["nama_item"],
                "status_pesanan": r["status_pesanan"],
                "status_pencairan": r["status_pencairan"],
                "tanggal": r["tanggal_transaksi"],
                "total": r["harga_total"],
                "metode_pembayaran": r["metode_pembayaran"],
                "alamat": alamat_data,
                "message": notif_text,
                "created_at": r["created_at"].strftime("%Y-%m-%d %H:%M:%S") if r["created_at"] else None,
                "updated_at": r["updated_at"].strftime("%Y-%m-%d %H:%M:%S") if r["updated_at"] else None
            })

        notifications = sorted(
            notifications,
            key=lambda x: x["created_at"] or "1970-01-01 00:00:00",
            reverse=True
        )

        return jsonify({"notifications": notifications}), 200

    except Exception as e:
        print(f"[ERROR] get_notifikasi_penjual: {e}")
        return jsonify({"error": str(e)}), 500




# === HAPUS NOTIFIKASI ===
@notifikasi_bp.route('/transaksi/notifikasi/<int:id_notifikasi>', methods=['DELETE'])
def delete_notifikasi(id_notifikasi):
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute("DELETE FROM notifikasi WHERE id_notifikasi = %s", (id_notifikasi,))
        db.commit()

        if cursor.rowcount == 0:
            return jsonify({"error": "Notifikasi tidak ditemukan"}), 404

        return jsonify({"message": "Notifikasi berhasil dihapus"}), 200
    except Exception as e:
        print(f"[ERROR] delete_notifikasi: {e}")
        return jsonify({"error": str(e)}), 500

