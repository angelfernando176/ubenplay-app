import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/database_service.dart';
import '../data/lessons_data.dart';

/// Servicio de sincronización con el Admin Web
class SyncService {
  static String _serverUrl = 'http://192.168.100.14:9999';

  static void setServerUrl(String url) => _serverUrl = url;
  static String get serverUrl => _serverUrl;

  /// Descargar todas las palabras desde el admin web
  static Future<Map<String, dynamic>> syncFromServer() async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/api/words')).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {'success': false, 'error': 'Error del servidor: ${response.statusCode}'};
      }

      final data = json.decode(response.body);
      final words = data['words'] as List<dynamic>;

      if (words.isEmpty) {
        return {'success': false, 'error': 'El servidor no tiene palabras'};
      }

      // Agrupar por categoría
      final byCategory = <String, List<Map<String, dynamic>>>{};
      for (final w in words) {
        final cat = w['category_id'] as String? ?? 'imported';
        byCategory.putIfAbsent(cat, () => []);
        byCategory[cat]!.add(w);
      }

      // Insertar en BD local por categoría
      int total = 0;
      for (final entry in byCategory.entries) {
        // Eliminar existentes de esa categoría
        await DatabaseService.deleteByCategory(entry.key);

        // Insertar nuevos
        final rows = entry.value.map((w) => {
          'spanish': w['spanish']?.toString() ?? '',
          'article': w['article']?.toString() ?? 'der',
          'german': w['german']?.toString() ?? '',
          'plural': w['plural']?.toString() ?? '',
          'level': w['cefr_level']?.toString() ?? 'A1',
        }).toList();

        final result = await DatabaseService.importFromExcel(rows, entry.key);
        total += result;
      }

      // Recargar datos en memoria
      await LessonsData.reloadFromDatabase();

      return {
        'success': true,
        'imported': total,
        'categories': byCategory.length,
      };
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e\n\nVerifica que el admin web esté corriendo en $_serverUrl'};
    }
  }
}
