import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../theme/app_theme.dart';

/// S002: Pantalla de avances
class ProgressScreen extends StatelessWidget {
  final UserProgress progress;
  const ProgressScreen({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    // Calcular días totales con práctica
    final days = progress.currentStreak;
    final lessons = progress.lessonsCompleted;
    
    return Scaffold(
      appBar: AppBar(title: const Text('📊 Avances')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _BigStat(icon: '📅', value: '$days', label: 'Días con repasos'),
                  _BigStat(icon: '✅', value: '$lessons', label: 'Lecciones realizadas'),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _RowStat('🎯 Precisión', '${progress.accuracy.toStringAsFixed(1)}%'),
                  _RowStat('⭐ XP total', '${progress.totalXp}'),
                  _RowStat('🔥 Racha actual', '${progress.currentStreak} días'),
                  _RowStat('🏆 Récord', '${progress.longestStreak} días'),
                  _RowStat('📝 Total intentos', '${progress.totalAttempts}'),
                  _RowStat('✅ Total correctas', '${progress.totalCorrect}'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String icon, value, label;
  const _BigStat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(icon, style: const TextStyle(fontSize: 40)), const SizedBox(height: 8),
    Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
    Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
  ]);
}

class _RowStat extends StatelessWidget {
  final String label, value;
  const _RowStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 15, color: AppTheme.textDark)),
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.xpBlue)),
    ]),
  );
}
