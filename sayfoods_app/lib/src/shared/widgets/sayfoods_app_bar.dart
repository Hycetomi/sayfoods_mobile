import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';

/// Premium branded app bar with a clean, modern aesthetic.
class SayfoodsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const SayfoodsAppBar({
    super.key,
    this.title = 'Sayfoods',
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (showBackButton) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
