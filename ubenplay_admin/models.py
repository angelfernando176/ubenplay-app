import hashlib
from datetime import datetime

from database import db
from flask_login import UserMixin
from sqlalchemy import event

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password = db.Column(db.String(200))
    role = db.Column(db.String(20), default='user')
    name = db.Column(db.String(100))
    correo = db.Column(db.String(150))  # espejo en usuarios (persona)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))  # vínculo a la persona
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def set_password(self, pw):
        from werkzeug.security import generate_password_hash
        self.password = generate_password_hash(pw)
    
    def check_password(self, pw):
        from werkzeug.security import check_password_hash
        return check_password_hash(self.password, pw)

    @property
    def is_root(self):
        return self.role == 'root'

class Palabra(db.Model):
    __tablename__ = 'palabras'
    id_palabra = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_categoria = db.Column(db.Integer, default=1)
    id_tipo = db.Column(db.Integer, default=1)
    id_nivel = db.Column(db.Integer, default=1)
    id_tematica = db.Column(db.Integer)
    palabra_es = db.Column(db.String(100))
    palabra_de = db.Column(db.String(100))
    definicion = db.Column(db.String(200))
    imagen_path = db.Column(db.String(250))
    texto_emoji = db.Column(db.String(10))
    oracion_ejemplo = db.Column(db.String(500))
    oracion_palabras = db.Column(db.Text)
    activo = db.Column(db.Boolean, default=True)

    def to_dict(self):
        nivel = {1: 'A1', 2: 'A2', 3: 'B1', 4: 'B2'}.get(self.id_nivel, 'A1')
        return {
            'id_palabra': self.id_palabra,
            'id_categoria': self.id_categoria,
            'id_tipo': self.id_tipo,
            'id_nivel': self.id_nivel,
            'id_tematica': self.id_tematica,
            'palabra_es': self.palabra_es or '',
            'palabra_de': self.palabra_de or '',
            'definicion': self.definicion or '',
            'texto_emoji': self.texto_emoji or '',
            'oracion_ejemplo': self.oracion_ejemplo or '',
            'activo': self.activo,
            # aliases compat con el esquema legacy (SyncService /api/words)
            'spanish': self.palabra_es or '',
            'german': self.palabra_de or '',
            'article': _tipo_to_article(self.id_tipo),
            'cefr_level': nivel,
            'category_id': str(self.id_tematica or ''),
            'plural': '',
        }

class Sustantivo(db.Model):
    __tablename__ = 'sustantivos'
    id_palabra = db.Column(db.Integer, db.ForeignKey('palabras.id_palabra'), primary_key=True)
    plural = db.Column(db.String(50))
    femenino = db.Column(db.String(50))
    verbo_relacionado = db.Column(db.String(100))

class Verbo(db.Model):
    __tablename__ = 'verbos'
    id_palabra = db.Column(db.Integer, db.ForeignKey('palabras.id_palabra'), primary_key=True)
    conjuga_ich = db.Column(db.String(50))
    conjuga_du = db.Column(db.String(50))
    conjuga_er = db.Column(db.String(50))
    conjuga_sie = db.Column(db.String(50))
    conjuga_es = db.Column(db.String(50))
    conjuga_wir = db.Column(db.String(50))
    conjuga_ihr = db.Column(db.String(50))
    conjuga_Sie_formal = db.Column('conjuga_Sie_formal', db.String(50))
    conjuga_sie_plural = db.Column(db.String(50))
    ejemplo_oracion1 = db.Column(db.String(200))

class Adjetivo(db.Model):
    __tablename__ = 'adjetivos'
    id_palabra = db.Column(db.Integer, db.ForeignKey('palabras.id_palabra'), primary_key=True)
    comparativo_aleman = db.Column(db.String(100))
    superlativo_aleman = db.Column(db.String(100))

def _oracion_hash(id_palabra, oracion_ejemplo):
    """Clave única anti-duplicados: md5(cast(id_palabra as text) || oracion_ejemplo)."""
    return hashlib.md5(f'{id_palabra}{oracion_ejemplo or ""}'.encode('utf-8')).hexdigest()


class Oracion(db.Model):
    __tablename__ = 'oraciones'
    id_oracion = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_palabra = db.Column(db.Integer, db.ForeignKey('palabras.id_palabra'))
    oracion_ejemplo = db.Column(db.String(500))
    oracion_traduccion = db.Column(db.String(500))
    nivel_dificultad = db.Column(db.Integer, default=1)
    hash_key = db.Column(db.String(32), unique=True)


@event.listens_for(Oracion, 'before_insert')
@event.listens_for(Oracion, 'before_update')
def _set_oracion_hash(mapper, connection, target):
    """Recalcula hash_key en cada insert/update para mantener la unicidad."""
    target.hash_key = _oracion_hash(target.id_palabra, target.oracion_ejemplo)


def upsert_oracion(id_palabra, texto, traduccion='', nivel=1, update_existing=True):
    """Inserta o actualiza una oración por clave md5(id_palabra||texto).

    - Si no existe → inserta y retorna la Oracion nueva (con id_oracion).
    - Si existe y update_existing=True → actualiza traducción/nivel y retorna None.
    - Si existe y update_existing=False → no toca nada y retorna None.
    """
    existing = Oracion.query.filter_by(hash_key=_oracion_hash(id_palabra, texto)).first()
    if existing:
        if update_existing:
            existing.oracion_traduccion = traduccion
            if nivel is not None:
                existing.nivel_dificultad = nivel
        return None
    o = Oracion(id_palabra=id_palabra, oracion_ejemplo=texto,
                oracion_traduccion=traduccion, nivel_dificultad=nivel)
    db.session.add(o)
    db.session.flush()
    return o

class PalabraOracion(db.Model):
    __tablename__ = 'palabra_oracion'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_oracion = db.Column(db.Integer, db.ForeignKey('oraciones.id_oracion'))
    orden = db.Column(db.Integer)
    palabra = db.Column(db.String(100))

class CatTematica(db.Model):
    __tablename__ = 'cat_tematica'
    id_tematica = db.Column(db.Integer, primary_key=True)
    nombre_tematica = db.Column(db.String(100))

def _tipo_to_article(tipo_id):
    return {1: 'der', 2: 'die', 3: 'das', 4: 'die'}.get(tipo_id, 'der')

def _nivel_to_cefr(nivel_id):
    return {1: 'A1', 2: 'A2', 3: 'B1', 4: 'B2'}.get(nivel_id, 'A1')

def _article_to_tipo(article):
    article = article.lower().strip()
    return {'der': 1, 'die': 2, 'das': 3}.get(article, 1)

def _cefr_to_nivel(cefr):
    return {'A1': 1, 'A2': 2, 'B1': 3, 'B2': 4}.get(cefr.upper(), 1)


class Usuario(db.Model):
    """Estudiante registrado desde la APK (distinto de User = admin)."""
    __tablename__ = 'usuarios'
    id_usuario = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nombre = db.Column(db.String(100))
    apellido = db.Column(db.String(100))
    correo = db.Column(db.String(150), unique=True, nullable=False)
    rango_edad = db.Column(db.Integer, default=2)  # 1<18, 2=18-35, 3=36-50, 4>50
    pais = db.Column(db.String(100))
    correo_representante = db.Column(db.String(150))
    nivel_acceso = db.Column(db.Integer, default=1)  # 1 Registrado, 2 Funcional, 3 Lic1, 4 Lic2
    estado = db.Column(db.Integer, default=0)  # 0 inactivo, 1 activo
    lopdp = db.Column(db.Integer, default=0)  # 0 no autorizado, 1 autorizado
    insistencias = db.Column(db.Integer, default=0)
    codigo_hash = db.Column(db.String(255))  # hash del código de 6 dígitos
    codigo_expiracion = db.Column(db.DateTime)
    token_autorizacion = db.Column(db.String(100))  # token para el link LOPDP
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow)
    id_suscripcion = db.Column(db.String(10), default='0')  # 0 = sin suscripción (uso limitado)
    tipo_usuario = db.Column(db.String(20), default='estudiante')  # estudiante | profesor

    def set_codigo(self, codigo):
        from werkzeug.security import generate_password_hash
        self.codigo_hash = generate_password_hash(codigo)

    def check_codigo(self, codigo):
        from werkzeug.security import check_password_hash
        return bool(self.codigo_hash) and check_password_hash(self.codigo_hash, codigo)


class RegistroUsuario(db.Model):
    """Historial de cambios de nivel de acceso. El código se guarda encriptado (hash)."""
    __tablename__ = 'registro_usuarios'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    fecha_hora = db.Column(db.DateTime, default=datetime.utcnow)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))
    codigo_enviado = db.Column(db.String(255))  # hash del código
    tipo_cambio = db.Column(db.String(10))  # '1->2', '2->3', '3->4'


class EventoUsuario(db.Model):
    """Eventos de ingreso/salida de la app (local; sync a Supabase en background)."""
    __tablename__ = 'eventos_usuario'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))
    tipo_evento = db.Column(db.String(20))  # login, logout, apertura
    fecha_hora = db.Column(db.DateTime, default=datetime.utcnow)
    dispositivo = db.Column(db.String(100))
    sincronizado = db.Column(db.Integer, default=0)  # 0 pendiente, 1 sincronizado


class DatosBatch(db.Model):
    """Metadatos de una carga batch. Las lecciones se crean al 'Activar' (no en la carga)."""
    __tablename__ = 'datos_batch'
    id_datos_batch = db.Column(db.Integer, primary_key=True, autoincrement=True)
    fecha_carga = db.Column(db.DateTime, default=datetime.utcnow)
    numero_palabras = db.Column(db.Integer, default=0)
    id_tematica = db.Column(db.Integer, db.ForeignKey('cat_tematica.id_tematica'))
    id_categoria = db.Column(db.Integer)  # 1 sustantivo, 2 verbo, 3 adjetivo, 4 conector
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))
    observaciones = db.Column(db.Text)
    nombre_archivo = db.Column(db.String(255))
    estado = db.Column(db.Integer, default=0)  # 0 cargada, 1 disponible, 2 inactivada


class EncabezadoLeccion(db.Model):
    """Cabecera de una lección creada al activar una carga batch."""
    __tablename__ = 'encabezado_leccion'
    id_leccion = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))
    fecha_inicio = db.Column(db.DateTime, default=datetime.utcnow)
    cantidad_palabras = db.Column(db.Integer, default=10)
    porcentaje_aciertos = db.Column(db.Integer)
    estado = db.Column(db.Integer, default=1)  # 1 activa, 0 inactiva
    tipo_leccion = db.Column(db.Integer, default=1)  # 1 pública, 2 privada
    id_suscripcion = db.Column(db.String(10), default='0')
    icono = db.Column(db.String(100))
    id_datos_batch = db.Column(db.Integer, db.ForeignKey('datos_batch.id_datos_batch'))


class LeccionDetalle(db.Model):
    """Elementos (palabra+juego) que componen una lección."""
    __tablename__ = 'leccion_detalle'
    id_detalle = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_leccion = db.Column(db.Integer, db.ForeignKey('encabezado_leccion.id_leccion'))
    id_palabra = db.Column(db.Integer, db.ForeignKey('palabras.id_palabra'))
    id_juego = db.Column(db.Integer)
    estado = db.Column(db.Integer, default=1)
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow)
    id_datos_batch = db.Column(db.Integer, db.ForeignKey('datos_batch.id_datos_batch'))


class LeccionPalabra(db.Model):
    """Seguimiento por usuario de las palabras de una lección (copia de detalle + avance)."""
    __tablename__ = 'leccion_palabras'
    id_leccion_palabra = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_leccion = db.Column(db.Integer, db.ForeignKey('encabezado_leccion.id_leccion'))
    id_palabra = db.Column(db.Integer, db.ForeignKey('palabras.id_palabra'))
    veces_revisada = db.Column(db.Integer, default=0)
    aprendida = db.Column(db.Integer, default=0)  # 0/1
    id_detalle = db.Column(db.Integer, db.ForeignKey('leccion_detalle.id_detalle'))
    id_juego = db.Column(db.Integer)
    respuesta = db.Column(db.Integer)  # 0/1 (última)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow)
    estado = db.Column(db.Integer, default=1)
    id_datos_batch = db.Column(db.Integer, db.ForeignKey('datos_batch.id_datos_batch'))
