import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

class DobbleGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const DobbleGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<DobbleGame> createState() => _DobbleGameState();
}

class _DobbleGameState extends State<DobbleGame> {
  late List<VocabularyNoun> _nouns;
  int _current = 0, _score = 0, _maxScore = 15;
  final List<GameError> _errors = [];
  DateTime? _questionTime;
  bool _showHelp = false, _showResult = false, _showPts = false;
  String? _selected, _highlighted;
  late List<VocabularyNoun> _currentOptions; // ✅ estables, solo cambian con restart

  @override
  void initState() { super.initState(); _nouns = List.from(widget.nouns.take(5))..shuffle(); _maxScore = _nouns.length * 3; _questionTime = DateTime.now(); _shuffleOptions(); }

  void _shuffleOptions() {
    final rng = Random(); final opts = [_nouns[_current]]; while (opts.length < 4) { final o = widget.nouns[rng.nextInt(widget.nouns.length)]; if (!opts.any((x) => x.wordId == o.wordId)) opts.add(o); }
    _currentOptions = opts..shuffle();
  }

  void _restart() { setState(() { _nouns = List.from(widget.nouns.take(5))..shuffle(); _current = 0; _score = 0; _errors.clear(); _questionTime = DateTime.now(); _shuffleOptions(); }); }

  void _hint() { setState(() => _highlighted = _currentNoun.german); Future.delayed(const Duration(milliseconds: 800), () { if (mounted) setState(() => _highlighted = null); }); }

  void _answer(VocabularyNoun selected) {
    if (_showResult) return;
    final correct = selected.wordId == _currentNoun.wordId;
    final elapsed = DateTime.now().difference(_questionTime!).inMilliseconds;
    setState(() { _selected = selected.german; _showResult = true; _score += correct ? 2 + (elapsed < 5000 ? 1 : 0) : -1; _score = max(0, _score); if (!correct) _errors.add(GameError(gameType: GameType.dobble, wordId: _currentNoun.wordId, correctAnswer: _currentNoun.german, userAnswer: selected.german)); });
    if (correct) AudioService.playCorrectSound(); else AudioService.playIncorrectSound();
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (!mounted) return;
    if (_current + 1 >= _nouns.length) {
      setState(() => _showPts = true);
      Future.delayed(const Duration(seconds: 2), () { if (mounted) { Future.microtask(() { if (mounted) widget.onComplete(GameResult(gameType: GameType.dobble, correct: _nouns.length - _errors.length, total: _nouns.length, errors: _errors, score: _score)); }); } });
    } else { setState(() { _current++; _showResult = false; _selected = null; _highlighted = null; _questionTime = DateTime.now(); _shuffleOptions(); }); }
  }

  VocabularyNoun get _currentNoun => _nouns[_current];

  @override
  Widget build(BuildContext context) {
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('de $_maxScore posibles', style: const TextStyle(color: Colors.black54))]));
    final noun = _currentNoun;
    return Stack(children: [
      SafeArea(child: Column(children: [
        GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart, onHints: _hint, onHelp: () => showGameHelp(context, GameType.dobble, widget.nouns)),
        GameScoreBar(score: _score, maxScore: _maxScore),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), child: Column(children: [
          Text('${_current + 1}/${_nouns.length}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8), Text(noun.spanish, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)), const SizedBox(height: 4),
          Text(noun.image, style: const TextStyle(fontSize: 72)), const SizedBox(height: 20),
          ..._currentOptions.map((opt) {
            final isCorrect = _showResult && opt.wordId == noun.wordId; final isWrong = _showResult && _selected == opt.german && !isCorrect; final isHl = _highlighted == opt.german;
            Color bg = Colors.white, border = Colors.grey[300]!;
            if (isCorrect) { bg = Colors.green[50]!; border = Colors.green; } if (isWrong) { bg = Colors.red[50]!; border = Colors.red; } if (isHl) border = Colors.orange;
            return GestureDetector(onTap: _showResult ? null : () => _answer(opt), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(vertical: 14), width: double.infinity, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 2)),
              child: Row(children: [const Spacer(), Text(opt.fullGerman, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: articleColor(opt.article))), if (isCorrect) const Text(' ✅', style: TextStyle(fontSize: 16)), if (isWrong) const Text(' ❌', style: TextStyle(fontSize: 16)), const Spacer()])));
          }),
        ])))]),
    )]);
  }
}
