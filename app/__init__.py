from flask import Flask
from app.routes.users import users_bp
from app.routes.test_db import test_db_bp
from app.routes.categories import categories_bp
from app.routes.items import items_bp
from app.routes.profile_page import profile_page_bp  
from app.routes.favorites import favorites_bp
from app.routes.transaksi import transaksi_bp
from app.routes.whatsapp import whatsapp_bp
from app.routes.search import search_bp
from app.routes.notification import notifikasi_bp
from app.routes.pencairan import pencairan_bp
from app.routes.chat import chat_bp
from app.routes.alamat import alamat_bp
from dotenv import load_dotenv
load_dotenv()

from app.db import get_db, close_db
from app.config import Config
def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    app.register_blueprint(users_bp)
    app.register_blueprint(test_db_bp, url_prefix='/test-db')
    app.register_blueprint(categories_bp)
    app.register_blueprint(items_bp)
    app.register_blueprint(profile_page_bp)  
    app.register_blueprint(favorites_bp)
    app.register_blueprint(transaksi_bp)
    app.register_blueprint(whatsapp_bp)
    app.register_blueprint(search_bp)
    app.register_blueprint(notifikasi_bp)
    app.register_blueprint(pencairan_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(alamat_bp)

    @app.teardown_appcontext
    def teardown_db(exception):
        close_db()

    # Tambahkan ini
    @app.route("/")
    def index():
        return "Server Jalan 🚀"

    return app

