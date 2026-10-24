import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/audio_service.dart';
import 'game_result.dart';
import 'game_widgets.dart';

/// Juego 7: Sopa de Letras — 10×10, 8 palabras ocultas
class WordSearchGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const WordSearchGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  static const _gridSize = 10, _wordCount = 8;
  late List<VocabularyNoun> _words;
  late List<List<String>> _grid;
  late List<_FoundWord> _foundWords;
  final _selected = <_Cell>{};
  bool _hintUsed = false, _showPts = false, _showHint = false, _showWordHint = false;
  int _showWordHintId = -1;
  int _score = 0, _maxScore = 0;
  Timer? _hintTimer;

  @override
  void initState() { super.initState(); _initGame(); }

  void _initGame() {
    _words = List.from(widget.nouns)..shuffle(); _words = _words.take(_wordCount).toList();
    if (_words.isEmpty) _words = widget.nouns.take(1).toList();
    _maxScore = 0;
    for (final w in _words) _maxScore += w.german.length * 2;
    _foundWords = _words.map((w) => _FoundWord(word: w, found: false, cells: [])).toList();
    _grid = _buildGrid();
    // Filtrar palabras que no se pudieron colocar (cells vacías)
    _foundWords.removeWhere((fw) => fw.cells.isEmpty);
    _words = _foundWords.map((fw) => fw.word).toList();
    _maxScore = 0;
    for (final w in _words) _maxScore += w.german.length * 2;
    _selected.clear(); _score = 0; _hintUsed = false; _hintTimer?.cancel();
  }

  void _restart() { setState(() { _initGame(); }); }

  void _wordTap(int idx) {
    final fw = _foundWords[idx];
    if (fw.found || fw.cells.isEmpty) return;
    _hintTimer?.cancel();
    setState(() { _showWordHint = true; _showWordHintId = idx; _showHint = false; });
    _hintTimer = Timer(const Duration(seconds: 2), () { if (mounted) setState(() { _showWordHint = false; _showWordHintId = -1; }); });
  }

  void _showHelpDialog() {
    // ✅ También mostrar pistas visuales
    _hintTimer?.cancel();
    setState(() { _showHint = true; _showWordHint = false; });
    _hintTimer = Timer(const Duration(seconds: 2), () { if (mounted) setState(() => _showHint = false); });

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('📖 Ayuda — Oraciones'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        ..._foundWords.where((fw) => fw.cells.isNotEmpty).map((fw) {
          final ex = fw.word.exampleSentence.isNotEmpty ? fw.word.exampleSentence : '${fw.word.german} — ${fw.word.spanish}';
          final dirName = fw.dir == _Dir.h ? 'Horizontal' : fw.dir == _Dir.v ? 'Vertical' : 'Diagonal';
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: Colors.black87), children: [
            TextSpan(text: '${fw.word.spanish}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            ..._highlightWord(ex, fw.word.german),
            TextSpan(text: ' [$dirName]', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])));
        }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Regresar'))],
    ));
  }

  List<TextSpan> _highlightWord(String text, String word) {
    final result = <TextSpan>[];
    final lower = text.toLowerCase(); final w = word.toLowerCase();
    int start = 0;
    while (start < text.length) {
      final idx = lower.indexOf(w, start);
      if (idx == -1) { result.add(TextSpan(text: text.substring(start))); break; }
      if (idx > start) result.add(TextSpan(text: text.substring(start, idx)));
      result.add(TextSpan(text: text.substring(idx, idx + word.length), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
      start = idx + word.length;
    }
    return result;
  }

  void _hint() {
    setState(() => _hintUsed = true);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () { if (mounted) setState(() => _showHint = false); });
    setState(() => _showHint = true);
  }

  List<List<String>> _buildGrid() {
    final grid = List.generate(_gridSize, (_) => List.filled(_gridSize, ''));
    final rng = Random();

    for (var di = 0; di < _words.length; di++) {
      final word = _words[di].german.toUpperCase();
      if (word.length < 2 || word.length > _gridSize) continue;
      final dirs = <_Dir>[_Dir.h, _Dir.v, _Dir.d1, _Dir.d2]..shuffle(rng);
      bool ok = false;
      for (final dir in dirs) {
        for (var a = 0; a < 200 && !ok; a++) {
          final r = rng.nextInt(_gridSize), c = rng.nextInt(_gridSize);
          if (_fits(grid, word, r, c, dir)) {
            _put(grid, word, r, c, dir);
            final cells = <_Cell>[];
            for (var i = 0; i < word.length; i++) {
              final (cr, cc) = _pos(r, c, dir, i);
              cells.add(_Cell(r: cr, c: cc, letter: word[i]));
            }
            _foundWords[di].cells = cells;
            _foundWords[di].dir = dir;
            ok = true;
          }
        }
        if (ok) break;
      }
      if (!ok) {
        // fallback horizontal
        if (word.length <= _gridSize) {
          for (var a = 0; a < 200 && !ok; a++) {
            final r = rng.nextInt(_gridSize), c = rng.nextInt(_gridSize - word.length + 1);
            if (_fits(grid, word, r, c, _Dir.h)) {
              _put(grid, word, r, c, _Dir.h);
              final cells = <_Cell>[];
              for (var i = 0; i < word.length; i++) cells.add(_Cell(r: r, c: c + i, letter: word[i]));
              _foundWords[di].cells = cells;
              _foundWords[di].dir = _Dir.h;
              ok = true;
            }
          }
        }
      }
    }

    const fill = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜß';
    for (var r = 0; r < _gridSize; r++)
      for (var c = 0; c < _gridSize; c++)
        if (grid[r][c].isEmpty) grid[r][c] = fill[rng.nextInt(fill.length)];

    return grid;
  }

  bool _fits(List<List<String>> g, String w, int r, int c, _Dir d) {
    for (var i = 0; i < w.length; i++) {
      final (cr, cc) = _pos(r, c, d, i);
      if (cr < 0 || cr >= _gridSize || cc < 0 || cc >= _gridSize) return false;
      if (g[cr][cc].isNotEmpty && g[cr][cc] != w[i]) return false;
    }
    return true;
  }

  void _put(List<List<String>> g, String w, int r, int c, _Dir d) {
    for (var i = 0; i < w.length; i++) {
      final (cr, cc) = _pos(r, c, d, i);
      g[cr][cc] = w[i];
    }
  }

  (int, int) _pos(int r, int c, _Dir d, int i) => switch (d) {
    _Dir.h  => (r, c + i),
    _Dir.v  => (r + i, c),
    _Dir.d1 => (r + i, c + i),
    _Dir.d2 => (r + i, c - i),
  };

  void _tap(int r, int c) {
    if (_showPts) return;
    final cell = _Cell(r: r, c: c, letter: '');
    final exists = _selected.any((s) => s.r == r && s.c == c);
    if (exists) {
      // Toggle off
      setState(() => _selected.removeWhere((s) => s.r == r && s.c == c));
    } else {
      // Toggle on
      final newCell = _Cell(r: r, c: c, letter: _grid[r][c]);
      setState(() => _selected.add(newCell));
    }
    _check();
  }

  void _check() {
    for (final fw in _foundWords) {
      if (fw.found || fw.cells.isEmpty) continue;
      // Check if ALL cells of this word are in _selected
      if (fw.cells.every((c) => _selected.any((s) => s.r == c.r && s.c == c.c))) {
        setState(() {
          fw.found = true;
          final pts = fw.cells.length * 2;
          _score += _hintUsed ? pts ~/ 2 : pts;
        });
        AudioService.playCorrectSound();

        if (_foundWords.every((f) => f.found)) {
          setState(() => _showPts = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Future.microtask(() {
              if (mounted) widget.onComplete(GameResult(gameType: GameType.wordSearch, correct: _foundWords.where((f) => f.found).length, total: _foundWords.length, errors: [], score: _score));
            });
          });
        }
      }
    }
  }

  @override
  void dispose() { _hintTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_showPts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('de $_maxScore posibles', style: const TextStyle(color: Colors.black54))]));

    return Stack(children: [
      SafeArea(child: Column(children: [
        GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart, onHints: _hint, onHelp: () => showGameHelp(context, GameType.wordSearch, widget.nouns)),
        GameScoreBar(score: _hintUsed ? _score ~/ 2 : _score, maxScore: _maxScore),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Encuentra las 8 palabras en alemán. Toca las letras que las forman.', style: TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center)),
        Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(4), child: _buildGridWidget())),
        Expanded(flex: 1, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Wrap(spacing: 4, runSpacing: 3, children: List.generate(_words.length, (i) {
          final w = _words[i]; final fw = _foundWords[i];
          return GestureDetector(
            onTap: () => _wordTap(i),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: fw.found ? Colors.green[100] : Colors.grey[100], borderRadius: BorderRadius.circular(5), border: Border.all(color: fw.found ? Colors.green : Colors.grey[300]!)), child: Text(w.spanish, style: TextStyle(fontSize: 11, decoration: fw.found ? TextDecoration.lineThrough : null, color: fw.found ? Colors.green : Colors.black54))),
          );
        })))),
      ])),
    ]);
  }

  Widget _buildGridWidget() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cs = (constraints.maxWidth - 2) / _gridSize;
      return Column(children: List.generate(_gridSize, (r) => Row(children: List.generate(_gridSize, (c) {
        final letter = _grid[r][c];
        final found = _foundWords.any((f) => f.found && f.cells.any((fc) => fc.r == r && fc.c == c));
        final sel = _selected.any((s) => s.r == r && s.c == c);
        final hintStart = _showHint 
            ? _foundWords.any((f) => !f.found && f.cells.isNotEmpty && f.cells.first.r == r && f.cells.first.c == c)
            : (_showWordHint && _showWordHintId >= 0 && _showWordHintId < _foundWords.length && !_foundWords[_showWordHintId].found && _foundWords[_showWordHintId].cells.isNotEmpty && _foundWords[_showWordHintId].cells.first.r == r && _foundWords[_showWordHintId].cells.first.c == c);
        Color bg = Colors.white;
        if (found && sel) bg = Colors.green;
        else if (found) bg = Colors.green[200]!;
        else if (sel) bg = Colors.yellow[200]!;
        else if (hintStart) bg = const Color(0xFF9C27B0); // ✅ morado
        return GestureDetector(
          onTap: () => _tap(r, c),
          child: Container(width: cs, height: cs, decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.grey[300]!, width: 0.5)),
            child: Center(child: Text(letter, style: TextStyle(fontSize: cs * 0.55, fontWeight: FontWeight.bold, color: found || sel ? Colors.black : Colors.black87)))),
        );
      }))));
    });
  }
}

enum _Dir { h, v, d1, d2 }
class _Cell { final int r, c; String letter; _Cell({required this.r, required this.c, required this.letter}); }
class _FoundWord { final VocabularyNoun word; List<_Cell> cells; bool found; _Dir? dir; _FoundWord({required this.word, required this.found, required this.cells, this.dir}); }
