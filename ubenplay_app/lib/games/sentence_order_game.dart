import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import 'game_result.dart';
import 'game_widgets.dart';
import 'glass_bridge.dart';

/// Juego 12: Ordenar Palabras — oraciones desde oracion_ejemplo
class SentenceOrderGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const SentenceOrderGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<SentenceOrderGame> createState() => _SentenceOrderGameState();
}

class _SentenceOrderGameState extends State<SentenceOrderGame> {
  List<_Sent> _sents = [];
  int _si = 0, _score = 0, _max = 0;
  late _Sent _cur;
  late List<_WB> _opts;
  int _pos = 0, _errorAt = -1;
  bool _hint = false, _showHint = false, _pts = false, _done = false;
  int _ws = 0;
  DateTime? _qt;

  @override void initState() { super.initState(); _gen(); }

  void _gen() {
    final ns = List.from(widget.nouns)..shuffle();
    _sents = [];
    for (final n in ns.take(5)) {
      final parts = n.sentenceWords.isNotEmpty ? n.sentenceWords : _split(n.exampleSentence.isNotEmpty ? n.exampleSentence : '${n.article} ${n.german} ist gut');
      _sents.add(_Sent(g: n.exampleSentence, s: n.spanish, de: n.german, w: parts));
    }
    while (_sents.length < 5 && ns.isNotEmpty) {
      final n = ns[_sents.length % ns.length];
      _sents.add(_Sent(g: '${n.article} ${n.german} ist gut', s: n.spanish, de: n.german,
        w: _split('${n.article} ${n.german} ist gut')));
    }
    _max = 0; for (final s in _sents) _max += s.w.length * 3;
    _si = 0; _score = 0; _hint = false; _init();
  }

  List<String> _split(String s) => s.split(RegExp(r'\s+')).map((w) =>
    w.replaceAll(RegExp(r'[.,;:!?¿¡()\[\]"»«]'), '').toLowerCase()).where((w) => w.isNotEmpty).toList();

  void _init() { _cur = _sents[_si]; _pos = 0; _errorAt = -1; _done = false; _ws = 0;
    _opts = List.generate(_cur.w.length, (i) => _WB(w: _cur.w[i]))..shuffle(); _qt = DateTime.now(); }

  void _restart() { setState(() { _si = 0; _score = 0; _hint = false; _init(); }); }
  void _hintFn() { setState(() { _hint = true; _showHint = true; }); Future.delayed(const Duration(seconds:1), ()=>mounted?setState(()=>_showHint=false):null); }

  void _tap(int idx) {
    if (_errorAt >= 0 || _done) return;
    final btn = _opts[idx]; final ok = btn.w == _cur.w[_pos];
    final ms = DateTime.now().difference(_qt!).inMilliseconds;
    if (ok) {
      setState(() { _pos++; _opts.removeAt(idx); _score += _hint ? 1 : (2 + (ms < 5000 ? 1 : 0)); _ws += _hint ? 1 : (2 + (ms < 5000 ? 1 : 0)); _qt = DateTime.now(); });
      if (_pos >= _cur.w.length) { setState(() => _done = true); Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        if (_si + 1 >= _sents.length) { setState(() => _pts = true); Future.delayed(const Duration(seconds:2), ()=> mounted?Future.microtask(()=>mounted?widget.onComplete(GameResult(gameType:GameType.sentenceOrder, correct:_sents.length, total:_sents.length, errors:[], score:_score)):null):null); }
        else setState(() { _si++; _init(); });
      });}
    } else {
      setState(() { _pos++; _opts.removeAt(idx); _errorAt = _pos - 1; _score = max(0, _score - 1); });
      Future.delayed(const Duration(seconds:2), ()=>!mounted?null:setState((){_pos=_errorAt>=0?_errorAt:_pos; _errorAt=-1; _opts.add(btn); _opts.shuffle();}));
    }
  }

  @override
  Widget build(BuildContext ctx) {
    if (_pts) return Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[const Text('🎉', style:TextStyle(fontSize:64)), Text('Has ganado $_score puntos', style:TextStyle(fontSize:24, fontWeight:FontWeight.bold)), Text('de $_max posibles', style:TextStyle(color:Colors.black54))]));
    return SafeArea(child:Column(children:[
      GameHeader(level:'A1', wordType:'frase', category:'', onRestart:_restart, onHints:_hintFn, onHelp: () => showGameHelp(context, GameType.sentenceOrder, widget.nouns)),
      GameScoreBar(score:_hint?_score~/2:_score, maxScore:_max),
      Text('${_si+1}/${_sents.length} oraciones', style:TextStyle(fontSize:11, color:Colors.black54)),
      // Palabra en español + alemán
      Container(padding:EdgeInsets.all(6), margin:EdgeInsets.symmetric(horizontal:12), decoration:BoxDecoration(color:Colors.amber[50], borderRadius:BorderRadius.circular(8)),
        child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[
          Text('${_cur.de}  ', style:TextStyle(fontSize:14, fontWeight:FontWeight.w700, color:Colors.blue[800])),
          Text('(${_cur.s})', style:TextStyle(fontSize:13, color:Colors.black54)),
        ])),
      SizedBox(height:2),
      // Pista de la oración
      Container(padding:EdgeInsets.all(4), margin:EdgeInsets.symmetric(horizontal:12), decoration:BoxDecoration(color:Colors.blue[50], borderRadius:BorderRadius.circular(6)),
        child:Text(_cur.s.isNotEmpty?'Ordena: "${_cur.s}"':'Ordena las palabras', style:TextStyle(fontSize:12, fontWeight:FontWeight.w500), textAlign:TextAlign.center)),
      SizedBox(height:4),
      // Puente de Cristal + traducción al completar
      Expanded(child:Column(children:[
        Expanded(child:GlassBridge(totalSteps:_cur.w.length, currentStep:_pos, errorStep:_errorAt, avatarEmoji:'📝', placed:List.generate(_cur.w.length, (i)=>i<_pos?_cur.w[i]:''), labels:List.generate(_cur.w.length, (i)=>i<_pos?_cur.w[i]:''), showCelebration:_done, wordScore:_ws)),
        if (_done)
          Container(padding:EdgeInsets.all(8), margin:EdgeInsets.only(bottom:4), decoration:BoxDecoration(color:Colors.green[50], borderRadius:BorderRadius.circular(8), border:Border.all(color:Colors.green[200]!)),
            child:Column(children:[
              Text(_cur.g, style:TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:Colors.green[800])),
              SizedBox(height:2),
              Text('($_cur.s)', style:TextStyle(fontSize:11, color:Colors.black54)),
              SizedBox(height:2),
              Text('+$_ws pts', style:TextStyle(fontSize:12, fontWeight:FontWeight.w700, color:Colors.green[700])),
            ])),
      ])),
      // Botones de palabras
      Container(padding:EdgeInsets.all(6), decoration:BoxDecoration(color:Colors.grey[100]), child:Wrap(spacing:4, runSpacing:4, children:List.generate(_opts.length, (i){
        final o = _opts[i]; final hn = _showHint ? _cur.w.indexOf(o.w) + 1 : 0;
        return GestureDetector(onTap:()=>_tap(i), child:Container(padding:EdgeInsets.symmetric(horizontal:12, vertical:8), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(8), border:Border.all(color:Colors.grey[400]!)), child:Row(mainAxisSize:MainAxisSize.min, children:[
          if(hn>0) Container(margin:EdgeInsets.only(right:4), padding:EdgeInsets.symmetric(horizontal:4, vertical:1), decoration:BoxDecoration(color:Colors.green[200], borderRadius:BorderRadius.circular(4)), child:Text('$hn', style:TextStyle(fontSize:10, fontWeight:FontWeight.bold))),
          Text(o.w, style:TextStyle(fontSize:15, fontWeight:FontWeight.w600)),
        ])));
      }))),
      SizedBox(height:4),
    ]));
  }
}

class _Sent { final String g, s, de; final List<String> w; _Sent({required this.g, required this.s, required this.de, required this.w}); }
class _WB { final String w; _WB({required this.w}); }
