import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vocabulary_noun.dart';

/// Servicio Supabase v2 — schema PALABRAS + SUSTANTIVOS
class SupabaseService {
  static const _table = 'palabras';

  static Future<void> init({required String url, required String publishableKey}) async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  /// Obtener todos los sustantivos con su plural
  static Future<List<VocabularyNoun>> fetchAll() async {
    final data = await Supabase.instance.client
        .from(_table)
        .select('*, sustantivos(plural), verbos(*), adjetivos(*)')
        .inFilter('id_categoria', [1, 2, 3]) // sustantivos, verbos, adjetivos
        .eq('activo', true)
        .order('id_nivel')
        .order('id_tematica');

    return data.map(_fromRow).toList();
  }

  /// Obtener sustantivos por temática
  static Future<List<VocabularyNoun>> fetchByCategory(int tematicaId) async {
    final data = await Supabase.instance.client
        .from(_table)
        .select('*, sustantivos(plural), verbos(*), adjetivos(*)')
        .inFilter('id_categoria', [1, 2, 3])
        .eq('id_tematica', tematicaId)
        .eq('activo', true)
        .order('id_palabra');

    return data.map(_fromRow).toList();
  }

  /// Obtener sustantivos por nivel CEFR
  static Future<List<VocabularyNoun>> fetchByLevel(int nivelId) async {
    final data = await Supabase.instance.client
        .from(_table)
        .select('*, sustantivos(plural), verbos(*), adjetivos(*)')
        .inFilter('id_categoria', [1, 2, 3])
        .eq('id_nivel', nivelId)
        .eq('activo', true)
        .order('id_tematica');

    return data.map(_fromRow).toList();
  }

  /// Agrupar por temática — soporta sustantivos, verbos, adjetivos, conectores
  static Future<Map<String, List<VocabularyNoun>>> fetchAllGrouped() async {
    final data = await Supabase.instance.client
        .from(_table)
        .select('*, sustantivos(plural), verbos(*), adjetivos(*)')
        .inFilter('id_categoria', [1, 2, 3])
        .eq('activo', true)
        .order('id_tematica')
        .order('id_palabra');

    const themeMap = {1:'family',2:'house',3:'food',4:'transport',5:'jobs',6:'travel',
      7:'city',8:'office',9:'tech',10:'health',11:'shopping',12:'city2',13:'timeplan',
      15:'animals',17:'school',99:'popular'};

    final map = <String, List<VocabularyNoun>>{};
    for (final row in data) {
      final noun = _fromRow(row);
      final tid = row['id_tematica'] as int? ?? 99;
      final key = themeMap[tid] ?? 'general';
      map.putIfAbsent(key, () => []);
      map[key]!.add(noun);
    }
    return map;
  }

  /// Contar por temática
  static Future<Map<String, int>> getCategoryCounts() async {
    final data = await Supabase.instance.client
        .from(_table)
        .select('id_tematica, cat_tematica(nombre_tematica)')
        .inFilter('id_categoria', [1, 2, 3])
        .eq('activo', true);

    final map = <String, int>{};
    for (final row in data) {
      final name = row['cat_tematica'] is Map
          ? (row['cat_tematica'] as Map)['nombre_tematica']?.toString() ?? 'General'
          : 'General';
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  /// Verificar conexión
  static Future<bool> testConnection() async {
    try {
      await Supabase.instance.client.from(_table).select('id_palabra').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── FASE 4: lecciones activadas (vistas + tablas) ──────────────────

  /// Temáticas con lecciones disponibles (vista v_tematicas_disponibles).
  static Future<List<Map<String, dynamic>>> fetchTematicasDisponibles() async {
    final data = await Supabase.instance.client
        .from('v_tematicas_disponibles')
        .select()
        .order('id_tematica');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Lecciones disponibles (vista v_lecciones).
  static Future<List<Map<String, dynamic>>> fetchLecciones() async {
    final data = await Supabase.instance.client
        .from('v_lecciones')
        .select()
        .order('id_leccion');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Progreso por lección y usuario (vista v_progreso_leccion).
  static Future<List<Map<String, dynamic>>> fetchProgresoLeccion() async {
    final data = await Supabase.instance.client
        .from('v_progreso_leccion')
        .select();
    return List<Map<String, dynamic>>.from(data);
  }

  /// Elementos (palabra+juego) de una lección (tabla leccion_detalle).
  static Future<List<Map<String, dynamic>>> fetchLeccionDetalle(int idLeccion) async {
    final data = await Supabase.instance.client
        .from('leccion_detalle')
        .select()
        .eq('id_leccion', idLeccion)
        .eq('estado', 1)
        .order('id_detalle');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Palabras por ids (con plural/conjugaciones), sin orden garantizado.
  static Future<List<VocabularyNoun>> fetchPalabrasByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final data = await Supabase.instance.client
        .from(_table)
        .select('*, sustantivos(plural), verbos(*), adjetivos(*)')
        .inFilter('id_palabra', ids)
        .eq('activo', true);
    return data.map(_fromRow).toList();
  }

  /// Palabras de una lección EN ORDEN (según id_detalle).
  static Future<List<VocabularyNoun>> fetchPalabrasDeLeccion(int idLeccion) async {
    final detalles = await fetchLeccionDetalle(idLeccion);
    final idsInOrder = <int>[];
    final seen = <int>{};
    for (final d in detalles) {
      final pid = d['id_palabra'] as int?;
      if (pid != null && seen.add(pid)) idsInOrder.add(pid);
    }
    final palabras = await fetchPalabrasByIds(idsInOrder);
    final byId = <int, VocabularyNoun>{for (final p in palabras) p.wordId: p};
    return idsInOrder.map((id) => byId[id]).whereType<VocabularyNoun>().toList();
  }

  /// Distribución juego→palabras de una lección (según leccion_detalle).
  /// Retorna una lista ordenada de {id_juego, palabras}.
  static Future<List<Map<String, dynamic>>> fetchLeccionJuegos(int idLeccion) async {
    final detalles = await fetchLeccionDetalle(idLeccion);
    final juegoIds = <int>[];
    final seenJuego = <int>{};
    final palabrasPorJuego = <int, List<int>>{};
    for (final d in detalles) {
      final jid = d['id_juego'] as int?;
      final pid = d['id_palabra'] as int?;
      if (jid == null || pid == null) continue;
      if (seenJuego.add(jid)) juegoIds.add(jid);
      palabrasPorJuego.putIfAbsent(jid, () => []).add(pid);
    }
    final allIds = palabrasPorJuego.values.expand((x) => x).toSet().toList();
    final palabras = await fetchPalabrasByIds(allIds);
    final byId = <int, VocabularyNoun>{for (final p in palabras) p.wordId: p};
    return juegoIds.map((jid) => {
          'id_juego': jid,
          'palabras': palabrasPorJuego[jid]!
              .map((id) => byId[id])
              .whereType<VocabularyNoun>()
              .toList(),
        }).toList();
  }

  static VocabularyNoun _fromRow(Map<String, dynamic> row) {
    return VocabularyNoun.fromMap(row);
  }
}
