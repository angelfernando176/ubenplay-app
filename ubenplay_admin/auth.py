"""Autenticación y gestión de usuarios"""
from database import db
from models import User
from flask_login import login_user, logout_user, login_required, current_user


def init_auth():
    """Crear usuario root por defecto si no existe"""
    if not User.query.filter_by(username='admin').first():
        admin = User(username='admin', role='root', name='Administrador')
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
        print("[OK] Usuario root creado: admin / admin123")


def create_user(username, password, role='profesor', name='', correo=''):
    """Crear nuevo usuario. Si es profesor, crea también el espejo en 'usuarios' (persona)."""
    from models import User, Usuario
    if User.query.filter_by(username=username).first():
        return False, "El usuario ya existe"

    correo = (correo or '').strip()

    # Espejo en 'usuarios' (universo de personas): obligatorio para profesores.
    usuario_id = None
    if role == 'profesor':
        if not correo:
            return False, "El correo es obligatorio para crear un profesor (se usa en 'usuarios')"
        if Usuario.query.filter_by(correo=correo).first():
            return False, f"Ya existe un registro en 'usuarios' con el correo {correo}"
        persona = Usuario(
            nombre=name or '', correo=correo, tipo_usuario='profesor',
            nivel_acceso=2, estado=1, lopdp=1, id_suscripcion='0',
        )
        db.session.add(persona)
        db.session.flush()  # asigna persona.id_usuario
        usuario_id = persona.id_usuario

    user = User(username=username, role=role, name=name,
                correo=correo or None, id_usuario=usuario_id)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    # Sincronizar el espejo del profesor a Supabase (para que la APK lo vea)
    if usuario_id:
        try:
            from activacion import sync_usuario_to_supabase
            sync_usuario_to_supabase(usuario_id)
        except Exception:
            pass

    return True, f"Usuario {username} creado"


def authenticate(username, password):
    """Validar credenciales"""
    user = User.query.filter_by(username=username).first()
    if user and user.check_password(password):
        login_user(user)
        return True, None
    return False, "Usuario o contraseña incorrectos"
