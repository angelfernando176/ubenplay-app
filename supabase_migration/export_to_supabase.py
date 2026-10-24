#!/usr/bin/env python3
"""
Exportar SQLite → PostgreSQL para Supabase
Uso: python3 export_to_supabase.py [--db path/to/lingo_nouns.db] [--output dump.sql]
"""

import sqlite3
import sys
import os
from datetime import datetime
from werkzeug.security import generate_password_hash

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'lingo_admin', 'lingo_nouns.db')
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), 'data_dump.sql')

def export_vocabulary(cursor, out):
    """Exportar tabla vocabulary"""
    count = 0
    # Leer de la tabla 'nouns' (SQLite del Flutter) o 'vocabulary' (Flask)
    tables = []
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    for row in cursor.fetchall():
        tables.append(row[0])
    
    table_name = 'vocabulary' if 'vocabulary' in tables else 'nouns'
    print(f"Usando tabla: {table_name}")
    
    cursor.execute(f"SELECT * FROM {table_name}")
    columns = [desc[0] for desc in cursor.description]
    
    out.write("-- Datos exportados de SQLite\n")
    out.write(f"-- Fecha: {datetime.now()}\n")
    out.write(f"-- Tabla: {table_name}\n\n")
    out.write("INSERT INTO vocabulary (spanish, german, article, plural, cefr_level, category_id, word_type, image_code, image_url) VALUES\n")
    
    rows = cursor.fetchall()
    lines = []
    for row in rows:
        data = dict(zip(columns, row))
        spanish = escape_sql(data.get('spanish', ''))
        german = escape_sql(data.get('german', ''))
        article = escape_sql(data.get('article', ''))
        plural = escape_sql(data.get('plural', ''))
        level = data.get('cefr_level', 'A1') or 'A1'
        cat = escape_sql(data.get('category_id', 'general'))
        wtype = data.get('word_type', 'noun') or 'noun'
        img_code = escape_sql(data.get('image_code', ''))
        img_url = escape_sql(data.get('image_url', ''))
        
        lines.append(f"  ('{spanish}','{german}','{article}','{plural}','{level}','{cat}','{wtype}','{img_code}','{img_url}')")
        count += 1
    
    out.write(",\n".join(lines))
    out.write(";\n\n")
    print(f"✅ {count} registros exportados")
    return count

def escape_sql(value):
    """Escapar comillas simples para SQL"""
    if value is None:
        return ''
    return str(value).replace("'", "''")

def create_admin_sql(out):
    """Generar INSERT para admin con hash de contraseña"""
    password_hash = generate_password_hash('admin123')
    out.write("-- Usuario admin\n")
    out.write(f"INSERT INTO admin_users (username, password_hash, role, name)\n")
    out.write(f"VALUES ('admin', '{password_hash}', 'root', 'Administrador')\n")
    out.write("ON CONFLICT (username) DO UPDATE SET password_hash = EXCLUDED.password_hash;\n\n")
    print("✅ Usuario admin generado")

def main():
    db_path = sys.argv[1] if len(sys.argv) > 1 else DB_PATH
    output_file = sys.argv[2] if len(sys.argv) > 2 else OUTPUT_FILE
    
    if not os.path.exists(db_path):
        print(f"❌ BD no encontrada: {db_path}")
        print(f"   Busca en: ~/lingo_admin/lingo_nouns.db")
        sys.exit(1)
    
    print(f"📂 Leyendo: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    with open(output_file, 'w', encoding='utf-8') as out:
        out.write("-- ============================================================\n")
        out.write("-- LINGO - Datos para Supabase\n")
        out.write(f"-- Generado: {datetime.now()}\n")
        out.write("-- Ejecutar en SQL Editor de Supabase DESPUÉS de crear el schema\n")
        out.write("-- ============================================================\n\n")
        
        export_vocabulary(cursor, out)
        create_admin_sql(out)
    
    conn.close()
    print(f"\n✅ Archivo generado: {output_file}")
    print(f"   Tamaño: {os.path.getsize(output_file) / 1024:.1f} KB")
    print(f"\n📋 Siguiente paso:")
    print(f"   1. Abre Supabase Dashboard → SQL Editor")
    print(f"   2. Ejecuta schema.sql (crea tablas)")
    print(f"   3. Ejecuta {os.path.basename(output_file)} (carga datos)")

if __name__ == '__main__':
    main()
