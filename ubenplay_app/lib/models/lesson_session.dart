/// Sesión de lección: tracking de fecha, hora, puntuación
class LessonSession {
  final String lessonId;
  final DateTime startDate;
  final DateTime? endDate;
  final int numberOfRepasos;
  final int score;
  final List<dynamic> errors;

  const LessonSession({
    required this.lessonId,
    required this.startDate,
    this.endDate,
    this.numberOfRepasos = 1,
    this.score = 0,
    this.errors = const [],
  });

  factory LessonSession.start(String lessonId, {int repasos = 1}) {
    return LessonSession(
      lessonId: lessonId,
      startDate: DateTime.now(),
      numberOfRepasos: repasos,
    );
  }

  LessonSession finish({required int score, required List<dynamic> errors}) {
    return LessonSession(
      lessonId: lessonId,
      startDate: startDate,
      endDate: DateTime.now(),
      numberOfRepasos: numberOfRepasos,
      score: score.clamp(0, 30),
      errors: errors,
    );
  }

  String get startTime => _format(startDate);
  String get endTime => endDate != null ? _format(endDate!) : '';
  String get startDateStr =>
      '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
  String get endDateStr => endDate != null
      ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
      : '';

  String _format(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
