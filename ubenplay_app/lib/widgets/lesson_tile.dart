import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';

class LessonTile extends StatelessWidget {
  final Lesson lesson;
  final double progress;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap;

  const LessonTile({super.key, required this.lesson, required this.progress, required this.isCompleted, required this.onTap, this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.cardWhite, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompleted ? AppTheme.primaryGreen.withAlpha(80) : Colors.grey.withAlpha(40), width: isCompleted ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isCompleted ? 20 : 12), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Expanded(flex: isCompleted && onInfoTap != null ? 9 : 10,
          child: GestureDetector(onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: isCompleted ? AppTheme.primaryGreen.withAlpha(30) : AppTheme.primaryGreen.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(isCompleted ? '✅' : lesson.icon, style: const TextStyle(fontSize: 24)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lesson.title, style: Theme.of(context).textTheme.titleMedium),
              Text(lesson.description, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey.withAlpha(30), valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppTheme.crownGold : AppTheme.primaryGreen)))),
                const SizedBox(width: 8),
                Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isCompleted ? AppTheme.crownGold : AppTheme.primaryGreen)),
              ]),
            ])),
            Column(children: [
              Icon(isCompleted ? Icons.check_circle : Icons.star, color: isCompleted ? AppTheme.crownGold : AppTheme.xpBlue, size: 18),
              Text('+${lesson.xpReward} XP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isCompleted ? AppTheme.crownGold : AppTheme.xpBlue)),
            ]),
          ])))),
        if (isCompleted && onInfoTap != null)
          GestureDetector(onTap: onInfoTap, child: Container(width: 40, constraints: const BoxConstraints(minHeight: 72),
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.only(topRight: Radius.circular(14), bottomRight: Radius.circular(14))),
            child: const Center(child: Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 22)))),
      ]),
    );
  }
}
