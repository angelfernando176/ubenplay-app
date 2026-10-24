import 'vocabulary_noun.dart';

/// Nivel de dificultad de una lección
enum LessonDifficulty { beginner, intermediate, advanced }

/// Tipo de vocabulario
enum VocabularyType { nouns, verbs, adjectives }

/// Representa una lección con tracking completo
class Lesson {
  final String id;
  final String title;
  final String description;
  final LessonDifficulty difficulty;
  final VocabularyType vocabularyType;
  final String icon;
  final List<VocabularyNoun> nouns;

  /// Puntuación máxima de la lección (30 puntos)
  static const int maxScore = 30;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    this.vocabularyType = VocabularyType.nouns,
    required this.icon,
    required this.nouns,
  });

  int get wordCount => nouns.length;

  /// XP reward basado en dificultad y cantidad de palabras
  int get xpReward {
    switch (difficulty) {
      case LessonDifficulty.beginner:
        return 30;
      case LessonDifficulty.intermediate:
        return 45;
      case LessonDifficulty.advanced:
        return 60;
    }
  }
}
