/// Progreso del usuario: XP, racha, lecciones completadas
class UserProgress {
  int totalXp;
  int currentStreak; // Días consecutivos
  int longestStreak;
  int lessonsCompleted;
  int totalCorrect;
  int totalAttempts;
  DateTime lastPracticeDate;
  final Set<String> completedLessonIds;
  final Map<String, int> lessonScores; // lessonId → puntuación

  UserProgress({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lessonsCompleted = 0,
    this.totalCorrect = 0,
    this.totalAttempts = 0,
    DateTime? lastPracticeDate,
    Set<String>? completedLessonIds,
    Map<String, int>? lessonScores,
  })  : lastPracticeDate = lastPracticeDate ?? DateTime(2024, 1, 1),
        completedLessonIds = completedLessonIds ?? {},
        lessonScores = lessonScores ?? {};

  /// Precisión en porcentaje
  double get accuracy =>
      totalAttempts > 0 ? totalCorrect / totalAttempts * 100 : 0;

  /// ¿Mantuvo la racha hoy?
  bool get practicedToday {
    final now = DateTime.now();
    return lastPracticeDate.year == now.year &&
        lastPracticeDate.month == now.month &&
        lastPracticeDate.day == now.day;
  }

  /// Registrar práctica completada
  void completePractice(int xpEarned, int correct, int total) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Actualizar racha
    if (!practicedToday) {
      if (lastPracticeDate.year == yesterday.year &&
          lastPracticeDate.month == yesterday.month &&
          lastPracticeDate.day == yesterday.day) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }

    totalXp += xpEarned;
    totalCorrect += correct;
    totalAttempts += total;
    lessonsCompleted++;
    lastPracticeDate = now;
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalXp: json['totalXp'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      lastPracticeDate: json['lastPracticeDate'] != null
          ? DateTime.parse(json['lastPracticeDate'] as String)
          : DateTime.now(),
      completedLessonIds: (json['completedLessonIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      lessonScores: (json['lessonScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lessonsCompleted': lessonsCompleted,
        'totalCorrect': totalCorrect,
        'totalAttempts': totalAttempts,
        'lastPracticeDate': lastPracticeDate.toIso8601String(),
        'completedLessonIds': completedLessonIds.toList(),
        'lessonScores': lessonScores,
      };
}
