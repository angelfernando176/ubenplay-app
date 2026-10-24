import 'package:flutter/material.dart';
import '../data/lessons_data.dart';
import '../models/user_progress.dart';
import '../models/vocabulary_noun.dart';
import '../widgets/streak_widget.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/category_tile.dart';
import '../theme/app_theme.dart';
import '../services/lecciones_service.dart';
import 'category_screen.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';

/// Pantalla principal con pestañas A1/A2/B1/B2
class HomeScreen extends StatefulWidget {
  final UserProgress progress;
  const HomeScreen({super.key, required this.progress});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late UserProgress _progress;
  late TabController _tabController;

  static const _levels = [CefrLevel.a1, CefrLevel.a2, CefrLevel.b1, CefrLevel.b2];
  static const _tabLabels = ['A1', 'A2', 'B1', 'B2'];

  // S005: Admin mode — desarrollo, sin restricciones
  final bool _isAdmin = true;

  // S003: Tipo de vocabulario seleccionado
  String _grammarMode = 'Sustantivos';

  int _nivelId(CefrLevel l) =>
      l == CefrLevel.a1 ? 1 : l == CefrLevel.a2 ? 2 : l == CefrLevel.b1 ? 3 : 4;

  int _catId(String m) =>
      m == 'Sustantivos' ? 1 : m == 'Verbos' ? 2 : m == 'Adjetivos' ? 3 : 4;

  String _iconoCat(int catId) =>
      catId == 1 ? '📝' : catId == 2 ? '🏃' : catId == 3 ? '🎨' : '🔗';

  String get _grammarSubtitle => {
    'Sustantivos': 'Sustantivos · Nomen',
    'Verbos': 'Verbos · Verben',
    'Adjetivos': 'Adjetivos · Adjektive',
    'Conectores': 'Conectores · Konnektoren',
  }[_grammarMode] ?? 'Sustantivos · Nomen';

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isLevelUnlocked(int index) {
    if (_isAdmin) return true; // Admin ve todo
    if (index == 0) return true;
    final prevLevel = _levels[index - 1];
    final progress = LessonsData.levelProgress(prevLevel, _progress.completedLessonIds);
    return progress >= 0.95;
  }

  void _onProgressUpdated(UserProgress newProgress) {
    setState(() => _progress = newProgress);
  }

  void _showGrammarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Tipo de vocabulario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          _GrammarOption(icon: '📝', label: 'Sustantivos', enabled: true, selected: _grammarMode == 'Sustantivos', onTap: () { setState(() => _grammarMode = 'Sustantivos'); Navigator.pop(ctx); }),
          _GrammarOption(icon: '🏃', label: 'Verbos', enabled: true, selected: _grammarMode == 'Verbos', onTap: () { setState(() => _grammarMode = 'Verbos'); Navigator.pop(ctx); }),
          _GrammarOption(icon: '🎨', label: 'Adjetivos', enabled: true, selected: _grammarMode == 'Adjetivos', onTap: () { setState(() => _grammarMode = 'Adjetivos'); Navigator.pop(ctx); }),
          _GrammarOption(icon: '🔗', label: 'Conectores', enabled: false, selected: false, onTap: () {}),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🦉 Ubenplay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(_grammarSubtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
          ],
        ),
        actions: [
          // S001: Configuración (3 opciones)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          // S002: Avances
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Avances',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressScreen(progress: _progress))),
          ),
          // S003: Gramática (selector)
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Gramática',
            onPressed: _showGrammarPicker,
          ),
          StreakWidget(streakDays: _progress.currentStreak, practicedToday: _progress.practicedToday),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          tabs: List.generate(4, (i) => Tab(
            child: Opacity(
              opacity: _isLevelUnlocked(i) ? 1.0 : 0.4,
              child: Text(_tabLabels[i]),
            ),
          )),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: XpProgressBar(currentXp: _progress.totalXp),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _StatItem(icon: '✅', value: '${_progress.lessonsCompleted}', label: 'Lecciones'),
                  _StatItem(icon: '🎯', value: '${_progress.accuracy.toStringAsFixed(0)}%', label: 'Precisión'),
                  _StatItem(icon: '🔥', value: '${_progress.longestStreak}', label: 'Récord'),
                ]),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (i) {
                if (!_isLevelUnlocked(i)) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🔒', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text('Completa el 95% de ${_tabLabels[i-1]} para desbloquear',
                          style: const TextStyle(color: AppTheme.textLight)),
                    ]),
                  );
                }
                return _buildLevelGrid(_levels[i]);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGrid(CefrLevel level) {
    final nivelId = _nivelId(level);
    final catId = _catId(_grammarMode);
    final temas = LeccionesService.tematicasDeNivel(nivelId)
        .where((t) => catId == 0 || t['id_categoria'] == catId)
        .toList();
    if (temas.isEmpty) {
      return const Center(child: Text('Próximamente', style: TextStyle(color: AppTheme.textLight)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: temas.length,
      itemBuilder: (context, index) {
        final tema = temas[index];
        final nLecciones = (tema['lecciones'] as List).length;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(
                idTematica: tema['id_tematica'] as int,
                idCategoria: catId,
                nombreTematica: tema['nombre_tematica'] as String,
                progress: _progress,
                grammarMode: _grammarMode,
              )));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_iconoCat(catId), style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 6),
                Text(tema['nombre_tematica'] as String, textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('$nLecciones lección(es)', style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon, value, label;
  const _StatItem({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
  ]);
}

class _GrammarOption extends StatelessWidget {
  final String icon, label;
  final bool enabled, selected;
  final VoidCallback onTap;
  const _GrammarOption({required this.icon, required this.label, required this.enabled, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(icon, style: TextStyle(fontSize: 28, color: enabled ? null : Colors.grey)),
    title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: enabled ? AppTheme.textDark : AppTheme.textLight)),
    trailing: selected ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen) : (enabled ? null : const Text('próximo', style: TextStyle(fontSize: 11, color: AppTheme.textLight))),
    enabled: enabled,
    onTap: enabled ? onTap : null,
  );
}
