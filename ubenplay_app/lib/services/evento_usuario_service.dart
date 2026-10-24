import 'dart:io';
import 'progreso_repository.dart';

/// Registro de eventos de ingreso/salida (login/logout/apertura).
///
/// Directriz de persistencia: los eventos viven en SQLite local (`eventos_usuario`)
/// con `sincronizado = 0`; la cola de sync los sube a Supabase. Ya NO usa
/// SharedPreferences.
class EventoUsuarioService {
  /// Identificador simple del dispositivo (sistema operativo + versión).
  static String get _dispositivo {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'android';
    }
  }

  /// Registra un evento localmente (SQLite, sincronizado=0).
  static Future<void> registrar(String tipo, {int? idUsuario}) async {
    if (idUsuario == null || idUsuario <= 0) return;
    await ProgresoRepository.registrarEvento(
      idUsuario: idUsuario,
      tipoEvento: tipo,
      dispositivo: _dispositivo,
    );
  }
}