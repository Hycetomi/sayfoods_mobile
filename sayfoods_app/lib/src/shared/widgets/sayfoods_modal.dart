import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';

enum SayfoodsModalType { info, success, warning, error, custom }

/// A globally accessible utility to show modern, beautifully styled modals and bottom sheets.
class SayfoodsModal {
  /// Shows a beautiful, animated modal dialog with a glassmorphism backdrop.
  /// 
  /// Use this for critical alerts, confirmations, or success messages.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    SayfoodsModalType type = SayfoodsModalType.info,
    Widget? customContent,
    IconData? customIcon,
    Color? customIconColor,
    String primaryButtonText = 'Okay',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'SayfoodsModal',
      barrierColor: Colors.black.withOpacity(0.3), // Soft dark overlay
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Glassmorphism blur
          child: ScaleTransition(
            scale: scaleCurve,
            child: FadeTransition(
              opacity: animation,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: _ModalBody(
                  title: title,
                  subtitle: subtitle,
                  type: type,
                  customContent: customContent,
                  customIcon: customIcon,
                  customIconColor: customIconColor,
                  primaryButtonText: primaryButtonText,
                  onPrimaryPressed: onPrimaryPressed,
                  secondaryButtonText: secondaryButtonText,
                  onSecondaryPressed: onSecondaryPressed,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shows a beautiful bottom sheet popup that slides up from the bottom.
  /// 
  /// Perfect for actions, options, or complex forms.
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool useGlassmorphism = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final content = Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child,
            ],
          ),
        );

        if (useGlassmorphism) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: content,
          );
        }

        return content;
      },
    );
  }
}

class _ModalBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final SayfoodsModalType type;
  final Widget? customContent;
  final IconData? customIcon;
  final Color? customIconColor;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const _ModalBody({
    required this.title,
    this.subtitle,
    required this.type,
    this.customContent,
    this.customIcon,
    this.customIconColor,
    required this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (type) {
      case SayfoodsModalType.success:
        icon = LucideIcons.checkCircle;
        iconColor = AppColors.success;
        iconBgColor = AppColors.success.withValues(alpha: 0.1);
        break;
      case SayfoodsModalType.error:
        icon = LucideIcons.alertTriangle;
        iconColor = AppColors.error;
        iconBgColor = AppColors.error.withValues(alpha: 0.1);
        break;
      case SayfoodsModalType.warning:
        icon = LucideIcons.alertCircle;
        iconColor = AppColors.warning;
        iconBgColor = AppColors.warning.withValues(alpha: 0.1);
        break;
      case SayfoodsModalType.info:
        icon = LucideIcons.info;
        iconColor = AppColors.primary;
        iconBgColor = AppColors.primary.withValues(alpha: 0.1);
        break;
      case SayfoodsModalType.custom:
        icon = customIcon ?? LucideIcons.star;
        iconColor = customIconColor ?? AppColors.primary;
        iconBgColor = iconColor.withValues(alpha: 0.1);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Icon Container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: iconColor),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          
          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          
          const SizedBox(height: 28),
          
          // Custom Content (Optional extra widgets)
          if (customContent != null) ...[
            customContent!,
            const SizedBox(height: 28),
          ],
          
          // Buttons
          Row(
            children: [
              if (secondaryButtonText != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      secondaryButtonText!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
