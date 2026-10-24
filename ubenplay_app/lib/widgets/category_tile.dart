import 'package:flutter/material.dart';
import '../data/lessons_data.dart';
import '../theme/app_theme.dart';

/// Tarjeta de categoría para el grid principal
class CategoryTile extends StatelessWidget {
  final VocabularyCategory category;
  final double progress; // 0.0 a 1.0
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.category,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = progress >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isComplete
                ? AppTheme.crownGold.withAlpha(100)
                : Colors.grey.withAlpha(40),
            width: isComplete ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isComplete ? 15 : 8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji grande
                  Text(
                    category.icon,
                    style: TextStyle(
                      fontSize: isComplete ? 36 : 42,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Título
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Descripción
                  Text(
                    category.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withAlpha(25),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AppTheme.crownGold : AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Indicador de completado
                  if (isComplete)
                    const Text(
                      '✅ Completado',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.crownGold,
                      ),
                    )
                  else
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
