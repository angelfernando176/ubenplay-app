import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vocabulary_noun.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'ubenplay_nouns.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE nouns (
          id INTEGER PRIMARY KEY AUTOINCREMENT, category_id TEXT NOT NULL,
          category_index INTEGER, word_id INTEGER, spanish TEXT NOT NULL,
          german TEXT NOT NULL, article TEXT NOT NULL, plural TEXT NOT NULL,
          cefr_level TEXT NOT NULL, image TEXT NOT NULL, image_code TEXT NOT NULL,
          example_sentence TEXT, definition TEXT
        )''');
        await db.execute('''CREATE TABLE palabras (
          id_palabra INTEGER PRIMARY KEY AUTOINCREMENT, id_categoria INTEGER DEFAULT 1,
          palabra_es TEXT NOT NULL, palabra_de TEXT NOT NULL, id_tipo INTEGER,
          id_nivel INTEGER DEFAULT 1, id_tematica INTEGER, definicion TEXT,
          imagen_path TEXT, activo INTEGER DEFAULT 1, texto_emoji TEXT,
          oracion_ejemplo TEXT, example_sentence TEXT, definition TEXT
        )''');
        await db.execute('''CREATE TABLE sustantivos (
          id_palabra INTEGER PRIMARY KEY, plural TEXT
        )''');
        await _crearTablasPersistencia(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migración de persistencia (v1 → v2): crear tablas nuevas sin borrar datos.
        await _crearTablasPersistencia(db);
      },
    );
    return _db!;
  }

  static VocabularyNoun _fromRow(Map<String, dynamic> row) {
    return VocabularyNoun(
      wordId: row['id_palabra'] as int? ?? row['id'] as int? ?? 0,
      spanish: (row['palabra_es'] ?? row['spanish'] ?? '') as String,
      german: (row['palabra_de'] ?? row['german'] ?? '') as String,
      article: row['article'] as String? ?? 'der',
      plural: row['plural'] as String? ?? row['sust_plural'] as String? ?? '',
      image: row['texto_emoji'] as String? ?? row['image'] as String? ?? '📦',
      imageCode: row['image_code'] as String? ?? '0000000001',
      exampleSentence: row['example_sentence'] as String? ?? '',
      definition: row['definition'] as String? ?? '',
      imageUrl: row['image_url'] as String? ?? '',
    );
  }

  static Future<void> clearAll() async {
    final db = await database;
    try { await db.delete('nouns'); } catch (_) {}
    try { await db.delete('palabras'); } catch (_) {}
    try { await db.delete('sustantivos'); } catch (_) {}
  }

  static Future<bool> hasData() async {
    final db = await database;
    try {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM nouns'));
      if (count != null && count > 0) return true;
    } catch (_) {}
    return false;
  }

  static Future<Map<String, List<VocabularyNoun>>> getAllGrouped() async {
    final db = await database;
    try {
      final rows = await db.query('nouns', orderBy: 'category_id, category_index ASC');
      if (rows.isNotEmpty) {
        final map = <String, List<VocabularyNoun>>{};
        for (final row in rows) {
          final cat = row['category_id'] as String;
          map.putIfAbsent(cat, () => []);
          map[cat]!.add(_fromRow(row));
        }
        return map;
      }
    } catch (_) {}
    return {};
  }

  static String _tematicaName(int id) {
    const names = {1:'family',2:'house',3:'food',4:'transport',5:'jobs',6:'travel',
      7:'city',8:'office',9:'tech',10:'health',11:'shopping',12:'city2',13:'timeplan',
      15:'animals',17:'school',99:'general'};
    return names[id] ?? 'general';
  }

  static Future<Map<String, int>> getCategoryCounts() async {
    final db = await database;
    try {
      final rows = await db.rawQuery('SELECT id_tematica, COUNT(*) as cnt FROM palabras WHERE activo=1 AND id_categoria=1 GROUP BY id_tematica');
      final map = <String, int>{};
      for (final row in rows) {
        map[_tematicaName(row['id_tematica'] as int? ?? 99)] = row['cnt'] as int;
      }
      if (map.isNotEmpty) return map;
    } catch (_) {}
    try {
      final rows = await db.rawQuery('SELECT category_id, COUNT(*) as cnt FROM nouns GROUP BY category_id');
      final map = <String, int>{};
      for (final row in rows) {
        map[row['category_id'] as String] = row['cnt'] as int;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<int> importFromExcel(List<Map<String, String>> rows, String category) async {
    final db = await database;
    int imported = 0;
    for (final row in rows) {
      try {
        await db.insert('nouns', {
          'category_id': category, 'spanish': row['spanish'] ?? '',
          'german': row['german'] ?? '', 'article': row['article'] ?? 'der',
          'plural': row['plural'] ?? '', 'cefr_level': row['level'] ?? 'A1',
          'image': '📦', 'image_code': (imported + 1).toString().padLeft(10, '0'),
          'example_sentence': row['example_sentence'] ?? '',
          'definition': row['definition'] ?? '',
        });
        imported++;
      } catch (_) {}
    }
    return imported;
  }

  static Future<void> insertBatch(List<Map<String, dynamic>> rows) async {
    final db = await database;
    for (final row in rows) {
      try { await db.insert('palabras', row); } catch (_) {}
    }
  }

  static Future<void> deleteByCategory(String categoryId) async {
    final db = await database;
    await db.delete('palabras', where: 'id_tematica = ?', whereArgs: [_tematicaId(categoryId)]);
  }
  
  static int _tematicaId(String name) {
    const map = {'family':1,'house':2,'food':3,'transport':4,'jobs':5,'travel':6,'city':7,'office':8,'tech':9,'health':10,'shopping':11,'city2':12,'timeplan':13,'general':99};
    return map[name.toLowerCase()] ?? 99;
  }

  /// Crea las tablas de persistencia del estudiante (directriz: SQLite → Supabase).
  /// Idempotente (IF NOT EXISTS); tablas que NACEN en el móvil llevan sincronizado+fecha_sync.
  static Future<void> createSchemaForTest(Database db) => _crearTablasPersistencia(db);

  static Future<void> _crearTablasPersistencia(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS progreso_usuario (
      id_usuario           INTEGER PRIMARY KEY,
      total_xp             INTEGER NOT NULL DEFAULT 0,
      total_correct        INTEGER NOT NULL DEFAULT 0,
      total_attempts       INTEGER NOT NULL DEFAULT 0,
      lessons_completed    INTEGER NOT NULL DEFAULT 0,
      current_streak       INTEGER NOT NULL DEFAULT 0,
      longest_streak       INTEGER NOT NULL DEFAULT 0,
      last_practice_date   TEXT,
      ultima_actualizacion TEXT NOT NULL DEFAULT (datetime('now')),
      sincronizado         INTEGER NOT NULL DEFAULT 0,
      fecha_sync           TEXT
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS leccion_palabras (
      id_leccion_palabra INTEGER PRIMARY KEY AUTOINCREMENT,
      id_leccion         INTEGER NOT NULL,
      id_palabra         INTEGER NOT NULL,
      id_detalle         INTEGER,
      id_juego           INTEGER,
      veces_revisada     INTEGER NOT NULL DEFAULT 0,
      aprendida          INTEGER NOT NULL DEFAULT 0,
      respuesta          INTEGER,
      id_usuario         INTEGER NOT NULL,
      fecha_registro     TEXT NOT NULL DEFAULT (datetime('now')),
      estado             INTEGER NOT NULL DEFAULT 1,
      id_datos_batch     INTEGER,
      sincronizado       INTEGER NOT NULL DEFAULT 0,
      fecha_sync         TEXT
    )''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lp_leccion_user ON leccion_palabras(id_leccion, id_usuario)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lp_user_fecha ON leccion_palabras(id_usuario, fecha_registro)');

    await db.execute('''CREATE TABLE IF NOT EXISTS estado_leccion (
      id_estado_leccion    INTEGER PRIMARY KEY AUTOINCREMENT,
      id_leccion           INTEGER NOT NULL,
      id_usuario           INTEGER NOT NULL,
      id_leccion_palabra   INTEGER,
      id_juego             INTEGER,
      sequence_hash        TEXT,
      fecha_actualizacion  TEXT NOT NULL DEFAULT (datetime('now')),
      sincronizado         INTEGER NOT NULL DEFAULT 0,
      fecha_sync           TEXT
    )''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_estado_leccion_user ON estado_leccion(id_usuario)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_estado_leccion_leccion ON estado_leccion(id_leccion)');

    await db.execute('''CREATE TABLE IF NOT EXISTS eventos_usuario (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      id_usuario   INTEGER NOT NULL,
      tipo_evento  TEXT NOT NULL,
      fecha_hora   TEXT NOT NULL DEFAULT (datetime('now')),
      dispositivo  TEXT,
      sincronizado INTEGER NOT NULL DEFAULT 0,
      fecha_sync   TEXT
    )''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_eventos_user ON eventos_usuario(id_usuario)');

    await db.execute('''CREATE TABLE IF NOT EXISTS registro_usuarios (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha_hora     TEXT NOT NULL DEFAULT (datetime('now')),
      id_usuario     INTEGER NOT NULL,
      codigo_enviado TEXT,
      tipo_cambio    TEXT,
      sincronizado   INTEGER NOT NULL DEFAULT 0,
      fecha_sync     TEXT
    )''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_registro_user ON registro_usuarios(id_usuario)');

    await db.execute('''CREATE TABLE IF NOT EXISTS ajuste_ui (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      clave      TEXT UNIQUE NOT NULL,
      valor      TEXT,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )''');
  }
}
