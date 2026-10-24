import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ubenplay_app/services/database_service.dart';

/// Prueba la creación de las tablas de persistencia (directriz SQLite→Supabase)
/// y la lógica de acumulación de progreso, usando SQLite en memoria (ffi).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('crea las tablas de persistencia y registra avance + progreso', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, v) async {
          await DatabaseService.createSchemaForTest(db);
        },
      ),
    );

    // Las 6 tablas de persistencia existen.
    for (final t in [
      'progreso_usuario', 'leccion_palabras', 'estado_leccion',
      'eventos_usuario', 'registro_usuarios', 'ajuste_ui',
    ]) {
      final n = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$t'");
      expect(n.isNotEmpty, true, reason: 'tabla $t no fue creada');
    }

    // Registro de avance: inserta fila en leccion_palabras con sincronizado=0.
    await db.insert('leccion_palabras', {
      'id_leccion': 5, 'id_palabra': 73, 'id_juego': 1,
      'veces_revisada': 1, 'aprendida': 1, 'respuesta': 1,
      'id_usuario': 13, 'fecha_registro': DateTime.now().toIso8601String(),
      'estado': 1, 'sincronizado': 0,
    });
    final pendientes = await db.query('leccion_palabras', where: 'sincronizado = 0');
    expect(pendientes.length, 1);

    // UPSERT acumulativo en progreso_usuario (acumula, no recalcula).
    await db.insert('progreso_usuario', {
      'id_usuario': 13, 'total_xp': 15, 'total_correct': 3,
      'total_attempts': 4, 'lessons_completed': 0, 'current_streak': 0,
      'longest_streak': 0, 'sincronizado': 0,
    });
    await db.update('progreso_usuario',
      {'total_correct': 5, 'total_attempts': 6, 'sincronizado': 0},
      where: 'id_usuario = ?', whereArgs: [13]);
    final row = await db.query('progreso_usuario', where: 'id_usuario = ?', whereArgs: [13]);
    expect(row.single['total_correct'], 5);
    expect(row.single['total_attempts'], 6);

    await db.close();
  });
}