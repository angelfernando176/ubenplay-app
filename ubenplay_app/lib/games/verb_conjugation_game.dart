import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import 'game_result.dart';
import 'game_widgets.dart';

class VerbConjugationGame extends StatefulWidget {
  final List<VocabularyNoun> nouns;
  final void Function(GameResult) onComplete;
  const VerbConjugationGame({super.key, required this.nouns, required this.onComplete});
  @override
  State<VerbConjugationGame> createState() => _VerbConjugationGameState();
}

class _VerbConjugationGameState extends State<VerbConjugationGame> {
  static const _vpg = 3;
  static const _prons = ['ich', 'du', 'er/sie/es', 'wir', 'ihr', 'sie/Sie'];
  late List<_VD> _verbs;
  int _vi = 0, _score = 0, _max = 0;
  late _VD _cur;
  late List<String?> _placed;
  late List<_DB> _opts;
  bool _hint = false, _pts = false;
  DateTime? _qt;

  @override void initState() { super.initState(); _gen(); }

  void _gen() {
    final ns = List.from(widget.nouns)..shuffle();
    _verbs = ns.take(_vpg).map((n) => _mk(n)).toList();
    _max = _vpg * _prons.length * 3; _vi = 0; _score = 0; _hint = false; _init();
  }

  _VD _mk(VocabularyNoun n) => _VD(inf: n.german, sp: n.spanish, img: n.image, ex: n.exampleSentence,
    conj: { 'ich': n.conjIch.isNotEmpty ? n.conjIch : '${n.german}e',
            'du': n.conjDu.isNotEmpty ? n.conjDu : '${n.german}st',
            'er/sie/es': n.conjEr.isNotEmpty ? n.conjEr : '${n.german}t',
            'wir': n.conjWir.isNotEmpty ? n.conjWir : n.german,
            'ihr': n.conjIhr.isNotEmpty ? n.conjIhr : '${n.german}t',
            'sie/Sie': n.conjSieFormal.isNotEmpty ? n.conjSieFormal : n.german });

  void _init() { _cur = _verbs[_vi]; _placed = List.filled(_prons.length, null);
    _opts = List.generate(_prons.length, (i) => _DB(f: _cur.conj[_prons[i]]!, ix: i))..shuffle();
    _qt = DateTime.now(); }

  void _restart() { setState(() => _gen()); }
  void _hintFn() { setState(() => _hint = true); Future.delayed(const Duration(seconds:1), ()=>mounted?setState(()=>_hint=false):null); }

  void _drop(int si, int oi) {
    if (_placed[si] != null) return;
    final f = _opts[oi].f;
    final ok = f == _cur.conj[_prons[si]];
    final ms = DateTime.now().difference(_qt!).inMilliseconds;
    if (ok) {
      setState(() { _placed[si] = f; _opts.removeAt(oi); _score += _hint?1:(2+(ms<5000?1:0)); _qt=DateTime.now(); });
      if (_placed.every((v) => v != null))
        Future.delayed(const Duration(milliseconds:600), (){
          if (!mounted) return;
          if (_vi+1>=_vpg) { setState(()=>_pts=true); Future.delayed(const Duration(seconds:2),()=>mounted?Future.microtask(()=>mounted?widget.onComplete(GameResult(gameType:GameType.verbConjugation, correct:_vpg, total:_vpg, errors:[], score:_score)):null):null); }
          else setState(() { _vi++; _init(); });
        });
    } else {
      setState(() { _placed[si] = f; _opts.removeAt(oi); _score=max(0,_score-1); });
      Future.delayed(const Duration(seconds:2), ()=> mounted?setState(() { _placed[si]=null; _opts.add(_DB(f:f,ix:oi)); }):null);
    }
  }

  Widget _btn(_DB o, int ri) {
    final hm = _hint && o.ix == ri;
    return Container(margin:const EdgeInsets.only(left:4), padding:const EdgeInsets.symmetric(horizontal:10, vertical:6),
      decoration:BoxDecoration(color:hm?Colors.green[100]:Colors.white, borderRadius:BorderRadius.circular(6), border:Border.all(color:hm?Colors.green:Colors.grey[400]!)),
      child:Row(mainAxisSize:MainAxisSize.min, children:[
        if(_hint) Container(margin:const EdgeInsets.only(right:3), padding:const EdgeInsets.symmetric(horizontal:3,vertical:1), decoration:BoxDecoration(color:Colors.green[200], borderRadius:BorderRadius.circular(3)), child:Text('${o.ix+1}', style:const TextStyle(fontSize:9, fontWeight:FontWeight.bold))),
        Text(o.f, style:TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:hm?Colors.green[800]:Colors.black87)),
      ]));
  }

  @override
  Widget build(BuildContext ctx) {
    if (_pts) return Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[const Text('🎉', style:TextStyle(fontSize:64)), Text('Has ganado $_score puntos', style:const TextStyle(fontSize:24, fontWeight:FontWeight.bold)), Text('de $_max posibles', style:const TextStyle(color:Colors.black54))]));
    return SafeArea(child:Column(children:[
      GameHeader(level:'A1', wordType:'verbo', category:'', onRestart:_restart, onHints:_hintFn, onHelp: () => showGameHelp(context, GameType.verbConjugation, widget.nouns)),
      GameScoreBar(score:_hint?_score~/2:_score, maxScore:_max),
      Text('${_vi+1}/$_vpg verbos', style:const TextStyle(fontSize:11, color:Colors.black54)),
      Container(padding:const EdgeInsets.all(6), margin:const EdgeInsets.symmetric(horizontal:12), decoration:BoxDecoration(color:Colors.blue[50], borderRadius:BorderRadius.circular(8)),
        child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[
          Text(_cur.img, style:const TextStyle(fontSize:24)), const SizedBox(width:6),
          Text(_cur.inf, style:TextStyle(fontSize:18, fontWeight:FontWeight.w800, color:Colors.blue[800])),
          Text(' (${_cur.sp})', style:const TextStyle(fontSize:12, color:Colors.black54)),
        ])),
      if(_cur.ex.isNotEmpty) Padding(padding:const EdgeInsets.symmetric(horizontal:12), child:Text(_cur.ex, style:const TextStyle(fontSize:10, color:Colors.black54, fontStyle:FontStyle.italic), textAlign:TextAlign.center)),
      const SizedBox(height:4),
      Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:8), child:Column(children:List.generate(_prons.length, (i){
        final val = _placed[i];
        final ok = val!=null && val==_cur.conj[_prons[i]];
        final wr = val!=null && val!=_cur.conj[_prons[i]];
        Color bg = Colors.grey[100]!;
        if(ok) bg=Colors.green[100]!; else if(wr) bg=Colors.red[100]!;
        final btn = i < _opts.length ? _opts[i] : null;
        return Padding(padding:const EdgeInsets.symmetric(vertical:2), child:Row(children:[
          SizedBox(width:100, child:Text('${i+1}. ${_prons[i]}', style:const TextStyle(fontSize:13, fontWeight:FontWeight.w600))),
          Expanded(child:DragTarget<String>(
            onWillAcceptWithDetails:(d)=>val==null,
            onAcceptWithDetails:(d)=>_drop(i, _opts.indexWhere((o)=>o.f==d.data)),
            builder:(_,__,___)=>Container(height:36, decoration:BoxDecoration(color:bg, borderRadius:BorderRadius.circular(6), border:Border.all(color:ok?Colors.green:wr?Colors.red:Colors.grey[300]!, width:1.5)),
              child:Center(child:Text(val??'', style:TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:ok?Colors.green[800]:wr?Colors.red:Colors.black54)))),
          )),
          if(btn!=null) Draggable<String>(data:btn.f, feedback:Material(child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration:BoxDecoration(color:Colors.blue[100], borderRadius:BorderRadius.circular(6), border:Border.all(color:Colors.blue)), child:Text(btn.f, style:const TextStyle(fontSize:13, fontWeight:FontWeight.w600)))), childWhenDragging:Opacity(opacity:0.3, child:_btn(btn,i)), child:_btn(btn,i)),
        ]));
      })))),
    ]));
  }
}

class _VD { final String inf, sp, img; final Map<String,String> conj; final String ex; _VD({required this.inf, required this.sp, required this.img, required this.conj, this.ex=''}); }
class _DB { final String f; final int ix; _DB({required this.f, required this.ix}); }
