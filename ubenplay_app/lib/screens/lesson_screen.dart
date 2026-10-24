import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/lessons_data.dart';
import '../models/lesson.dart';
import '../models/lesson_session.dart';
import '../models/user_progress.dart';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../services/progress_service.dart';
import '../services/progreso_repository.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../games/game_result.dart';
import '../games/matching_game.dart';
import '../games/article_game.dart';
import '../games/dobble_game.dart';
import '../games/fill_blank_game.dart';
import '../games/pairs_game.dart';
import '../games/word_search_game.dart';
import '../games/word_roulette_game.dart';
import '../games/path_finder_game.dart';
import '../games/letter_order_game.dart';
import '../games/verb_conjugation_game.dart';
import '../games/sentence_order_game.dart';
import '../games/crossword_game.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final int multiplier;
  final String grammarMode;
  final List<GameType>? customGameSequence;
  final Map<GameType, List<VocabularyNoun>>? customWords;
  final int? idLeccion;
  final int? idUsuario;
  const LessonScreen({super.key, required this.lesson, this.multiplier = 1, this.grammarMode = 'Sustantivos', this.customGameSequence, this.customWords, this.idLeccion, this.idUsuario});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _gameIndex = 0;
  int _score = 0;
  final List<GameResult> _results = [];
  final List<GameError> _allErrors = [];
  late LessonSession _session;
  bool _completed = false;
  bool _resumed = false;

  static const _gameNames = {
    GameType.matching: 'Unión de Palabras', GameType.article: 'Caza del Artículo',
    GameType.dobble: 'Traduce', GameType.fillBlank: 'Ahorcado', GameType.pairs: 'Memoria', GameType.wordSearch: 'Sopa de Letras', GameType.wordRoulette: 'Ruleta de Palabras', GameType.pathFinder: 'Puente de Cristal', GameType.letterOrder: 'Puente de Cristal', GameType.verbConjugation: 'Ordena Filas', GameType.sentenceOrder: 'Ordenar Palabras', GameType.crossword: 'Crucigrama',
 };
 static const _gameMaxScores = {
 GameType.matching: 15, GameType.article: 15, GameType.dobble: 15,
 GameType.fillBlank: 45, GameType.pairs: 50, GameType.wordSearch: 80, GameType.wordRoulette: 12, GameType.pathFinder: 30, GameType.letterOrder: 75, GameType.verbConjugation: 81, GameType.sentenceOrder: 60, GameType.crossword: 150,
 };
 List<GameType> _gameSequence = [];
 bool _gamesLoaded = false;

 static const _gameOrder = [
   GameType.matching, GameType.article, GameType.dobble,
   GameType.fillBlank, GameType.pairs, GameType.wordSearch, GameType.wordRoulette, GameType.pathFinder, GameType.letterOrder, GameType.verbConjugation, GameType.sentenceOrder, GameType.crossword,
 ];

 GameType get _currentGame => _gameSequence[_gameIndex];

 @override
 void initState() {
   super.initState();
   _session = LessonSession.start(widget.lesson.id);
   AudioService.init();
   _init();
 }

 Future<void> _init() async {
   await _loadGameSettings();
   await _checkResume();
 }

 Future<void> _loadGameSettings() async {
   // Fase 4: si viene una secuencia personalizada (activación del profesor), úsala.
   if (widget.customGameSequence != null && widget.customGameSequence!.isNotEmpty) {
     if (mounted) {
       setState(() { _gameSequence = List.of(widget.customGameSequence!); _gamesLoaded = true; });
     }
     return;
   }
   final prefs = await SharedPreferences.getInstance();
   // Matriz de disponibilidad por categoría (mismo orden que _gameOrder)
   // Sustantivos, Verbos, Adjetivos, Conectores
   const _avail = {
     GameType.matching:   [true, true, true, true],
     GameType.article:    [true, false, false, false],
     GameType.dobble:     [true, true, true, true],
     GameType.fillBlank:  [true, true, true, false],
     GameType.pairs:      [true, true, true, true],
     GameType.wordSearch: [true, true, true, true],
     GameType.wordRoulette:[true, true, true, false],
     GameType.pathFinder: [true, true, true, true],
     GameType.letterOrder:[true, true, true, true],
     GameType.verbConjugation:[false, true, false, false],
     GameType.sentenceOrder:[true, true, true, true],
     GameType.crossword:  [true, true, true, true],
   };
   final catIdx = widget.grammarMode == 'Verbos' ? 1
                : widget.grammarMode == 'Adjetivos' ? 2
                : widget.grammarMode == 'Conectores' ? 3 : 0;

   final enabled = <GameType>[];
   for (final g in _gameOrder) {
     final avail = _avail[g]?[catIdx] ?? true;
     if (!avail) continue; // ❌ No disponible para esta categoría
     final key = _gamePrefKey(g);
     if (prefs.getBool(key) ?? true) enabled.add(g);
   }
   if (mounted) setState(() { _gameSequence = enabled.isNotEmpty ? enabled : _gameOrder.where((g) => (_avail[g]?[catIdx] ?? true)).toList(); _gamesLoaded = true; });
 }

 String _gamePrefKey(GameType g) => 'game_${widget.grammarMode.toLowerCase()}_${g.name}';

 Future<void> _checkResume() async {
     // Directriz: el resume vive en `estado_leccion` (SQLite), no en SharedPreferences.
     // El hash de secuencia detecta si el profesor cambió la lección.
     final seqHash = _gameSequence.map((g) => g.name).join(',');
     int? idJuego;
     try {
       if (widget.idLeccion != null && widget.idUsuario != null && widget.idUsuario != 0) {
         final estado = await ProgresoRepository.estadoLeccion(widget.idLeccion!, widget.idUsuario!);
         if (estado != null && estado['sequence_hash'] != seqHash) {
           await ProgresoRepository.borrarEstadoLeccion(widget.idLeccion!, widget.idUsuario!);
         } else if (estado != null) {
           idJuego = estado['id_juego'] as int?;
         }
       }
     } catch (_) {
       // Fallo de SQLite no debe interrumpir el arranque de la lección.
       idJuego = null;
     }

     // `idJuego` guarda el ÚLTIMO juego completado (guardado por _saveProgress
     // solo cuando _gameIndex>=2, así que basta con que exista para saber que
     // hay avance real; NO se debe reusar el valor de id_juego como umbral).
     if (idJuego != null) {
       final idxCompletado = _gameSequence.indexWhere((g) => idJuegoFromGameType(g) == idJuego);
       if (idxCompletado >= 0) {
         // Reanudar en el SIGUIENTE juego al último completado (no repetirlo).
         final idxSiguiente = (idxCompletado + 1).clamp(0, _gameSequence.length - 1);
         if (mounted) {
           final resume = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
             title: const Text('¿Continuar lección?'),
             content: Text('Tienes avance guardado (juego ${idxSiguiente + 1} de ${_gameSequence.length}). ¿Deseas continuar?'),
             actions: [
               TextButton(onPressed: () { ProgresoRepository.borrarEstadoLeccion(widget.idLeccion!, widget.idUsuario!); Navigator.pop(ctx, false); }, child: const Text('Empezar de 0')),
               TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar ▶')),
             ]));
           if (resume == true) {
             setState(() { _gameIndex = idxSiguiente; _resumed = true; });
           }
         }
       }
     }
   }

   Future<void> _saveProgress() async {
     // Directriz: guarda el resume en `estado_leccion` (SQLite), no en SharedPreferences.
     // Solo con lección activada (tiene idLeccion e idUsuario real).
     if (widget.idLeccion == null || widget.idUsuario == null || widget.idUsuario == 0) return;
     try {
       // Solo guardar avance representativo (≥2 juegos completados).
       if (_gameIndex < 2) {
         await ProgresoRepository.borrarEstadoLeccion(widget.idLeccion!, widget.idUsuario!);
         return;
       }
       final seqHash = _gameSequence.map((g) => g.name).join(',');
       await ProgresoRepository.guardarEstadoLeccion(
         idLeccion: widget.idLeccion!,
         idUsuario: widget.idUsuario!,
         idJuego: idJuegoFromGameType(_gameSequence[_gameIndex - 1]),
         sequenceHash: seqHash,
       );
     } catch (_) {
       // Fallo de SQLite al guardar resume no debe interrumpir el juego.
     }
   }

  void _onGameComplete(GameResult result) {
    _results.add(result); _allErrors.addAll(result.errors);
    _enviarAvance(result);
    if (_gameIndex + 1 >= _gameSequence.length) { _finalizeLesson(); }
    else { setState(() => _gameIndex++); _saveProgress(); }
  }

  Future<void> _enviarAvance(GameResult result) async {
    if (widget.idLeccion == null || widget.idUsuario == null || widget.idUsuario == 0) return;
    final idJuego = idJuegoFromGameType(_gameSequence[_gameIndex]);
    if (idJuego == null) return;
    final palabras = _nounsForGame(_gameIndex, 10);
    final wrongIds = result.errors.map((e) => e.wordId).toSet();
    final resultados = palabras.map((p) => {
          'id_palabra': p.wordId,
          'respuesta': wrongIds.contains(p.wordId) ? 0 : 1,
        }).toList();
    // Directriz de persistencia: el avance NACE en SQLite local (sincronizado=0),
    // en vez de POST al admin. La cola de sync lo sube a Supabase.
    try {
      await ProgresoRepository.registrarAvance(
        idLeccion: widget.idLeccion!,
        idUsuario: widget.idUsuario!,
        idJuego: idJuego,
        resultados: resultados,
      );
    } catch (_) {
      // Un fallo al registrar avance NO debe bloquear el flujo del juego.
    }
  }

  Future<void> _finalizeLesson() async {
    setState(() => _completed = true); AudioService.playCompleteSound();
    final totalCorrect = _results.fold<int>(0, (s, r) => s + r.correct);
    final totalQuestions = _results.fold<int>(0, (s, r) => s + r.total);
    final pct = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100).round() : 0;
    _session = _session.finish(score: pct, errors: _allErrors);
    final prefixedId = widget.grammarMode == 'Verbos' ? 'verb-${widget.lesson.id}' : widget.lesson.id;
    // Directriz: progreso en SQLite (no SharedPreferences). Si hay lección
    // activada, acumula en progreso_usuario vía el repositorio + marca sync.
    // Protegido con try/catch: un fallo de SQLite no debe dejar al estudiante
    // sin ver la pantalla de finalización de la lección.
    if (widget.idUsuario != null && widget.idUsuario != 0) {
      try {
        await ProgresoRepository.completarLeccion(
          idUsuario: widget.idUsuario!,
          xpEarned: widget.lesson.xpReward,
          correct: totalCorrect,
          total: totalQuestions,
        );
        if (widget.idLeccion != null) {
          await ProgresoRepository.borrarEstadoLeccion(widget.idLeccion!, widget.idUsuario!);
        }
      } catch (_) {}
    }
    UserProgress progress;
    try {
      progress = await ProgressService.completeLesson(
        lessonId: prefixedId, xpEarned: widget.lesson.xpReward, correct: totalCorrect, total: totalQuestions, idUsuario: widget.idUsuario);
    } catch (_) {
      // Fallback: si SQLite falla, igual se muestra el resultado de la sesión.
      progress = UserProgress();
    }
    if (mounted) _showCompletionDialog(progress, pct, totalCorrect, totalQuestions);
  }

  void _showCompletionDialog(UserProgress progress, int score, int correct, int total) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎉', style: TextStyle(fontSize: 64)), const SizedBox(height: 12),
        Text('¡Lección completada!', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ..._results.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
          Text(r.allCorrect ? '✅' : '⚠️'), const SizedBox(width: 8),
          Expanded(child: Text(_gameNames[r.gameType]!, style: const TextStyle(fontSize: 12))),
          Text('${r.correct}/${r.total}  ${r.score}/${_gameMaxScores[r.gameType] ?? 15}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.allCorrect ? AppTheme.correctGreen : AppTheme.incorrectRed)),
        ]))),
        const Divider(), Text('Total: ${_results.fold<int>(0,(s,r)=>s+(r.score??0))} pts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12), Text(_mascot(score, correct, total), style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(progress); }, child: const Text('Continuar'))),
      ]))));
  }

  String _mascot(int s, int c, int t) { final p = t>0?c/t:0; if(p<0.5)return'🤒'; if(p<0.8)return'😅'; return'🧠✨'; }

  Future<bool> _onWillPop() async {
    final willSave = _gameIndex >= 2;
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('¿Salir del juego?'),
      content: Text(willSave
          ? '¿Desea finalizar el juego? Se guardarán tus avances.'
          : 'Aún no has completado el reto de los 2 primeros juegos, por lo que el avance no se guardará.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SÍ')),
      ]));
    if (result == true) await _saveProgress();
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.lesson.title), leading: IconButton(icon: const Icon(Icons.close), onPressed: () async { if (await _onWillPop() && mounted) Navigator.of(context).pop(); })),
        body: _buildCurrentGame(),
      ),
    );
  }

  /// Selecciona las palabras para el juego en la posición `seqIndex` de la secuencia.
  List<VocabularyNoun> _nounsForGame(int seqIndex, int capacity) {
    if (widget.customWords != null) {
      return widget.customWords![_gameSequence[seqIndex]] ?? const [];
    }
    return LessonsData.wordsForGame(widget.lesson.nouns, seqIndex, capacity);
  }

  Widget _buildCurrentGame() {
    if (!_gamesLoaded || _gameSequence.isEmpty || _gameIndex >= _gameSequence.length) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_gameSequence[_gameIndex]) {
      case GameType.matching: return MatchingGame(nouns: _nounsForGame(_gameIndex, 5), onComplete: _onGameComplete);
      case GameType.article: return ArticleGame(nouns: _nounsForGame(_gameIndex, 5), onComplete: _onGameComplete);
      case GameType.dobble: return DobbleGame(nouns: _nounsForGame(_gameIndex, 5), onComplete: _onGameComplete);
      case GameType.fillBlank: return FillBlankGame(nouns: _nounsForGame(_gameIndex, 5), onComplete: _onGameComplete);
      case GameType.pairs: return PairsGame(nouns: _nounsForGame(_gameIndex, 10), onComplete: _onGameComplete);
      case GameType.wordSearch: return WordSearchGame(nouns: _nounsForGame(_gameIndex, 8), onComplete: _onGameComplete);
      case GameType.wordRoulette: return WordRouletteGame(nouns: _nounsForGame(_gameIndex, 4), onComplete: _onGameComplete);
      case GameType.pathFinder: return PathFinderGame(nouns: _nounsForGame(_gameIndex, 10), onComplete: _onGameComplete);
      case GameType.letterOrder: return LetterOrderGame(nouns: _nounsForGame(_gameIndex, 5), onComplete: _onGameComplete);
      case GameType.verbConjugation: return VerbConjugationGame(nouns: _nounsForGame(_gameIndex, 3), onComplete: _onGameComplete);
      case GameType.sentenceOrder: return SentenceOrderGame(nouns: _nounsForGame(_gameIndex, 5), onComplete: _onGameComplete);
      case GameType.crossword: return CrosswordGame(nouns: _nounsForGame(_gameIndex, 10), onComplete: _onGameComplete);
      default: return const Center(child: Text('...'));
    }
  }
}
