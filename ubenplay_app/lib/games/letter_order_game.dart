import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../theme/app_theme.dart';
import 'game_result.dart';
import 'game_widgets.dart';
import 'glass_bridge.dart';

/// Juego 10: Ordenar Letras — Puente de Cristal
class LetterOrderGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const LetterOrderGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<LetterOrderGame> createState() => _LetterOrderGameState();
}

class _LetterOrderGameState extends State<LetterOrderGame> {
  static const _wc = 5;
  late List<VocabularyNoun> _words;
  int _wi = 0, _score = 0, _pos = 0, _totalMax = 0, _errorAt = -1;
  late String _target;
  late List<_LB> _letters;
  bool _hintUsed = false, _showPts = false, _showHint = false, _wordDone = false;
  int _wordScore = 0;
  DateTime? _qt;

  @override
  void initState() { super.initState(); _newGame(); }

  void _newGame() {
    _words = List.from(widget.nouns)..shuffle(); _words = _words.take(_wc).toList();
    _totalMax = 0; for (final w in _words) _totalMax += w.german.length * 3;
    _wi = 0; _score = 0; _hintUsed = false; _initWord();
  }

  void _initWord() {
    _target = _words[_wi].german.toUpperCase();
    _pos = 0; _errorAt = -1; _wordDone = false; _wordScore = 0;
    _letters = _target.split('').map((l) => _LB(letter: l)).toList()..shuffle();
    _qt = DateTime.now();
  }

  void _restart() { setState(() { _newGame(); }); }

  void _hint() { setState(() { _hintUsed = true; _showHint = true; }); Future.delayed(const Duration(seconds: 1), () { if (mounted) setState(() => _showHint = false); }); }

  void _tap(int idx) {
    if (_errorAt >= 0 || _wordDone) return;
    final btn = _letters[idx];
    final correct = btn.letter == _target[_pos];
    final ms = DateTime.now().difference(_qt!).inMilliseconds;

    if (correct) {
      final pts = _hintUsed ? 1 : (2 + (ms < 5000 ? 1 : 0));
      setState(() { btn.placed = true; _pos++; _score += pts; _wordScore += pts; _qt = DateTime.now(); });

      if (_pos >= _target.length) {
        // ✅ Palabra completada → celebrar
        setState(() => _wordDone = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (_wi + 1 >= _wc) {
            setState(() => _showPts = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Future.microtask(() {
                if (mounted) widget.onComplete(GameResult(gameType: GameType.letterOrder, correct: _wc, total: _wc, errors: [], score: _score));
              });
            });
          } else {
            setState(() { _wi++; _initWord(); });
          }
        });
      }
    } else {
      setState(() { _errorAt = _pos; _score = max(0, _score - 1); });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() { _errorAt = -1; _score = 0; _wordScore = 0; _pos = 0; _letters.forEach((l) => l.placed = false); _letters.shuffle(); });
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🎉', style: TextStyle(fontSize: 64)),
      Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      Text('de $_totalMax posibles', style: const TextStyle(color: Colors.black54)),
    ]));

    final w = _words[_wi];
    return SafeArea(child: Column(children: [
      GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart, onHints: _hint, onHelp: () => showGameHelp(context, GameType.letterOrder, widget.nouns)),
      GameScoreBar(score: _hintUsed ? _score ~/ 2 : _score, maxScore: _totalMax),
      Text('${_wi + 1}/$_wc  ·  ${_pos}/${_target.length}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
      Container(padding: const EdgeInsets.all(6), margin: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(6)),
        child: Text(w.spanish, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
      // Puente de Cristal
      Expanded(child: GlassBridge(
        totalSteps: _target.length, currentStep: _pos, errorStep: _errorAt,
        avatarEmoji: w.image, placed: List.generate(_target.length, (i) => i < _pos ? _target[i] : null),
        labels: _target.split(''), showCelebration: _wordDone, wordScore: _wordScore,
      )),
      // Puntos conseguidos (sobre botones de letras)
      if (_wordDone)
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
          child: Text('+$_wordScore pts  ·  Palabra: $_score pts', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
      // Botones de letras
      Padding(padding: const EdgeInsets.all(6), child: Wrap(spacing: 4, runSpacing: 4, alignment: WrapAlignment.center, children: List.generate(_letters.length, (i) {
        final btn = _letters[i]; if (btn.placed) return const SizedBox.shrink();
        return GestureDetector(
          onTap: (_errorAt >= 0 || _wordDone) ? null : () => _tap(i),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(
            color: _showHint && btn.letter == _target[_pos] ? Colors.green[100] : Colors.white,
            borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[400]!)),
            child: Text(btn.letter, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _showHint && btn.letter == _target[_pos] ? Colors.green[800] : Colors.black87))),
        );
      }))),
    ]));
  }
}

class _LB { final String letter; bool placed = false; _LB({required this.letter}); }
