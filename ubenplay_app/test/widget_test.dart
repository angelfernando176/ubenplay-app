import 'package:flutter_test/flutter_test.dart';
import 'package:ubenplay_app/models/vocabulary_noun.dart';
import 'package:ubenplay_app/models/lesson.dart';
import 'package:ubenplay_app/models/lesson_session.dart';
import 'package:ubenplay_app/models/user_progress.dart';
import 'package:ubenplay_app/games/game_result.dart';
import 'package:ubenplay_app/models/game_type.dart';
import 'package:ubenplay_app/data/lessons_data.dart';

void main() {
  group('VocabularyNoun', () {
    test('has all required fields', () {
      final noun = VocabularyNoun(
        wordId: 1, spanish: 'perro', german: 'Hund',
        article: 'der', plural: 'Hunde', cefrLevel: CefrLevel.a1,
        image: '🐕', imageCode: '0010000001',
      );
      expect(noun.wordId, 1);
      expect(noun.fullGerman, 'der Hund');
      expect(noun.imageCode.length, 10);
      expect(noun.articleLabel, 'der (m)');
      expect(noun.plural, 'Hunde');
      expect(noun.cefrLevel, CefrLevel.a1);
    });
  });

  group('Lesson', () {
    test('maxScore is 30', () {
      expect(Lesson.maxScore, 30);
    });
  });

  group('LessonSession', () {
    test('tracks start and finish', () {
      final session = LessonSession.start('lesson-1');
      expect(session.lessonId, 'lesson-1');
      expect(session.score, 0);
      final finished = session.finish(score: 25, errors: []);
      expect(finished.score, 25);
      expect(finished.endDate, isNotNull);
    });
  });

  group('GameError', () {
    test('records error details', () {
      final error = GameError(
        gameType: GameType.article, wordId: 5,
        correctAnswer: 'der', userAnswer: 'die',
      );
      expect(error.wordId, 5);
      expect(error.correctAnswer, 'der');
    });
  });

  group('LessonsData', () {
    test('all nouns have 10-digit imageCode', () {
      for (final lesson in LessonsData.getLessons()) {
        for (final noun in lesson.nouns) {
          expect(noun.imageCode.length, 10,
              reason: 'imageCode inválido para ${noun.spanish}');
          expect(int.tryParse(noun.imageCode), isNotNull);
        }
      }
    });

    test('wordIds are unique', () {
      final ids = <int>{};
      for (final lesson in LessonsData.getLessons()) {
        for (final noun in lesson.nouns) {
          expect(ids.contains(noun.wordId), false,
              reason: 'wordId duplicado: ${noun.wordId}');
          ids.add(noun.wordId);
        }
      }
    });
  });

  group('UserProgress', () {
    test('streak tracking', () {
      final progress = UserProgress();
      progress.completePractice(20, 4, 5);
      expect(progress.currentStreak, 1);
    });
  });
}
