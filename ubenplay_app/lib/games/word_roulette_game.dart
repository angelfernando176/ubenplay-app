import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

/// Juego 8: Ruleta de Palabras — Octágono, emparejar español ↔ alemán
class WordRouletteGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const WordRouletteGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<WordRouletteGame> createState() => _WordRouletteGameState();
}

class _WordRouletteGameState extends State<WordRouletteGame> {
  static const _pairCount = 4;
  late List<VocabularyNoun> _nouns;
  late List<_RouletteButton> _buttons;
  int? _first, _second;
  int _score = 0, _found = 0, _maxScore = 0;
  bool _locked = false, _showPts = false;
  final List<GameError> _errors = [];
  DateTime? _selectTime;

  @override
  void initState() { super.initState(); _initGame(); }

  void _initGame() {
    _nouns = List.from(widget.nouns)..shuffle();
    _nouns = _nouns.take(_pairCount).toList();
    _maxScore = _nouns.length * 3;

    // Crear botones: parejas español ↔ alemán
    _buttons = [];
    for (final n in _nouns) {
      _buttons.add(_RouletteButton(id: n.wordId, label: n.spanish, article: n.article, type: _BtnType.es, word: n));
      _buttons.add(_RouletteButton(id: n.wordId, label: n.fullGerman, article: n.article, type: _BtnType.de, word: n));
    }
    _buttons.shuffle();
    _score = 0; _found = 0; _first = null; _second = null; _locked = false;
  }

  void _restart() { setState(() => _initGame()); }

  void _tap(int index) {
    if (_locked || _buttons[index].matched) return;
    if (_first == index) {
      setState(() { _first = null; _buttons[index].selected = false; });
      return;
    }

    if (_first == null) {
      setState(() { _first = index; _buttons[index].selected = true; _selectTime = DateTime.now(); });
      return;
    }

    // No permitir mismo tipo (es-es o de-de)
    if (_buttons[_first!].type == _buttons[index].type) {
      // Cambiar selección
      setState(() { _buttons[_first!].selected = false; _first = index; _buttons[index].selected = true; _selectTime = DateTime.now(); });
      return;
    }

    _second = index;
    _buttons[index].selected = true;
    _locked = true;

    final a = _buttons[_first!], b = _buttons[index];
    final correct = a.id == b.id;
    final elapsed = DateTime.now().difference(_selectTime!).inMilliseconds;

    if (correct) {
      setState(() {
        a.matched = true; a.correct = true; b.matched = true; b.correct = true;
        _score += 2 + (elapsed < 5000 ? 1 : 0); _found++;
        _first = null; _second = null; _locked = false;
      });
      AudioService.playCorrectSound();
      if (_found >= _nouns.length) {
        setState(() => _showPts = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Future.microtask(() {
            if (mounted) widget.onComplete(GameResult(gameType: GameType.wordRoulette, correct: _found, total: _nouns.length, errors: _errors, score: _score));
          });
        });
      }
    } else {
      setState(() { a.wrong = true; b.wrong = true; _score = max(0, _score - 1); });
      AudioService.playIncorrectSound();
      _errors.add(GameError(gameType: GameType.wordRoulette, wordId: a.id, correctAnswer: a.word.german, userAnswer: b.word.german));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() {
          a.selected = false; a.wrong = false;
          b.selected = false; b.wrong = false;
          _first = null; _second = null; _locked = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('de $_maxScore posibles', style: const TextStyle(color: Colors.black54))]));

    return SafeArea(child: Column(children: [
      GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart, onHints: () => _showHintSheet(context), onHelp: () => showGameHelp(context, GameType.wordRoulette, widget.nouns)),
      GameScoreBar(score: _score, maxScore: _maxScore),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Empareja cada palabra en español con su traducción en alemán', style: TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center)),
      const SizedBox(height: 8),
      Expanded(child: Center(child: _buildOctagon())),
    ]));
  }

  void _showHintSheet(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(16), child: Text('Pista: busca pares español ↔ alemán.\n${_nouns.map((n) => '${n.spanish} ↔ ${n.german}').join('\n')}', style: const TextStyle(fontSize: 13))));
  }

  Widget _buildOctagon() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight) * 0.85;
      final radius = size / 2;
      final center = Offset(radius, radius);

      return SizedBox(width: size, height: size, child: Stack(children: [
        // Líneas de conexión para pares correctos
        CustomPaint(size: Size(size, size), painter: _LinesPainter(_buttons, _nouns.length, center, radius * 0.72)),
        // Botones en octágono
        ...List.generate(_buttons.length, (i) {
          final angle = (2 * pi * i / _buttons.length) - pi / 2;
          final x = center.dx + radius * 0.72 * cos(angle) - 32;
          final y = center.dy + radius * 0.72 * sin(angle) - 32;
          final btn = _buttons[i];
          return Positioned(left: x, top: y, child: GestureDetector(
            onTap: () => _tap(i),
            child: _buildButton(btn, i == _first || i == _second),
          ));
        }),
      ]));
    });
  }

  Widget _buildButton(_RouletteButton btn, bool selected) {
    Color bg;
    if (btn.matched) bg = Colors.green;
    else if (btn.wrong) bg = Colors.red;
    else if (selected) bg = Colors.blue[200]!;
    else bg = btn.type == _BtnType.es ? const Color(0xFFB3E5FC) : Colors.white; // celeste / blanco

    Color textColor = Colors.black;
    if (btn.type == _BtnType.de && btn.article.isNotEmpty && !btn.matched && !btn.wrong) {
      textColor = articleColor(btn.article);
    }

    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: btn.matched ? Colors.green[800]! : Colors.grey[400]!, width: btn.matched ? 3 : 1.5)),
      child: Center(child: Padding(padding: const EdgeInsets.all(4), child: Text(btn.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 2))),
    );
  }
}

enum _BtnType { es, de }

class _RouletteButton {
  final int id; final String label; final String article; final _BtnType type;
  final VocabularyNoun word;
  bool selected = false, matched = false, correct = false, wrong = false;
  _RouletteButton({required this.id, required this.label, required this.article, required this.type, required this.word});
}

class _LinesPainter extends CustomPainter {
  final List<_RouletteButton> buttons; final int pairs; final Offset center; final double radius;
  _LinesPainter(this.buttons, this.pairs, this.center, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green.withAlpha(60)..strokeWidth = 3..style = PaintingStyle.stroke;
    final matched = <int>{};
    for (var i = 0; i < buttons.length; i++) {
      if (buttons[i].matched && buttons[i].correct && !matched.contains(buttons[i].id)) {
        matched.add(buttons[i].id);
        // Encontrar el par
        for (var j = i + 1; j < buttons.length; j++) {
          if (buttons[j].matched && buttons[j].correct && buttons[j].id == buttons[i].id) {
            final a1 = (2 * pi * i / buttons.length) - pi / 2;
            final a2 = (2 * pi * j / buttons.length) - pi / 2;
            final p1 = Offset(center.dx + radius * cos(a1), center.dy + radius * sin(a1));
            final p2 = Offset(center.dx + radius * cos(a2), center.dy + radius * sin(a2));
            canvas.drawLine(p1, p2, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) => true;
}
