import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

class ArticleGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const ArticleGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<ArticleGame> createState() => _ArticleGameState();
}

class _ArticleGameState extends State<ArticleGame> {
  late List<VocabularyNoun> _nouns;
  int _current = 0, _score = 0, _maxScore = 15;
  String? _selected;
  bool _showResult = false, _showHelp = false, _showPts = false;
  final _errors = <GameError>[];
  DateTime? _questionTime;
  static const _articles = ['der', 'die', 'das', 'die (pl)'];
  String? _highlighted;

  @override
  void initState() { super.initState(); _nouns = List.from(widget.nouns.take(5))..shuffle(); _maxScore = _nouns.length * 3; _questionTime = DateTime.now(); }

  // ✅ Pistas: resalta el botón correcto
  void _hint() { setState(() => _highlighted = _currentNoun.article); Future.delayed(const Duration(milliseconds: 800), () { if (mounted) setState(() => _highlighted = null); }); }

  void _check(String article) {
    if (_showResult) return;
    final clean = article.replaceAll(' (pl)', '');
    final correct = clean == _currentNoun.article;
    final elapsed = DateTime.now().difference(_questionTime!).inMilliseconds;
    setState(() { _selected = article; _showResult = true; _score += correct ? 2 + (elapsed < 5000 ? 1 : 0) : -1; _score = max(0, _score); if (!correct) _errors.add(GameError(gameType: GameType.article, wordId: _currentNoun.wordId, correctAnswer: _currentNoun.article, userAnswer: clean)); });
    if (correct) AudioService.playCorrectSound(); else AudioService.playIncorrectSound();
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (!mounted) return;
    if (_current + 1 >= _nouns.length) {
      setState(() => _showPts = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) { Future.microtask(() { if (mounted) widget.onComplete(GameResult(gameType: GameType.article, correct: _nouns.length - _errors.length, total: _nouns.length, errors: _errors, score: _score)); }); }
      });
    } else { setState(() { _current++; _selected = null; _showResult = false; _questionTime = DateTime.now(); }); }
  }

  VocabularyNoun get _currentNoun => _nouns[_current];

  @override
  Widget build(BuildContext context) {
    final noun = _currentNoun;
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('de $_maxScore posibles', style: const TextStyle(color: Colors.black54))]));
    return Stack(children: [
      SafeArea(child: Column(children: [
        GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: (){}, onHints: _hint, onHelp: () => showGameHelp(context, GameType.article, widget.nouns)),
        GameScoreBar(score: _score, maxScore: _maxScore),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), child: Column(children: [
          Text('${_current + 1}/${_nouns.length}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(noun.german, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: articleColor(noun.article))),
          Text('(${noun.spanish})', style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 6), Text(noun.image, style: const TextStyle(fontSize: 64)), const SizedBox(height: 16),
          ..._articles.map((art) {
            final clean = art.replaceAll(' (pl)', ''); final isCorrect = _showResult && clean == noun.article; final isWrong = _showResult && _selected == art && !isCorrect; final isHl = _highlighted == clean;
            Color bg = Colors.white, border = Colors.grey[300]!;
            if (isCorrect) { bg = Colors.green[50]!; border = Colors.green; } if (isWrong) { bg = Colors.red[50]!; border = Colors.red; } if (isHl) bg = Colors.orange[50]!;
            return GestureDetector(onTap: _showResult ? null : () => _check(art), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(vertical: 14), width: double.infinity, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 2)),
              child: Row(children: [const Spacer(), Text(art, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: articleColor(clean))), if (isCorrect) const Text(' ✅', style: TextStyle(fontSize: 16)), if (isWrong) const Text(' ❌', style: TextStyle(fontSize: 16)), const Spacer()])));
          }),
        ])))]),
    )]);
  }
}
