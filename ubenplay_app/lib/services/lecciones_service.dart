import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Datos de lecciones activadas (Fase 4). Carga desde Supabase en memoria.
class LeccionesService {
  static List<Map<String, dynamic>> tematicas = [];
  static List<Map<String, dynamic>> lecciones = [];
  static List<Map<String, dynamic>> progreso = [];

  static const _keyLecciones = 'ultimas_lecciones';

  static Future<void> loadFromSupabase() async {
    try {
      tematicas = await SupabaseService.fetchTematicasDisponibles();
      lecciones = await SupabaseService.fetchLecciones();
      progreso = await SupabaseService.fetchProgresoLeccion();
    } catch (e) {
      // ignore: avoid_print
      print('[LeccionesService] Error cargando: $e');
    }
  }

  /// Lecciones de una temática, filtradas también por categoría (sustantivo/
  /// verbo/adjetivo/conector) para no mezclar categorías que comparten
  /// temática (ver bug corregido en `tematicasDeNivel`).
  static List<Map<String, dynamic>> leccionesDeTematica(int idTematica, int idCategoria) {
    return lecciones.where((l) =>
        l['id_tematica'] == idTematica && l['id_categoria'] == idCategoria).toList();
  }

  /// Temáticas (con sus lecciones) para un nivel CEFR dado (1=A1..4=B2).
  ///
  /// Bug corregido: la llave del mapa era solo `id_tematica`, pero una misma
  /// temática (ej. "Comida") puede existir en varias categorías (Sustantivo,
  /// Verbo, Adjetivo). Usar solo `id_tematica` colisionaba: la última
  /// categoría procesada sobrescribía `id_categoria` para TODAS, dejando
  /// invisibles las lecciones de las otras categorías en esa temática.
  static List<Map<String, dynamic>> tematicasDeNivel(int idNivel) {
    final map = <String, Map<String, dynamic>>{};
    for (final l in lecciones) {
      if ((l['id_nivel'] ?? 1) != idNivel) continue;
      final tid = l['id_tematica'] as int?;
      final catId = l['id_categoria'] as int?;
      if (tid == null || catId == null) continue;
      final key = '$tid|$catId';
      map.putIfAbsent(key, () => {
            'id_tematica': tid,
            'nombre_tematica': l['nombre_tematica'] ?? 'Temática',
            'id_categoria': catId,
            'lecciones': <Map<String, dynamic>>[],
          });
      (map[key]!['lecciones'] as List).add(l);
    }
    return map.values.toList();
  }

  static Map<String, dynamic>? progresoDe(int idLeccion, int idUsuario) {
    for (final p in progreso) {
      if (p['id_leccion'] == idLeccion && p['id_usuario'] == idUsuario) return p;
    }
    return null;
  }

  /// 0 = sin iniciar · 1 = iniciada · 2 = finalizada.
  static int estadoLeccion(Map<String, dynamic> leccion, int idUsuario) {
    final p = progresoDe(leccion['id_leccion'] as int, idUsuario);
    final requeridas =
        (leccion['porcentaje_aciertos'] ?? leccion['cantidad_palabras']) as int? ?? 10;
    if (p == null) return 0;
    final aprendidas = (p['palabras_aprendidas'] as int?) ?? 0;
    return aprendidas >= requeridas ? 2 : 1;
  }

  /// Detecta novedades vs cambios comparando con la última sincronización.
  /// Retorna: 'nuevos' si hay lecciones nuevas, 'cambios' si cambiaron de estado, o null.
  static Future<String?> detectarNovedades() async {
    final prefs = await SharedPreferences.getInstance();
    final anterior = jsonDecode(prefs.getString(_keyLecciones) ?? '{}') as Map<String, dynamic>;

    final actual = <String, int>{};
    for (final l in lecciones) {
      actual['${l['id_leccion']}'] = (l['estado'] ?? 1) as int;
    }

    var hayNuevas = false;
    var hayCambios = false;
    for (final e in actual.entries) {
      if (!anterior.containsKey(e.key)) {
        if (e.value == 1) hayNuevas = true;
      } else if (anterior[e.key] != e.value) {
        hayCambios = true;
      }
    }
    // Lecciones que estaban antes y ya no están (desactivadas/inactivadas).
    for (final key in anterior.keys) {
      if (!actual.containsKey(key)) {
        hayCambios = true;
      }
    }

    await prefs.setString(_keyLecciones, jsonEncode(actual));
    if (hayNuevas) return 'nuevos';
    if (hayCambios) return 'cambios';
    return null;
  }
}
