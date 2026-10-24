enum GameType { matching, article, dobble, fillBlank, imageOptions, pairs, wordSearch, wordRoulette, pathFinder, letterOrder, verbConjugation, sentenceOrder, crossword }

extension GameTypeX on GameType {
  String get displayName {
    switch (this) {
      case GameType.matching: return 'Unión de Palabras';
      case GameType.article: return 'Caza del Artículo';
      case GameType.dobble: return 'Traduce';
      case GameType.fillBlank: return 'Ahorcado';
      case GameType.imageOptions: return 'Opciones';
      case GameType.pairs: return 'Memoria';
      case GameType.wordSearch: return 'Sopa de Letras';
      case GameType.wordRoulette: return 'Ruleta de Palabras';
      case GameType.pathFinder: return 'Puente de Cristal';
      case GameType.letterOrder: return 'Puente de Cristal';
      case GameType.verbConjugation: return 'Ordena Filas';
      case GameType.sentenceOrder: return 'Ordenar Palabras';
      case GameType.crossword: return 'Crucigrama';
    }
  }
}

/// Mapeo de id_juego (numeración canónica de Fernando, 1-13) a GameType.
/// El 6 (Opciones) está inactivo.
GameType? gameTypeFromIdJuego(int idJuego) {
  switch (idJuego) {
    case 1: return GameType.matching;
    case 2: return GameType.article;
    case 3: return GameType.dobble;
    case 4: return GameType.fillBlank;
    case 5: return GameType.pairs;
    case 6: return null; // Opciones (inactivo)
    case 7: return GameType.wordSearch;
    case 8: return GameType.wordRoulette;
    case 9: return GameType.pathFinder;
    case 10: return GameType.letterOrder;
    case 11: return GameType.verbConjugation;
    case 12: return GameType.sentenceOrder;
    case 13: return GameType.crossword;
    default: return null;
  }
}

/// Mapeo inverso: GameType → id_juego (numeración canónica).
int? idJuegoFromGameType(GameType g) {
  switch (g) {
    case GameType.matching: return 1;
    case GameType.article: return 2;
    case GameType.dobble: return 3;
    case GameType.fillBlank: return 4;
    case GameType.pairs: return 5;
    case GameType.imageOptions: return 6;
    case GameType.wordSearch: return 7;
    case GameType.wordRoulette: return 8;
    case GameType.pathFinder: return 9;
    case GameType.letterOrder: return 10;
    case GameType.verbConjugation: return 11;
    case GameType.sentenceOrder: return 12;
    case GameType.crossword: return 13;
  }
}
