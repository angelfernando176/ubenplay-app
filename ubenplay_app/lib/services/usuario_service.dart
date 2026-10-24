import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'sync_service.dart';

/// Cliente HTTP al backend Flask para registro/verificación de usuarios.
///
/// Usa la misma URL de servidor que SyncService (configurable en AdminScreen).
class UsuarioService {
  static const _sessionKey = 'usuario_sesion';

  static String get _baseUrl => SyncService.serverUrl;

  // ── Sesión local (SharedPreferences) ─────────────────────────

  static Future<Usuario?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_sessionKey);
    if (json == null) return null;
    try {
      return Usuario.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSession(Usuario u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(u.toJson()));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // ── Llamadas al backend ──────────────────────────────────────

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      decoded['_status'] = response.statusCode;
      return decoded;
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e\nVerifica que el admin web esté corriendo en $_baseUrl',
      };
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$path')).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Registro: crea el usuario y envía el código de 6 dígitos por correo.
  static Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required int rangoEdad,
    required String pais,
    String? correoRepresentante,
  }) {
    final body = <String, dynamic>{
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'rango_edad': rangoEdad,
      'pais': pais,
    };
    if (correoRepresentante != null && correoRepresentante.isNotEmpty) {
      body['correo_representante'] = correoRepresentante;
    }
    return _post('/api/usuarios/registro', body);
  }

  /// Verificación del código de 6 dígitos → activa el usuario (estado 0→1).
  static Future<Map<String, dynamic>> verificar({
    required String correo,
    required String codigo,
  }) {
    return _post('/api/usuarios/verificar', {'correo': correo, 'codigo': codigo});
  }

  /// Reenvío del código (si no llegó).
  static Future<Map<String, dynamic>> reenviarCodigo({required String correo}) {
    return _post('/api/usuarios/reenviar-codigo', {'correo': correo});
  }

  /// Registra el avance del estudiante por juego en leccion_palabras (vía admin).
  static Future<void> registrarAvance({
    required int idUsuario,
    required int idLeccion,
    required List<Map<String, dynamic>> resultados,
  }) async {
    await _post('/api/leccion/avance', {
      'id_usuario': idUsuario,
      'id_leccion': idLeccion,
      'resultados': resultados,
    });
  }

  /// Consulta el estado actual del usuario en el backend.
  static Future<Map<String, dynamic>> estado({required String correo}) {
    return _get('/api/usuarios/estado?correo=${Uri.encodeComponent(correo)}');
  }
}
