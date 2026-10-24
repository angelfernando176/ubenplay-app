"""Generación de imágenes vía Unsplash API — v2"""
import os, json, urllib.request, time
from database import db
from models import Palabra
from progress import start_task, update_progress, finish_task, fail_task

UNSPLASH_ACCESS_KEY = os.environ.get('UNSPLASH_KEY', '')
IMAGES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static', 'images')
BASE_URL = os.environ.get('BASE_URL', 'http://172.20.135.58:9999')
os.makedirs(IMAGES_DIR, exist_ok=True)

SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'

def _upload_to_storage(filepath, filename):
    try:
        with open(filepath, 'rb') as f: data = f.read()
        req = urllib.request.Request(
            f'{SUPABASE_URL}/storage/v1/object/nouns/{filename}',
            data=data, headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'image/png', 'x-upsert': 'true'}, method='POST')
        resp = urllib.request.urlopen(req, timeout=10)
        if resp.status in (200,201): return f'{SUPABASE_URL}/storage/v1/object/public/nouns/{filename}'
    except: pass
    return None

def _sync_image_to_supabase(word_id, image_url):
    try:
        data = json.dumps({'imagen_path': image_url}).encode()
        req = urllib.request.Request(f'{SUPABASE_URL}/rest/v1/palabras?id_palabra=eq.{word_id}',
            data=data, headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json'}, method='PATCH')
        urllib.request.urlopen(req, timeout=5)
    except: pass

def search_image(query):
    q = urllib.request.quote(query)
    try:
        req = urllib.request.Request(f'https://source.unsplash.com/200x200/?{q}', headers={'User-Agent': 'Ubenplay/1.0'})
        return urllib.request.urlopen(req, timeout=5).geturl()
    except:
        return f'https://api.dicebear.com/7.x/icons/svg?seed={q}&size=200'

def download_image(url, filepath):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Ubenplay/1.0'})
        with urllib.request.urlopen(req, timeout=10) as r:
            with open(filepath, 'wb') as f: f.write(r.read())
        return True
    except: return False

def generate_images_for_category(tematica_id, task_id=None):
    words = Palabra.query.filter_by(id_categoria=1, id_tematica=tematica_id, activo=True).all()
    results = {'total': len(words), 'generated': 0, 'failed': 0, 'skipped': 0}
    if task_id: start_task(task_id, len(words))
    for i, w in enumerate(words):
        if w.imagen_path and w.imagen_path.startswith('http'):
            results['skipped'] += 1
            if task_id: update_progress(task_id, i+1, f'Omitida: {w.palabra_es}')
            continue
        img_url = search_image(f'{w.palabra_de} {w.palabra_es}')
        if not img_url:
            results['failed'] += 1
            if task_id: update_progress(task_id, i+1, f'Sin resultado: {w.palabra_es}')
            continue
        filename = f'{w.id_palabra}.png'
        filepath = os.path.join(IMAGES_DIR, filename)
        if download_image(img_url, filepath):
            public_url = _upload_to_storage(filepath, filename) or f'{BASE_URL}/static/images/{filename}'
            w.imagen_path = public_url
            results['generated'] += 1
            if task_id: update_progress(task_id, i+1, f'OK {w.palabra_es}')
            db.session.commit()
            _sync_image_to_supabase(w.id_palabra, public_url)
        else:
            results['failed'] += 1
            if task_id: update_progress(task_id, i+1, f'FAIL {w.palabra_es}')
        time.sleep(0.4)
    if task_id: finish_task(task_id, f'{results["generated"]} generadas')
    return results

def generate_all_images(task_id=None):
    words = Palabra.query.filter_by(id_categoria=1).filter((Palabra.imagen_path == None) | (Palabra.imagen_path == '')).all()
    results = {'total': len(words), 'generated': 0, 'failed': 0}
    if task_id: start_task(task_id, len(words))
    for i, w in enumerate(words):
        img_url = search_image(f'{w.palabra_de} {w.palabra_es}')
        if not img_url:
            results['failed'] += 1
            if task_id: update_progress(task_id, i+1, f'Sin resultado: {w.palabra_es}')
            continue
        filename = f'{w.id_palabra}.png'
        filepath = os.path.join(IMAGES_DIR, filename)
        if download_image(img_url, filepath):
            public_url = _upload_to_storage(filepath, filename) or f'{BASE_URL}/static/images/{filename}'
            w.imagen_path = public_url
            results['generated'] += 1
            if task_id: update_progress(task_id, i+1, f'OK {w.palabra_es}')
            db.session.commit()
            _sync_image_to_supabase(w.id_palabra, public_url)
        else:
            results['failed'] += 1
            if task_id: update_progress(task_id, i+1, f'FAIL {w.palabra_es}')
        time.sleep(0.3)
    if task_id: finish_task(task_id, f'{results["generated"]} generadas')
    return results
