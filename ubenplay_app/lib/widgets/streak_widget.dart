import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget de racha de días (🔥 streak)
class StreakWidget extends StatelessWidget {
  final int streakDays;
  final bool practicedToday;

  const StreakWidget({
    super.key,
    required this.streakDays,
    required this.practicedToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: practicedToday
            ? AppTheme.streakOrange.withAlpha(25)
            : Colors.grey.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: practicedToday
              ? AppTheme.streakOrange.withAlpha(80)
              : Colors.grey.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥',
            style: TextStyle(
              fontSize: practicedToday ? 24 : 20,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$streakDays',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: practicedToday
                  ? AppTheme.streakOrange
                  : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
