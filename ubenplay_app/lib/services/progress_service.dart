import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/user_progress.dart';

/// Servicio para guardar y cargar el progreso del usuario.
///
/// Directriz de persistencia: el progreso vive en SQLite local (`progreso_usuario`)
/// y se sincroniza a Supabase vía la cola. Ya NO usa SharedPreferences.
///
/// El progreso es 1:1 con el usuario en `progreso_usuario` (PK `id_usuario`).
/// Cuando no hay sesión activa se usa `id_usuario = 0` como fila anónima.
class ProgressService {
  static const int _anonimo = 0;

  static Future<Database> get _db => DatabaseService.database;

  /// Loads el progreso del usuario activo (o anónimo si idUsuario es null/0).
  static Future<UserProgress> loadProgress({int? idUsuario}) async {
    final db = await _db;
    final uid = idUsuario ?? 0;
    try {
      final rows = await db.query(
        'progreso_usuario',
        where: 'id_usuario = ?',
        whereArgs: [uid],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return _fromRow(rows.first);
      }
    } catch (_) {}
    return UserProgress();
  }

  /// Guarda el progreso actual (upsert en `progreso_usuario`, marca sincronizado=0).
  static Future<void> saveProgress(UserProgress progress, {int? idUsuario}) async {
    final db = await _db;
    final uid = idUsuario ?? _anonimo;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'progreso_usuario',
      {
        'id_usuario': uid,
        'total_xp': progress.totalXp,
        'current_streak': progress.currentStreak,
        'longest_streak': progress.longestStreak,
        'lessons_completed': progress.lessonsCompleted,
        'total_correct': progress.totalCorrect,
        'total_attempts': progress.totalAttempts,
        'last_practice_date': progress.lastPracticeDate.toIso8601String(),
        'ultima_actualizacion': now,
        'sincronizado': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Marca una lección como completada.
  static Future<UserProgress> completeLesson({
    required String lessonId,
    required int xpEarned,
    required int correct,
    required int total,
    int? idUsuario,
  }) async {
    final progress = await loadProgress(idUsuario: idUsuario);
    progress.completePractice(xpEarned, correct, total);
    progress.completedLessonIds.add(lessonId);
    await saveProgress(progress, idUsuario: idUsuario);
    return progress;
  }

  /// Resetea el progreso (para testing). Borra la fila de `progreso_usuario`.
  static Future<void> resetProgress({int? idUsuario}) async {
    final db = await _db;
    await db.delete(
      'progreso_usuario',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario ?? _anonimo],
    );
  }

  static UserProgress _fromRow(Map<String, dynamic> row) {
    return UserProgress(
      totalXp: row['total_xp'] as int? ?? 0,
      currentStreak: row['current_streak'] as int? ?? 0,
      longestStreak: row['longest_streak'] as int? ?? 0,
      lessonsCompleted: row['lessons_completed'] as int? ?? 0,
      totalCorrect: row['total_correct'] as int? ?? 0,
      totalAttempts: row['total_attempts'] as int? ?? 0,
      lastPracticeDate: row['last_practice_date'] != null
          ? DateTime.tryParse(row['last_practice_date'] as String) ??
              DateTime(2024, 1, 1)
          : DateTime(2024, 1, 1),
      // completedLessonIds / lessonScores no viven en progreso_usuario: se derivan
      // de `leccion_palabras` (v_leccion_completa). Se dejan vacíos aquí.
    );
  }
}