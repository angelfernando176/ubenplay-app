import '../models/game_type.dart';

/// Resultado de un juego individual con errores
class GameResult {
  final GameType gameType;
  final int correct;
  final int total;
  final int score; // 🆕 puntaje alcanzado
  final List<GameError> errors;

  const GameResult({
    required this.gameType,
    required this.correct,
    required this.total,
    this.score = 0,
    this.errors = const [],
  });

  bool get allCorrect => correct == total;
}

/// Error cometido en un juego específico
class GameError {
  final GameType gameType;
  final int wordId;
  final String correctAnswer;
  final String userAnswer;

  const GameError({
    required this.gameType,
    required this.wordId,
    required this.correctAnswer,
    required this.userAnswer,
  });
}
