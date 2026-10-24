import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

/// Juego 1: Pares — Dos columnas (español ↔ artículo+alemán)
class MatchingGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const MatchingGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  static const _maxScore = 15, _wordCount = 5;
  int _score = 0;
  int? _selectedLeft, _selectedRight;
  final _matchedLeft = <int>{}, _matchedRight = <int>{};
  late List<int> _leftOrder, _rightOrder;
  bool _showPistas = false, _showPts = false;
  Timer? _pistasTimer;
  DateTime? _selectTime;
  final List<GameError> _errors = [];

  @override
  void initState() { super.initState(); _shuffle(); AudioService.init(); }

  void _shuffle() {
    final n = min(widget.nouns.length, _wordCount);
    _leftOrder = List.generate(n, (i) => i)..shuffle();
    _rightOrder = List.generate(n, (i) => i)..shuffle();
    _matchedLeft.clear(); _matchedRight.clear();
    _selectedLeft = null; _selectedRight = null;
    _score = 0; _errors.clear();
    setState(() {});
  }

  void _selectLeft(int i) {
    if (_matchedLeft.contains(i) || i >= _leftOrder.length) return;
    setState(() { _selectedLeft = i; _selectTime = DateTime.now(); if (_selectedRight != null) _check(); });
  }

  void _selectRight(int i) {
    if (_matchedRight.contains(i) || i >= _rightOrder.length) return;
    setState(() { _selectedRight = i; _selectTime = DateTime.now(); if (_selectedLeft != null) _check(); });
  }

  void _check() {
    final li = _selectedLeft!, ri = _selectedRight!;
    final correct = _leftOrder[li] == _rightOrder[ri];
    final elapsed = DateTime.now().difference(_selectTime!).inMilliseconds;
    setState(() {
      if (correct) {
        _score += 2 + (elapsed < 5000 ? 1 : 0); _matchedLeft.add(li); _matchedRight.add(ri);
        AudioService.playCorrectSound();
        if (_matchedLeft.length == _leftOrder.length) { setState(() => _showPts = true); Future.delayed(const Duration(seconds: 2), () { if (mounted) { Future.microtask(() { if (mounted) widget.onComplete(GameResult(gameType: GameType.matching, correct: _matchedLeft.length, total: _leftOrder.length, errors: _errors, score: _score)); }); } }); }
      } else {
        _score = max(0, _score - 1); AudioService.playIncorrectSound();
        _errors.add(GameError(gameType: GameType.matching, wordId: widget.nouns.isNotEmpty ? widget.nouns[_leftOrder[li]].wordId : 0, userAnswer: 'Incorrecto', correctAnswer: '${widget.nouns[_leftOrder[li]].spanish} ↔ ${widget.nouns[_rightOrder[ri]].spanish}'));
      }
      _selectedLeft = null; _selectedRight = null;
    });
  }

  void _hint() { setState(() => _showPistas = true); _pistasTimer?.cancel(); _pistasTimer = Timer(const Duration(seconds: 1), () { if (mounted) setState(() => _showPistas = false); }); }

  @override
  void dispose() { _pistasTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final n = _leftOrder.length;
    if (n == 0) return const Center(child: Text('Sin palabras'));
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('de $_maxScore posibles', style: const TextStyle(color: Colors.black54))]));
    return Column(children: [
      GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _shuffle, onHints: _hint, onHelp: () => showGameHelp(context, GameType.matching, widget.nouns)),
      GameScoreBar(score: _score, maxScore: _maxScore),
      Expanded(child: Row(children: [
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: n, itemBuilder: (ctx, i) {
          final wi = i < _leftOrder.length && _leftOrder[i] < widget.nouns.length ? widget.nouns[_leftOrder[i]] : null;
          if (wi == null) return const SizedBox.shrink();
          final m = _matchedLeft.contains(i), s = _selectedLeft == i;
          return _btn('${wi.image} ${wi.spanish}', m, s, () => _selectLeft(i), _showPistas ? '${_leftOrder[i] + 1}' : null);
        })),
        Container(width: 1, color: Colors.grey[300]),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: n, itemBuilder: (ctx, i) {
          final wi = i < _rightOrder.length && _rightOrder[i] < widget.nouns.length ? widget.nouns[_rightOrder[i]] : null;
          if (wi == null) return const SizedBox.shrink();
          final m = _matchedRight.contains(i), s = _selectedRight == i;
          return _btn(wi.fullGerman, m, s, () => _selectRight(i), _showPistas ? '${_rightOrder[i] + 1}' : null, articleColor(wi.article));
        })),
      ])),
    ]);
  }

  Widget _btn(String label, bool matched, bool selected, VoidCallback onTap, String? hint, [Color? textColor]) {
    Color bg = matched ? Colors.green[100]! : (selected ? Colors.blue[50]! : Colors.white);
    Color border = matched ? Colors.green : (selected ? Colors.blue : Colors.grey[300]!);
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: GestureDetector(
      onTap: matched ? null : onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14), decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 2), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          if (hint != null) Container(padding: const EdgeInsets.all(2), margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)), child: Text(hint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
          if (matched) const Icon(Icons.check_circle, color: Colors.green, size: 18),
        ])),
    ));
  }
}
