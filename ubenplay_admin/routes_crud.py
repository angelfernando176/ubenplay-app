from app import app
from database import db
from flask import render_template, request, redirect, url_for, flash
from flask_login import login_required
from models import Palabra, Sustantivo, _oracion_hash
from excel_import import TEMATICA_MAP

# ─── CRUD PALABRAS ────────────────────────────────────

@app.route('/words')
@login_required
def words_page():
    # Filtros
    nivel = request.args.get('nivel', '')
    categoria = request.args.get('categoria', '')
    id_tematica = request.args.get('id_tematica', '')
    id_categoria = request.args.get('id_categoria', '')
    search_field = request.args.get('search_field', 'palabra_es')
    search_query = request.args.get('search', '').strip()
    sort = request.args.get('sort', 'id_palabra')
    order = request.args.get('order', 'asc')
    page = request.args.get('page', 1, type=int)
    per_page = 15

    # Query base
    query = Palabra.query.filter_by(activo=True)

    # Filtro por nivel
    if nivel:
        nivel_id = {'A1': 1, 'A2': 2, 'B1': 3, 'B2': 4}.get(nivel.upper())
        if nivel_id:
            query = query.filter_by(id_nivel=nivel_id)

    # Filtro por categoría
    if categoria:
        cat_id = TEMATICA_MAP.get(categoria.lower().strip())
        if cat_id:
            query = query.filter_by(id_tematica=cat_id)

    # Filtro directo por temática + tipo (desde "Revisar" de Activar lecciones)
    if id_tematica:
        try:
            query = query.filter_by(id_tematica=int(id_tematica))
        except (ValueError, TypeError):
            pass
    if id_categoria:
        try:
            query = query.filter_by(id_categoria=int(id_categoria))
        except (ValueError, TypeError):
            pass

    # Búsqueda
    if search_query:
        valid_fields = {'palabra_es': Palabra.palabra_es, 'palabra_de': Palabra.palabra_de,
                        'definicion': Palabra.definicion, 'oracion_ejemplo': Palabra.oracion_ejemplo}
        field = valid_fields.get(search_field, Palabra.palabra_es)
        query = query.filter(field.ilike(f'%{search_query}%'))

    # Ordenamiento
    sort_map = {
        'id_palabra': Palabra.id_palabra, 'palabra_es': Palabra.palabra_es,
        'palabra_de': Palabra.palabra_de, 'id_nivel': Palabra.id_nivel,
        'id_tematica': Palabra.id_tematica, 'id_tipo': Palabra.id_tipo,
    }
    sort_col = sort_map.get(sort, Palabra.id_palabra)
    if order == 'desc':
        query = query.order_by(sort_col.desc())
    else:
        query = query.order_by(sort_col.asc())

    # Paginación
    total = query.count()
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    words = pagination.items

    # Datos para filtros
    niveles = {'A1': 1, 'A2': 2, 'B1': 3, 'B2': 4}
    tematicas = {v: k for k, v in TEMATICA_MAP.items() if isinstance(k, str) and len(k) > 2}

    return render_template('words.html',
        words=words, pagination=pagination, total=total,
        nivel=nivel, categoria=categoria, search_field=search_field,
        search_query=search_query, sort=sort, order=order,
        niveles=niveles, tematicas=sorted(set(tematicas.values())))


@app.route('/word/edit/<int:word_id>', methods=['GET', 'POST'])
@login_required
def edit_word(word_id):
    word = Palabra.query.get_or_404(word_id)
    if request.method == 'POST':
        word.palabra_es = request.form.get('palabra_es', word.palabra_es)
        word.palabra_de = request.form.get('palabra_de', word.palabra_de)
        word.id_tipo = int(request.form.get('id_tipo', word.id_tipo or 1))
        word.id_nivel = int(request.form.get('id_nivel', word.id_nivel or 1))
        word.id_tematica = int(request.form.get('id_tematica', word.id_tematica or 99))
        word.definicion = request.form.get('definicion', '')
        word.oracion_ejemplo = request.form.get('oracion_ejemplo', '')
        word.texto_emoji = request.form.get('texto_emoji', '📦')
        
        # Actualizar plural
        plural = request.form.get('plural', '')
        if word.sustantivo:
            word.sustantivo.plural = plural
        elif plural:
            db.session.add(Sustantivo(id_palabra=word.id_palabra, plural=plural))
        
        db.session.commit()
        _sync_single_to_supabase(word)
        flash('✅ Palabra actualizada', 'success')
        return redirect(url_for('words_page'))
    
    return render_template('word_edit.html', word=word)


@app.route('/word/toggle/<int:word_id>', methods=['POST'])
@login_required
def toggle_word(word_id):
    word = Palabra.query.get_or_404(word_id)
    word.activo = not word.activo
    db.session.commit()
    _sync_single_to_supabase(word)
    estado = 'activada' if word.activo else 'inactivada'
    flash(f'🔴 Palabra {estado}', 'info')
    return redirect(url_for('words_page'))


import json, urllib.request
SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'

def _sync_single_to_supabase(word):
    """Sincronizar una palabra editada a Supabase"""
    try:
        payload = {
            'palabra_es': word.palabra_es, 'palabra_de': word.palabra_de,
            'id_tipo': word.id_tipo or 1, 'id_nivel': word.id_nivel or 1,
            'id_tematica': word.id_tematica or 99, 'activo': word.activo,
            'definicion': word.definicion or '',
            'oracion_ejemplo': word.oracion_ejemplo or '',
            'texto_emoji': word.texto_emoji or '📦',
        }
        # Buscar por palabra_es + palabra_de (no tenemos el supabase id)
        data = json.dumps(payload).encode()
        req = urllib.request.Request(
            f'{SUPABASE_URL}/rest/v1/palabras?palabra_es=eq.{urllib.request.quote(word.palabra_es)}&palabra_de=eq.{urllib.request.quote(word.palabra_de)}',
            data=data,
            headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}',
                     'Content-Type': 'application/json'},
            method='PATCH')
        urllib.request.urlopen(req, timeout=10)
    except Exception:
        pass


# ─── CRUD ORACIONES ────────────────────────────────────

@app.route('/oraciones')
@login_required
def oraciones_page():
    from models import Oracion, Palabra
    page = request.args.get('page', 1, type=int)
    per_page = 15
    search = request.args.get('search', '').strip()
    field = request.args.get('field', 'oracion')
    sort = request.args.get('sort', 'id')
    order = request.args.get('order', 'asc')

    query = Oracion.query

    # Búsqueda
    if search:
        if field == 'traduccion':
            query = query.filter(Oracion.oracion_traduccion.ilike(f'%{search}%'))
        elif field == 'palabra':
            pids = [p.id_palabra for p in Palabra.query.filter(
                (Palabra.palabra_es.ilike(f'%{search}%')) | (Palabra.palabra_de.ilike(f'%{search}%')
            )).all()]
            query = query.filter(Oracion.id_palabra.in_(pids) if pids else Oracion.id_palabra == -1)
        else:
            query = query.filter(Oracion.oracion_ejemplo.ilike(f'%{search}%'))

    # Orden
    sort_map = {'id': Oracion.id_oracion, 'palabra': Oracion.id_palabra,
                'oracion': Oracion.oracion_ejemplo, 'nivel': Oracion.nivel_dificultad}
    sort_col = sort_map.get(sort, Oracion.id_oracion)
    query = query.order_by(sort_col.desc() if order == 'desc' else sort_col.asc())

    total = query.count()
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    oraciones = pagination.items

    # Nombres de nivel
    nivel_names = {1: 'A1 Básico', 2: 'A2 Elemental', 3: 'B1 Intermedio', 4: 'B2 Avanzado'}

    for o in oraciones:
        p = Palabra.query.get(o.id_palabra)
        o._palabra_es = p.palabra_es if p else '?'
        o._palabra_de = p.palabra_de if p else '?'
        o._nivel_nombre = nivel_names.get(o.nivel_dificultad, str(o.nivel_dificultad))

    return render_template('oraciones.html', oraciones=oraciones, pagination=pagination,
        total=total, search=search, field=field, sort=sort, order=order)

@app.route('/oracion/delete/<int:oid>', methods=['POST'])
@login_required
def delete_oracion(oid):
    from models import Oracion, PalabraOracion
    PalabraOracion.query.filter_by(id_oracion=oid).delete()
    o = Oracion.query.get_or_404(oid)
    db.session.delete(o)
    db.session.commit()
    flash('🗑️ Oración eliminada', 'info')
    return redirect(url_for('oraciones_page'))

@app.route('/oracion/edit/<int:oid>', methods=['GET', 'POST'])
@login_required
def edit_oracion(oid):
    from models import Oracion, PalabraOracion, Palabra
    o = Oracion.query.get_or_404(oid)
    p = Palabra.query.get(o.id_palabra)
    palabra_nombre = f'{p.palabra_de} ({p.palabra_es})' if p else '?'
    
    if request.method == 'POST':
        new_text = request.form.get('oracion_ejemplo', o.oracion_ejemplo)
        existing = Oracion.query.filter_by(hash_key=_oracion_hash(o.id_palabra, new_text)).first()
        if existing and existing.id_oracion != o.id_oracion:
            flash('⚠️ Ya existe una oración idéntica para esta palabra', 'error')
            return redirect(url_for('oraciones_page'))
        o.oracion_ejemplo = new_text
        o.oracion_traduccion = request.form.get('oracion_traduccion', o.oracion_traduccion or '')
        o.nivel_dificultad = int(request.form.get('nivel_dificultad', o.nivel_dificultad or 1))
        db.session.commit()
        
        # Regenerar palabra_oracion
        PalabraOracion.query.filter_by(id_oracion=o.id_oracion).delete()
        parts = o.oracion_ejemplo.split()
        for i, part in enumerate(parts):
            word = part.strip('.,;:!?¿¡()[]""')[:50]
            if word:
                db.session.add(PalabraOracion(id_oracion=o.id_oracion, orden=i+1, palabra=word))
        db.session.commit()
        
        flash('✅ Oración actualizada', 'success')
        return redirect(url_for('oraciones_page'))
    
    palabras = PalabraOracion.query.filter_by(id_oracion=o.id_oracion).order_by(PalabraOracion.orden).all()
    return render_template('oracion_edit.html', o=o, palabra_nombre=palabra_nombre, palabras=palabras)
