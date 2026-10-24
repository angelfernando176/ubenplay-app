"""Ubenplay Admin - Panel web de administración"""
import os
from flask import Flask
from flask_login import LoginManager
from database import db

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Base de datos: PostgreSQL (Supabase) si está configurado, sino SQLite local
DB_URI = os.environ.get('DATABASE_URL', '')  # postgresql://postgres:...@db.xxx.supabase.co:5432/postgres
if not DB_URI:
    DB_PATH = os.environ.get('LINGO_DB_PATH', os.path.join(BASE_DIR, 'lingo_nouns.db'))
    DB_URI = f'sqlite:///{DB_PATH}'

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'lingo-admin-dev-key-2026')
app.config['SQLALCHEMY_DATABASE_URI'] = DB_URI
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message = 'Inicia sesión para acceder al panel.'

# Importar modelos y rutas después de inicializar db
from models import User, Palabra, Sustantivo
from auth import init_auth
from routes import *
from routes_crud import *
from routes_usuarios import *
from routes_usuarios_api import *

# Crear tablas y usuario root por defecto
with app.app_context():
    db.create_all()
    init_auth()

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 9999))
    print(f"\n[Ubenplay Admin Web]")
    print(f"   URL: http://localhost:{port}")
    print(f"   BD:  {DB_PATH}")
    print(f"   Usuario root: admin / admin123")
    print(f"   Modo: desarrollo\n")
    app.run(host='0.0.0.0', port=port, debug=True)
