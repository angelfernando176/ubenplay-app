import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

class FillBlankGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const FillBlankGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<FillBlankGame> createState() => _FillBlankGameState();
}

class _FillBlankGameState extends State<FillBlankGame> {
  late List<VocabularyNoun> _nouns;
  int _current = 0, _score = 0, _errCount = 0;
  int _maxPerWord = 0, _totalMax = 0;
  late String _word;
  late List<String?> _guessed;
  final _used = <String>{};
  final List<GameError> _gameErrors = [];
  bool _showHelp = false, _hintUsed = false, _failed = false, _showExcelente = false, _showPts = false;
  DateTime? _questionTime;
  static const _maxErrors = 6;

  @override
  void initState() { super.initState(); _nouns = List.from(widget.nouns.take(5))..shuffle(); _initWord(); }

  void _initWord() { _word = _currentNoun.german.toUpperCase().replaceAll('Ü','UE').replaceAll('Ö','OE').replaceAll('Ä','AE').replaceAll('ß','SS'); _guessed = List.filled(_word.length, null); _used.clear(); _errCount = 0; _hintUsed = false; _failed = false; _showExcelente = false; _maxPerWord = _word.length * 3; _totalMax += _maxPerWord; _questionTime = DateTime.now(); }

  void _restart() { setState(() { _nouns = List.from(widget.nouns.take(5))..shuffle(); _current = 0; _score = 0; _gameErrors.clear(); _initWord(); }); }

  void _hint() { setState(() { _hintUsed = true; final idx = List.generate(_word.length, (i) => i)..shuffle(); for (var i = 0; i < (_word.length/2).ceil() && i < idx.length; i++) _guessed[idx[i]] = _word[idx[i]]; }); }

  void _guessLetter(String l) {
    if (_used.contains(l) || _failed || _showExcelente) return;
    setState(() => _used.add(l));
    if (_word.contains(l)) {
      for (var i = 0; i < _word.length; i++) if (_word[i] == l) _guessed[i] = l;
      final elapsed = DateTime.now().difference(_questionTime!).inMilliseconds;
      _score += _hintUsed ? 1 : (2 + (elapsed < 5000 ? 1 : 0)); _questionTime = DateTime.now();
      AudioService.playCorrectSound();
      if (!_guessed.contains(null)) { _showExcelente = true; Future.delayed(const Duration(seconds: 2), () { if (mounted) _finish(true); }); return; }
    } else { _errCount++; _score = max(0, _score - 1); AudioService.playIncorrectSound(); if (_errCount >= _maxErrors) { _failed = true; _gameErrors.add(GameError(gameType: GameType.fillBlank, wordId: _currentNoun.wordId, correctAnswer: _word, userAnswer: _guessed.map((e) => e ?? '_').join())); } }
  }

  void _showPtsScreen() { if (mounted) setState(() => _showPts = true); Future.delayed(const Duration(seconds: 2), () { if (mounted) _finish(true); }); }

  void _finish(bool correct) {
    if (_current + 1 >= _nouns.length) {
      // Última palabra: mostrar puntaje final
      setState(() => _showPts = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) { Future.microtask(() { if (mounted) widget.onComplete(GameResult(gameType: GameType.fillBlank, correct: _nouns.length - _gameErrors.length, total: _nouns.length, errors: _gameErrors, score: _score)); }); }
      });
    }
    else { setState(() { _current++; _initWord(); }); }
  }

  VocabularyNoun get _currentNoun => _nouns[_current];

  @override
  Widget build(BuildContext context) {
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('de ${_totalMax} posibles', style: const TextStyle(color: Colors.black54))]));
    final noun = _currentNoun; final cols = _word.length > 9 ? (_word.length > 15 ? 3 : 2) : 1;
    return Stack(children: [
      SafeArea(child: Column(children: [
        GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart, onHints: _hint, onHelp: () => showGameHelp(context, GameType.fillBlank, widget.nouns)),
        GameScoreBar(score: _score, maxScore: _totalMax),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: Column(children: [
          Text('${_current + 1}/${_nouns.length} · Fallos: $_errCount/$_maxErrors', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(noun.spanish, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          Text(noun.image, style: const TextStyle(fontSize: 48)),
          if (_showExcelente) const Text('🌟 ¡Excelente! 🌟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 80, height: 80, child: CustomPaint(painter: _HangPainter(_errCount))), // 10% más grande
            const SizedBox(width: 4),
            Column(children: [
              if (_failed) const Text('¡Has fallado!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
              if (cols == 1) Wrap(spacing: 4, runSpacing: 5, children: List.generate(_word.length, (i) => _letterBox(i)))
              else ...List.generate(cols, (row) { final perRow = (_word.length / cols).ceil(); final start = row * perRow; final end = min(start + perRow, _word.length); return Wrap(spacing: 4, runSpacing: 5, key: ValueKey(row), children: List.generate(end - start, (i) => _letterBox(start + i))); }),
              if (_hintUsed) const Text('⚠️ Pista usada', style: TextStyle(color: Colors.orange, fontSize: 10)),
            ]),
          ]),
          if (_failed) Padding(padding: const EdgeInsets.only(top: 8), child: ElevatedButton(onPressed: () { setState(() { _current++; if (_current >= _nouns.length) { Future.microtask(() { if (mounted) widget.onComplete(GameResult(gameType: GameType.fillBlank, correct: _nouns.length - _gameErrors.length, total: _nouns.length, errors: _gameErrors, score: _score)); }); } else { _initWord(); } }); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: Text(_current + 1 >= _nouns.length ? 'Terminar' : 'Siguiente ▶'))),
          const SizedBox(height: 4),
          _buildKeyboard(),
        ])))]))]);
  }

  Widget _letterBox(int i) => Container(width: 30, height: 36, decoration: BoxDecoration(color: _failed && _guessed[i] == null ? Colors.red[50] : _guessed[i] != null ? Colors.green[100] : Colors.grey[200], border: Border.all(color: _failed && _guessed[i] == null ? Colors.red : _guessed[i] != null ? Colors.green : Colors.grey[400]!), borderRadius: BorderRadius.circular(4)), child: Center(child: Text(_failed && _guessed[i] == null ? _word[i] : (_guessed[i] ?? ''), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))));

  Widget _buildKeyboard() {
    const rows = ['QWERTZUIOP', 'ASDFGHJKL', 'YXCVBNM', 'ÜÖÄßÁÉÍÓÚ']; // ✅ 4ta fila con todas las especiales
    return Column(children: rows.map((r) => Row(mainAxisAlignment: MainAxisAlignment.center, children: r.split('').map((l) {
      final u = _used.contains(l), c = u && _word.contains(l);
      return GestureDetector(onTap: u || _failed || _showExcelente ? null : () => _guessLetter(l), child: Container(margin: const EdgeInsets.all(1.5), width: 30, height: 30, decoration: BoxDecoration(color: c ? Colors.green[200] : u ? Colors.red[100] : Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(3)), child: Center(child: Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: u ? Colors.black45 : Colors.black)))));
    }).toList())).toList());
  }
}

class _HangPainter extends CustomPainter {
  final int e; _HangPainter(this.e);
  @override void paint(Canvas c, Size s) { final p = Paint()..color=Colors.black..strokeWidth=2..style=PaintingStyle.stroke; c.drawLine(Offset(s.width*.05,s.height*.95),Offset(s.width*.25,s.height*.95),p); if(e>=1){c.drawLine(Offset(s.width*.15,s.height*.95),Offset(s.width*.15,s.height*.1),p);c.drawLine(Offset(s.width*.15,s.height*.1),Offset(s.width*.6,s.height*.1),p);c.drawLine(Offset(s.width*.6,s.height*.1),Offset(s.width*.6,s.height*.25),p);}if(e>=2)c.drawCircle(Offset(s.width*.6,s.height*.33),s.width*.07,p);if(e>=3)c.drawLine(Offset(s.width*.6,s.height*.40),Offset(s.width*.6,s.height*.60),p);if(e>=4)c.drawLine(Offset(s.width*.6,s.height*.46),Offset(s.width*.45,s.height*.55),p);if(e>=5)c.drawLine(Offset(s.width*.6,s.height*.46),Offset(s.width*.75,s.height*.55),p);if(e>=6){c.drawLine(Offset(s.width*.6,s.height*.60),Offset(s.width*.48,s.height*.80),p);c.drawLine(Offset(s.width*.6,s.height*.60),Offset(s.width*.72,s.height*.80),p);}}
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
