import 'package:flutter/material.dart';
import 'dart:math';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

class ImageOptionsGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const ImageOptionsGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<ImageOptionsGame> createState() => _ImageOptionsGameState();
}

class _ImageOptionsGameState extends State<ImageOptionsGame> {
  late List<VocabularyNoun> _nouns;
  int _current = 0, _score = 0, _maxScore = 15;
  final List<GameError> _errors = [];
  DateTime? _questionTime;

  @override
  void initState() {
    super.initState();
    _nouns = List.from(widget.nouns.take(5))..shuffle();
    _maxScore = _nouns.length * 3;
    _questionTime = DateTime.now();
  }

  void _restart() {
    setState(() {
      _nouns = List.from(widget.nouns.take(5))..shuffle();
      _current = 0; _score = 0; _errors.clear();
      _questionTime = DateTime.now();
    });
  }

  void _answer(VocabularyNoun selected) {
    final correct = selected.wordId == _currentNoun.wordId;
    final elapsed = DateTime.now().difference(_questionTime!).inMilliseconds;
    final speedBonus = elapsed < 5000 ? 1 : 0;

    if (correct) {
      _score += 2 + speedBonus;
      AudioService.playCorrectSound();
    } else {
      _score = max(0, _score - 1);
      _errors.add(GameError(gameType: GameType.imageOptions, wordId: _currentNoun.wordId, correctAnswer: _currentNoun.german, userAnswer: selected.german));
      AudioService.playIncorrectSound();
    }

    if (_current + 1 >= _nouns.length) {
      widget.onComplete(GameResult(gameType: GameType.imageOptions, correct: _nouns.length - _errors.length, total: _nouns.length, errors: _errors));
    } else {
      setState(() { _current++; _questionTime = DateTime.now(); });
    }
  }

  VocabularyNoun get _currentNoun => _nouns[_current];
  List<VocabularyNoun> get _options {
    final rng = Random();
    final opts = [widget.nouns[_current], widget.nouns[widget.nouns.length - 1 - _current], widget.nouns[rng.nextInt(widget.nouns.length)]];
    return opts.toSet().take(3).toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final noun = _currentNoun;
    return Column(children: [
      GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart),
      GameScoreBar(score: _score, maxScore: _maxScore),
      Expanded(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('${_current + 1}/${_nouns.length}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          Text(noun.image, style: const TextStyle(fontSize: 80)),
          const Spacer(),
          ..._options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => _answer(opt), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(opt.fullGerman, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            )),
          )),
          const Spacer(),
        ]),
      )),
    ]);
  }
}
