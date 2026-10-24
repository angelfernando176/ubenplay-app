import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

/// Juego 5: Encontrar Equivalencias — Grid 5×4 (10 imágenes + 10 textos)
class PairsGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const PairsGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<PairsGame> createState() => _PairsGameState();
}

class _PairsGameState extends State<PairsGame> {
  late List<VocabularyNoun> _words;
  late List<_Cell> _cells;
  int? _revealed;
  int _pairsFound = 0, _score = 0, _errors = 0, _totalPairs = 0;
  final _pressedOnce = <int>{}; // ✅ botones presionados una vez (sin error)
  bool _locked = false, _showHelp = false, _hintUsed = false, _showPts = false;
  Timer? _hintTimer;

  @override
  void initState() { super.initState(); _initGrid(); }

  void _initGrid() {
    _words = List.from(widget.nouns)..shuffle(); _totalPairs = min(_words.length, 10); _words = _words.take(_totalPairs).toList();
    _cells = [];
    for (var i = 0; i < _totalPairs; i++) { _cells.add(_Cell(id: i, isImage: true, word: _words[i])); _cells.add(_Cell(id: i, isImage: false, word: _words[i])); }
    _cells.shuffle(); _pairsFound = 0; _score = 0; _errors = 0; _revealed = null; _locked = false; _pressedOnce.clear();
  }

  void _restart() { setState(() { _initGrid(); _hintUsed = false; }); }

  void _hint() { setState(() => _hintUsed = true); _hintTimer?.cancel(); _hintTimer = Timer(const Duration(seconds: 1), () { if (mounted) setState(() { for (var c in _cells) c.revealed = false; _revealed = null; }); }); setState(() { for (var c in _cells) c.revealed = true; _revealed = null; }); }

  void _tap(int index) {
    final cell = _cells[index];
    if (_locked || cell.matched || _revealed == index) return;

    // ✅ Contar error solo si se presiona un botón ya presionado antes (pero no bloquear)
    if (_pressedOnce.contains(index)) {
      _errors++;
      _score = max(0, _score - 1);
      AudioService.playIncorrectSound();
    }
    _pressedOnce.add(index);

    if (_revealed == null) { setState(() { cell.revealed = true; _revealed = index; }); return; }

    final first = _cells[_revealed!];
    setState(() => cell.revealed = true);
    _locked = true;

    if (first.id == cell.id && first.isImage != cell.isImage) {
      setState(() { first.matched = true; cell.matched = true; _pairsFound++; _score += _hintUsed ? 2 : 5; _revealed = null; _locked = false; });
      AudioService.playCorrectSound();
      if (_pairsFound >= _totalPairs) {
        setState(() => _showPts = true);
        Future.delayed(const Duration(seconds: 2), () { if (mounted) { Future.microtask(() { if (mounted) widget.onComplete(GameResult(gameType: GameType.pairs, correct: _pairsFound, total: _totalPairs, errors: [], score: _score)); }); } });
      }
    } else {
      _score = max(0, _score - 1); AudioService.playIncorrectSound();
      Future.delayed(const Duration(milliseconds: 700), () { if (mounted) setState(() { first.revealed = false; cell.revealed = false; _revealed = null; _locked = false; }); });
    }
  }

  @override
  void dispose() { _hintTimer?.cancel(); super.dispose(); }

  Widget _cellContent(_Cell cell) {
    if (cell.isImage) return Column(mainAxisSize: MainAxisSize.min, children: [Text(cell.word.image, style: const TextStyle(fontSize: 24)), Text(cell.word.spanish, style: const TextStyle(fontSize: 9, color: Colors.black54), textAlign: TextAlign.center)]);
    return Text(cell.word.german, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: articleColor(cell.word.article)), textAlign: TextAlign.center);
  }

  @override
  Widget build(BuildContext context) {
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('de ${_totalPairs * 5} posibles', style: const TextStyle(color: Colors.black54))]));
    return Stack(children: [
      SafeArea(child: Column(children: [
        GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart, onHints: _hint, onHelp: () => showGameHelp(context, GameType.pairs, widget.nouns)),
        GameScoreBar(score: _hintUsed ? _score ~/ 2 : _score, maxScore: _totalPairs * 5),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), child: Row(children: [
          Text('Pares: $_pairsFound/$_totalPairs', style: const TextStyle(fontSize: 13)),
          if (_hintUsed) const Text(' ⚠️ Pista', style: TextStyle(color: Colors.orange, fontSize: 11)),
          const Spacer(), Text('Fallos: $_errors', style: const TextStyle(fontSize: 13, color: Colors.red)),
        ])),
        Expanded(child: GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 4, crossAxisSpacing: 4), itemCount: _cells.length, itemBuilder: (ctx, i) {
          final cell = _cells[i]; final show = cell.revealed || cell.matched;
          return GestureDetector(onTap: () => _tap(i), child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(color: cell.matched ? Colors.green[100] : (show ? Colors.white : Colors.blueGrey[700]), borderRadius: BorderRadius.circular(8), border: Border.all(color: cell.matched ? Colors.green : Colors.grey[300]!, width: cell.matched ? 2 : 1)),
            child: Center(child: show ? _cellContent(cell) : const Text('?', style: TextStyle(fontSize: 18, color: Colors.white54, fontWeight: FontWeight.bold)))));
        })),
      ])),
    ]);
  }
}

class _Cell { final int id; final bool isImage; final VocabularyNoun word; bool matched = false; bool revealed = false; _Cell({required this.id, required this.isImage, required this.word}); }
