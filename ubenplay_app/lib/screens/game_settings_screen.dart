import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});
  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  static const _categories = ['Sustantivos', 'Verbos', 'Adjetivos', 'Conectores'];
  static const _catKeys = ['sustantivos', 'verbos', 'adjetivos', 'conectores'];
  String _catKey = 'sustantivos';
  String _catName = 'Sustantivos';

  static const _games = [
    ('matching', 'Unión de Palabras', Icons.link, [true, true, true, true]),
    ('article', 'Caza del Artículo', Icons.article, [true, false, false, false]),
    ('dobble', 'Traduce', Icons.translate, [true, true, true, true]),
    ('fillBlank', 'Ahorcado', Icons.edit, [true, true, true, false]),
    ('pairs', 'Memoria', Icons.grid_on, [true, true, true, true]),
    ('wordSearch', 'Sopa de Letras', Icons.search, [true, true, true, true]),
    ('wordRoulette', 'Ruleta de Palabras', Icons.circle_outlined, [true, true, true, false]),
    ('pathFinder', 'Puerta Verde', Icons.door_front_door, [true, true, true, true]),
    ('letterOrder', 'Puente de Cristal - Palabra', Icons.sort_by_alpha, [true, true, true, true]),
    ('verbConjugation', 'Ordena Filas', Icons.table_rows, [false, true, false, false]),
    ('sentenceOrder', 'Puente de cristal - oracion', Icons.text_fields, [true, true, true, true]),
    ('crossword', 'Crucigrama', Icons.grid_3x3, [true, true, true, true]),
  ];

  final _toggles = <String, bool>{};
  int _active = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _active = prefs.getInt('game_settings_category') ?? 0;
      _catKey = _catKeys[_active];
      _catName = _categories[_active];
      for (final g in _games) {
        _toggles[g.$1] = prefs.getBool('game_${_catKey}_${g.$1}') ?? true;
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juegos activos'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _catName,
              dropdownColor: AppTheme.primaryGreen,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) async {
                final idx = _categories.indexOf(v!);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('game_settings_category', idx);
                setState(() {
                  _active = idx;
                  _catKey = _catKeys[idx];
                  _catName = v;
                  for (final g in _games) {
                    _toggles[g.$1] = prefs.getBool('game_${_catKey}_${g.$1}') ?? true;
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Categoría: $_catName', style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          ..._games.map((g) => _buildToggle(g.$1, g.$2, g.$3, g.$4[_active])),
        ],
      ),
    );
  }

  Widget _buildToggle(String key, String name, IconData icon, bool available) {
    final value = _toggles[key] ?? true;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: SwitchListTile(
        secondary: Icon(icon, color: available ? AppTheme.primaryGreen : Colors.grey),
        title: Row(children: [
          Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: available ? Colors.black : Colors.grey))),
          if (!available) const Text('N/A', style: TextStyle(fontSize: 11, color: Colors.red)),
        ]),
        value: available && value,
        activeColor: AppTheme.primaryGreen,
        onChanged: available ? (v) async {
          setState(() => _toggles[key] = v);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('game_${_catKey}_$key', v);
        } : null,
      ),
    );
  }
}
