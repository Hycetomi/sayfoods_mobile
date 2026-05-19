import 'package:flutter/material.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final String emoji;
  final String? imageUrl;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.emoji,
    this.imageUrl,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keeps the chip hugging the text closely
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) =>
                    Text(emoji, style: const TextStyle(fontSize: 16)),
              )
            else
              Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
