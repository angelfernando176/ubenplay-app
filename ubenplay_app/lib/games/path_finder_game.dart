import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import 'game_result.dart';
import 'game_widgets.dart';
import 'stickman_animation.dart';

class PathFinderGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const PathFinderGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<PathFinderGame> createState() => _PathFinderGameState();
}

class _PathFinderGameState extends State<PathFinderGame> {
  static const _steps = 10, _maxScore = 30, _maxErrors = 4;
  late List<_Question> _qs;
  int _cur = 0, _score = 0, _errs = 0, _pendingErr = 0;
  bool _hint = false, _pts = false, _point = false, _showFail = false;
  DateTime? _qt;
  String? _sel;

  @override
  void initState() { super.initState(); _gen(); }

  void _gen() {
    final ns = List.from(widget.nouns)..shuffle();
    // Asegurar exactamente _steps preguntas
    _qs = [];
    for (var i = 0; i < _steps; i++) {
      _qs.add(_Q(ns[i % ns.length]));
    }
    _cur = 0; _score = 0; _errs = 0; _point = false; _hint = false; _sel = null; _qt = DateTime.now();
  }

  _Question _Q(VocabularyNoun n) {
    final r = Random();
    final wt = n.wordType;

    // === SUSTANTIVOS (tipo 1) ===
    if (wt == 1) {
      final t = r.nextInt(3);
      switch (t) {
        case 0:
          final c = n.article.isNotEmpty ? n.article : 'der';
          final w = ['der','die','das'].where((a)=>a!=c).toList()..shuffle();
          return _Question(t: '¿Cuál es el ARTÍCULO de "${n.german}"?', c: c, o: [c, w[0], w[1]]..shuffle(), w: n);
        case 1:
          final c = n.plural.isNotEmpty ? n.plural : n.german;
          final wrongs = widget.nouns.where((x)=>x.plural.isNotEmpty&&x.plural!=c).take(3).map((x)=>x.plural).toList();
          while (wrongs.length < 2) wrongs.add(n.german);
          return _Question(t: '¿Cuál es el PLURAL de "${n.german}"?', c: c, o: [c, ...wrongs.take(2)]..shuffle(), w: n);
        default:
          final c = n.spanish;
          final wrongs = widget.nouns.where((x)=>x.spanish.isNotEmpty&&x.spanish!=c).take(3).map((x)=>x.spanish).toList();
          while (wrongs.length < 2) wrongs.add(c);
          return _Question(t: '¿Cuál es el SIGNIFICADO de "${n.german}"?', c: c, o: [c, ...wrongs.take(2)]..shuffle(), w: n);
      }
    }

    // === VERBOS (tipo 2) ===
    if (wt == 2) {
      final pron = ['ich','du','er/sie/es','wir','ihr','sie/Sie'];
      final cnj = [n.conjIch, n.conjDu, n.conjEr, n.conjWir, n.conjIhr, n.conjSieFormal];
      final cj = List.generate(6, (i) => cnj[i].isNotEmpty ? cnj[i] : '${n.german}${["e","st","t","en","t","en"][i]}');

      if (r.nextBool()) {
        final pi = r.nextInt(6);
        final wrongs = List.generate(6, (i) => cj[i]).where((c)=>c!=cj[pi]).take(2).toList();
        if (wrongs.length<2) wrongs.addAll(['${n.german}te','${n.german}ten']);
        return _Question(t: 'Conjuga "${n.german}" para: ${pron[pi]}', c: cj[pi], o: [cj[pi], ...wrongs]..shuffle(), w: n);
      } else {
        final pi = r.nextInt(6);
        final wrongs = List.generate(6, (i) => pron[i]).where((p)=>p!=pron[pi]).take(2).toList();
        if (wrongs.length<2) wrongs.addAll(['él','vosotros']);
        return _Question(t: '¿Qué PRONOMBRE usa "${cj[pi]}"?', c: pron[pi], o: [pron[pi], ...wrongs]..shuffle(), w: n);
      }
    }

    // Fallback
    final c = n.spanish;
    final wrongs = widget.nouns.where((x)=>x.spanish.isNotEmpty&&x.spanish!=c).take(3).map((x)=>x.spanish).toList();
    while (wrongs.length < 2) wrongs.add(c);
    return _Question(t: '¿Cuál es el SIGNIFICADO de "${n.german}"?', c: c, o: [c, ...wrongs.take(2)]..shuffle(), w: n);
  }

  void _restart() => setState(() => _gen());
  void _hintFn() { setState(() => _hint = true); Future.delayed(const Duration(seconds: 1), () { if (mounted) setState(() => _hint = false); }); }

  void _ans(String o) {
    if (_sel != null) return;
    final q = _qs[_cur], ok = o == q.c;
    final ms = DateTime.now().difference(_qt!).inMilliseconds;
    setState(() { _point = true; _sel = o; if (!ok) _pendingErr = _errs + 1; });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (ok) {
        setState(() { _score += _hint?1:(2+(ms<5000?1:0)); _sel=null; _point=false; });
        if (_cur+1>=_steps) { setState(()=>_pts=true); Future.delayed(const Duration(seconds:2), (){ if(mounted) Future.microtask((){ if(mounted) widget.onComplete(GameResult(gameType:GameType.pathFinder, correct:_steps-_errs, total:_steps, errors:[], score:_score)); }); }); }
        else setState(() { _cur++; _qt=DateTime.now(); });
      } else {
        _errs++; setState(() { _sel=null; _point=false; _pendingErr=0; _qt=DateTime.now(); });
        if (_errs>=_maxErrors) { setState(()=>_showFail=true); Future.delayed(const Duration(seconds:2), (){ if(mounted) Future.microtask((){ if(mounted) widget.onComplete(GameResult(gameType:GameType.pathFinder, correct:_steps-_errs, total:_steps, errors:[], score:_score)); }); }); }
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    if (_pts) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🎉', style: TextStyle(fontSize: 64)), Text(_errs>=_maxErrors?'Du hast versagt!':'Has ganado $_score pts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text('de $_maxScore', style: TextStyle(color: Colors.black54))]));

    final q = (_qs.isNotEmpty && _cur < _qs.length) ? _qs[_cur] : null;
    if (q==null) return Center(child: Text('...'));

    return SafeArea(child: Column(children: [
      GameHeader(level:'A1', wordType: wordTypeLabel(widget.nouns), category:'', onRestart:_restart, onHints:_hintFn, onHelp: () => showGameHelp(context, GameType.pathFinder, widget.nouns)),
      GameScoreBar(score:_hint?_score~/2:_score, maxScore:_maxScore),
      Text('Fallos: $_errs/$_maxErrors  |  ${_cur+1}/$_steps', style: TextStyle(fontSize:11, color:Colors.black54)),
      Expanded(child: Padding(padding: EdgeInsets.all(8), child: Row(children: [
        Expanded(flex:3, child: MascotHitAnimation(walking:_sel==null, pointing:_point, errorLevel:_pendingErr)),
        Expanded(flex:5, child: Column(mainAxisAlignment:MainAxisAlignment.center, children: q.o.map((opt) {
          final isC = _sel!=null && opt==q.c;
          final isW = _sel==opt && opt!=q.c;
          Color bg = Colors.grey[100]!;
          if(isC) bg=Colors.green[100]!; else if(isW) bg=Colors.red[100]!;
          final hint = _hint && opt==q.c && _sel==null;
          if(hint) bg=Colors.orange[100]!;
          return Padding(padding: EdgeInsets.only(bottom:6), child: GestureDetector(
            onTap: _sel!=null?null:()=>_ans(opt),
            child: Container(padding: EdgeInsets.symmetric(vertical:10), decoration: BoxDecoration(color:bg, borderRadius:BorderRadius.circular(10), border:Border.all(color:isC?Colors.green:isW?Colors.red:hint?Colors.orange:Colors.brown[200]!, width:2)),
              child: Row(children: [
                SizedBox(width:6), Text('🚪', style:TextStyle(fontSize:18)), SizedBox(width:6),
                Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, mainAxisSize:MainAxisSize.min, children: [
                  Text(opt, style:TextStyle(fontSize:13, fontWeight:FontWeight.w600)),
                  if(isW) Text('❌ Tu elección', style:TextStyle(fontSize:9, color:Colors.red)),
                  if(isC) Text('✅ Correcto', style:TextStyle(fontSize:9, color:Colors.green)),
                ])),
                if(isC) Icon(Icons.check_circle, color:Colors.green, size:18),
                SizedBox(width:4),
              ])),
          ));
        }).toList())),
      ]))),
      Container(padding:EdgeInsets.all(10), margin:EdgeInsets.symmetric(horizontal:12), decoration:BoxDecoration(color:Colors.blue[50], borderRadius:BorderRadius.circular(10)), child:Text(q.t, style:TextStyle(fontSize:13, fontWeight:FontWeight.w600), textAlign:TextAlign.center)),
      // Mensaje de fallo
      if (_showFail) Container(margin:EdgeInsets.symmetric(horizontal:12), padding:EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.red[50], borderRadius:BorderRadius.circular(10)), child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[Text('🚨', style:TextStyle(fontSize:20)), SizedBox(width:8), Text('Du hast versagt!', style:TextStyle(fontSize:15, fontWeight:FontWeight.bold, color:Colors.red[800]))])),
      SizedBox(height:6),
      Padding(padding:EdgeInsets.symmetric(horizontal:20, vertical:4), child:_bar()),
    ]));
  }

  Widget _bar() => Row(children: List.generate(_steps, (i) => Expanded(child: Container(height:8, margin:EdgeInsets.symmetric(horizontal:1), decoration:BoxDecoration(color:i<_cur?Colors.green:Colors.grey[300]!, borderRadius:BorderRadius.circular(4))))));
}

class _Question { final String t, c; final List<String> o; final VocabularyNoun w; _Question({required this.t, required this.c, required this.o, required this.w}); }
