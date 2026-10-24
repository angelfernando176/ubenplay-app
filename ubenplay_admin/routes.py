"""Rutas del panel de administración"""
import os
from flask import render_template, request, redirect, url_for, flash, send_file, session
from flask_login import login_required, current_user, login_user, logout_user
from werkzeug.utils import secure_filename
from app import app
from database import db
from models import User, Palabra, Sustantivo, Oracion, PalabraOracion, CatTematica, upsert_oracion, DatosBatch
from auth import authenticate, create_user
from excel_import import import_excel, allowed_file, get_or_create_tematica
from image_generator import generate_images_for_category, generate_all_images
from progress import get_progress
import uuid
from game_config import GAMES, juegos_aplicables
from activacion import activar_batch, inactivar_batch, borrar_batch, sync_datos_batch_to_supabase

UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ─── AUTH ────────────────────────────────────────────

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username', '')
        password = request.form.get('password', '')
        success, error = authenticate(username, password)
        if success:
            return redirect(url_for('dashboard'))
        flash(error or 'Error al iniciar sesión', 'error')
    return render_template('login.html')


@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))


# ─── DASHBOARD ───────────────────────────────────────

@app.route('/')
@login_required
def dashboard():
    # Tipo seleccionado (default: sustantivos)
    wtype = request.args.get('type', 'noun')
    cat_id = 2 if wtype == 'verb' else 1
    cat_label = 'Verbos' if wtype == 'verb' else 'Sustantivos'
    
    stats = {
        'total_words': Palabra.query.filter_by(activo=True).count(),
        'nouns': Palabra.query.filter_by(id_categoria=1, activo=True).count(),
        'verbs': Palabra.query.filter_by(id_categoria=2, activo=True).count(),
        'adjectives': Palabra.query.filter_by(id_categoria=3, activo=True).count(),
        'connectors': Palabra.query.filter_by(id_categoria=4, activo=True).count(),
        'oraciones': Oracion.query.count(),
    }
    
    # Palabras por nivel CEFR (del tipo seleccionado)
    levels = {}
    for nivel_id, code in [(1,'A1'),(2,'A2'),(3,'B1'),(4,'B2')]:
        levels[code] = Palabra.query.filter_by(id_categoria=cat_id, id_nivel=nivel_id).count()
    
    # Últimas importaciones (desde uploads)
    import glob, os, time as _time
    recent = []
    upload_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
    for f in sorted(glob.glob(os.path.join(upload_dir, '*.xlsx')), key=os.path.getmtime, reverse=True)[:10]:
        fname = os.path.basename(f)
        fsize = os.path.getsize(f)
        ftime = _time.strftime('%d/%m/%Y %H:%M', _time.localtime(os.path.getmtime(f)))
        recent.append({'name': fname, 'date': ftime, 'size': f'{fsize/1024:.0f} KB'})
    
    # Conteo por temática (JOIN lógico con TEMATICA_MAP)
    from collections import Counter
    from excel_import import TEMATICA_MAP
    # Invertir: id → nombre
    tema_names = {v: k for k, v in TEMATICA_MAP.items()}
    
    words = Palabra.query.filter_by(id_categoria=cat_id, activo=True).all()
    cat_counts = Counter()
    for p in words:
        name = tema_names.get(p.id_tematica, f'Tema {p.id_tematica}')
        cat_counts[name] += 1
    
    return render_template('dashboard.html', stats=stats, 
                          categories=cat_counts.most_common(20),
                          wtype=wtype, cat_label=cat_label,
                          levels=levels, recent=recent)


# ─── IMPORT ──────────────────────────────────────────

@app.route('/import', methods=['GET', 'POST'])
@login_required
def import_page():
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('No se seleccionó ningún archivo', 'error')
            return redirect(request.url)

        file = request.files['file']
        if file.filename == '':
            flash('No se seleccionó ningún archivo', 'error')
            return redirect(request.url)

        if not allowed_file(file.filename):
            flash('Formato no permitido. Usa .xlsx o .xls', 'error')
            return redirect(request.url)

        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        word_type = request.form.get('word_type', 'auto').strip()
        cat_sel = request.form.get('category_id', '').strip()
        new_cat = request.form.get('new_category', '').strip()

        if new_cat:
            tematica_id = get_or_create_tematica(new_cat)
        elif cat_sel:
            tematica_id = int(cat_sel)
        else:
            tematica_id = None  # auto-detect (join con la columna 'tematica' del Excel)

        success, stats = import_excel(filepath, word_type, tematica_id)

        if success:
            # Registrar metadatos de la carga batch en datos_batch (estado 0 = cargada)
            try:
                batch = DatosBatch(
                    numero_palabras=stats.get('imported', 0),
                    id_tematica=stats.get('tematica_id'),
                    id_categoria=stats.get('id_categoria', 1),
                    id_usuario=(getattr(current_user, 'id_usuario', None) if current_user.is_authenticated else None),
                    nombre_archivo=filename,
                    observaciones=(request.form.get('observaciones', '') or '').strip() or None,
                    estado=0,
                )
                db.session.add(batch)
                db.session.commit()
                try:
                    sync_datos_batch_to_supabase(batch.id_datos_batch)
                except Exception:
                    pass
            except Exception as e:
                db.session.rollback()
                app.logger.warning(f'No se pudo registrar datos_batch: {e}')
            # Sync oraciones automáticamente
            try:
                from sync_oraciones import sync_oraciones_to_supabase
                sync_oraciones_to_supabase()
            except Exception:
                pass
            # Resumen de controles para el popup
            lines = [
                f"Se encontraron {stats.get('total', 0)} palabras",
                f"Se importaron {stats.get('imported', 0)} palabras",
                f"Se identificaron {stats.get('dupes', 0)} duplicados",
                f"Se identificaron {stats.get('same_lang', 0)} registros con las columnas \"palabra_espaniol\" y \"palabra_aleman\" con la misma información",
                "Recuerde activar las lecciones de esta carga para el estudiante, a través de la opción: Activar lecciones",
            ]
            if stats.get('repaso'):
                lines.append("⚠️ Algunas palabras re-cargadas tenían avance de estudiantes: se recomienda invitar al repaso de esa lección por más puntos.")
            session['import_summary'] = {
                'lines': lines,
                'details': stats.get('details', []),
            }
        else:
            flash(f'❌ {stats.get("error", "Error desconocido")}', 'error')

        return redirect(url_for('import_page'))

    categories = CatTematica.query.order_by(CatTematica.id_tematica).all()
    summary = session.pop('import_summary', None)
    return render_template('import.html', categories=categories, summary=summary)


@app.route('/pull-supabase', methods=['POST'])
@login_required
def pull_supabase():
    """Espejo Supabase → SQLite (Supabase es la fuente de verdad)."""
    from pull_supabase import pull
    report = pull(dry_run=False)
    a = sum(r['added'] for r in report.values())
    u = sum(r['updated'] for r in report.values())
    d = sum(r['deleted'] for r in report.values())
    flash(f'🔄 Sync Supabase→SQLite: +{a} añadidas, ~{u} actualizadas, -{d} borradas', 'success')
    return redirect(url_for('import_page'))


# ─── ACTIVAR LECCIONES ────────────────────────────────

@app.route('/activar-lecciones')
@login_required
def activar_lecciones_page():
    """Listado de cargas batch (datos_batch) para activar/inactivar lecciones."""
    batches = DatosBatch.query.order_by(DatosBatch.fecha_carga.desc()).all()
    tipo_labels = {1: 'Sustantivo', 2: 'Verbo', 3: 'Adjetivo', 4: 'Conector'}
    estado_labels = {0: 'Cargada', 1: 'Disponible', 2: 'Inactivado'}
    estado_colors = {0: '#777777', 1: '#58CC02', 2: '#FF4B4B'}
    rows = []
    for b in batches:
        rows.append({
            'id': b.id_datos_batch,
            'id_tematica': b.id_tematica,
            'id_categoria': b.id_categoria,
            'fecha': b.fecha_carga.strftime('%d/%m/%Y %H:%M') if b.fecha_carga else '-',
            'tipo': tipo_labels.get(b.id_categoria, f'Categoría {b.id_categoria}'),
            'cantidad': b.numero_palabras or 0,
            'archivo': b.nombre_archivo or '-',
            'estado': b.estado or 0,
            'estado_label': estado_labels.get(b.estado, f'Estado {b.estado}'),
            'estado_color': estado_colors.get(b.estado, '#777777'),
            'juegos': [{'id': gid, 'nombre': GAMES[gid]['nombre']}
                       for gid in juegos_aplicables(b.id_categoria or 1)],
        })
    return render_template('activar_lecciones.html', rows=rows)


@app.route('/activar-lecciones/<int:batch_id>/activar', methods=['POST'])
@login_required
def activar_batch_route(batch_id):
    juegos = request.form.get('juegos', '')
    ids = [j for j in juegos.split(',') if j.strip().isdigit()]
    ok, msg = activar_batch(batch_id, ids)
    flash(msg, 'success' if ok else 'error')
    return redirect(url_for('activar_lecciones_page'))


@app.route('/activar-lecciones/<int:batch_id>/inactivar', methods=['POST'])
@login_required
def inactivar_batch_route(batch_id):
    ok, msg = inactivar_batch(batch_id)
    flash(msg, 'success' if ok else 'error')
    return redirect(url_for('activar_lecciones_page'))


@app.route('/activar-lecciones/<int:batch_id>/borrar', methods=['POST'])
@login_required
def borrar_batch_route(batch_id):
    ok, msg = borrar_batch(batch_id)
    flash(msg, 'success' if ok else 'error')
    return redirect(url_for('activar_lecciones_page'))


@app.route('/api/leccion/avance', methods=['POST'])
def avance_leccion():
    """Recibe el avance del estudiante por juego (sin login admin; lo llama la APK)."""
    from activacion import registrar_avance
    data = request.get_json(silent=True) or {}
    id_usuario = data.get('id_usuario')
    id_leccion = data.get('id_leccion')
    resultados = data.get('resultados', []) or []
    if not id_usuario or not id_leccion:
        return {'success': False, 'error': 'Faltan id_usuario o id_leccion'}, 400
    ok, msg = registrar_avance(int(id_usuario), int(id_leccion), resultados)
    return {'success': ok, 'message': msg}, (200 if ok else 400)


# ─── USERS ───────────────────────────────────────────

@app.route('/users')
@login_required
def users_page():
    if not current_user.is_root:
        flash('Solo el administrador root puede gestionar usuarios', 'error')
        return redirect(url_for('dashboard'))
    users = User.query.all()
    return render_template('users.html', users=users)


@app.route('/users/create', methods=['POST'])
@login_required
def create_user_route():
    if not current_user.is_root:
        flash('No autorizado', 'error')
        return redirect(url_for('users_page'))

    username = request.form.get('username', '')
    password = request.form.get('password', '')
    role = request.form.get('role', 'profesor')
    name = request.form.get('name', '')
    correo = request.form.get('correo', '').strip()

    if not username or not password:
        flash('Usuario y contraseña son requeridos', 'error')
        return redirect(url_for('users_page'))

    success, msg = create_user(username, password, role, name, correo)
    flash(msg, 'success' if success else 'error')
    return redirect(url_for('users_page'))


@app.route('/users/<int:user_id>/delete', methods=['POST'])
@login_required
def delete_user(user_id):
    if not current_user.is_root:
        flash('No autorizado', 'error')
        return redirect(url_for('users_page'))
    user = User.query.get_or_404(user_id)
    if user.username == 'admin':
        flash('No se puede eliminar al administrador root', 'error')
    else:
        db.session.delete(user)
        db.session.commit()
        flash(f'Usuario {user.username} eliminado', 'success')
    return redirect(url_for('users_page'))


# ─── EXPORT ──────────────────────────────────────────

@app.route('/export_db')
@login_required
def export_db():
    """Descargar la base de datos actualizada"""
    from app import DB_PATH
    if os.path.exists(DB_PATH):
        return send_file(DB_PATH, as_attachment=True, download_name='lingo_nouns.db')
    flash('Base de datos no encontrada', 'error')
    return redirect(url_for('dashboard'))


# ─── API REST (para futura sincronización con app Flutter) ───

@app.route('/progress/<task_id>')
def progress_endpoint(task_id):
    return get_progress(task_id)


@app.route('/api/stats')
def api_stats():
    return {
        'total': Palabra.query.filter_by(activo=True).count(),
        'by_level': {l: Palabra.query.filter_by(id_nivel=i, activo=True).count() for i, l in [(1,'A1'),(2,'A2'),(3,'B1'),(4,'B2')]},
        'by_type': {'noun': Palabra.query.filter_by(id_categoria=1).count(), 'verb': 0, 'adjective': 0, 'connector': 0},
    }


@app.route('/api/words')
def api_words():
    words = Palabra.query.filter_by(id_categoria=1, activo=True).all()
    # Plural por palabra (bulk, evita N+1)
    pids = [w.id_palabra for w in words]
    plurals = {}
    if pids:
        for s in Sustantivo.query.filter(Sustantivo.id_palabra.in_(pids)).all():
            plurals[s.id_palabra] = s.plural or ''
    result = []
    for w in words:
        d = w.to_dict()
        d['plural'] = plurals.get(w.id_palabra, '')
        result.append(d)
    return {'words': result}


# ─── GENERAR IMÁGENES ──────────────────────────────

@app.route('/generate-images', methods=['POST'])
@login_required
def generate_images():
    category_id = request.form.get('category_id', '') or None
    task_id = str(uuid.uuid4())[:8]
    
    # Iniciar generación en un thread separado
    import threading
    
    def run_generation():
        with app.app_context():
            if category_id:
                generate_images_for_category(category_id, task_id=task_id)
            else:
                generate_all_images(task_id=task_id)
    
    thread = threading.Thread(target=run_generation)
    thread.start()
    
    return render_template('progress.html', task_id=task_id, 
                          title=f'Generando imágenes para {category_id or "todas las categorías"}')


@app.route('/import-sentences', methods=['POST'])
@login_required
def import_sentences():
    import pandas as pd, re, urllib.request, json
    from sqlalchemy import func
    from excel_import import SUPABASE_URL, SUPABASE_KEY, _safe_str, _es_de_same
    
    if 'file' not in request.files or not request.files['file'].filename:
        flash('❌ Selecciona un archivo', 'error')
        return redirect(url_for('import_page'))
    
    file = request.files['file']
    if not file.filename.endswith(('.xlsx', '.xls')):
        flash('❌ Solo .xlsx permitido', 'error')
        return redirect(url_for('import_page'))
    
    filename = secure_filename(file.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)
    
    try:
        df = pd.read_excel(filepath, engine='openpyxl')
    except Exception as e:
        flash(f'❌ Error: {e}', 'error')
        return redirect(url_for('import_page'))
    
    if df.empty:
        flash('❌ Archivo vacío', 'error')
        return redirect(url_for('import_page'))
    
    cleaned = [re.sub(r'\s*\([^)]*\)', '', _safe_str(c)).strip().lower() for c in df.columns]
    df.columns = cleaned
    # Alias para la palabra: acepta 'Español'/'Alemán' o 'palabra_espaniol'/'palabra_aleman'
    df.rename(columns={'español': 'palabra_espaniol', 'espanol': 'palabra_espaniol', 'es': 'palabra_espaniol',
                       'alemán': 'palabra_aleman', 'aleman': 'palabra_aleman', 'de': 'palabra_aleman'}, inplace=True)
    
    stats = {'total': len(df), 'imported': 0, 'updated': 0, 'errors': 0, 'dupes': 0, 'same_lang': 0, 'details': []}
    seen = set()

    for idx, row in df.iterrows():
        es_raw = _safe_str(row.get('palabra_espaniol', ''))
        de_raw = _safe_str(row.get('palabra_aleman', ''))
        es = es_raw.lower()
        de = de_raw.lower()
        if not es or not de:
            stats['errors'] += 1; stats['details'].append(f'Fila {idx+2}: falta espaniol/aleman'); continue
        if _es_de_same(es_raw, de_raw):
            stats['errors'] += 1; stats['same_lang'] += 1
            stats['details'].append(f'Fila {idx+2}: español y alemán idénticos ({es_raw!r}) — omitida'); continue
        if (es, de) in seen:
            stats['errors'] += 1; stats['dupes'] += 1
            stats['details'].append(f'Fila {idx+2}: duplicado ({es_raw} / {de_raw}) — omitida'); continue
        seen.add((es, de))
        
        # Match con trim + lower: palabra_es ↔ palabra_espaniol, palabra_de ↔ palabra_aleman
        es_col = func.lower(func.trim(Palabra.palabra_es))
        de_col = func.lower(func.trim(Palabra.palabra_de))
        p = Palabra.query.filter(es_col == es, de_col == de).first()
        if not p:
            p = Palabra.query.filter(de_col == de).first()
        if not p:
            stats['errors'] += 1; stats['details'].append(f'Fila {idx+2}: {es}/{de} no encontrada'); continue
        
        tipos = [('pregunta',1),('pregunta',2),('negacion',1),('negacion',2),('afirmativa',1),('afirmativa',2),('afirmativa',3)]
        for tipo, num in tipos:
            txt = _safe_str(row.get(f'oracion_{tipo}{num}', ''))
            trad = _safe_str(row.get(f'traduccion_{tipo}{num}', ''))
            if not txt: continue
            
            o = upsert_oracion(p.id_palabra, txt, trad, 1)
            if not o:
                stats['updated'] += 1
                continue
            words = []
            for i, part in enumerate(txt.split()):
                word = part.strip('.,;:!?¿¡()[]""')[:50]
                if word: words.append(word); db.session.add(PalabraOracion(id_oracion=o.id_oracion, orden=i+1, palabra=word))
            # Guardar palabras en la tabla palabra para sync a Supabase
            if words and not p.oracion_palabras:
                p.oracion_palabras = '|'.join(words)
            stats['imported'] += 1
    

    db.session.commit()
    session['import_summary'] = {
        'lines': [
            f"Se encontraron {stats['total']} filas de oraciones",
            f"Se importaron {stats['imported']} oraciones nuevas",
            f"Se actualizaron {stats['updated']} oraciones existentes",
            f"Se identificaron {stats['dupes']} duplicados",
            f"Se identificaron {stats['same_lang']} registros con las columnas \"palabra_espaniol\" y \"palabra_aleman\" con la misma información",
            f"Se encontraron {stats['errors']} errores",
        ],
        'details': stats['details'],
    }
    return redirect(url_for('import_page'))

@app.route('/sync-oraciones', methods=['POST'])
@login_required
def sync_oraciones():
    import threading
    from sync_oraciones import sync_oraciones_to_supabase
    
    def do_sync():
        try:
            sync_oraciones_to_supabase()
        except Exception as e:
            print(f'Sync error: {e}')
    
    threading.Thread(target=do_sync).start()
    flash('🔄 Sincronizando en segundo plano... Revisa Supabase en unos minutos.', 'info')
    return redirect(url_for('import_page'))
