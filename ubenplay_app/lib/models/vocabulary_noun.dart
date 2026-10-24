enum CefrLevel { a1, a2, b1, b2 }

/// Modelo unificado de palabra (sustantivo, verbo, adjetivo, conector)
class VocabularyNoun {
  final int wordId;
  final String spanish, german, article, plural;
  final CefrLevel cefrLevel;
  final String image, imageCode, exampleSentence, definition, imageUrl;
  final List<String> sentenceWords;
  final int wordType; // 1=sustantivo, 2=verbo, 3=adjetivo, 4=conector
  final List<Map<String, String>> sentences; // [{oracion, traduccion}, ...]

  // Campos de verbo
  final String conjIch, conjDu, conjEr, conjSie, conjEs, conjWir, conjIhr, conjSieFormal, conjSiePlural;
  final String ejemploOracion;
  final String comparativo, superlativo;

  const VocabularyNoun({
    required this.wordId,
    required this.spanish,
    required this.german,
    this.article = '',
    this.plural = '',
    this.cefrLevel = CefrLevel.a1,
    this.image = '📝',
    this.imageCode = '',
    this.exampleSentence = '',
    this.definition = '',
    this.imageUrl = '',
    this.sentenceWords = const [],
    this.wordType = 1,
    this.sentences = const [],
    this.conjIch = '',
    this.conjDu = '',
    this.conjEr = '',
    this.conjSie = '',
    this.conjEs = '',
    this.conjWir = '',
    this.conjIhr = '',
    this.conjSieFormal = '',
    this.conjSiePlural = '',
    this.ejemploOracion = '',
    this.comparativo = '',
    this.superlativo = '',
  });

  /// Nombre completo en alemán con artículo (para sustantivos)
  String get fullGerman => article.isNotEmpty ? '$article $german' : german;

  /// Artículo con género abreviado: 'der (m)', 'die (f)', 'das (n)'
  String get articleLabel {
    return {
      'der': 'der (m)',
      'die': 'die (f)',
      'das': 'das (n)',
    }[article] ?? article;
  }

  factory VocabularyNoun.fromMap(Map<String, dynamic> map) {
    final sust = map['sustantivos'] as Map<String, dynamic>?;
    final verb = map['verbos'] as Map<String, dynamic>?;
    final adj = map['adjetivos'] as Map<String, dynamic>?;
    return VocabularyNoun(
      wordId: map['id_palabra'] ?? 0,
      spanish: map['palabra_es'] ?? '',
      german: map['palabra_de'] ?? '',
      article: _articleForType(map['id_tipo'] ?? 1),
      plural: sust?['plural'] ?? '',
      cefrLevel: _cefrFromId(map['id_nivel'] ?? 1),
      image: map['texto_emoji'] ?? '📝',
      imageCode: '',
      exampleSentence: map['oracion_ejemplo'] ?? '',
      sentenceWords: map['oracion_palabras']?.toString().split('|').where((w) => w.isNotEmpty).toList() ?? [],
      definition: map['definicion'] ?? '',
      imageUrl: map['imagen_url'] ?? '',
      wordType: map['id_categoria'] ?? 1,
      conjIch: verb?['conjuga_ich'] ?? '',
      conjDu: verb?['conjuga_du'] ?? '',
      conjEr: verb?['conjuga_er'] ?? '',
      conjSie: verb?['conjuga_ella'] ?? '',
      conjEs: verb?['conjuga_es'] ?? '',
      conjWir: verb?['conjuga_wir'] ?? '',
      conjIhr: verb?['conjuga_ihr'] ?? '',
      conjSieFormal: verb?['conjuga_usted'] ?? '',
      conjSiePlural: verb?['conjuga_ellos'] ?? '',
      ejemploOracion: verb?['ejemplo_oracion1'] ?? '',
      comparativo: adj?['comparativo_aleman'] ?? '',
      superlativo: adj?['superlativo_aleman'] ?? '',
    );
  }

  static String _articleForType(int tipo) {
    return {1: 'der', 2: 'die', 3: 'das'}[tipo] ?? '';
  }

  static CefrLevel _cefrFromId(int id) {
    return {1: CefrLevel.a1, 2: CefrLevel.a2, 3: CefrLevel.b1, 4: CefrLevel.b2}[id] ?? CefrLevel.a1;
  }
}
