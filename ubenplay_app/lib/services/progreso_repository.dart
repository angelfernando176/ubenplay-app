import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

/// Repositorio de persistencia del estudiante (directriz: SQLite → Supabase).
///
/// Agrupa las escrituras que NACEN en el móvil y que la cola de sync sube a
/// Supabase, marcando `sincronizado = 0` al escribir. `pending()` devuelve lo
/// pendiente de subir para cada tabla.
class ProgresoRepository {
  static Future<Database> get _db => DatabaseService.database;

  // ═══ leccion_palabras (avance por palabra × juego) ═══

  /// Registra el avance del estudiante por juego. Acumula `veces_revisada` y
  /// fija `aprendida`/`respuesta` según el resultado. Marca sincronizado=0.
  static Future<void> registrarAvance({
    required int idLeccion,
    required int idUsuario,
    required int idJuego,
    required List<Map<String, dynamic>> resultados,
    int? idDetalle,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final r in resultados) {
      final pid = r['id_palabra'];
      final resp = (r['respuesta'] == 1 || r['respuesta'] == true || r['respuesta'] == '1') ? 1 : 0;
      if (pid == null) continue;
      // Buscar fila existente (mismo id_leccion+id_palabra+id_juego+id_usuario).
      final existing = await db.query(
        'leccion_palabras',
        where: 'id_leccion = ? AND id_palabra = ? AND id_juego = ? AND id_usuario = ?',
        whereArgs: [idLeccion, pid, idJuego, idUsuario],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final row = existing.first;
        final id = row['id_leccion_palabra'] as int;
        final veces = (row['veces_revisada'] as int? ?? 0) + 1;
        batch.update(
          'leccion_palabras',
          {
            'veces_revisada': veces,
            'respuesta': resp,
            'aprendida': resp == 1 ? 1 : (row['aprendida'] as int? ?? 0),
            'sincronizado': 0,
          },
          where: 'id_leccion_palabra = ?',
          whereArgs: [id],
        );
      } else {
        batch.insert('leccion_palabras', {
          'id_leccion': idLeccion,
          'id_palabra': pid,
          'id_juego': idJuego,
          'id_detalle': idDetalle,
          'veces_revisada': 1,
          'respuesta': resp,
          'aprendida': resp,
          'id_usuario': idUsuario,
          'fecha_registro': now,
          'estado': 1,
          'sincronizado': 0,
        });
      }
    }
    await batch.commit(noResult: true);

    // UPSERT acumulativo en progreso_usuario (acumula, no recalcula).
    final correct = resultados.where((r) => r['respuesta'] == 1 || r['respuesta'] == true || r['respuesta'] == '1').length;
    final attempts = resultados.length;
    await _acumularProgreso(idUsuario: idUsuario, correct: correct, attempts: attempts, xp: 0);
  }

  /// Acumula aciertos/intentos (y opcional XP) en `progreso_usuario`.
  static Future<void> _acumularProgreso({
    required int idUsuario,
    required int correct,
    required int attempts,
    required int xp,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query('progreso_usuario', where: 'id_usuario = ?', whereArgs: [idUsuario], limit: 1);
    if (rows.isEmpty) {
      await db.insert('progreso_usuario', {
        'id_usuario': idUsuario,
        'total_xp': xp,
        'total_correct': correct,
        'total_attempts': attempts,
        'lessons_completed': 0,
        'current_streak': 0,
        'longest_streak': 0,
        'last_practice_date': now,
        'ultima_actualizacion': now,
        'sincronizado': 0,
      });
    } else {
      final row = rows.first;
      await db.update(
        'progreso_usuario',
        {
          'total_xp': (row['total_xp'] as int? ?? 0) + xp,
          'total_correct': (row['total_correct'] as int? ?? 0) + correct,
          'total_attempts': (row['total_attempts'] as int? ?? 0) + attempts,
          'last_practice_date': now,
          'ultima_actualizacion': now,
          'sincronizado': 0,
        },
        where: 'id_usuario = ?',
        whereArgs: [idUsuario],
      );
    }
  }

  /// Completa una lección: acumula XP/lección y actualiza racha.
  static Future<void> completarLeccion({
    required int idUsuario,
    required int xpEarned,
    required int correct,
    required int total,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query('progreso_usuario', where: 'id_usuario = ?', whereArgs: [idUsuario], limit: 1);
    if (rows.isEmpty) {
      await db.insert('progreso_usuario', {
        'id_usuario': idUsuario,
        'total_xp': xpEarned,
        'total_correct': correct,
        'total_attempts': total,
        'lessons_completed': 1,
        'current_streak': 1,
        'longest_streak': 1,
        'last_practice_date': now,
        'ultima_actualizacion': now,
        'sincronizado': 0,
      });
    } else {
      final row = rows.first;
      final streak = _nuevaRacha(row['last_practice_date'] as String?, row['current_streak'] as int? ?? 0);
      final longest = (row['longest_streak'] as int? ?? 0);
      await db.update(
        'progreso_usuario',
        {
          'total_xp': (row['total_xp'] as int? ?? 0) + xpEarned,
          'total_correct': (row['total_correct'] as int? ?? 0) + correct,
          'total_attempts': (row['total_attempts'] as int? ?? 0) + total,
          'lessons_completed': (row['lessons_completed'] as int? ?? 0) + 1,
          'current_streak': streak,
          'longest_streak': streak > longest ? streak : longest,
          'last_practice_date': now,
          'ultima_actualizacion': now,
          'sincronizado': 0,
        },
        where: 'id_usuario = ?',
        whereArgs: [idUsuario],
      );
    }
  }

  static int _nuevaRacha(String? lastDate, int current) {
    final now = DateTime.now();
    if (lastDate != null) {
      final last = DateTime.tryParse(lastDate);
      if (last != null) {
        final today = DateTime(now.year, now.month, now.day);
        final lastDay = DateTime(last.year, last.month, last.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) return current; // ya practicó hoy: mantiene
        if (diff == 1) return current + 1; // ayer: suma
      }
    }
    return 1; // reinicia
  }

  // ═══ estado_leccion (resume a media lección) ═══

  static Future<void> guardarEstadoLeccion({
    required int idLeccion,
    required int idUsuario,
    int? idJuego,
    int? idLeccionPalabra,
    String? sequenceHash,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query(
      'estado_leccion',
      where: 'id_leccion = ? AND id_usuario = ?',
      whereArgs: [idLeccion, idUsuario],
      limit: 1,
    );
    final data = {
      'id_juego': idJuego,
      'id_leccion_palabra': idLeccionPalabra,
      'sequence_hash': sequenceHash,
      'fecha_actualizacion': now,
      'sincronizado': 0,
    };
    if (rows.isEmpty) {
      await db.insert('estado_leccion', {
        ...data,
        'id_leccion': idLeccion,
        'id_usuario': idUsuario,
      });
    } else {
      await db.update('estado_leccion', data,
          where: 'id_leccion = ? AND id_usuario = ?', whereArgs: [idLeccion, idUsuario]);
    }
  }

  static Future<Map<String, dynamic>?> estadoLeccion(int idLeccion, int idUsuario) async {
    final db = await _db;
    final rows = await db.query(
      'estado_leccion',
      where: 'id_leccion = ? AND id_usuario = ?',
      whereArgs: [idLeccion, idUsuario],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> borrarEstadoLeccion(int idLeccion, int idUsuario) async {
    final db = await _db;
    await db.delete('estado_leccion', where: 'id_leccion = ? AND id_usuario = ?', whereArgs: [idLeccion, idUsuario]);
  }

  // ═══ eventos_usuario ═══

  static Future<void> registrarEvento({
    required int idUsuario,
    required String tipoEvento,
    String? dispositivo,
  }) async {
    final db = await _db;
    await db.insert('eventos_usuario', {
      'id_usuario': idUsuario,
      'tipo_evento': tipoEvento,
      'fecha_hora': DateTime.now().toUtc().toIso8601String(),
      'dispositivo': dispositivo,
      'sincronizado': 0,
    });
  }

  // ═══ ajuste_ui (local) ═══

  static Future<void> setAjuste(String clave, String valor) async {
    final db = await _db;
    await db.insert(
      'ajuste_ui',
      {'clave': clave, 'valor': valor, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getAjuste(String clave) async {
    final db = await _db;
    final rows = await db.query('ajuste_ui', where: 'clave = ?', whereArgs: [clave], limit: 1);
    return rows.isEmpty ? null : rows.first['valor'] as String?;
  }

  // ═══ cola de sync ═══

  /// Devuelve las filas pendientes de subir (`sincronizado = 0`) de una tabla.
  static Future<List<Map<String, dynamic>>> pending(String tabla) async {
    final db = await _db;
    return db.query(tabla, where: 'sincronizado = 0');
  }

  /// Marca una fila como sincronizada (por PK).
  static Future<void> marcarSincronizado(String tabla, String pkCol, int id, String fechaSync) async {
    final db = await _db;
    await db.update(tabla, {'sincronizado': 1, 'fecha_sync': fechaSync},
        where: '$pkCol = ?', whereArgs: [id]);
  }
}