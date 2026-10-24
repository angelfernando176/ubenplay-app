import pandas as pd, re, os, unicodedata
from datetime import datetime
from database import db
from models import Palabra, Sustantivo, Verbo, Adjetivo, Oracion, PalabraOracion, CatTematica, _article_to_tipo, _cefr_to_nivel, upsert_oracion

ALLOWED_EXTENSIONS = {'xlsx'}

COLUMN_ALIASES = {
    # Español
    'español': 'spanish', 'espanol': 'spanish', 'palabra_espaniol': 'spanish', 'es': 'spanish',
    'palabra español': 'spanish', 'palabra_español': 'spanish',
    # Artículo
    'artículo': 'article', 'articulo': 'article', 'art': 'article', 'artículo': 'article',
    # Alemán
    'alemán': 'german', 'aleman': 'german', 'palabra_aleman': 'german', 'de': 'german',
    'palabra alemán': 'german',
    # Plural
    'plural': 'plural', 'palabra_plural': 'plural', 'pl': 'plural',
    # Femenino
    'palabra_femenino': 'fem', 'femenino': 'fem',
    # Nivel
    'nivel': 'level', 'cefr': 'level', 'cefr_level': 'level', 'nivel cefr': 'level',
    # Temática
    'tematica': 'category', 'temática': 'category', 'tema': 'category',
    'categoria': 'word_cat', 'categoría': 'word_cat',
    # Oraciones — TODAS las variantes
    'ejemplo_oracion1': 'example', 'oracion_pregunta1': 'example', 'oracion1': 'example',
    'oracion_ejemplo1': 'example', 'frase_ejemplo': 'example', 'frase ejemplo': 'example',
    # Traducciones — TODAS las variantes
    'traduccion_pregunta1': 'translation', 'ejemplo_oracion1_traduccion': 'translation',
    'traduccion': 'translation', 'traducción': 'translation',
    'oracion_traduccion': 'translation', 'traduccion_oracion': 'translation', 'traduccion_oracion1': 'translation',
    # Definición
    'definicion_palabra': 'definition', 'definicion': 'definition', 'definición': 'definition',
    'verbo_relacionado': 'related_verb',
    # Verbos
    'infinitivo': 'infinitive', 'inf': 'infinitive',
    # Conjugaciones
    'conjuga_ich': 'conjuga_ich', 'conjuga_du': 'conjuga_du', 'conjuga_er': 'conjuga_er',
    'conjuga_sie': 'conjuga_sie', 'conjuga_es': 'conjuga_es',
    'conjuga_wir': 'conjuga_wir', 'conjuga_ihr': 'conjuga_ihr',
    'conjuga_sie_plural': 'conjuga_sie_plural',
    'conj_ich': 'conjuga_ich', 'conj_du': 'conjuga_du', 'conj_er': 'conjuga_er',
    'conj_sie': 'conjuga_sie', 'conj_es': 'conjuga_es',
    'conj_wir': 'conjuga_wir', 'conj_ihr': 'conjuga_ihr',
    'conj_sie_plural': 'conjuga_sie_plural',
}

# Columnas REQUERIDAS según tipo
REQUIRED_COLUMNS = {
    'noun': ['spanish', 'article', 'german'],
    'verb': ['spanish', 'german'],
    'adj': ['spanish', 'german'],
}

def validate_columns(df, word_type):
    """Valida que el Excel tenga las columnas necesarias. Retorna (ok, mensaje)."""
    missing = [c for c in REQUIRED_COLUMNS.get(word_type, ['spanish', 'german']) if c not in df.columns]
    if missing:
        return False, f'Faltan columnas: {", ".join(missing)}. Columnas detectadas: {", ".join(df.columns[:10])}'
    return True, ''

SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'

TEMATICA_MAP = {
    'family':1,'familia':1,'house':2,'casa':2,'food':3,'comida':3,
    'transport':4,'transporte':4,'jobs':5,'oficios':5,'travel':6,'viajes':6,'viaje':6,
    'city':7,'ciudad':7,'office':8,'oficina':8,'tech':9,'tecnologia':9,'tecnología':9,
    'health':10,'salud':10,'shopping':11,'compras':11,'city2':12,'lugares':12,
    'timeplan':13,'tiempo':13,'animals':15,'animales':15,'school':17,'escuela':17,
    'clothes':16,'ropa':16,'nature':15,'naturaleza':15,'sports':14,'deportes':14,
}

# ─── Resolución de temática: join contra la tabla cat_tematica (fuente de verdad) ───

def _normalize_tematica(s):
    """Normaliza un nombre de temática: minúsculas, sin tildes, sin espacios extra."""
    s = str(s).strip().lower()
    s = ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')
    return s

def _cat_tematica_map():
    """{nombre_normalizado: id_tematica} leído de la tabla cat_tematica."""
    m = {}
    for tid, nombre in db.session.query(CatTematica.id_tematica, CatTematica.nombre_tematica).all():
        n = _normalize_tematica(nombre)
        if n:
            m[n] = int(tid)
    return m

def _plural_variants(n):
    """Variantes singular/plural para un nombre normalizado."""
    v = set()
    if n.endswith('es'):
        v.add(n[:-2])
    elif n.endswith('s'):
        v.add(n[:-1])
    v.add(n + 's')
    v.add(n + 'es')
    return v

def resolve_tematica_id(name):
    """Join del valor de temática (columna 'tematica' del Excel) contra cat_tematica.
    Devuelve id_tematica o None si no existe. Tolerante a tildes y singular/plural."""
    n = _normalize_tematica(name)
    if not n:
        return None
    cmap = _cat_tematica_map()
    if n in cmap:
        return cmap[n]
    for v in _plural_variants(n):
        if v in cmap:
            return cmap[v]
    # Alias en inglés (legacy): solo si el id existe realmente en cat_tematica
    valid_ids = set(cmap.values())
    for key, tid in TEMATICA_MAP.items():
        if int(tid) in valid_ids and _normalize_tematica(key) == n:
            return int(tid)
    return None

def get_or_create_tematica(nombre):
    """Devuelve id_tematica existente (por nombre) o crea una nueva entrada en cat_tematica."""
    nombre = str(nombre).strip()
    if not nombre:
        return None
    existing = resolve_tematica_id(nombre)
    if existing:
        return existing
    max_id = db.session.query(db.func.max(CatTematica.id_tematica)).scalar() or 0
    new_id = int(max_id) + 1
    if new_id == 99:
        new_id = int(max_id) + 2  # evita chocar con 99 (General)
    db.session.add(CatTematica(id_tematica=new_id, nombre_tematica=nombre))
    db.session.commit()
    return new_id

# Emojis por palabra — mapeo amplio
WORD_EMOJIS = {
    'familia': '👨‍👩‍👧‍👦', 'padre': '👨', 'madre': '👩', 'hijo': '👦', 'hija': '👧',
    'hermano': '👨', 'hermana': '👩', 'abuelo': '👴', 'abuela': '👵', 'bebé': '👶',
    'adulto': '🧑', 'amigo': '🤝', 'amiga': '👩‍🤝‍👩', 'alumno': '👨‍🎓', 'alumna': '👩‍🎓',
    'vecino': '🏘️', 'vecina': '👩', 'turista': '📸', 'niño': '👦', 'niña': '👧',
    'casa': '🏠', 'edificio': '🏢', 'apartamento': '🏢', 'habitación': '🛏️',
    'cocina': '🍳', 'baño': '🛁', 'jardín': '🌳', 'puerta': '🚪', 'ventana': '🪟',
    'techo': '🏠', 'pared': '🧱', 'escalera': '🪜', 'sótano': '🏚️', 'ático': '🏠',
    'balcón': '🏗️', 'pasillo': '🚶', 'terraza': '🏡', 'armario': '🗄️', 'alfombra': '🟫',
    'ascensor': '🛗', 'suelo': '🟤', 'entrada': '🚪', 'salida': '🏃',
    'garaje': '🚗', 'buzón': '📬', 'timbre': '🔔', 'llave': '🔑', 'cerradura': '🔒',
    'comida': '🍽️', 'agua': '💧', 'pan': '🍞', 'leche': '🥛', 'queso': '🧀',
    'carne': '🥩', 'pescado': '🐟', 'huevo': '🥚', 'fruta': '🍎', 'verdura': '🥬',
    'manzana': '🍎', 'naranja': '🍊', 'plátano': '🍌', 'uva': '🍇', 'fresa': '🍓',
    'tomate': '🍅', 'cebolla': '🧅', 'ajo': '🧄', 'papa': '🥔', 'arroz': '🍚',
    'pollo': '🍗', 'cerdo': '🐷', 'ternera': '🐄', 'sal': '🧂', 'azúcar': '🍬',
    'café': '☕', 'té': '🍵', 'cerveza': '🍺', 'vino': '🍷', 'jugo': '🧃',
    'transporte': '🚗', 'coche': '🚗', 'auto': '🚙', 'autobús': '🚌', 'bus': '🚌',
    'tren': '🚂', 'avión': '✈️', 'barco': '🚢', 'bicicleta': '🚲', 'moto': '🏍️',
    'taxi': '🚕', 'metro': '🚇', 'camión': '🚛', 'helicóptero': '🚁',
    'calle': '🛣️', 'carretera': '🛣️', 'autopista': '🛣️', 'cruce': '🚦', 'semáforo': '🚦',
    'puente': '🌉', 'túnel': '🚇', 'estación': '🚉', 'aeropuerto': '🛫', 'puerto': '⚓',
    'acera': '🚶', 'plaza': '🏛️', 'parada': '🚏', 'esquina': '📐', 'peatón': '🚶',
    'fuente': '⛲', 'monumento': '🗽', 'banco': '🪑', 'árbol': '🌳', 'flor': '🌸',
    'ayuntamiento': '🏛️', 'correos': '📮', 'comisaría': '👮', 'biblioteca': '📚',
    'viaje': '🧳', 'hotel': '🏨', 'maleta': '🧳', 'pasaporte': '📘', 'billete': '🎫',
    'playa': '🏖️', 'montaña': '🏔️', 'bosque': '🌲', 'río': '🏞️', 'lago': '🏞️',
    'animal': '🐾', 'perro': '🐕', 'gato': '🐈', 'caballo': '🐎', 'pájaro': '🐦',
    'pez': '🐠', 'conejo': '🐰', 'ratón': '🐭', 'elefante': '🐘', 'león': '🦁',
    'escuela': '🏫', 'maestro': '👨‍🏫', 'libro': '📚', 'lápiz': '✏️',
    'mochila': '🎒', 'computadora': '💻', 'teléfono': '📱', 'televisión': '📺',
    'doctor': '👨‍⚕️', 'hospital': '🏥', 'medicina': '💊', 'enfermo': '🤒',
    'dinero': '💰', 'tienda': '🛒', 'supermercado': '🛒', 'mercado': '🏪',
    'ropa': '👕', 'camisa': '👔', 'pantalón': '👖', 'zapato': '👞', 'vestido': '👗',
    'abrigo': '🧥', 'sombrero': '🎩', 'bufanda': '🧣', 'guante': '🧤',
    'deporte': '⚽', 'fútbol': '⚽', 'baloncesto': '🏀', 'tenis': '🎾', 'natación': '🏊',
    'gimnasio': '🏋️', 'correr': '🏃', 'bailar': '💃', 'música': '🎵', 'cantar': '🎤',
    'ciudad': '🏙️', 'pueblo': '🏘️', 'campo': '🌾', 'iglesia': '⛪', 'museo': '🏛️',
    'restaurante': '🍽️', 'cine': '🎬', 'teatro': '🎭', 'parque': '🏞️', 'zoológico': '🦁',
    'sol': '☀️', 'luna': '🌙', 'estrella': '⭐', 'nube': '☁️', 'lluvia': '🌧️',
    'nieve': '❄️', 'viento': '💨', 'fuego': '🔥',
    'abrir': '🔓', 'cerrar': '🔒', 'buscar': '🔍', 'comprar': '🛍️', 'alquilar': '🔑',
    'encontrar': '📍', 'ayudar': '🤝', 'bajar': '⬇️', 'subir': '⬆️',
}

def _safe_str(val):
    """Convierte celda a string limpio; NaN/None/vacío → '' (evita texto basura 'nan')."""
    import pandas as pd
    if isinstance(val, pd.Series):
        val = val.iloc[0] if len(val) > 0 else ''
    try:
        if pd.isna(val):
            return ''
    except (TypeError, ValueError):
        pass
    if val is None:
        return ''
    s = str(val).strip()
    return '' if s.lower() in ('nan', 'none', 'null', 'nat', '<na>') else s

def _es_de_same(es, de):
    """True si el contenido de español y alemán es EXACTAMENTE idéntico (sensible a
    mayúsculas).

    Control anti-error: detecta la palabra alemana copiada en el campo español
    (ej. palabra_espaniol='dunkel', palabra_aleman='dunkel'), que hace que los juegos
    muestren alemán en ambos lados. Sensible a mayúsculas para NO marcar préstamos
    legítimos tipo 'tomate'/'Tomate' (español minúscula vs alemán mayúscula).
    """
    return _safe_str(es).strip() == _safe_str(de).strip()

def _word_emoji(spanish_word):
    """Emoji representativo de la palabra"""
    w = spanish_word.lower().strip()
    if w in WORD_EMOJIS: return WORD_EMOJIS[w]
    # Buscar por palabras clave
    for key, emoji in WORD_EMOJIS.items():
        if key in w or w in key: return emoji
    return '📦'

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def normalize_columns(df):
    # Renombrar columnas que colisionan al lowercase
    manual = {}
    for c in df.columns:
        s = str(c).strip()
        if s == 'conjuga_sie_ella':
            manual[s] = 'conjuga_sie'
        elif s == 'conjuga_Sie_usted':
            manual[s] = 'conjuga_Sie_formal'
    df.rename(columns=manual, inplace=True)
    
    cleaned = []
    for c in df.columns:
        s = re.sub(r'\s*\([^)]*\)', '', str(c).strip()).strip().lower()
        cleaned.append(s)
    
    # Detectar duplicados
    from collections import Counter
    dupes = [k for k, v in Counter(cleaned).items() if v > 1]
    if dupes:
        raise ValueError(f'Columnas duplicadas detectadas: {", ".join(dupes)}. '
                         f'Renombre las columnas para que sean únicas.')
    
    df.columns = cleaned
    df.rename(columns=COLUMN_ALIASES, inplace=True)
    return df

def import_excel(filepath, word_type='auto', category_id=None):
    try:
        df = pd.read_excel(filepath, engine='openpyxl')
    except Exception as e:
        return False, {'error': str(e)}
    if df.empty:
        return False, {'error': 'El archivo Excel está vacío'}
    
    df = normalize_columns(df)
    
    # Normalizar el tipo desde el desplegable
    if word_type in ('adjective', 'adjetivo', 'adjectives'):
        word_type = 'adj'
    
    # Validar columnas
    ok, msg = validate_columns(df, word_type if word_type != 'auto' else 'noun')
    if not ok:
        return False, {'error': msg}
    
    # Auto-detectar tipo desde el Excel (columna 'categoria' = id_categoria)
    first_row = df.iloc[0]
    if word_type == 'auto':
        wc = _safe_str(first_row.get('word_cat', first_row.get('categoria', ''))).lower()
        if wc in ('2', 'verb', 'verbo'):
            word_type = 'verb'
        elif wc in ('3', 'adj', 'adjetivo', 'adjective'):
            word_type = 'adj'
        else:
            word_type = 'noun'
    
    # Resolver temática:
    #  1) id explícito del desplegable (category_id entero)
    #  2) si no, join de la columna 'tematica' del Excel contra cat_tematica
    #  3) si no resuelve → error (nunca fallback silencioso a 99/General)
    excel_tematica = _safe_str(first_row.get('category', first_row.get('tematica', '')))
    if category_id is not None:
        try:
            tematica_id = int(category_id)
        except (ValueError, TypeError):
            tematica_id = resolve_tematica_id(str(category_id).strip())
    else:
        tematica_id = resolve_tematica_id(excel_tematica)
    
    if not tematica_id:
        nombre = str(category_id) if category_id is not None else excel_tematica
        return False, {'error': (
            f'Temática "{nombre or "(vacía)"}" no existe en cat_tematica. '
            'Selecciónala en el desplegable o créala como nueva categoría.')}
    
    stats = {'total': len(df), 'imported': 0, 'skipped': 0, 'same_lang': 0, 'dupes': 0,
             'details': [], 'tematica_id': tematica_id,
             'id_categoria': {'noun': 1, 'verb': 2, 'adj': 3}.get(word_type, 1)}
    stats['repaso'] = _clear_category(tematica_id, word_type)

    
    if word_type == 'verb':
        return _import_verbs(df, tematica_id, stats)
    elif word_type == 'adj':
        return _import_adjectives(df, tematica_id, stats)
    else:
        return _import_nouns(df, tematica_id, stats)

def _cleanup_lesson_data(pids):
    """Limpia datos de lecciones (detalle/seguimiento/encabezado) asociados a palabras
    que van a re-importarse. Retorna True si había progreso de estudiante (avisar repaso)."""
    from models import LeccionDetalle, LeccionPalabra, EncabezadoLeccion
    if not pids:
        return False
    detalles = LeccionDetalle.query.filter(LeccionDetalle.id_palabra.in_(pids)).all()
    if not detalles:
        return False
    det_ids = [d.id_detalle for d in detalles]
    lec_ids = list({d.id_leccion for d in detalles})
    progreso = LeccionPalabra.query.filter(
        LeccionPalabra.id_detalle.in_(det_ids),
        ((LeccionPalabra.aprendida == 1) | (LeccionPalabra.veces_revisada > 0))
    ).count() > 0
    LeccionPalabra.query.filter(LeccionPalabra.id_detalle.in_(det_ids)).delete(synchronize_session=False)
    LeccionDetalle.query.filter(LeccionDetalle.id_detalle.in_(det_ids)).delete(synchronize_session=False)
    for lid in lec_ids:
        if LeccionDetalle.query.filter_by(id_leccion=lid).count() == 0:
            EncabezadoLeccion.query.filter_by(id_leccion=lid).delete(synchronize_session=False)
    db.session.commit()
    return progreso


def _clear_category(tematica_id, word_type):
    """Borra palabras de una temática+tipo en SQLite y Supabase.
    Retorna True si había progreso de estudiante en lecciones afectadas (avisar repaso)."""
    cat_id = 2 if word_type == 'verb' else (3 if word_type == 'adj' else 1)
    target_pids = [p.id_palabra for p in Palabra.query.filter_by(
        id_tematica=tematica_id, id_categoria=cat_id).all()]
    
    # 0. Limpiar datos de lecciones asociados (dedup §4.2)
    progreso = _cleanup_lesson_data(target_pids) if target_pids else False
    
    # 1. Borrar de Supabase (si hay políticas DELETE)
    if target_pids:
        _supabase_delete_category(tematica_id, cat_id, target_pids)
    
    # 2. Borrar de SQLite
    if target_pids:
        oids = [o.id_oracion for o in Oracion.query.filter(Oracion.id_palabra.in_(target_pids)).all()]
        if oids:
            PalabraOracion.query.filter(PalabraOracion.id_oracion.in_(oids)).delete(synchronize_session=False)
        Oracion.query.filter(Oracion.id_palabra.in_(target_pids)).delete(synchronize_session=False)
        if word_type == 'verb':
            Verbo.query.filter(Verbo.id_palabra.in_(target_pids)).delete(synchronize_session=False)
        elif word_type == 'adj':
            Adjetivo.query.filter(Adjetivo.id_palabra.in_(target_pids)).delete(synchronize_session=False)
        else:
            Sustantivo.query.filter(Sustantivo.id_palabra.in_(target_pids)).delete(synchronize_session=False)
        Palabra.query.filter(Palabra.id_palabra.in_(target_pids)).delete(synchronize_session=False)
    
    db.session.commit()
    return progreso

def _supabase_delete_category(tematica_id, cat_id, pids):
    """Borra de Supabase por temática y categoría usando (es,de) como llave"""
    try:
        import urllib.request, json
        # Obtener palabras de Supabase para esta temática
        r = urllib.request.Request(
            f'{SUPABASE_URL}/rest/v1/palabras?select=id_palabra,palabra_es,palabra_de'
            f'&id_tematica=eq.{tematica_id}&id_categoria=eq.{cat_id}',
            headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}'})
        supa_words = json.loads(urllib.request.urlopen(r).read())
        supa_pids = [w['id_palabra'] for w in supa_words]
        
        if not supa_pids:
            return
        
        # Borrar palabra_oracion asociadas
        r = urllib.request.Request(
            f'{SUPABASE_URL}/rest/v1/oraciones?select=id_oracion'
            f'&id_palabra=in.({",".join(str(p) for p in supa_pids)})',
            headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}'})
        supa_oids = [o['id_oracion'] for o in json.loads(urllib.request.urlopen(r).read())]
        
        for oid in supa_oids:
            try:
                req = urllib.request.Request(f'{SUPABASE_URL}/rest/v1/palabra_oracion?id_oracion=eq.{oid}',
                    method='DELETE', headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}'})
                urllib.request.urlopen(req)
            except: pass
        
        # Borrar oraciones
        for pid in supa_pids:
            try:
                req = urllib.request.Request(f'{SUPABASE_URL}/rest/v1/oraciones?id_palabra=eq.{pid}',
                    method='DELETE', headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}'})
                urllib.request.urlopen(req)
            except: pass
        
        # Borrar sustantivos/verbos
        table = 'verbos' if cat_id == 2 else ('adjetivos' if cat_id == 3 else 'sustantivos')
        for pid in supa_pids:
            try:
                req = urllib.request.Request(f'{SUPABASE_URL}/rest/v1/{table}?id_palabra=eq.{pid}',
                    method='DELETE', headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}'})
                urllib.request.urlopen(req)
            except: pass
        
        # Borrar palabras
        for pid in supa_pids:
            try:
                req = urllib.request.Request(f'{SUPABASE_URL}/rest/v1/palabras?id_palabra=eq.{pid}',
                    method='DELETE', headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}'})
                urllib.request.urlopen(req)
            except: pass
                
    except Exception as e:
        pass  # Sin políticas DELETE, falla silenciosamente

def _import_nouns(df, tematica_id, stats):
    seen = set()
    for idx, row in df.iterrows():
        es = _safe_str(row.get('spanish', ''))
        art = _safe_str(row.get('article', ''))
        de = _safe_str(row.get('german', ''))
        pl = _safe_str(row.get('plural', ''))
        fem = _safe_str(row.get('fem', ''))
        lv = _safe_str(row.get('level', 'A1')).upper()
        ex = _safe_str(row.get('example', ''))
        trad = _safe_str(row.get('translation', ''))
        dfn = _safe_str(row.get('definition', ''))
        rv = _safe_str(row.get('related_verb', ''))
        
        if not es or not de:
            stats['skipped'] += 1; continue
        if _es_de_same(es, de):
            stats['skipped'] += 1
            stats['same_lang'] += 1
            stats['details'].append(f'Fila {idx+2}: español y alemán idénticos ({es!r}) — omitida')
            continue
        key = (es.strip().lower(), de.strip().lower())
        if key in seen:
            stats['skipped'] += 1
            stats['dupes'] += 1
            stats['details'].append(f'Fila {idx+2}: duplicado ({es} / {de}) — omitida')
            continue
        seen.add(key)
        
        p = Palabra(
            id_categoria=1, id_tipo=_article_to_tipo(art), id_nivel=_cefr_to_nivel(lv),
            id_tematica=tematica_id, palabra_es=es, palabra_de=de,
            definicion=dfn, oracion_ejemplo=ex, texto_emoji=_word_emoji(es),
        )
        db.session.add(p)
        db.session.flush()
        db.session.add(Sustantivo(id_palabra=p.id_palabra, plural=pl, femenino=fem, verbo_relacionado=rv))
        stats['imported'] += 1
        
        # Crear oración si tiene ejemplo (control anti-duplicados)
        if ex:
            o = upsert_oracion(p.id_palabra, ex, trad, 1)
            if o:
                for i, part in enumerate(ex.split()):
                    word = part.strip('.,;:!?¿¡()[]""')[:50]
                    if word: db.session.add(PalabraOracion(id_oracion=o.id_oracion, orden=i+1, palabra=word))
    
    db.session.commit()
    _sync_to_supabase(tematica_id, 'noun')
    _create_oraciones(tematica_id, 1)
    return True, stats

def _import_verbs(df, tematica_id, stats):
    seen = set()
    for idx, row in df.iterrows():
        es = _safe_str(row.get('spanish', ''))
        de = _safe_str(row.get('german', ''))
        lv = _safe_str(row.get('level', 'A1')).upper()
        ex = _safe_str(row.get('example', ''))
        trad = _safe_str(row.get('translation', ''))
        dfn = _safe_str(row.get('definition', ''))
        ci = _safe_str(row.get('conjuga_ich', row.get('conj_ich', '')))
        cd = _safe_str(row.get('conjuga_du', row.get('conj_du', '')))
        ce = _safe_str(row.get('conjuga_er', row.get('conj_er', '')))
        cs = _safe_str(row.get('conjuga_sie', row.get('conj_sie', '')))
        ces = _safe_str(row.get('conjuga_es', row.get('conj_es', '')))
        cw = _safe_str(row.get('conjuga_wir', row.get('conj_wir', '')))
        chi = _safe_str(row.get('conjuga_ihr', row.get('conj_ihr', '')))
        cS = _safe_str(row.get('conjuga_Sie_formal', row.get('conjuga_sie_formal', '')))
        cp = _safe_str(row.get('conjuga_sie_plural', row.get('conj_sie_plural', '')))
        ej1 = _safe_str(row.get('ejemplo_oracion1', ''))
        
        if not es or not de:
            stats['skipped'] += 1; continue
        if _es_de_same(es, de):
            stats['skipped'] += 1
            stats['same_lang'] += 1
            stats['details'].append(f'Fila {idx+2}: español y alemán idénticos ({es!r}) — omitida')
            continue
        key = (es.strip().lower(), de.strip().lower())
        if key in seen:
            stats['skipped'] += 1
            stats['dupes'] += 1
            stats['details'].append(f'Fila {idx+2}: duplicado ({es} / {de}) — omitida')
            continue
        seen.add(key)
        
        p = Palabra(
            id_categoria=2, id_tipo=4, id_nivel=_cefr_to_nivel(lv),
            id_tematica=tematica_id, palabra_es=es, palabra_de=de,
            definicion=dfn, oracion_ejemplo=ex, texto_emoji=_word_emoji(es),
        )
        db.session.add(p)
        db.session.flush()
        db.session.add(Verbo(
            id_palabra=p.id_palabra,
            conjuga_ich=ci, conjuga_du=cd, conjuga_er=ce, conjuga_sie=cs,
            conjuga_es=ces, conjuga_wir=cw, conjuga_ihr=chi,
            conjuga_Sie_formal=cS, conjuga_sie_plural=cp, ejemplo_oracion1=ej1,
        ))
        stats['imported'] += 1
        
        # Crear oración con traducción (control anti-duplicados)
        if ex:
            o = upsert_oracion(p.id_palabra, ex, trad, 1)
            if o:
                for i, part in enumerate(ex.split()):
                    word = part.strip('.,;:!?¿¡()[]""')[:50]
                    if word: db.session.add(PalabraOracion(id_oracion=o.id_oracion, orden=i+1, palabra=word))
    
    db.session.commit()
    _sync_to_supabase(tematica_id, 'verb')
    _create_oraciones(tematica_id, 1)
    return True, stats

def _import_adjectives(df, tematica_id, stats):
    """Importa adjetivos (id_categoria=3) con comparativo y superlativo."""
    seen = set()
    for idx, row in df.iterrows():
        es = _safe_str(row.get('spanish', ''))
        de = _safe_str(row.get('german', ''))
        comp = _safe_str(row.get('comparativo', ''))
        sup = _safe_str(row.get('superlativo', ''))
        lv = _safe_str(row.get('level', 'A1')).upper()
        ex = _safe_str(row.get('example', ''))
        trad = _safe_str(row.get('translation', ''))
        dfn = _safe_str(row.get('definition', ''))

        if not es or not de:
            stats['skipped'] += 1; continue
        if _es_de_same(es, de):
            stats['skipped'] += 1
            stats['same_lang'] += 1
            stats['details'].append(f'Fila {idx+2}: español y alemán idénticos ({es!r}) — omitida')
            continue
        key = (es.strip().lower(), de.strip().lower())
        if key in seen:
            stats['skipped'] += 1
            stats['dupes'] += 1
            stats['details'].append(f'Fila {idx+2}: duplicado ({es} / {de}) — omitida')
            continue
        seen.add(key)

        # id_tipo: 9=regular (por defecto), 10=irregular (columna opcional 'tipo')
        tipo = _safe_str(row.get('tipo', '')).lower()
        id_tipo = 10 if tipo in ('irregular', 'irr', '10') else 9

        p = Palabra(
            id_categoria=3, id_tipo=id_tipo, id_nivel=_cefr_to_nivel(lv),
            id_tematica=tematica_id, palabra_es=es, palabra_de=de,
            definicion=dfn, oracion_ejemplo=ex, texto_emoji=_word_emoji(es),
        )
        db.session.add(p)
        db.session.flush()
        db.session.add(Adjetivo(
            id_palabra=p.id_palabra,
            comparativo_aleman=comp,
            superlativo_aleman=sup,
        ))
        stats['imported'] += 1

        # Crear oración con traducción (control anti-duplicados)
        if ex:
            o = upsert_oracion(p.id_palabra, ex, trad, 1)
            if o:
                for i, part in enumerate(ex.split()):
                    word = part.strip('.,;:!?¿¡()[]""')[:50]
                    if word:
                        db.session.add(PalabraOracion(id_oracion=o.id_oracion, orden=i+1, palabra=word))

    db.session.commit()
    _sync_to_supabase(tematica_id, 'adj')
    _create_oraciones(tematica_id, 1)
    return True, stats

def _create_oraciones(tematica_id, nivel_id):
    """Genera oraciones desde ejemplos ya guardados (solo si no existen)"""
    palabras = Palabra.query.filter_by(id_tematica=tematica_id).all()
    for p in palabras:
        ex = (p.oracion_ejemplo or '').strip()
        if not ex: continue
        # No duplicar: control por hash md5(id_palabra||texto)
        o = upsert_oracion(p.id_palabra, ex, '', nivel_id, update_existing=False)
        if not o: continue
        for i, part in enumerate(ex.split()):
            word = part.strip('.,;:!?¿¡()[]""')[:50]
            if word: db.session.add(PalabraOracion(id_oracion=o.id_oracion, orden=i+1, palabra=word))
    db.session.commit()

def _sync_to_supabase(tematica_id, word_type):
    """Sincroniza palabras + sustantivos/verbos a Supabase"""
    try:
        import json, urllib.request
        H = {'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}',
             'Content-Type': 'application/json', 'Prefer': 'resolution=merge-duplicates'}
        
        palabras = Palabra.query.filter_by(id_tematica=tematica_id).all()
        if not palabras: return
        
        # Palabras
        payload = []
        for p in palabras:
            payload.append({
                'id_palabra': p.id_palabra, 'id_categoria': p.id_categoria, 'id_tipo': p.id_tipo,
                'id_nivel': p.id_nivel, 'id_tematica': p.id_tematica,
                'palabra_es': p.palabra_es, 'palabra_de': p.palabra_de,
                'definicion': p.definicion or '', 'oracion_ejemplo': p.oracion_ejemplo or '',
                'texto_emoji': p.texto_emoji or '',
            })
        _supabase_post('palabras', payload)
        
        # Sustantivos, Verbos o Adjetivos
        if word_type == 'verb':
            verbos = Verbo.query.filter(Verbo.id_palabra.in_([p.id_palabra for p in palabras])).all()
            if verbos:
                payload = [{
                    'id_palabra': v.id_palabra,
                    'conjuga_ich': v.conjuga_ich or '', 'conjuga_du': v.conjuga_du or '',
                    'conjuga_er': v.conjuga_er or '', 'conjuga_ella': v.conjuga_sie or '',
                    'conjuga_es': v.conjuga_es or '', 'conjuga_wir': v.conjuga_wir or '',
                    'conjuga_ihr': v.conjuga_ihr or '', 'conjuga_usted': v.conjuga_Sie_formal or '',
                    'conjuga_ellos': v.conjuga_sie_plural or '',
                } for v in verbos]
                _supabase_post('verbos', payload)
        elif word_type == 'adj':
            adjs = Adjetivo.query.filter(Adjetivo.id_palabra.in_([p.id_palabra for p in palabras])).all()
            if adjs:
                payload = [{'id_palabra': a.id_palabra,
                           'comparativo_aleman': a.comparativo_aleman or '',
                           'superlativo_aleman': a.superlativo_aleman or ''} for a in adjs]
                _supabase_post('adjetivos', payload)
        else:
            susts = Sustantivo.query.filter(Sustantivo.id_palabra.in_([p.id_palabra for p in palabras])).all()
            if susts:
                payload = [{'id_palabra': s.id_palabra, 'plural': s.plural or '', 
                           'femenino': s.femenino or '', 'verbo_relacionado': s.verbo_relacionado or ''} for s in susts]
                _supabase_post('sustantivos', payload)
    except Exception:
        pass

def _supabase_post(table, payload):
    import json, urllib.request
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f'{SUPABASE_URL}/rest/v1/{table}',
        data=data, method='POST',
        headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}',
                 'Content-Type': 'application/json', 'Prefer': 'resolution=merge-duplicates'})
    urllib.request.urlopen(req)

# ─── Flask request helpers ────────────────────────────────────

def request_category_id():
    try:
        from flask import request
        return request.form.get('category_id', '').strip().lower()
    except:
        return ''

def request_tematica_id():
    try:
        from flask import request
        return TEMATICA_MAP.get(request.form.get('category_id', '').strip().lower(), 99)
    except:
        return 99

def request_word_cat():
    try:
        from flask import request
        return request.form.get('word_type', '')
    except:
        return ''
