import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

/// Servicio de audio: pronunciación (TTS) y efectos de sonido
class AudioService {
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  /// Inicializa TTS y audio
  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.4); // Lento para aprendizaje
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  /// Pronuncia un texto en español
  static Future<void> speak(String text) async {
    await init();
    await _tts.speak(text);
  }

  /// Detiene la pronunciación
  static Future<void> stop() async {
    await _tts.stop();
  }

  /// Reproduce el sonido de respuesta correcta
  static Future<void> playCorrectSound() async {
    try {
      await _player.play(
        AssetSource('sounds/correct.mp3'),
        volume: 0.7,
      );
    } catch (_) {
      // Silenciosamente ignorar si el archivo no existe aún
    }
  }

  /// Reproduce el sonido de respuesta incorrecta
  static Future<void> playIncorrectSound() async {
    try {
      await _player.play(
        AssetSource('sounds/incorrect.mp3'),
        volume: 0.7,
      );
    } catch (_) {
      // Silenciosamente ignorar
    }
  }

  /// Reproduce sonido de lección completada
  static Future<void> playCompleteSound() async {
    try {
      await _player.play(
        AssetSource('sounds/complete.mp3'),
        volume: 0.8,
      );
    } catch (_) {
      // Silenciosamente ignorar
    }
  }
}
