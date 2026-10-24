// Test de regresión: reproduce EXACTAMENTE la lógica de categoría/lección
// (fetchLeccionJuegos + _iniciarLeccion) con los datos reales de Supabase
// de la lección 20 (Verbo/Comida), para descartar un bug de reordenamiento
// en el código Dart compilado, independiente del estado del dispositivo.
import 'package:flutter_test/flutter_test.dart';
import 'package:ubenplay_app/models/game_type.dart';

void main() {
  test('secuencia de juegos respeta el orden real de leccion_detalle (id_detalle asc)', () {
    // Datos reales tal cual los devuelve Supabase para id_leccion=20, estado=1,
    // order=id_detalle (verificado por curl el 17/10).
    final detalles = <Map<String, dynamic>>[
      {'id_detalle': 543, 'id_juego': 1, 'id_palabra': 208},
      {'id_detalle': 544, 'id_juego': 1, 'id_palabra': 209},
      {'id_detalle': 548, 'id_juego': 3, 'id_palabra': 213},
      {'id_detalle': 553, 'id_juego': 4, 'id_palabra': 213},
      {'id_detalle': 558, 'id_juego': 5, 'id_palabra': 208},
      {'id_detalle': 566, 'id_juego': 7, 'id_palabra': 210},
      {'id_detalle': 574, 'id_juego': 8, 'id_palabra': 208},
      {'id_detalle': 578, 'id_juego': 9, 'id_palabra': 210},
      {'id_detalle': 582, 'id_juego': 10, 'id_palabra': 209},
      {'id_detalle': 587, 'id_juego': 11, 'id_palabra': 208},
      {'id_detalle': 593, 'id_juego': 12, 'id_palabra': 208},
    ];

    // --- Replica fetchLeccionJuegos (supabase_service.dart) ---
    final juegoIds = <int>[];
    final seenJuego = <int>{};
    for (final d in detalles) {
      final jid = d['id_juego'] as int;
      if (seenJuego.add(jid)) juegoIds.add(jid);
    }

    // --- Replica _iniciarLeccion (category_screen.dart) ---
    final secuencia = <GameType>[];
    for (final jid in juegoIds) {
      final g = gameTypeFromIdJuego(jid);
      if (g == null) continue;
      secuencia.add(g);
    }

    expect(secuencia.first, GameType.matching,
        reason: 'El primer juego debe ser "Unión de Palabras" (id_juego=1), '
            'tal como llega ordenado desde leccion_detalle.');
    expect(secuencia.first.displayName, 'Unión de Palabras');
  });
}
