import 'package:flutter/material.dart';
import '../services/lecciones_service.dart';
import '../services/usuario_service.dart';
import '../services/supabase_service.dart';
import '../models/user_progress.dart';
import '../models/lesson.dart';
import '../models/vocabulary_noun.dart';
import '../models/game_type.dart';
import '../theme/app_theme.dart';
import 'lesson_screen.dart';

/// Listado de lecciones habilitadas de una temática (Fase 4), con 3 estados.
class CategoryScreen extends StatefulWidget {
  final int idTematica;
  final int idCategoria;
  final String nombreTematica;
  final UserProgress progress;
  final String grammarMode;

  const CategoryScreen({
    super.key,
    required this.idTematica,
    required this.idCategoria,
    required this.nombreTematica,
    required this.progress,
    this.grammarMode = 'Sustantivos',
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _idUsuario = 0;
  List<Map<String, dynamic>> _lecciones = [];

  @override
  void initState() {
    super.initState();
    _lecciones = LeccionesService.leccionesDeTematica(widget.idTematica, widget.idCategoria);
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final u = await UsuarioService.loadSession();
    if (mounted && u != null) {
      setState(() => _idUsuario = u.idUsuario ?? 0);
    }
  }

  String _estadoLabel(int estado) =>
      estado == 2 ? 'Finalizada' : estado == 1 ? 'Iniciada' : 'Sin iniciar';

  Color _estadoColor(int estado) => estado == 2
      ? AppTheme.primaryGreen
      : estado == 1
          ? const Color(0xFF1CB0F6)
          : AppTheme.textLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.grammarMode} · ${widget.nombreTematica}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${_lecciones.length} lecciones disponibles',
                style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
            const SizedBox(height: 8),
            ..._lecciones.map((l) {
              final estado = LeccionesService.estadoLeccion(l, _idUsuario);
              final nPalabras = l['cantidad_palabras'] as int? ?? 10;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.school, color: AppTheme.primaryGreen),
                  title: Text('Lección ${l['id_leccion']} · $nPalabras palabras'),
                  trailing: Text(_estadoLabel(estado),
                      style: TextStyle(color: _estadoColor(estado), fontWeight: FontWeight.w700)),
                  onTap: () => _iniciarLeccion(l),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _iniciarLeccion(Map<String, dynamic> l) async {
    final idLeccion = l['id_leccion'] as int;
    final juegos = await SupabaseService.fetchLeccionJuegos(idLeccion);
    if (juegos.isEmpty) {
      _mostrarProximamente();
      return;
    }
    final catId = l['id_categoria'] as int? ?? 1;
    final vocabType = catId == 1
        ? VocabularyType.nouns
        : catId == 2
            ? VocabularyType.verbs
            : VocabularyType.adjectives;
    final grammar = catId == 1 ? 'Sustantivos' : catId == 2 ? 'Verbos' : 'Adjetivos';

    // Distribución exacta activada: secuencia de juegos + palabras por juego.
    final secuencia = <GameType>[];
    final palabrasPorJuego = <GameType, List<VocabularyNoun>>{};
    final todas = <VocabularyNoun>[];
    final vistas = <int>{};
    for (final j in juegos) {
      final g = gameTypeFromIdJuego(j['id_juego'] as int);
      if (g == null) continue;
      final palabras = (j['palabras'] as List).cast<VocabularyNoun>();
      if (palabras.isEmpty) continue;
      secuencia.add(g);
      palabrasPorJuego[g] = palabras;
      for (final p in palabras) {
        if (vistas.add(p.wordId)) todas.add(p);
      }
    }
    if (secuencia.isEmpty) {
      _mostrarProximamente();
      return;
    }

    final lesson = Lesson(
      id: '$idLeccion',
      title: 'Lección $idLeccion',
      description: '',
      difficulty: LessonDifficulty.beginner,
      vocabularyType: vocabType,
      icon: '📝',
      nouns: todas,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonScreen(
        lesson: lesson,
        grammarMode: grammar,
        customGameSequence: secuencia,
        customWords: palabrasPorJuego,
        idLeccion: idLeccion,
        idUsuario: _idUsuario > 0 ? _idUsuario : null,
      )),
    );
  }

  void _mostrarProximamente() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('En construcción'),
        content: const Text('La ejecución de lecciones con el nuevo modelo llega en la siguiente fase.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar')),
        ],
      ),
    );
  }
}
