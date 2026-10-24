import 'package:flutter_test/flutter_test.dart';
import 'package:ubenplay_app/models/vocabulary_noun.dart';
import 'package:ubenplay_app/data/lessons_data.dart';

List<VocabularyNoun> _fakeNouns(int n) => List.generate(
    n, (i) => VocabularyNoun(wordId: i + 1, spanish: 'p${i + 1}', german: 'w${i + 1}'));

void main() {
  group('Regla 2: 10 palabras por lección (división entera, resto pendiente)', () {
    test('todas las lecciones tienen exactamente 10 palabras', () {
      for (final filter in ['Sustantivos', 'Verbos', 'Adjetivos', 'Conectores']) {
        final lessons = LessonsData.getLessons(filterType: filter);
        for (final l in lessons) {
          expect(l.nouns.length, 10,
              reason: 'Lección ${l.id} (${filter}) tiene ${l.nouns.length} palabras, debería ser 10');
        }
      }
    });

    test('lessonIds de getCategories coincide con el número real de lecciones', () {
      for (final filter in ['Sustantivos', 'Verbos', 'Adjetivos']) {
        final cats = LessonsData.getCategories(filterType: filter);
        final lessons = LessonsData.getLessons(filterType: filter);
        for (final c in cats) {
          final count = lessons.where((l) => l.id.startsWith('${c.id}-')).length;
          expect(c.lessonIds.length, count,
              reason: 'Categoría ${c.id} (${filter}): ${c.lessonIds.length} ids vs $count lecciones');
        }
      }
    });
  });

  group('Reglas 4 y 5: icono por tipo de palabra', () {
    test('Verbos usan 🤸, Adjetivos 🎭, Sustantivos conservan su icono', () {
      final sust = LessonsData.getCategories(filterType: 'Sustantivos');
      final verb = LessonsData.getCategories(filterType: 'Verbos');
      final adj = LessonsData.getCategories(filterType: 'Adjetivos');

      if (verb.isNotEmpty) {
        for (final c in verb) {
          expect(c.icon, '🤸', reason: 'Categoría verbo ${c.id} debería usar 🤸');
        }
      }
      if (adj.isNotEmpty) {
        for (final c in adj) {
          expect(c.icon, '🎭', reason: 'Categoría adjetivo ${c.id} debería usar 🎭');
        }
      }
      if (sust.isNotEmpty) {
        for (final c in sust) {
          expect(c.icon, isNot('🤸'), reason: 'Sustantivo ${c.id} no debería usar 🤸');
          expect(c.icon, isNot('🎭'), reason: 'Sustantivo ${c.id} no debería usar 🎭');
        }
      }
    });
  });

  group('Regla 3: palabras por juego', () {
    test('juego 1 y juego 2 comparten las mismas palabras (complementario)', () {
      final nouns = _fakeNouns(10);
      final g1 = LessonsData.wordsForGame(nouns, 0, 5);
      final g2 = LessonsData.wordsForGame(nouns, 1, 5);
      expect(g1.map((n) => n.wordId).toList(), g2.map((n) => n.wordId).toList(),
          reason: 'El 2º juego debe repetir las palabras del 1º');
    });

    test('la secuencia completa de juegos cubre las 10 palabras de la lección', () {
      final nouns = _fakeNouns(10);
      // Capacidades por juego (secuencia de sustantivos)
      const caps = [5, 5, 5, 5, 10, 8, 4, 10, 5, 5, 10];
      final seen = <int>{};
      for (var seq = 0; seq < caps.length; seq++) {
        final sel = LessonsData.wordsForGame(nouns, seq, caps[seq]);
        expect(sel.length, lessThanOrEqualTo(caps[seq]));
        seen.addAll(sel.map((n) => n.wordId));
      }
      expect(seen, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
          reason: 'Las 10 palabras deben aparecer en la secuencia de juegos');
    });

    test('nunca devuelve más palabras de la capacidad pedida', () {
      final nouns = _fakeNouns(10);
      for (var seq = 0; seq < 12; seq++) {
        for (final cap in [3, 4, 5, 8, 10]) {
          final sel = LessonsData.wordsForGame(nouns, seq, cap);
          expect(sel.length, lessThanOrEqualTo(cap));
        }
      }
    });
  });
}
