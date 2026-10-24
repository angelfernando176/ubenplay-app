import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import 'game_result.dart';
import 'game_widgets.dart';

class CrosswordGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const CrosswordGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<CrosswordGame> createState() => _CrosswordGameState();
}

class _CrosswordGameState extends State<CrosswordGame> {
  static const _T = ['    HUND  ','  A T   M ',' AUTO   I ','  N O   L ',' SONNE  C ','     FISCH'];
  late List<_W> _words;
  late List<List<_C?>> _g;
  int _rows = 0, _cols = 0, _score = 0, _max = 0;
  bool _pts = false, _hint = false;
  int? _sel;
  DateTime? _qt;

  @override
  void initState() { super.initState(); _gen(); }

  void _gen() {
    final ns = List.from(widget.nouns)..shuffle();
    final pool = ns.map((n) => n.german.toUpperCase()).toList();
    final rng = Random();
    _rows = _T.length; _cols = _T.map((r) => r.length).reduce(max);
    _g = List.generate(_rows, (_) => List.filled(_cols, null));
    _words = []; _max = 0;
    for (var r = 0; r < _rows; r++) for (var c = 0; c < _T[r].length; c++) if (_T[r][c] != ' ') _g[r][c] = _C(l: _T[r][c]);

    int n = 1;
    for (var r = 0; r < _rows; r++) for (var c = 0; c < _cols; c++) {
      if (_g[r][c] == null) continue;
      if (c == 0 || _g[r][c-1] == null) {
        int len = 0; while (c + len < _cols && _g[r][c + len] != null) len++;
        if (len >= 2) {
          final cells = <_C>[]; for (var i = 0; i < len; i++) cells.add(_g[r][c + i]!);
          _words.add(_W(cells: cells, num: n++, isH: true, r: r, c: c)); _max += len * 3;
        }
      }
    }
    for (var c = 0; c < _cols; c++) for (var r = 0; r < _rows; r++) {
      if (_g[r][c] == null) continue;
      if (r == 0 || _g[r-1][c] == null) {
        int len = 0; while (r + len < _rows && _g[r + len][c] != null) len++;
        if (len >= 2) {
          final cells = <_C>[]; for (var i = 0; i < len; i++) cells.add(_g[r + i][c]!);
          _words.add(_W(cells: cells, num: n++, isH: false, r: r, c: c)); _max += len * 3;
        }
      }
    }
    for (final w in _words) {
      final ns2 = ns.where((x) => x.german.length == w.cells.length).toList();
      if (ns2.isNotEmpty) { final x = ns2[rng.nextInt(ns2.length)]; w.clue = x.spanish; w.emoji = x.image; ns.remove(x); }
    }
    _score = 0; _sel = null; _hint = false; _qt = DateTime.now();
  }

  void _restart() { setState(() { _gen(); }); }
  void _hintFn() { setState(() => _hint = true); Future.delayed(const Duration(seconds: 1), () { if (mounted) setState(() => _hint = false); }); }
  void _selW(int i) { setState(() => _sel = i); }

  void _type(int wi, int ci, String l) {
    if (_pts) return; final w = _words[wi]; final c = w.cells[ci]; final ok = l.toUpperCase() == c.l;
    final ms = DateTime.now().difference(_qt!).inMilliseconds;
    if (ok) {
      setState(() { c.u = l.toUpperCase(); c.g = true; _score += _hint ? 1 : (2 + (ms < 5000 ? 1 : 0)); _qt = DateTime.now(); });
      if (w.cells.every((x) => x.u != null)) Future.delayed(const Duration(milliseconds: 300), () { if (!mounted) return; if (_words.every((pw) => pw.cells.every((x) => x.u != null))) { setState(() => _pts = true); Future.delayed(const Duration(seconds: 2), () { if (mounted) Future.microtask(() { if (mounted) widget.onComplete(GameResult(gameType: GameType.crossword, correct: _words.length, total: _words.length, errors: [], score: _score)); }); }); } });
    } else { setState(() { c.u = l.toUpperCase(); _score = max(0, _score - 1); }); Future.delayed(const Duration(milliseconds: 400), () { if (mounted) setState(() { c.u = null; }); }); }
  }

  void _del() { if (_sel == null) return; final w = _words[_sel!]; for (var i = w.cells.length - 1; i >= 0; i--) if (w.cells[i].u != null) { setState(() { w.cells[i].u = null; w.cells[i].g = false; }); return; } }

  Widget _kb(String l, {bool del = false}) {
    if (del) return GestureDetector(onTap: _del, child: Container(margin: const EdgeInsets.all(1), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red[200]!)), child: const Text('⌫', style: TextStyle(fontSize: 17))));
    if (_sel == null) return const SizedBox(width: 1, height: 1);
    final w = _words[_sel!]; final nx = w.cells.indexWhere((c) => c.u == null); if (nx < 0) return const SizedBox(width: 1, height: 1);
    return GestureDetector(onTap: () => _type(_sel!, nx, l), child: Container(margin: const EdgeInsets.all(1), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[400]!)), child: Text(l, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))));
  }

  @override
  Widget build(BuildContext ctx) {
    if (_pts) return _winScreen();
    final cs = min((MediaQuery.of(ctx).size.width - 16) / _cols, 30.0);
    final kids = <Widget>[
      GameHeader(level: 'A1', wordType: wordTypeLabel(widget.nouns), category: '', onRestart: _restart, onHints: _hintFn, onHelp: () => showGameHelp(context, GameType.crossword, widget.nouns)),
      GameScoreBar(score: _hint ? _score ~/ 2 : _score, maxScore: _max),
      Text('${_words.length} palabras', style: const TextStyle(fontSize: 11, color: Colors.black54)),
      Expanded(child: _buildGrid(cs)),
      _buildClues(),
      _buildKeyboard(),
    ];
    return SafeArea(child: Column(children: kids));
  }

  Widget _winScreen() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🎉', style: TextStyle(fontSize: 64)), Text('Has ganado $_score puntos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text('de $_max posibles', style: const TextStyle(color: Colors.black54))]));

  Widget _buildGrid(double cs) {
    final rows = <Widget>[];
    for (var r = 0; r < _rows; r++) {
      final cells = <Widget>[];
      for (var c = 0; c < _cols; c++) {
        final cell = _g[r][c];
        if (cell == null) { cells.add(SizedBox(width: cs, height: cs, child: Container(color: Colors.black))); continue; }
        int? wi, ci;
        for (var i = 0; i < _words.length; i++) { final idx = _words[i].cells.indexOf(cell); if (idx >= 0) { wi = i; ci = idx; break; } }
        final isS = _sel == wi; final isStart = ci == 0;
        Color bg = cell.g ? Colors.green[100]! : (isS ? Colors.blue[50]! : (_hint && isStart ? const Color(0xFF9C27B0) : Colors.white));
        cells.add(GestureDetector(onTap: () { if (wi != null) _selW(wi!); }, child: Stack(children: [
          Container(width: cs, height: cs, decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.black, width: 0.8)), child: Center(child: Text(cell.u ?? '', style: TextStyle(fontSize: cs * 0.55, fontWeight: FontWeight.bold, color: cell.u != null ? Colors.black : Colors.transparent)))),
          if (isStart && wi != null) Positioned(left: 0, top: 0, child: Text('${_words[wi!].num}', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black54))),
        ])));
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }
    return SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(8), child: Column(children: rows)));
  }

  Widget _buildClues() {
    return Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.grey[100]), height: 70, child: SingleChildScrollView(child: Wrap(spacing: 4, runSpacing: 2, children: _words.map((w) {
      final i = _words.indexOf(w); final done = w.cells.every((c) => c.u != null);
      return GestureDetector(onTap: () => _selW(i), child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: _sel == i ? Colors.blue[50] : (done ? Colors.green[50] : null), borderRadius: BorderRadius.circular(4), border: Border.all(color: _sel == i ? Colors.blue : Colors.grey[300]!)), child: Text('${w.num}${w.isH?"→":"↓"} ${w.emoji}${w.clue}', style: TextStyle(fontSize: 10, color: done ? Colors.green : Colors.black87))));
    }).toList())));
  }

  Widget _buildKeyboard() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), child: _sel != null ? Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: 'QWERTZUIOP'.split('').map((l) => _kb(l)).toList()),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: 'ASDFGHJKL'.split('').map((l) => _kb(l)).toList()),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [...'YXCVBNM'.split('').map((l) => _kb(l)), _kb('', del: true)]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: 'ÄÖÜßÁÉÍÓÚ'.split('').map((l) => _kb(l)).toList()),
    ]) : const SizedBox.shrink());
  }
}

class _W { final List<_C> cells; String clue = '', emoji = '📝'; int num; bool isH; int r, c; _W({required this.cells, this.num = 0, this.isH = true, this.r = 0, this.c = 0}); }
class _C { final String l; String? u; bool g = false; _C({required this.l}); }
