import 'package:flutter/material.dart';
import '../data/lessons_data.dart';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
/// Barra de puntaje con zonas rojo/amarillo/verde (directrices)
class GameScoreBar extends StatelessWidget {
  final int score;
  final int maxScore;

  const GameScoreBar({super.key, required this.score, required this.maxScore});

  @override
  Widget build(BuildContext context) {
    final pct = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
    final barColor = pct < 0.33 ? Colors.red : (pct < 0.66 ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          Row(children: [
            Expanded(flex: 1, child: _zone(Colors.red[100]!, true, false)),
            Expanded(flex: 1, child: _zone(Colors.yellow[100]!, false, false)),
            Expanded(flex: 1, child: _zone(Colors.green[100]!, false, true)),
          ]),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: barColor)),
          ),
          Center(child: Text('$score / $maxScore', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _zone(Color color, bool first, bool last) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: first ? const Radius.circular(10) : Radius.zero,
          right: last ? const Radius.circular(10) : Radius.zero,
        ),
      ),
    );
  }
}

/// Etiqueta de categoría según el tipo de palabra (id_categoria: 1=sust, 2=verb, 3=adj, 4=conector)
String wordTypeLabel(List<VocabularyNoun> nouns) {
  if (nouns.isEmpty) return 'Sustantivo';
  return {1: 'Sustantivo', 2: 'Verbo', 3: 'Adjetivo', 4: 'Conector'}[nouns.first.wordType] ?? 'Sustantivo';
}

/// Encabezado de juego con nivel, tipo, botones (directrices)
class GameHeader extends StatelessWidget {
  final String level;
  final String wordType;
  final String category;
  final VoidCallback? onHints;
  final VoidCallback onRestart;
  final VoidCallback? onHelp;

  const GameHeader({
    super.key,
    this.level = 'A1',
    this.wordType = 'sustantivo',
    this.category = '',
    this.onHints,
    required this.onRestart,
    this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.grey[100],
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(10)),
          child: Text(level, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text('$category · $wordType', style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis)),
        if (onHints != null) ...[
          IconButton(icon: const Icon(Icons.lightbulb_outline, size: 18), onPressed: onHints, tooltip: 'Pistas', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 4),
        ],
        IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: onRestart, tooltip: 'Reiniciar', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        const SizedBox(width: 4),
        if (onHelp != null)
          IconButton(icon: const Icon(Icons.help_outline, size: 18), onPressed: onHelp, tooltip: 'Ayuda', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    );
  }
}

/// Colores por artículo
Color articleColor(String article) {
  switch (article) {
    case 'der': return const Color(0xFF1A237E);
    case 'die': return const Color(0xFF8B0000);
    case 'das': return const Color(0xFF1B5E20);
    default: return Colors.grey[700]!;
  }
}

/// Muestra diálogo de ayuda específico por juego
void showGameHelp(BuildContext context, GameType gameType, List<VocabularyNoun> words, {String? extraInfo}) {
  final hasData = words.any((w) => w.exampleSentence.isNotEmpty);
  
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Row(children: [const Icon(Icons.help_outline, color: Colors.blue), const SizedBox(width: 8), Text(gameType.displayName)]),
    content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!hasData)
        const Padding(padding: EdgeInsets.all(16), child: Text('La información no ha sido cargada.\nEs liegen keine Informationen vor.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
      if (gameType == GameType.article)
        _buildRulesContent(),
      if (gameType == GameType.verbConjugation)
        _buildConjugationHelp(words),
      if (gameType != GameType.article && gameType != GameType.verbConjugation)
        ...words.where((w) => w.exampleSentence.isNotEmpty).take(5).map((w) => _buildSentenceCard(w)),
    ]))),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Regresar'))],
  ));
}

Widget _buildRulesContent() {
  return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('📚 Reglas de artículos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    SizedBox(height: 8),
    Text('DER (masculino): días, meses, estaciones, puntos cardinales, fenómenos meteorológicos, bebidas alcohólicas, marcas de autos.', style: TextStyle(fontSize: 12)),
    SizedBox(height: 4),
    Text('DIE (femenino): terminados en -ung, -heit, -keit, -schaft, -tion, -tät, -ie, -ei, -enz, -ur, -ik, -ade, -age, -ette, -ille, -ine, -isse, -ive, -ose.', style: TextStyle(fontSize: 12)),
    SizedBox(height: 4),
    Text('DAS (neutro): terminados en -chen, -lein, -ment, -tum, -um, -nis, verbos sustantivados, colores, idiomas.', style: TextStyle(fontSize: 12)),
  ]));
}

Widget _buildConjugationHelp(List<VocabularyNoun> words) {
  final verbs = words.where((w) => w.wordType == 2).toList();
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📚 Reglas de conjugación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: 6),
      Text('Verbos regulares: raíz + e/st/t/en/t/en', style: TextStyle(fontSize: 12)),
      Text('Ej: machen → mache, machst, macht, machen, macht, machen', style: TextStyle(fontSize: 11, color: Colors.black54)),
      SizedBox(height: 4),
      Text('Verbos irregulares: cambian la vocal en 2ª y 3ª persona singular', style: TextStyle(fontSize: 12)),
      Text('Ej: essen → esse, isst, isst, essen, esst, essen', style: TextStyle(fontSize: 11, color: Colors.black54)),
    ])),
    const SizedBox(height: 8),
    if (verbs.isNotEmpty) ...verbs.take(2).map((v) => _buildSentenceCard(v)),
    if (verbs.isEmpty) const Text('No hay verbos disponibles.', style: TextStyle(fontSize: 12, color: Colors.grey)),
  ]);
}

Widget _buildSentenceCard(VocabularyNoun w) {
  final sentence = w.exampleSentence;
  if (sentence.isEmpty) return const SizedBox.shrink();
  final parts = sentence.split(RegExp(r'\s+'));
  return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: 3, runSpacing: 2, children: parts.map((part) {
      final clean = part.replaceAll(RegExp(r'[.,;:!?¿¡()\[\]"»«]'), '').toLowerCase();
      final isWord = clean == w.german.toLowerCase();
      return Container(padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1), decoration: isWord ? BoxDecoration(color: Colors.orange[200], borderRadius: BorderRadius.circular(4)) : null, child: Text(part, style: TextStyle(fontSize: 13, fontWeight: isWord ? FontWeight.w800 : FontWeight.w400, color: isWord ? Colors.orange[900] : Colors.black87)));
    }).toList()),
    const SizedBox(height: 4),
    Text(w.spanish, style: const TextStyle(fontSize: 11, color: Colors.black54)),
  ]));
}
