"""
validate_directrices.py — Valida que las directrices críticas del proyecto Ubenplay
estén intactas. Ejecutar ANTES de cualquier cambio de código y DESPUÉS de cada
carga de información.

Directrices protegidas:
  1. _clear_category filtra por id_tematica + id_categoria (NO borra toda la temática)
  2. COLUMN_ALIASES contiene todos los alias críticos
  3. _import_verbs usa id_categoria=2, _import_nouns usa id_categoria=1
  4. Sync incluye todos los campos (femenino, verbo_relacionado, conjugaciones)
  5. No hay duplicados en SQLite (mismo es+de+tema+cat)
  6. Tablas oraciones y palabra_oracion coherentes
  7. No hay palabras con español == alemán (idénticos)

Uso:
  python3 validate_directrices.py
  python3 validate_directrices.py --supabase   (también valida Supabase)
"""
import sys, os, re
import ast

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(os.path.dirname(os.path.abspath(__file__)))

FAILURES = []
PASSES = []

def check(name, condition, detail=''):
    if condition:
        PASSES.append(name)
        print(f'  ✅ {name}')
    else:
        FAILURES.append(name)
        print(f'  ❌ {name} — {detail}')

def main():
    print('=' * 60)
    print('🔍 Validando directrices del proyecto Ubenplay')
    print('=' * 60)

    # ── 1. _clear_category filtra por tipo+temática ──
    src = open('excel_import.py', encoding='utf-8').read()
    has_cat_filter = 'id_categoria=cat_id' in src or 'id_categoria = cat_id' in src
    check('1. _clear_category filtra por id_categoria',
          has_cat_filter,
          '_clear_category debe filtrar por id_tematica AND id_categoria')

    # ── 2. Aliases críticos presentes ──
    critical_aliases = [
        'ejemplo_oracion1', 'ejemplo_oracion1_traduccion',
        'oracion_pregunta1', 'traduccion_pregunta1',
        'palabra_espaniol', 'palabra_aleman', 'palabra_plural',
        'palabra_femenino', 'verbo_relacionado',
        'conjuga_sie_ella', 'conjuga_Sie_usted',
    ]
    missing_aliases = [a for a in critical_aliases if a not in src]
    check('2. Todos los alias críticos presentes',
          not missing_aliases,
          f'Faltan: {missing_aliases}')

    # ── 3. id_categoria correcto por tipo ──
    # _import_verbs debe usar id_categoria=2, _import_nouns id_categoria=1
    # Buscar en el bloque de _import_verbs
    m_verbs = re.search(r'def _import_verbs.*?(?=\ndef )', src, re.DOTALL)
    m_nouns = re.search(r'def _import_nouns.*?(?=\ndef )', src, re.DOTALL)
    verb_ok = m_verbs and 'id_categoria=2' in m_verbs.group(0)
    noun_ok = m_nouns and 'id_categoria=1' in m_nouns.group(0)
    check('3a. _import_verbs usa id_categoria=2', verb_ok)
    check('3b. _import_nouns usa id_categoria=1', noun_ok)

    # ── 4. Sync incluye todos los campos ──
    sync_fields = ['femenino', 'verbo_relacionado', 'plural', 'conjuga_ella',
                   'conjuga_usted', 'conjuga_ellos']
    missing_sync = [f for f in sync_fields if f"'{f}'" not in src and f'"{f}"' not in src]
    check('4. Sync incluye todos los campos', not missing_sync,
          f'Faltan en sync: {missing_sync}')

    # ── 5. Sin duplicados en SQLite ──
    try:
        from app import app
        from models import Palabra
        from collections import Counter
        with app.app_context():
            ps = Palabra.query.all()
            keys = [(p.palabra_es.lower().strip(), p.palabra_de.lower().strip(),
                     p.id_tematica, p.id_categoria) for p in ps]
            dupes = {k: c for k, c in Counter(keys).items() if c > 1}
            check('5. Sin duplicados en SQLite', not dupes,
                  f'{len(dupes)} duplicados: {list(dupes.items())[:5]}')
    except Exception as e:
        check('5. Sin duplicados en SQLite', False, f'Error: {e}')

    # ── 6. Coherencia oraciones/palabra_oracion ──
    try:
        from app import app
        from models import Oracion, PalabraOracion, Palabra
        with app.app_context():
            n_ora = Oracion.query.count()
            n_po = PalabraOracion.query.count()
            n_pal = Palabra.query.count()
            # Toda palabra con oracion_ejemplo debe tener oracion
            with_ex = Palabra.query.filter(Palabra.oracion_ejemplo != '', Palabra.oracion_ejemplo != None).count()
            with_ora = Oracion.query.count()
            check('6. Coherencia oraciones/palabra_oracion',
                  n_ora > 0 and n_po >= n_ora,
                  f'oraciones={n_ora}, palabra_oracion={n_po}, palabras={n_pal}')
    except Exception as e:
        check('6. Coherencia oraciones/palabra_oracion', False, f'Error: {e}')

    # ── 7. Sin palabras con español == alemán (evita alemán en ambos lados) ──
    try:
        from app import app
        from models import Palabra
        with app.app_context():
            ps = Palabra.query.all()
            bad = [p for p in ps
                   if (p.palabra_es or '').strip() == (p.palabra_de or '').strip()]
            check('7. Sin palabras con español == alemán', not bad,
                  f'{len(bad)} palabras idénticas: {[(p.palabra_es, p.palabra_de) for p in bad[:5]]}')
    except Exception as e:
        check('7. Sin palabras con español == alemán', False, f'Error: {e}')

    # ── Resultado ──
    print('=' * 60)
    print(f'✅ {len(PASSES)} pasaron | ❌ {len(FAILURES)} fallaron')
    if FAILURES:
        print('⚠️  Directrices violadas. NO continuar hasta corregir.')
        sys.exit(1)
    else:
        print('🎉 Todas las directrices intactas.')
        sys.exit(0)

if __name__ == '__main__':
    main()
