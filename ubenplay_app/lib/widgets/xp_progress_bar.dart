import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Barra de progreso de XP con corona
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int xpToNextLevel;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    this.xpToNextLevel = 100,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentXp % xpToNextLevel) / xpToNextLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de corona
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.crownGold.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // Barra de XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentXp XP',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Nivel ${currentXp ~/ xpToNextLevel + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.xpBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.withAlpha(25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.xpBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
