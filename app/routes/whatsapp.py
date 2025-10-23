# routes/whatsapp.py
from flask import Blueprint, request, jsonify
from twilio.rest import Client
import os

whatsapp_bp = Blueprint('whatsapp', __name__)

@whatsapp_bp.route('/whatsapp', methods=['POST'])
def kirim_whatsapp():
    try:
        data = request.get_json()
        nomor = data.get('nomor')
        pesan = data.get('pesan')

        if not nomor or not pesan:
            return jsonify({'success': False, 'error': 'Nomor atau pesan tidak boleh kosong'}), 400

        # ✅ Gunakan nama variabel dari .env, bukan nilainya langsung
        account_sid = os.getenv('TWILIO_ACCOUNT_SID')
        auth_token = os.getenv('TWILIO_AUTH_TOKEN')
        from_whatsapp_number = os.getenv('TWILIO_FROM_NUMBER')

        if not all([account_sid, auth_token, from_whatsapp_number]):
            return jsonify({'success': False, 'error': 'Konfigurasi Twilio tidak lengkap'}), 500
        print("SID:", os.getenv("TWILIO_ACCOUNT_SID"))
        print("AUTH:", os.getenv("TWILIO_AUTH_TOKEN"))
        print("FROM:", os.getenv("TWILIO_FROM_NUMBER"))

        client = Client(account_sid, auth_token)
        to_whatsapp_number = f'whatsapp:{nomor}'

        message = client.messages.create(
            body=pesan,
            from_=from_whatsapp_number,
            to=to_whatsapp_number
        )

        return jsonify({'success': True, 'sid': message.sid})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})
