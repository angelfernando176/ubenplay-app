import 'package:supabase_flutter/supabase_flutter.dart';
import 'progreso_repository.dart';

/// Cola de sincronización SQLite → Supabase (directriz de persistencia).
///
/// Sube las filas locales con `sincronizado = 0` a Supabase (REST directo) y,
/// al confirmar, marca `sincronizado = 1` + `fecha_sync`. No pasa por el admin.
class SyncProgresoService {
  /// Sincroniza todas las tablas que nacen en el móvil. Devuelve un resumen.
  static Future<Map<String, String>> sync() async {
    final res = <String, String>{};
    await _syncTabla(
      tabla: 'progreso_usuario',
      pk: 'id_usuario',
      columnasRemote: ['id_usuario', 'total_xp', 'total_correct', 'total_attempts',
          'lessons_completed', 'current_streak', 'longest_streak', 'last_practice_date'],
      res: res,
    );
    await _syncTabla(
      tabla: 'leccion_palabras',
      pk: 'id_leccion_palabra',
      columnasRemote: ['id_leccion', 'id_palabra', 'id_detalle', 'id_juego',
          'veces_revisada', 'aprendida', 'respuesta', 'id_usuario', 'estado', 'id_datos_batch'],
      res: res,
    );
    await _syncTabla(
      tabla: 'estado_leccion',
      pk: 'id_estado_leccion',
      columnasRemote: ['id_leccion', 'id_usuario', 'id_leccion_palabra', 'id_juego', 'sequence_hash'],
      res: res,
    );
    await _syncTabla(
      tabla: 'eventos_usuario',
      pk: 'id',
      columnasRemote: ['id_usuario', 'tipo_evento', 'fecha_hora', 'dispositivo'],
      res: res,
    );
    return res;
  }

  /// Sincroniza una tabla usando upsert por PK. Los registros nuevos se insertan;
  /// los que ya tenían PK asignada por Supabase se actualizan. Marca fecha_sync.
  static Future<void> _syncTabla({
    required String tabla,
    required String pk,
    required List<String> columnasRemote,
    required Map<String, String> res,
  }) async {
    int subidos = 0;
    int fallos = 0;
    try {
      final pendientes = await ProgresoRepository.pending(tabla);
      for (final row in pendientes) {
        final payload = <String, dynamic>{};
        // Generar PK si es autoincrement local y aún vale 0 (no asignado en Supabase).
        for (final c in columnasRemote) {
          if (row.containsKey(c)) payload[c] = row[c];
        }
        // Para tablas con PK autogenerada local (leccion_palabras, estado_leccion,
        // eventos_usuario), NO enviamos el id local: Supabase asigna el suyo.
        final isAutoinc = (tabla != 'progreso_usuario');
        try {
          if (isAutoinc) {
            // Insert nuevo; no enviamos PK local.
            await Supabase.instance.client.from(tabla).insert(payload);
          } else {
            // progreso_usuario: PK = id_usuario (ya en payload). Upsert.
            await Supabase.instance.client.from(tabla).upsert(payload);
          }
          final idLocal = row[pk] as int;
          await ProgresoRepository.marcarSincronizado(tabla, pk, idLocal, DateTime.now().toIso8601String());
          subidos++;
        } catch (_) {
          fallos++;
        }
      }
    } catch (_) {}
    res[tabla] = '+$subidos/-$fallos';
  }
}